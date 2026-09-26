class_name PlayerController
extends CharacterBody2D
## Physics body only. Level owns lifecycle state; posture changes use real casts.

signal melee_proximity(target: Node2D)

const AbilityCooldownRuntime = preload("res://scripts/abilities/ability_cooldown_state.gd")

const PLAYER_VISUAL_SCALE := Vector2(0.32, 0.32)
const PLAYER_VISUAL_OFFSET := Vector2(0.0, -13.0)

var rolling := false
var roll_until := 0.0
var simulation_time := 0.0
var runner_active := true
var damage_tint_until := -1.0
var jump_consumptions := 0
var roll_consumptions := 0
var jump_run_seed := 0
var snow_jump_sample_index := 0
var last_takeoff_material: StringName = &"grass"
var last_jump_multiplier := 1.0
var support_material_resolver: Callable = Callable()
var jump_height_resolver: Callable = Callable()
var movement_modifier_resolver: Callable = Callable()
var appearance_state_resolver: Callable = Callable()
var blood_loss_blink := false
var ability_profile: ProfileState
var ability_cooldowns: AbilityCooldownRuntime
var ability_time_resolver: Callable = Callable()
var gravity_sign := 1.0
var jumps_since_contact := 0
var wall_jumps_since_contact := 0
var jump_held := false
var jump_hold_seconds := 0.0
var glide_seconds := 0.0
var dashing := false
var dash_remaining_pixels := 0.0
var reverse_gravity_toggles := 0

@onready var standing_shape: CollisionShape2D = $StandingCollision
@onready var rolling_shape: CollisionShape2D = $RollingCollision

func _ready() -> void:
	$MeleeArea.collision_mask = 1 | GameConfig.ENEMY_COLLISION_LAYER
	apply_character_frames("res://assets/Characters/1/Png/Character Sprite/sprite_frames.tres")

func apply_character_frames(sprite_frames_path: String) -> bool:
	if sprite_frames_path.is_empty() or not ResourceLoader.exists(sprite_frames_path, "SpriteFrames"):
		return false
	var frames := load(sprite_frames_path) as SpriteFrames
	if frames == null:
		return false
	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.scale = PLAYER_VISUAL_SCALE
	$AnimatedSprite2D.position = PLAYER_VISUAL_OFFSET
	if frames.has_animation(&"idle"):
		$AnimatedSprite2D.play(&"idle")
	elif not frames.get_animation_names().is_empty():
		$AnimatedSprite2D.play(frames.get_animation_names()[0])
	return true

func set_runner_active(active: bool) -> void:
	runner_active = active
	if not active:
		velocity = Vector2.ZERO

func apply_damage_feedback(now: float) -> void:
	damage_tint_until = now + GameConfig.DAMAGE_FEEDBACK_DURATION
	_update_appearance()

func reset_for_revival() -> void:
	velocity = Vector2.ZERO
	simulation_time = 0.0
	stop_roll(true)
	damage_tint_until = -1.0
	gravity_sign = 1.0
	up_direction = Vector2.UP
	jumps_since_contact = 0
	wall_jumps_since_contact = 0
	jump_held = false
	jump_hold_seconds = 0.0
	glide_seconds = 0.0
	dashing = false
	dash_remaining_pixels = 0.0
	_update_appearance()

func configure_abilities(profile: ProfileState, cooldown_state: AbilityCooldownRuntime, time_resolver: Callable = Callable()) -> void:
	ability_profile = profile
	ability_cooldowns = cooldown_state
	ability_time_resolver = time_resolver

func _ability_now() -> float:
	if ability_time_resolver.is_valid():
		var resolved: Variant = ability_time_resolver.call()
		if resolved is float or resolved is int:
			return float(resolved)
	return simulation_time

func configure_jump_randomness(run_seed: int, new_support_material_resolver: Callable = Callable(), new_jump_height_resolver: Callable = Callable()) -> void:
	# Called once when a new Level/run is constructed. Revival intentionally does
	# not reset this run-owned stream position.
	jump_run_seed = run_seed
	snow_jump_sample_index = 0
	support_material_resolver = new_support_material_resolver
	jump_height_resolver = new_jump_height_resolver

func set_support_material_resolver(resolver: Callable) -> void:
	support_material_resolver = resolver

func set_jump_height_resolver(resolver: Callable) -> void:
	jump_height_resolver = resolver

func set_movement_modifier_resolver(resolver: Callable) -> void:
	movement_modifier_resolver = resolver

func set_appearance_state_resolver(resolver: Callable) -> void:
	appearance_state_resolver = resolver

func effective_movement_multiplier() -> float:
	var value := 1.0
	if movement_modifier_resolver.is_valid():
		var resolved: Variant = movement_modifier_resolver.call()
		if resolved is float or resolved is int:
			value = float(resolved)
	return clampf(value, GameConfig.MIN_SLOWDOWN_SPEED_MULTIPLIER, 1.0)

func appearance_state() -> StringName:
	if damage_tint_until > simulation_time:
		return &"damage"
	var has_blood := false
	var has_freeze := false
	if appearance_state_resolver.is_valid():
		var resolved: Variant = appearance_state_resolver.call(simulation_time)
		if resolved is Dictionary:
			has_blood = bool(resolved.get(&"blood", false))
			has_freeze = bool(resolved.get(&"freeze", false))
		elif resolved is StringName or resolved is String:
			has_blood = StringName(resolved) == &"blood"
			has_freeze = StringName(resolved) == &"freeze"
	# Deterministic priority: direct damage, red active blood blink, freeze
	# during a blood blink's off phase, then neutral.
	if has_blood and int(floor(simulation_time * 8.0)) % 2 == 0:
		return &"blood"
	if has_freeze:
		return &"freeze"
	return &"neutral"

func _update_appearance() -> void:
	if not is_node_ready():
		return
	match appearance_state():
		&"damage", &"blood": $AnimatedSprite2D.modulate = Color(1.0, 0.25, 0.25)
		&"freeze": $AnimatedSprite2D.modulate = Color(0.55, 0.82, 1.0)
		_: $AnimatedSprite2D.modulate = Color.WHITE

func snow_jump_samples_consumed() -> int:
	return snow_jump_sample_index

func _physics_process(delta: float) -> void:
	if not runner_active:
		return
	simulation_time += delta
	if damage_tint_until >= 0.0 and simulation_time >= damage_tint_until:
		damage_tint_until = -1.0
	_update_appearance()
	if rolling and simulation_time >= roll_until:
		stop_roll()
	if jump_held:
		jump_hold_seconds += delta
	else:
		jump_hold_seconds = 0.0
	var requested_speed := GameConfig.SPEED * effective_movement_multiplier()
	if dashing:
		requested_speed = minf(GameConfig.dash_speed_pixels_per_second(), dash_remaining_pixels / maxf(delta, 0.000001))
	velocity.x = requested_speed
	if not is_on_floor():
		if _glide_is_active():
			velocity.y = 0.0
			glide_seconds = minf(GameConfig.MAX_GLIDE_DURATION, glide_seconds + delta)
		else:
			velocity.y += GameConfig.GRAVITY * gravity_sign * delta
		$AnimatedSprite2D.play(&"fall")
	else:
		$AnimatedSprite2D.play(&"fast run")
	var before_x := global_position.x
	move_and_slide()
	if dashing:
		var moved := maxf(0.0, global_position.x - before_x)
		dash_remaining_pixels = maxf(0.0, dash_remaining_pixels - moved)
		if dash_remaining_pixels <= 0.001 or moved <= 0.001:
			dashing = false
			dash_remaining_pixels = 0.0
	if is_on_floor():
		jumps_since_contact = 0
		wall_jumps_since_contact = 0
		glide_seconds = 0.0
	_update_appearance()
	_emit_melee_for_targets()

func request_jump() -> bool:
	if not runner_active:
		return false
	var ability_now := _ability_now()
	if _ability_equipped(&"reverse_gravity") and ability_cooldowns != null and ability_cooldowns.can_activate(&"reverse_gravity", ability_now, ability_profile):
		if ability_cooldowns.commit_activation(&"reverse_gravity", ability_now, ability_profile):
			gravity_sign *= -1.0
			up_direction = Vector2.UP * gravity_sign
			velocity.y = 0.0
			reverse_gravity_toggles += 1
			return true
	var climb_level := _equipped_level(&"climb")
	if climb_level > 0 and not is_on_floor() and wall_jumps_since_contact < climb_level and _touching_wall_on_right():
		wall_jumps_since_contact += 1
		return _perform_vertical_jump(false)
	if _ability_equipped(&"fly"):
		return _perform_vertical_jump(false)
	var jump_level := _equipped_level(&"jump")
	if jump_level <= 0:
		return false
	if not is_on_floor() and jumps_since_contact >= jump_level:
		return false
	var grounded := is_on_floor()
	if grounded:
		jumps_since_contact = 0
	var accepted := _perform_vertical_jump(grounded)
	if accepted:
		jumps_since_contact += 1
	return accepted

func request_dash() -> bool:
	if not runner_active or dashing or not _ability_equipped(&"dash") or ability_cooldowns == null:
		return false
	var ability_now := _ability_now()
	if not ability_cooldowns.can_activate(&"dash", ability_now, ability_profile):
		return false
	dashing = true
	dash_remaining_pixels = GameConfig.DASH_TILES * GameConfig.TILE_SIZE
	if not ability_cooldowns.commit_activation(&"dash", ability_now, ability_profile):
		dashing = false
		dash_remaining_pixels = 0.0
		return false
	return true

func _perform_vertical_jump(from_support: bool) -> bool:
	last_takeoff_material = &"grass"
	last_jump_multiplier = 1.0
	if from_support:
		last_takeoff_material = _takeoff_support_material()
		if last_takeoff_material == &"snow":
			last_jump_multiplier = _resolve_snow_jump_multiplier(snow_jump_sample_index)
			snow_jump_sample_index += 1
	var impulse := sqrt(2.0 * GameConfig.GRAVITY * GameConfig.MAX_JUMP * GameConfig.TILE_SIZE * last_jump_multiplier)
	velocity.y = -gravity_sign * impulse
	jump_consumptions += 1
	$AnimatedSprite2D.play(&"jump before")
	return true

func _ability_equipped(ability_id: StringName) -> bool:
	return ability_profile != null and ability_id in ability_profile.abilities.equipped

func _equipped_level(ability_id: StringName) -> int:
	return ability_profile.ability_level(ability_id) if _ability_equipped(ability_id) else 0

func _glide_is_active() -> bool:
	return _ability_equipped(&"glide") and jump_held and jump_hold_seconds >= GameConfig.GLIDE_HOLD_THRESHOLD and glide_seconds < GameConfig.MAX_GLIDE_DURATION and not is_on_floor()

func _touching_wall_on_right() -> bool:
	if standing_shape == null or standing_shape.shape == null or not is_inside_tree():
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = standing_shape.shape
	query.transform = global_transform * Transform2D(0.0, standing_shape.position + Vector2(0.0, -1.0))
	query.motion = Vector2(GameConfig.WALL_JUMP_PROBE_DISTANCE, 0.0)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	var result := get_world_2d().direct_space_state.cast_motion(query)
	return result.size() == 2 and result[0] < 1.0

func _takeoff_support_material() -> StringName:
	if support_material_resolver.is_valid():
		var resolved: Variant = support_material_resolver.call()
		if resolved is StringName or resolved is String:
			return StringName(resolved)
	return &"grass"

func _resolve_snow_jump_multiplier(sample_index: int) -> float:
	var multiplier := deterministic_snow_jump_multiplier(jump_run_seed, sample_index)
	if jump_height_resolver.is_valid():
		var injected: Variant = jump_height_resolver.call(&"snow", jump_run_seed, sample_index, GameConfig.SNOW_MIN_JUMP_MULTIPLIER, GameConfig.SNOW_MAX_JUMP_MULTIPLIER)
		if injected is float or injected is int:
			multiplier = float(injected)
	return clampf(multiplier, GameConfig.SNOW_MIN_JUMP_MULTIPLIER, GameConfig.SNOW_MAX_JUMP_MULTIPLIER)

static func deterministic_snow_jump_multiplier(run_seed: int, sample_index: int) -> float:
	# Local integer mixing avoids global RNG state and makes the value a function
	# only of run seed and accepted Snow-jump index.
	var value := run_seed ^ (sample_index * 1103515245) ^ 0x51f15e7
	value = (value ^ (value >> 16)) * 0x45d9f3b
	value = value ^ (value >> 16)
	var fraction := float(abs(value) % 1000000) / 999999.0
	return lerpf(GameConfig.SNOW_MIN_JUMP_MULTIPLIER, GameConfig.SNOW_MAX_JUMP_MULTIPLIER, fraction)

func dispatch_input_action(action_name: StringName, pressed: bool = true) -> bool:
	if not runner_active:
		return false
	var semantic := ActionDispatch.from_input(action_name)
	if semantic == ActionDispatch.Action.JUMP:
		if pressed:
			if not jump_held:
				jump_hold_seconds = 0.0
			jump_held = true
			return request_jump()
		jump_held = false
		jump_hold_seconds = 0.0
		return true
	if semantic == ActionDispatch.Action.ROLL and pressed:
		if start_roll(simulation_time):
			roll_consumptions += 1
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"jump"):
		dispatch_input_action(&"jump", true)
	elif event.is_action_released(&"jump"):
		dispatch_input_action(&"jump", false)
	elif event.is_action_pressed(&"roll"):
		dispatch_input_action(&"roll", true)

func start_roll(now: float) -> bool:
	if rolling:
		return true
	if not _posture_is_clear(rolling_shape.shape, rolling_shape.position):
		return false
	rolling = true
	roll_until = now + GameConfig.ROLL_DURATION
	standing_shape.set_deferred("disabled", true)
	rolling_shape.set_deferred("disabled", false)
	$AnimatedSprite2D.play(&"roll")
	return true

func stop_roll(force: bool = false) -> bool:
	if not rolling:
		return true
	if not force and not _posture_is_clear(standing_shape.shape, standing_shape.position):
		return false
	rolling = false
	standing_shape.set_deferred("disabled", false)
	rolling_shape.set_deferred("disabled", true)
	return true

func _emit_melee_for_targets() -> void:
	# Polling the Area2D overlap list closes the timing gap for bodies spawned inside it.
	for body: Node2D in $MeleeArea.get_overlapping_bodies():
		if body.is_in_group(&"enemies"):
			melee_proximity.emit(body)

func _posture_is_clear(shape: Shape2D, local_offset: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	# Use the collision shape's exact local pose.  A posture is only clear when
	# there are no world collisions at all; floor contact is excluded with our RID.
	query.transform = global_transform * Transform2D(0.0, local_offset)
	# Keep PhysicsShapeQueryParameters2D's default all-layer mask: every body
	# collision blocks a posture change, irrespective of the player body's mask.
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
