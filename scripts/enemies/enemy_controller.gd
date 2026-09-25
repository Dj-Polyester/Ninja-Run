class_name EnemyController
extends CharacterBody2D
## Runtime body for one catalog definition. Level owns player damage authority.

const Policy = preload("res://scripts/enemies/enemy_attack_policy.gd")
const Projectile = preload("res://scripts/enemies/enemy_projectile.gd")
const AnimationLoader = preload("res://scripts/enemies/enemy_animation_loader.gd")
const Definition = preload("res://scripts/enemies/enemy_definition.gd")
const SpawnDescriptor = preload("res://scripts/enemies/enemy_spawn_descriptor.gd")

signal hit_requested(hit: DamageStatus.HitEnvelope)
signal died(enemy: EnemyController)
signal ranged_attack(enemy: EnemyController, kind: StringName)
signal melee_attack(enemy: EnemyController)

var definition: Definition
var descriptor: SpawnDescriptor
var health := 1.0
var dead := false
var retired := false
var policy := Policy.new()
var patrol_origin := 0.0
var patrol_direction := 1.0
var last_player_melee_at: float = -INF
var target: PlayerController
var director: RunDirector
var camera: Camera2D
var attack_parent: Node
var animation_loader: AnimationLoader
var _animation_cache_key: StringName = &""
var _sprite: AnimatedSprite2D
var _health_bar: ProgressBar

func configure(new_definition: Definition, new_descriptor: SpawnDescriptor, new_target: PlayerController, new_director: RunDirector, new_camera: Camera2D, new_attack_parent: Node, new_animation_loader: AnimationLoader = null) -> bool:
	if new_definition == null or new_descriptor == null or new_director == null:
		return false
	if not new_definition.is_valid() or not new_descriptor.is_valid():
		return false
	definition = new_definition
	descriptor = new_descriptor
	target = new_target
	director = new_director
	camera = new_camera
	attack_parent = new_attack_parent
	animation_loader = new_animation_loader if new_animation_loader != null else AnimationLoader.new()
	health = definition.maximum_health * (1.0 + 0.15 * float(maxi(0, descriptor.tier - 1)))
	return true

func _ready() -> void:
	if definition == null or descriptor == null:
		push_error("EnemyController must be configured before entering the tree.")
		set_physics_process(false)
		return
	add_to_group(&"enemies")
	patrol_origin = global_position.x
	collision_layer = GameConfig.ENEMY_COLLISION_LAYER
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(GameConfig.ENEMY_BODY_WIDTH, GameConfig.ENEMY_BODY_HEIGHT)
	collision.shape = shape
	add_child(collision)
	_health_bar = ProgressBar.new()
	_health_bar.position = Vector2(-24, -GameConfig.ENEMY_BODY_HEIGHT * 0.5 - 18)
	_health_bar.size = Vector2(48, 7)
	_health_bar.max_value = health
	_health_bar.value = health
	_health_bar.show_percentage = false
	add_child(_health_bar)
	_install_lazy_sprite()

func _install_lazy_sprite() -> void:
	if definition == null or definition.sprite_path.is_empty() or animation_loader == null:
		return
	_animation_cache_key = StringName("%s:%s:idle" % [definition.id, descriptor.variant_id])
	var idle_frames := definition.idle_frames_for_variant(descriptor.variant_id)
	if idle_frames.is_empty():
		return
	_sprite = animation_loader.create_animated_sprite(idle_frames, _animation_cache_key, &"Idle", 6.0, true)
	if _sprite != null:
		_sprite.scale = Vector2(0.12, 0.12)
		_sprite.position = Vector2(0, -20)
		_sprite.play(&"Idle")
		add_child(_sprite)

func update_runtime(delta: float, simulation_time: float, visible_to_camera: bool, target_in_camera: bool, line_of_sight: bool, target_visible: bool, interval_multiplier: float) -> void:
	if dead or retired or definition == null or director == null:
		return
	if director.state != RunDirector.State.RUNNING:
		return
	_update_movement(delta)
	var target_position := global_position
	if target != null and is_instance_valid(target):
		target_position = target.global_position
	var decision := policy.decide(definition, simulation_time, global_position, target_position, target_visible, visible_to_camera, line_of_sight, interval_multiplier, target_in_camera)
	if bool(decision[&"melee"]):
		melee_attack.emit(self)
		hit_requested.emit(_hit_envelope())
	if bool(decision[&"ranged"]):
		ranged_attack.emit(self, _ranged_kind())
		_emit_ranged(target_position)

func _update_movement(_delta: float) -> void:
	if definition.movement_type != Definition.MOVEMENT_PATROL:
		velocity = Vector2.ZERO
		return
	var surface_left := GameConfig.RUN_ORIGIN_X + float(descriptor.support_x_begin) * GameConfig.TILE_SIZE
	var surface_right := GameConfig.RUN_ORIGIN_X + float(descriptor.support_x_end - 1) * GameConfig.TILE_SIZE
	var left_limit := maxf(surface_left, patrol_origin - GameConfig.ENEMY_PATROL_RADIUS)
	var right_limit := minf(surface_right, patrol_origin + GameConfig.ENEMY_PATROL_RADIUS)
	if right_limit <= left_limit:
		velocity = Vector2.ZERO
		return
	if patrol_direction > 0.0 and global_position.x >= right_limit:
		patrol_direction = -1.0
	elif patrol_direction < 0.0 and global_position.x <= left_limit:
		patrol_direction = 1.0
	velocity = Vector2(patrol_direction * definition.movement_speed, 0.0)
	move_and_slide()
	global_position.x = clampf(global_position.x, left_limit, right_limit)

func _hit_envelope() -> DamageStatus.HitEnvelope:
	var scaled_damage := definition.contact_damage * (1.0 + 0.10 * float(maxi(0, descriptor.tier - 1)))
	return DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(scaled_damage, definition.id), definition.effect_spec, definition.id)

func _ranged_kind() -> StringName:
	return definition.ranged_kind

func _emit_ranged(target_position: Vector2) -> void:
	if attack_parent == null or not is_instance_valid(attack_parent):
		return
	if target == null or not is_instance_valid(target):
		return
	if _ranged_kind() == &"beam":
		var beam := Line2D.new()
		beam.width = 4.0
		beam.default_color = Color(0.65, 0.25, 1.0, 0.9)
		beam.points = PackedVector2Array([global_position, target_position])
		attack_parent.add_child(beam)
		hit_requested.emit(_hit_envelope())
		beam.call_deferred("queue_free")
		return
	var particles := GPUParticles2D.new()
	particles.position = global_position
	particles.amount = 8
	particles.lifetime = 0.25
	particles.one_shot = true
	particles.explosiveness = 0.85
	var particle_material := ParticleProcessMaterial.new()
	var particle_direction := (target_position - global_position).normalized()
	particle_material.direction = Vector3(particle_direction.x, particle_direction.y, 0.0)
	particle_material.spread = 12.0
	particle_material.initial_velocity_min = 180.0
	particle_material.initial_velocity_max = 260.0
	particle_material.gravity = Vector3.ZERO
	particles.process_material = particle_material
	particles.texture = load("res://assets/Particles/flame10/images/light.png") as Texture2D
	particles.finished.connect(Callable(particles, "queue_free"), CONNECT_ONE_SHOT)
	attack_parent.add_child(particles)
	particles.emitting = true
	var projectile := Projectile.new()
	attack_parent.add_child(projectile)
	var projectile_hit := _hit_envelope()
	if not projectile.configure(global_position + Vector2(0, -16), target_position - global_position, GameConfig.ENEMY_PROJECTILE_SPEED, projectile_hit, target, director):
		projectile.queue_free()
		return
	if attack_parent.has_method(&"_on_enemy_projectile_resolved"):
		projectile.resolved.connect(Callable(attack_parent, &"_on_enemy_projectile_resolved"))

func receive_player_melee(amount: float, simulation_time: float) -> bool:
	if dead or retired or director == null or director.state != RunDirector.State.RUNNING:
		return false
	if not is_finite(amount) or amount <= 0.0 or not is_finite(simulation_time):
		return false
	if simulation_time < last_player_melee_at + GameConfig.PLAYER_MELEE_INTERVAL:
		return false
	last_player_melee_at = simulation_time
	return apply_damage(amount)

func apply_damage(amount: float) -> bool:
	if dead or not is_finite(amount) or amount <= 0.0:
		return false
	health = maxf(0.0, health - amount)
	if _health_bar != null:
		_health_bar.value = health
	if health <= 0.0:
		dead = true
		collision_layer = 0
		died.emit(self)
		queue_free()
	return true

func retire() -> void:
	if retired:
		return
	retired = true
	collision_layer = 0
	if not dead:
		queue_free()

func _exit_tree() -> void:
	if animation_loader != null and not _animation_cache_key.is_empty():
		animation_loader.release(_animation_cache_key)
		_animation_cache_key = &""
