class_name Enemy
extends CharacterBody2D

const DAMAGE_INFO_SCRIPT := preload("res://src/gameplay/combat/damage_info.gd")
const ENEMY_DATA_SCRIPT := preload("res://src/data/enemy_data.gd")
const ENEMY_HEALTH_COMPONENT_SCRIPT := preload("res://src/gameplay/enemies/enemy_health_component.gd")
const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")
const ENEMY_BEAM_SCENE := preload("res://scenes/enemies/enemy_beam.tscn")

signal health_changed(current: float, maximum: float)
signal died(enemy: Enemy)
signal melee_attacked(target: Node, damage: float)
signal shot_fired(projectile_or_beam: Node, target: Node)

var data
var enemy_level := 1
var current_health := 1.0
var maximum_health := 1.0
var dead := false
var spawn_x := 0.0
var patrol_direction := -1.0
var melee_cooldown_remaining := 0.0
var shooting_cooldown_remaining := 0.0
var hit_flash_remaining := 0.0
var death_cleanup_remaining := 0.0
var target_player: Node2D
var projectile_parent: Node
var effects_parent: Node
var status_tick_flash_remaining := 0.0

var active_statuses: Dictionary:
	get:
		if status_controller == null:
			return {}
		return status_controller.remaining_snapshot()

@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component = $HealthComponent
@onready var status_controller = $StatusEffectController
@onready var health_bar: ProgressBar = $HealthBar
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var melee_area: Area2D = $MeleeArea
@onready var melee_shape: CollisionShape2D = $MeleeArea/CollisionShape2D
@onready var shooting_origin: Node2D = $ShootingOrigin

func _ready() -> void:
	add_to_group(&"enemies")
	health_component.health_changed.connect(_on_component_health_changed)
	collision_layer = GameConfig.ENEMY_COLLISION_MASK
	collision_mask = GameConfig.TERRAIN_COLLISION_LAYER
	hurtbox.collision_layer = GameConfig.ENEMY_COLLISION_MASK
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurtbox.monitorable = true
	detection_area.collision_layer = 0
	detection_area.collision_mask = GameConfig.PLAYER_COLLISION_LAYER
	detection_area.monitorable = false
	melee_area.collision_layer = 0
	melee_area.collision_mask = GameConfig.PLAYER_COLLISION_LAYER
	melee_area.monitorable = false
	_configure_body_shapes()

func configure(enemy_data, level: int, player: Node2D, projectile_container: Node = null, effect_container: Node = null) -> void:
	data = enemy_data
	enemy_level = maxi(1, level)
	target_player = player
	projectile_parent = projectile_container
	effects_parent = effect_container
	spawn_x = global_position.x
	dead = false
	health_component.configure(data.health_for_level(enemy_level) if data != null else 1.0)
	melee_cooldown_remaining = 0.0
	shooting_cooldown_remaining = _initial_shooting_delay()
	_configure_ranges()
	_build_animations()
	_play_animation(&"idle")

func _physics_process(delta: float) -> void:
	_update_feedback(delta)
	if dead:
		death_cleanup_remaining -= delta
		velocity = Vector2.ZERO
		if death_cleanup_remaining <= 0.0:
			queue_free()
		return
	if data == null:
		return
	status_controller.tick(delta)
	if dead:
		return

	melee_cooldown_remaining = maxf(0.0, melee_cooldown_remaining - delta)
	shooting_cooldown_remaining = maxf(0.0, shooting_cooldown_remaining - delta)
	_update_movement(delta)
	_update_attacks()

func _update_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GameConfig.GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if data.movement_mode == ENEMY_DATA_SCRIPT.MovementMode.PATROL:
		var range_pixels := GameConfig.tiles_to_pixels(maxf(0.0, data.patrol_range_tiles))
		if global_position.x <= spawn_x - range_pixels:
			patrol_direction = 1.0
		elif global_position.x >= spawn_x + range_pixels:
			patrol_direction = -1.0
		velocity.x = patrol_direction * GameConfig.tiles_to_pixels(data.move_speed_tiles) * WorldSpeed.enemy_move_multiplier * status_controller.movement_speed_multiplier()
	else:
		velocity.x = 0.0

	move_and_slide()
	if is_on_wall() and data.movement_mode == ENEMY_DATA_SCRIPT.MovementMode.PATROL:
		patrol_direction *= -1.0
	if absf(velocity.x) > 0.01:
		sprite.flip_h = velocity.x > 0.0
		if not _is_attack_animation_playing():
			_play_animation(&"walk")
	elif not _is_attack_animation_playing():
		_play_animation(&"idle")

func _update_attacks() -> void:
	if target_player == null or not is_instance_valid(target_player) or not _player_is_detectable():
		return
	var distance := global_position.distance_to(target_player.global_position)
	if data.has_attack(ENEMY_DATA_SCRIPT.AttackMode.MELEE) and distance <= GameConfig.tiles_to_pixels(data.melee_range_tiles):
		_try_melee_attack()
	if data.has_attack(ENEMY_DATA_SCRIPT.AttackMode.SHOOT) and distance <= GameConfig.tiles_to_pixels(data.vicinity_tiles):
		_try_shoot()

func _try_melee_attack() -> bool:
	if melee_cooldown_remaining > 0.0 or not _player_is_detectable():
		return false
	if target_player == null or not is_instance_valid(target_player):
		return false
	if global_position.distance_to(target_player.global_position) > GameConfig.tiles_to_pixels(data.melee_range_tiles):
		return false
	if not target_player.has_method(&"take_damage"):
		return false
	var damage := damage_amount()
	var info = DAMAGE_INFO_SCRIPT.new(self, DAMAGE_INFO_SCRIPT.DamageType.MELEE, data.status_effect)
	target_player.call(&"take_damage", damage, info)
	melee_cooldown_remaining = maxf(0.01, data.melee_interval)
	sprite.flip_h = target_player.global_position.x > global_position.x
	_play_animation(&"melee")
	melee_attacked.emit(target_player, damage)
	return true

func _try_shoot() -> bool:
	if shooting_cooldown_remaining > 0.0 or not _player_is_detectable():
		return false
	if target_player == null or not is_instance_valid(target_player):
		return false
	if global_position.distance_to(target_player.global_position) > GameConfig.tiles_to_pixels(data.vicinity_tiles):
		return false
	var parent := _projectile_parent()
	if parent == null:
		return false
	var attack_node: Node2D
	if data.ranged_style == ENEMY_DATA_SCRIPT.RangedStyle.BEAM:
		attack_node = ENEMY_BEAM_SCENE.instantiate() as Node2D
		parent.add_child(attack_node)
		attack_node.global_position = shooting_origin.global_position
		attack_node.call(&"configure", self, target_player.global_position, damage_amount(), data.status_effect)
	else:
		attack_node = ENEMY_PROJECTILE_SCENE.instantiate() as Node2D
		parent.add_child(attack_node)
		attack_node.global_position = shooting_origin.global_position
		attack_node.call(&"configure", self, target_player.global_position, damage_amount(), data.status_effect, data.projectile_speed_pixels())
	shooting_cooldown_remaining = effective_shooting_interval()
	sprite.flip_h = target_player.global_position.x > global_position.x
	_play_animation(&"shoot")
	shot_fired.emit(attack_node, target_player)
	return true

func take_damage(amount: float, damage_info = null) -> void:
	if dead:
		return
	var applied: float = health_component.take_damage(amount * status_controller.damage_taken_multiplier())
	if applied <= 0.0:
		return
	if damage_info != null and damage_info.status_effect != null:
		apply_status(damage_info.status_effect)
	hit_flash_remaining = GameConfig.ENEMY_DAMAGE_FLASH_DURATION
	if health_component.is_depleted():
		die()
	else:
		_play_animation(&"hurt")

func heal(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	health_component.heal(amount)

func apply_status(effect) -> bool:
	if dead:
		return false
	return status_controller.apply(effect)

func status_remaining(status_id: StringName) -> float:
	return status_controller.remaining(status_id)

func status_stacks(status_id: StringName) -> int:
	return status_controller.stacks(status_id)

func die() -> void:
	if dead:
		return
	dead = true
	health_component.kill()
	velocity = Vector2.ZERO
	body_collision.set_deferred(&"disabled", true)
	hurtbox_collision.set_deferred(&"disabled", true)
	status_controller.clear_all()
	death_cleanup_remaining = GameConfig.ENEMY_DEATH_CLEANUP_DELAY
	_update_health_bar()
	_play_animation(&"dead")
	died.emit(self)

func damage_amount() -> float:
	return data.damage_for_level(enemy_level) if data != null else 0.0

func effective_shooting_interval() -> float:
	if data == null:
		return INF
	var profile_multiplier := maxf(0.01, float(GameState.stat_value(&"enemy_fire_interval_multiplier")))
	return maxf(0.01, data.shooting_interval * profile_multiplier * WorldSpeed.enemy_fire_interval_multiplier)

func can_receive_melee_attack() -> bool:
	return not dead

func can_receive_projectile_attack() -> bool:
	return not dead

func _player_is_detectable() -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	if target_player.has_method(&"is_detectable"):
		return bool(target_player.call(&"is_detectable"))
	return true

func _projectile_parent() -> Node:
	if projectile_parent != null and is_instance_valid(projectile_parent):
		return projectile_parent
	if get_parent() != null:
		var sibling := get_parent().get_parent().get_node_or_null("ProjectileContainer") if get_parent().get_parent() != null else null
		if sibling != null:
			return sibling
	return get_parent()

func _initial_shooting_delay() -> float:
	if data == null or not data.has_attack(ENEMY_DATA_SCRIPT.AttackMode.SHOOT):
		return 0.0
	return minf(GameConfig.ENEMY_INITIAL_SHOOT_DELAY, maxf(0.0, data.shooting_interval * 0.35))

func _configure_body_shapes() -> void:
	var body_rectangle := body_collision.shape as RectangleShape2D
	if body_rectangle == null:
		body_rectangle = RectangleShape2D.new()
		body_collision.shape = body_rectangle
	body_rectangle.size = Vector2(GameConfig.ENEMY_COLLISION_WIDTH, GameConfig.ENEMY_COLLISION_HEIGHT)
	var hurt_rectangle := hurtbox_collision.shape as RectangleShape2D
	if hurt_rectangle == null:
		hurt_rectangle = RectangleShape2D.new()
		hurtbox_collision.shape = hurt_rectangle
	hurt_rectangle.size = body_rectangle.size

func _configure_ranges() -> void:
	if data == null:
		return
	var detection_circle := detection_shape.shape as CircleShape2D
	if detection_circle == null:
		detection_circle = CircleShape2D.new()
		detection_shape.shape = detection_circle
	detection_circle.radius = GameConfig.tiles_to_pixels(data.vicinity_tiles)
	var melee_circle := melee_shape.shape as CircleShape2D
	if melee_circle == null:
		melee_circle = CircleShape2D.new()
		melee_shape.shape = melee_circle
	melee_circle.radius = GameConfig.tiles_to_pixels(data.melee_range_tiles)

func _update_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.max_value = maxf(1.0, maximum_health)
	health_bar.value = current_health
	health_bar.visible = not dead

func _on_component_health_changed(current: float, maximum: float) -> void:
	current_health = current
	maximum_health = maximum
	_update_health_bar()
	health_changed.emit(current_health, maximum_health)

func _update_feedback(delta: float) -> void:
	hit_flash_remaining = maxf(0.0, hit_flash_remaining - delta)
	status_tick_flash_remaining = maxf(0.0, status_tick_flash_remaining - delta)
	if sprite != null:
		if hit_flash_remaining > 0.0 or status_tick_flash_remaining > 0.0:
			sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			sprite.modulate = status_controller.visual_tint() if status_controller != null else Color.WHITE

func apply_status_tick_damage(amount: float, effect: Resource) -> void:
	if dead or amount <= 0.0:
		return
	var applied: float = health_component.take_damage(amount * status_controller.damage_taken_multiplier())
	if applied <= 0.0:
		return
	if effect != null and bool(effect.blink_red_on_tick):
		status_tick_flash_remaining = GameConfig.STATUS_TICK_FLASH_DURATION
	if health_component.is_depleted():
		die()

func status_effect_applied(_effect: Resource, _stacks: int) -> void:
	_update_feedback(0.0)

func status_effect_ticked(effect: Resource, _stacks: int) -> void:
	if effect != null and bool(effect.blink_red_on_tick):
		status_tick_flash_remaining = GameConfig.STATUS_TICK_FLASH_DURATION
	_update_feedback(0.0)

func status_effect_removed(_effect: Resource) -> void:
	_update_feedback(0.0)

func _build_animations() -> void:
	if sprite == null or data == null:
		return
	sprite.scale = Vector2.ONE * data.sprite_scale
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	if DisplayServer.get_name() == "headless":
		for animation_name in [&"idle", &"walk", &"melee", &"shoot", &"hurt", &"dead"]:
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, animation_name in [&"idle", &"walk"])
		sprite.sprite_frames = frames
		return
	_add_animation(frames, &"idle", data.idle_animation_folder, 10.0, true)
	_add_animation(frames, &"walk", data.walk_animation_folder, 12.0, true)
	_add_animation(frames, &"melee", data.melee_animation_folder, 14.0, false)
	_add_animation(frames, &"shoot", data.shoot_animation_folder, 14.0, false)
	_add_animation(frames, &"hurt", data.hurt_animation_folder, 14.0, false)
	_add_animation(frames, &"dead", data.death_animation_folder, 12.0, false)
	sprite.sprite_frames = frames

func _add_animation(frames: SpriteFrames, animation_name: StringName, folder_name: String, fps: float, looped: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looped)
	if folder_name.is_empty() or data.animation_root.is_empty():
		return
	var folder: String = String(data.animation_root).path_join(folder_name)
	var files := ResourceLoader.list_directory(folder)
	if files.is_empty():
		files = DirAccess.get_files_at(folder)
	files.sort()
	var loaded := 0
	for file_name in files:
		if not file_name.to_lower().ends_with(".png"):
			continue
		var texture := _load_texture(folder.path_join(file_name))
		if texture != null:
			frames.add_frame(animation_name, texture)
			loaded += 1
		if loaded >= GameConfig.ENEMY_ANIMATION_MAX_FRAMES:
			break

func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute_path) and image.load(absolute_path) == OK and not image.is_empty():
		return ImageTexture.create_from_image(image)
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return null

func _play_animation(animation_name: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		return
	if sprite.animation == animation_name and sprite.is_playing():
		return
	sprite.animation = animation_name
	if sprite.sprite_frames.get_frame_count(animation_name) > 0:
		sprite.play(animation_name)

func _is_attack_animation_playing() -> bool:
	return sprite != null and sprite.is_playing() and sprite.animation in [&"melee", &"shoot", &"hurt"]
