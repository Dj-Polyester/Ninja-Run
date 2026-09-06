class_name NinjaPlayer
extends CharacterBody2D

const DAMAGE_INFO_SCRIPT := preload("res://src/gameplay/combat/damage_info.gd")

signal died(reason: String)
signal health_changed(current: float, maximum: float)
signal melee_attacked(target: Node, damage: float)
signal detectability_changed(detectable: bool)

enum State { RUNNING, JUMPING, FALLING, ROLLING, GLIDING, DASHING, DEAD, REVIVAL_WAIT }

var state := State.RUNNING
var current_health := 0.0
var maximum_health := 0.0
var defense_multiplier := 1.0
var roll_time_remaining := 0.0
var invulnerability_remaining := 0.0
var damage_flash_remaining := 0.0
var current_biome_id := BiomeData.Id.GRASS
var temporary_jump_modifier := 0.0
var active_statuses: Dictionary = {}
var last_damage_info
var melee_animation_remaining := 0.0
var gravity_direction := 1.0
var detectable := true
var wall_jump_push_remaining := 0.0
var wall_jump_velocity_x := 0.0

@onready var standing_collision: CollisionShape2D = $StandingCollision
@onready var rolling_collision: CollisionShape2D = $RollingCollision
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var burn_particles: GPUParticles2D = $BurnParticles
@onready var melee_controller = $MeleeDetector
@onready var weapon_controller = $WeaponController
@onready var ability_controller: AbilityController = $AbilityController

func _ready() -> void:
	maximum_health = float(GameState.stat_value(&"maximum_health"))
	defense_multiplier = maxf(0.0, float(GameState.stat_value(&"defense_multiplier")))
	current_health = maximum_health
	_configure_collision_shapes()
	_configure_burn_particles()
	_build_animations(int(GameState.profile.get("selected_character", 1)))
	set_gravity_direction(1.0)
	set_detectable(true)
	_set_roll_collision(false)
	_play_animation("run")
	health_changed.emit(current_health, maximum_health)

func _physics_process(delta: float) -> void:
	_update_feedback(delta)
	_update_melee_animation(delta)
	ability_controller.tick(delta)
	if state == State.DEAD or state == State.REVIVAL_WAIT:
		velocity = Vector2.ZERO
		return

	var previous_position := global_position
	var dash_speed := ability_controller.horizontal_speed(delta)
	if dash_speed > 0.0:
		velocity.x = dash_speed
	elif wall_jump_push_remaining > 0.0:
		velocity.x = wall_jump_velocity_x
		wall_jump_push_remaining = maxf(0.0, wall_jump_push_remaining - delta)
	else:
		velocity.x = run_speed_pixels()
	if not is_supported():
		var gravity_multiplier := ability_controller.gravity_multiplier(delta)
		velocity.y += GameConfig.GRAVITY * gravity_direction * gravity_multiplier * delta
	move_and_slide()
	ability_controller.after_move(previous_position)
	var supported := is_supported()
	ability_controller.update_support_state(supported)

	if state == State.ROLLING:
		roll_time_remaining -= delta
		if roll_time_remaining <= 0.0:
			_finish_roll()
	if state != State.ROLLING:
		if ability_controller.is_dashing():
			_set_state(State.DASHING)
		elif ability_controller.is_gliding():
			_set_state(State.GLIDING)
		elif supported:
			_set_state(State.RUNNING)
		elif velocity.y * gravity_direction < 0.0:
			_set_state(State.JUMPING)
		else:
			_set_state(State.FALLING)

	if global_position.y > GameConfig.KILL_PLANE_Y:
		die("fall")
		return

	_try_automatic_melee()

func trigger_jump() -> void:
	if state == State.DEAD or state == State.REVIVAL_WAIT or state == State.ROLLING:
		return
	ability_controller.handle_jump_pressed()

func release_jump() -> void:
	ability_controller.handle_jump_released()

func perform_jump(wall_normal: Vector2 = Vector2.ZERO) -> void:
	velocity.y = -gravity_direction * jump_speed_pixels()
	if not is_zero_approx(wall_normal.x):
		wall_jump_velocity_x = wall_normal.x * GameConfig.tiles_to_pixels(GameConfig.WALL_JUMP_HORIZONTAL_SPEED)
		wall_jump_push_remaining = GameConfig.WALL_JUMP_PUSH_DURATION
		velocity.x = wall_jump_velocity_x
	_set_state(State.JUMPING)

func trigger_roll() -> void:
	if state == State.DEAD or state == State.REVIVAL_WAIT or state == State.ROLLING:
		return
	if not is_supported():
		return
	roll_time_remaining = GameConfig.ROLL_DURATION
	_set_roll_collision(true)
	_set_state(State.ROLLING)

func take_damage(amount: float, damage_info = null) -> void:
	if state == State.DEAD or state == State.REVIVAL_WAIT or invulnerability_remaining > 0.0:
		return
	last_damage_info = damage_info
	var final_damage := maxf(0.0, amount) * defense_multiplier
	if final_damage <= 0.0:
		return
	current_health = maxf(0.0, current_health - final_damage)
	invulnerability_remaining = GameConfig.DAMAGE_INVULNERABILITY
	damage_flash_remaining = GameConfig.DAMAGE_FLASH_DURATION
	sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
	if damage_info != null:
		if not damage_info.status_effect.is_empty():
			apply_status(damage_info.status_effect)
		if damage_info.knockback != Vector2.ZERO:
			velocity += damage_info.knockback
	GameState.set_run_health(current_health)
	health_changed.emit(current_health, maximum_health)
	if current_health <= 0.0:
		die("damage")

func heal(amount: float) -> void:
	if amount <= 0.0 or state == State.DEAD:
		return
	current_health = minf(maximum_health, current_health + amount)
	GameState.set_run_health(current_health)
	health_changed.emit(current_health, maximum_health)

func set_biome_context(biome: BiomeData, jump_modifier: float = 0.0) -> void:
	if biome == null:
		current_biome_id = BiomeData.Id.GRASS
		temporary_jump_modifier = 0.0
		return
	current_biome_id = biome.id
	temporary_jump_modifier = jump_modifier if biome.id == BiomeData.Id.SNOW else 0.0

func effective_max_jump_tiles() -> float:
	return maxf(0.1, GameConfig.MAX_JUMP + temporary_jump_modifier)

func apply_status(effect: Dictionary) -> void:
	var status_id := StringName(effect.get("id", &""))
	if status_id == &"":
		return
	var duration := maxf(0.0, float(effect.get("duration", 0.0)))
	active_statuses[status_id] = maxf(float(active_statuses.get(status_id, 0.0)), duration)
	if status_id == &"burn":
		burn_particles.emitting = duration > 0.0

func status_remaining(status_id: StringName) -> float:
	return float(active_statuses.get(status_id, 0.0))

func die(reason: String = "damage") -> void:
	if state == State.DEAD or state == State.REVIVAL_WAIT:
		return
	current_health = 0.0
	GameState.set_run_health(current_health)
	health_changed.emit(current_health, maximum_health)
	ability_controller.cancel_active_effects()
	wall_jump_push_remaining = 0.0
	set_detectable(true)
	_set_roll_collision(false)
	_set_state(State.DEAD)
	died.emit(reason)

func enter_revival_wait() -> void:
	if state != State.DEAD:
		return
	velocity = Vector2.ZERO
	_set_roll_collision(false)
	_set_state(State.REVIVAL_WAIT)

func revive_at(checkpoint_position: Vector2, restored_health: float = -1.0) -> void:
	ability_controller.cancel_active_effects(true)
	wall_jump_push_remaining = 0.0
	set_gravity_direction(1.0)
	set_detectable(true)
	global_position = checkpoint_position
	velocity = Vector2.ZERO
	current_health = maximum_health if restored_health < 0.0 else clampf(restored_health, 1.0, maximum_health)
	active_statuses.clear()
	burn_particles.emitting = false
	damage_flash_remaining = 0.0
	invulnerability_remaining = GameConfig.REVIVE_INVULNERABILITY
	sprite.modulate = Color.WHITE
	_set_roll_collision(false)
	_set_state(State.FALLING)
	GameState.set_run_health(current_health)
	health_changed.emit(current_health, maximum_health)

func run_speed_pixels() -> float:
	return GameConfig.tiles_to_pixels(GameConfig.SPEED) * WorldSpeed.player_speed_multiplier

func jump_speed_pixels() -> float:
	return sqrt(2.0 * GameConfig.GRAVITY * GameConfig.tiles_to_pixels(effective_max_jump_tiles()))

func melee_power() -> float:
	return maxf(0.0, float(GameState.stat_value(&"melee_power")))

func can_use_weapons() -> bool:
	return state != State.DEAD and state != State.REVIVAL_WAIT

func can_activate_abilities() -> bool:
	return state != State.DEAD and state != State.REVIVAL_WAIT

func trigger_ability(ability_id: StringName) -> bool:
	return ability_controller.activate_ability(ability_id)

func ability_cooldown_remaining(ability_id: StringName) -> float:
	return ability_controller.cooldown_remaining(ability_id)

func is_supported() -> bool:
	# CharacterBody2D evaluates floor contacts relative to up_direction. The
	# gravity setter flips up_direction, so is_on_floor() remains the correct
	# support query even while gravity points upward.
	return is_on_floor()

func set_gravity_direction(direction: float) -> void:
	gravity_direction = -1.0 if direction < 0.0 else 1.0
	up_direction = Vector2(0.0, -gravity_direction)
	if sprite != null:
		sprite.flip_v = gravity_direction < 0.0

func set_detectable(value: bool) -> void:
	if detectable == value:
		_apply_feedback_color()
		return
	detectable = value
	detectability_changed.emit(detectable)
	_apply_feedback_color()

func is_detectable() -> bool:
	return detectable

func _try_automatic_melee() -> void:
	var target: Node = melee_controller.try_attack(self, melee_power())
	if target == null:
		return
	melee_animation_remaining = _animation_duration(&"melee")
	if melee_animation_remaining <= 0.0:
		melee_animation_remaining = GameConfig.MELEE_ATTACK_INTERVAL
	_play_animation(&"melee")
	melee_attacked.emit(target, melee_controller.last_damage)

func _update_melee_animation(delta: float) -> void:
	if melee_animation_remaining <= 0.0:
		return
	melee_animation_remaining = maxf(0.0, melee_animation_remaining - delta)
	if melee_animation_remaining <= 0.0:
		_play_state_animation()

func _finish_roll() -> void:
	_set_roll_collision(false)
	_set_state(State.RUNNING if is_supported() else State.FALLING)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		trigger_jump()
	elif event.is_action_released("jump"):
		release_jump()
	elif event.is_action_pressed("roll"):
		trigger_roll()

func _set_roll_collision(rolling: bool) -> void:
	standing_collision.disabled = rolling
	rolling_collision.disabled = not rolling

func _configure_collision_shapes() -> void:
	var standing_shape := standing_collision.shape as RectangleShape2D
	standing_shape.size = Vector2(GameConfig.PLAYER_COLLISION_WIDTH, GameConfig.PLAYER_COLLISION_HEIGHT)
	var rolling_shape := rolling_collision.shape as RectangleShape2D
	var rolling_height := GameConfig.PLAYER_COLLISION_HEIGHT * GameConfig.ROLL_HEIGHT_RATIO
	rolling_shape.size = Vector2(GameConfig.PLAYER_COLLISION_WIDTH, rolling_height)
	rolling_collision.position.y = (GameConfig.PLAYER_COLLISION_HEIGHT - rolling_height) * 0.5

func _configure_burn_particles() -> void:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 35.0
	material.initial_velocity_min = 18.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3(0.0, -12.0, 0.0)
	material.scale_min = 0.12
	material.scale_max = 0.3
	burn_particles.process_material = material
	if DisplayServer.get_name() != "headless":
		var texture := load("res://assets/Particles/flame3/png/flame_00.png") as Texture2D
		if texture != null:
			burn_particles.texture = texture

func _set_state(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state
	_play_state_animation()

func _play_state_animation() -> void:
	match state:
		State.RUNNING:
			_play_animation("run")
		State.JUMPING:
			_play_animation("jump")
		State.FALLING:
			_play_animation("fall")
		State.ROLLING:
			_play_animation("roll")
		State.GLIDING:
			_play_animation("fall")
		State.DASHING:
			_play_animation("run")
		State.DEAD:
			_play_animation("dead")

func _update_feedback(delta: float) -> void:
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)
	damage_flash_remaining = maxf(0.0, damage_flash_remaining - delta)
	for status_id in active_statuses.keys():
		var remaining := maxf(0.0, float(active_statuses[status_id]) - delta)
		if remaining <= 0.0:
			active_statuses.erase(status_id)
		else:
			active_statuses[status_id] = remaining
	burn_particles.emitting = active_statuses.has(&"burn")
	_apply_feedback_color()

func _apply_feedback_color() -> void:
	if sprite == null:
		return
	var alpha := 1.0 if detectable else GameConfig.INVISIBILITY_ALPHA
	if damage_flash_remaining > 0.0:
		sprite.modulate = Color(1.0, 0.2, 0.2, alpha)
	elif active_statuses.has(&"burn"):
		sprite.modulate = Color(1.0, 0.65, 0.3, alpha)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, alpha)

func _build_animations(character_id: int) -> void:
	var base := "res://assets/Characters/%d/Png/Character Sprite" % character_id
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	if DisplayServer.get_name() == "headless":
		_add_headless_animation(frames, "run")
		_add_headless_animation(frames, "jump")
		_add_headless_animation(frames, "fall")
		_add_headless_animation(frames, "roll")
		_add_headless_animation(frames, "dead")
		_add_headless_animation(frames, "melee")
		sprite.sprite_frames = frames
		return
	_add_animation(frames, "run", base.path_join("Fast Run"), 12.0, true)
	_add_animation(frames, "jump", base.path_join("Jump Before"), 16.0, false)
	_add_animation(frames, "fall", base.path_join("Fall"), 12.0, true)
	_add_animation(frames, "roll", base.path_join("Roll"), 14.0, true)
	_add_animation(frames, "dead", base.path_join("Dead"), 12.0, false)
	_add_animation(frames, "melee", base.path_join("Shoot"), 16.0, false)
	sprite.sprite_frames = frames

func _add_animation(frames: SpriteFrames, animation_name: StringName, folder: String, fps: float, looped: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looped)
	var files := DirAccess.get_files_at(folder)
	files.sort()
	for file_name in files:
		if not file_name.to_lower().ends_with(".png"):
			continue
		var texture := load(folder.path_join(file_name)) as Texture2D
		if texture != null:
			frames.add_frame(animation_name, texture)

func _add_headless_animation(frames: SpriteFrames, animation_name: StringName) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)

func _animation_duration(animation_name: StringName) -> float:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	var fps := sprite.sprite_frames.get_animation_speed(animation_name)
	if frame_count <= 0 or fps <= 0.0:
		return 0.0
	return float(frame_count) / fps

func _play_animation(animation_name: StringName) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		return
	sprite.animation = animation_name
	if sprite.sprite_frames.get_frame_count(animation_name) > 0:
		sprite.play(animation_name)
