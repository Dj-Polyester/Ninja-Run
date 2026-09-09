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
	if not _validate_animation_root():
		sprite.sprite_frames = frames
		return
	_add_animation(frames, &"idle", data.idle_animation_folder, 10.0, true, true)
	_add_animation(frames, &"walk", data.walk_animation_folder, 12.0, true, true)
	_add_animation(frames, &"melee", data.melee_animation_folder, 14.0, false, data.has_attack(ENEMY_DATA_SCRIPT.AttackMode.MELEE))
	_add_animation(frames, &"shoot", data.shoot_animation_folder, 14.0, false, data.has_attack(ENEMY_DATA_SCRIPT.AttackMode.SHOOT))
	_add_animation(frames, &"hurt", data.hurt_animation_folder, 14.0, false, true)
	_add_animation(frames, &"dead", data.death_animation_folder, 12.0, false, true)
	_apply_animation_fallbacks(frames)
	sprite.sprite_frames = frames

func _validate_animation_root() -> bool:
	var enemy_id := _enemy_id_for_log()
	var root := String(data.animation_root)
	if root.is_empty():
		push_error("Enemy animation root missing enemy_id: %s" % enemy_id)
		return false
	if not root.begins_with("res://"):
		push_error("Enemy animation root must use res:// enemy_id: %s root: %s" % [enemy_id, root])
		return false
	if ResourceLoader.list_directory(root).is_empty():
		push_error("Enemy animation root inaccessible or empty enemy_id: %s root: %s" % [enemy_id, root])
		return false
	return true

func _add_animation(frames: SpriteFrames, animation_name: StringName, folder_name: String, fps: float, looped: bool, required: bool) -> int:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looped)
	var folder := ""
	if not folder_name.is_empty():
		folder = String(data.animation_root).path_join(folder_name)
	var loaded_frames := _load_animation_frames(frames, animation_name, folder)
	if loaded_frames == 0:
		var message := "Enemy animation load failed enemy_id: %s animation: %s folder: %s" % [_enemy_id_for_log(), String(animation_name), folder if not folder.is_empty() else "<empty>"]
		if required:
			push_error(message)
		else:
			push_warning(message)
	return loaded_frames

func _load_animation_frames(frames: SpriteFrames, animation_name: StringName, folder_path: String) -> int:
	if folder_path.is_empty():
		return 0
	var files: Array[String] = []
	for file_name in ResourceLoader.list_directory(folder_path):
		files.append(String(file_name))
	files.sort_custom(_natural_file_less)
	var loaded_frames := 0
	for file_name in files:
		if not file_name.to_lower().ends_with(".png"):
			continue
		var texture := ResourceLoader.load(folder_path.path_join(file_name)) as Texture2D
		if texture == null:
			push_warning("Enemy animation texture load failed enemy_id: %s animation: %s path: %s" % [_enemy_id_for_log(), String(animation_name), folder_path.path_join(file_name)])
			continue
		frames.add_frame(animation_name, texture)
		loaded_frames += 1
		if loaded_frames >= GameConfig.ENEMY_ANIMATION_MAX_FRAMES:
			break
	return loaded_frames

func _natural_file_less(left: String, right: String) -> bool:
	return left.naturalnocasecmp_to(right) < 0

func _apply_animation_fallbacks(frames: SpriteFrames) -> void:
	if frames.get_frame_count(&"idle") == 0:
		var idle_source := _first_animation_with_frames(frames, [&"walk", &"hurt", &"dead", &"melee", &"shoot"])
		if not idle_source.is_empty():
			_copy_animation_frames(frames, idle_source, &"idle")
			push_warning("Enemy idle animation fallback enemy_id: %s source: %s" % [_enemy_id_for_log(), String(idle_source)])
		else:
			push_error("Enemy has no usable animation frames enemy_id: %s root: %s" % [_enemy_id_for_log(), String(data.animation_root)])
			return

	for animation_name in [&"walk", &"melee", &"shoot", &"hurt", &"dead"]:
		if frames.get_frame_count(animation_name) > 0:
			continue
		_copy_animation_frames(frames, &"idle", animation_name)
		push_warning("Enemy animation fallback enemy_id: %s animation: %s source: idle" % [_enemy_id_for_log(), String(animation_name)])

func _first_animation_with_frames(frames: SpriteFrames, animation_names: Array) -> StringName:
	for animation_name in animation_names:
		if frames.has_animation(animation_name) and frames.get_frame_count(animation_name) > 0:
			return animation_name
	return &""

func _copy_animation_frames(frames: SpriteFrames, source_animation: StringName, target_animation: StringName) -> void:
	if not frames.has_animation(source_animation) or not frames.has_animation(target_animation):
		return
	for frame_index in range(frames.get_frame_count(source_animation)):
		frames.add_frame(
			target_animation,
			frames.get_frame_texture(source_animation, frame_index),
			frames.get_frame_duration(source_animation, frame_index)
		)

func _enemy_id_for_log() -> String:
	if data == null:
		return "<unknown>"
	var enemy_id := String(data.id)
	return enemy_id if not enemy_id.is_empty() else "<unknown>"

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
