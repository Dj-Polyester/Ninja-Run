class_name NinjaPlayer
extends CharacterBody2D

const DAMAGE_INFO_SCRIPT := preload("res://src/gameplay/combat/damage_info.gd")

signal died(reason: String)
signal health_changed(current: float, maximum: float)

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

@onready var standing_collision: CollisionShape2D = $StandingCollision
@onready var rolling_collision: CollisionShape2D = $RollingCollision
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var burn_particles: GPUParticles2D = $BurnParticles

func _ready() -> void:
	maximum_health = float(GameState.stat_value(&"maximum_health"))
	defense_multiplier = maxf(0.0, float(GameState.stat_value(&"defense_multiplier")))
	current_health = maximum_health
	_configure_collision_shapes()
	_configure_burn_particles()
	_build_animations(int(GameState.profile.get("selected_character", 1)))
	_set_roll_collision(false)
	_play_animation("run")
	health_changed.emit(current_health, maximum_health)

func _physics_process(delta: float) -> void:
	_update_feedback(delta)
	if state == State.DEAD or state == State.REVIVAL_WAIT:
		velocity = Vector2.ZERO
		return

	velocity.x = run_speed_pixels()
	if not is_on_floor():
		velocity.y += GameConfig.GRAVITY * delta
	move_and_slide()

	if state == State.ROLLING:
		roll_time_remaining -= delta
		if roll_time_remaining <= 0.0:
			_finish_roll()
	elif is_on_floor():
		_set_state(State.RUNNING)
	elif velocity.y < 0.0:
		_set_state(State.JUMPING)
	else:
		_set_state(State.FALLING)

	if global_position.y > GameConfig.KILL_PLANE_Y:
		die("fall")

func trigger_jump() -> void:
	if state == State.DEAD or state == State.REVIVAL_WAIT or state == State.ROLLING:
		return
	if not is_on_floor():
		return
	velocity.y = -jump_speed_pixels()
	_set_state(State.JUMPING)

func trigger_roll() -> void:
	if state == State.DEAD or state == State.REVIVAL_WAIT or state == State.ROLLING:
		return
	if not is_on_floor():
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
	return GameConfig.tiles_to_pixels(GameConfig.SPEED)

func jump_speed_pixels() -> float:
	return sqrt(2.0 * GameConfig.GRAVITY * GameConfig.tiles_to_pixels(effective_max_jump_tiles()))

func _finish_roll() -> void:
	_set_roll_collision(false)
	_set_state(State.RUNNING if is_on_floor() else State.FALLING)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		trigger_jump()
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
	match state:
		State.RUNNING:
			_play_animation("run")
		State.JUMPING:
			_play_animation("jump")
		State.FALLING:
			_play_animation("fall")
		State.ROLLING:
			_play_animation("roll")
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
	var burning := active_statuses.has(&"burn")
	burn_particles.emitting = burning
	if damage_flash_remaining > 0.0:
		sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
	elif burning:
		sprite.modulate = Color(1.0, 0.65, 0.3, 1.0)
	elif sprite.modulate != Color.WHITE:
		sprite.modulate = Color.WHITE

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
		sprite.sprite_frames = frames
		return
	_add_animation(frames, "run", base.path_join("Fast Run"), 12.0, true)
	_add_animation(frames, "jump", base.path_join("Jump Before"), 16.0, false)
	_add_animation(frames, "fall", base.path_join("Fall"), 12.0, true)
	_add_animation(frames, "roll", base.path_join("Roll"), 14.0, true)
	_add_animation(frames, "dead", base.path_join("Dead"), 12.0, false)
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

func _play_animation(animation_name: StringName) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		return
	sprite.animation = animation_name
	if sprite.sprite_frames.get_frame_count(animation_name) > 0:
		sprite.play(animation_name)
