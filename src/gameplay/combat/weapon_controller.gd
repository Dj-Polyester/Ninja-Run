class_name WeaponController
extends Node2D

const WEAPON_CATALOG_SCRIPT := preload("res://src/data/weapon_catalog.gd")
const WEAPON_DATA_SCRIPT := preload("res://src/data/weapon_data.gd")
const DAMAGEABLE_CONTRACT_SCRIPT := preload("res://src/gameplay/combat/damageable_contract.gd")
const PROJECTILE_SCENE := preload("res://scenes/combat/weapon_projectile.tscn")

signal weapon_fired(weapon, projectile: Node, target: Node)

var cooldowns: Dictionary = {}
var rng := RandomNumberGenerator.new()
var projectile_parent_override: Node
var target_provider: Callable

@onready var player: Node = get_parent()

func _ready() -> void:
	var run_seed := int(GameState.run.get("seed", 0))
	rng.seed = run_seed ^ 0x5EED8A7

func _physics_process(delta: float) -> void:
	_tick_cooldowns(delta)
	if not can_fire():
		return
	var enemies := on_screen_enemies()
	if enemies.is_empty():
		return
	for weapon in equipped_weapon_data():
		if cooldown_remaining(weapon.id) > 0.0:
			continue
		if fire_weapon(weapon, enemies) > 0:
			cooldowns[String(weapon.id)] = weapon.fire_interval

func can_fire() -> bool:
	if not GameState.shooting_unlocked():
		return false
	if player == null or not is_instance_valid(player):
		return false
	if player.has_method(&"can_use_weapons") and not bool(player.call(&"can_use_weapons")):
		return false
	return not equipped_weapon_data().is_empty()

func equipped_weapon_data() -> Array:
	var result: Array = []
	var equipped = GameState.profile.get("equipped_weapons", [])
	if not equipped is Array:
		return result
	for raw_id in equipped:
		if result.size() >= GameConfig.NUM_EQUIPPABLE_WEAPONS:
			break
		var weapon = WEAPON_CATALOG_SCRIPT.get_by_id(StringName(raw_id))
		if weapon != null:
			result.append(weapon)
	return result

func cooldown_remaining(weapon_id: StringName) -> float:
	return maxf(0.0, float(cooldowns.get(String(weapon_id), 0.0)))

func set_rng_seed(seed_value: int) -> void:
	rng.seed = seed_value

func fire_weapon(weapon, enemies: Array) -> int:
	if weapon == null or enemies.is_empty():
		return 0
	var targets := select_targets(weapon, enemies)
	if targets.is_empty():
		return 0
	var projectile_parent := _projectile_parent()
	if projectile_parent == null:
		return 0

	var fired := 0
	for index in targets.size():
		var target := targets[index] as Node2D
		if target == null or not is_instance_valid(target):
			continue
		var projectile = PROJECTILE_SCENE.instantiate()
		projectile_parent.add_child(projectile)
		projectile.global_position = global_position
		var launch := launch_parameters(weapon, target, index, targets.size())
		projectile.configure(
			player,
			weapon,
			launch.velocity,
			launch.gravity,
			target if weapon.trajectory == WEAPON_DATA_SCRIPT.Trajectory.HOMING else null,
			GameConfig.WEAPON_HOMING_TURN_RATE if weapon.trajectory == WEAPON_DATA_SCRIPT.Trajectory.HOMING else 0.0
		)
		weapon_fired.emit(weapon, projectile, target)
		fired += 1
	return fired

func select_targets(weapon, enemies: Array) -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	for candidate in enemies:
		if candidate is Node2D and is_instance_valid(candidate) and _is_attackable(candidate):
			candidates.append(candidate)
	if candidates.is_empty():
		return []

	var desired_count := mini(weapon.target_count, candidates.size())
	if weapon.aim_mode == WEAPON_DATA_SCRIPT.AimMode.RANDOM:
		var randomized := candidates.duplicate()
		for index in range(randomized.size() - 1, 0, -1):
			var swap_index := rng.randi_range(0, index)
			var temp = randomized[index]
			randomized[index] = randomized[swap_index]
			randomized[swap_index] = temp
		return randomized.slice(0, desired_count)

	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	return candidates.slice(0, desired_count)

func launch_parameters(weapon, target: Node2D, shot_index: int = 0, shot_count: int = 1) -> Dictionary:
	var speed: float = float(weapon.projectile_speed_pixels())
	var direction := aim_direction(weapon, target, shot_index, shot_count)
	var gravity := 0.0
	var launch_velocity: Vector2 = direction * speed

	match weapon.trajectory:
		WEAPON_DATA_SCRIPT.Trajectory.BALLISTIC:
			gravity = GameConfig.WEAPON_PROJECTILE_GRAVITY
			if weapon.aim_mode == WEAPON_DATA_SCRIPT.AimMode.TARGETED:
				launch_velocity = ballistic_velocity(global_position, target.global_position, speed, gravity)
			else:
				# Ballistic describes motion, while aim mode describes direction.
				# Preserve forward/random/fixed aim instead of silently converting
				# every ballistic weapon into a targeted one.
				launch_velocity = direction * speed
				launch_velocity.y -= speed * 0.35
				if launch_velocity != Vector2.ZERO:
					launch_velocity = launch_velocity.normalized() * speed
		WEAPON_DATA_SCRIPT.Trajectory.ARC:
			gravity = GameConfig.WEAPON_PROJECTILE_GRAVITY * 0.55
			launch_velocity = direction * speed + Vector2(0.0, -speed * 0.38)
			if launch_velocity != Vector2.ZERO:
				launch_velocity = launch_velocity.normalized() * speed
		WEAPON_DATA_SCRIPT.Trajectory.HOMING:
			launch_velocity = direction * speed
		_:
			pass

	return {"velocity": launch_velocity, "gravity": gravity}

func aim_direction(weapon, target: Node2D, shot_index: int = 0, shot_count: int = 1) -> Vector2:
	match weapon.aim_mode:
		WEAPON_DATA_SCRIPT.AimMode.TARGETED:
			return _direction_to_target(target)
		WEAPON_DATA_SCRIPT.AimMode.RANDOM:
			var random_angle := deg_to_rad(rng.randf_range(-GameConfig.WEAPON_RANDOM_AIM_MAX_DEGREES, GameConfig.WEAPON_RANDOM_AIM_MAX_DEGREES))
			return Vector2.RIGHT.rotated(random_angle)
		WEAPON_DATA_SCRIPT.AimMode.FIXED_PATTERN:
			if shot_count <= 1:
				return Vector2.RIGHT
			var t := float(shot_index) / float(shot_count - 1)
			var half_spread: float = float(weapon.fixed_pattern_spread_degrees) * 0.5
			var angle := deg_to_rad(lerpf(-half_spread, half_spread, t))
			return Vector2.RIGHT.rotated(angle)
		_:
			return Vector2.RIGHT

func ballistic_velocity(origin: Vector2, target_position: Vector2, speed: float, gravity: float) -> Vector2:
	if speed <= 0.0 or gravity <= 0.0:
		return origin.direction_to(target_position) * maxf(0.0, speed)
	var delta := target_position - origin
	var horizontal := absf(delta.x)
	if horizontal <= 0.001:
		return Vector2(0.0, -speed if delta.y <= 0.0 else speed)

	# Convert Godot's down-positive Y into the conventional up-positive
	# projectile equation, then select the lower-angle physical solution.
	var target_y_up := -delta.y
	var speed_squared := speed * speed
	var discriminant := speed_squared * speed_squared - gravity * (gravity * horizontal * horizontal + 2.0 * target_y_up * speed_squared)
	if discriminant < 0.0:
		var fallback := origin.direction_to(target_position)
		if fallback == Vector2.ZERO:
			fallback = Vector2.RIGHT
		fallback.y -= 0.35
		return fallback.normalized() * speed
	var tan_theta := (speed_squared - sqrt(discriminant)) / (gravity * horizontal)
	var angle := atan(tan_theta)
	var x_sign := 1.0 if delta.x >= 0.0 else -1.0
	return Vector2(cos(angle) * speed * x_sign, -sin(angle) * speed)

func on_screen_enemies() -> Array[Node2D]:
	var raw_candidates: Array = []
	if target_provider.is_valid():
		var supplied = target_provider.call()
		if supplied is Array:
			raw_candidates.append_array(supplied)
	else:
		raw_candidates.append_array(get_tree().get_nodes_in_group(&"enemies"))
		var enemy_container := _enemy_container()
		if enemy_container != null:
			raw_candidates.append_array(enemy_container.find_children("*", "", true, false))

	var result: Array[Node2D] = []
	var seen: Dictionary = {}
	for candidate in raw_candidates:
		if not candidate is Node2D or not is_instance_valid(candidate):
			continue
		var node := candidate as Node2D
		var id := node.get_instance_id()
		if seen.has(id) or not _is_attackable(node) or not _is_on_screen(node):
			continue
		seen[id] = true
		result.append(node)
	return result

func _tick_cooldowns(delta: float) -> void:
	for key in cooldowns.keys():
		var remaining := maxf(0.0, float(cooldowns[key]) - delta)
		if remaining <= 0.0:
			cooldowns.erase(key)
		else:
			cooldowns[key] = remaining

func _direction_to_target(target: Node2D) -> Vector2:
	if target == null or not is_instance_valid(target):
		return Vector2.RIGHT
	var direction := global_position.direction_to(target.global_position)
	return direction if direction != Vector2.ZERO else Vector2.RIGHT

func _is_attackable(candidate: Node) -> bool:
	if candidate == null or candidate == player or not DAMAGEABLE_CONTRACT_SCRIPT.supports(candidate):
		return false
	if candidate.has_method(&"can_receive_projectile_attack"):
		return bool(candidate.call(&"can_receive_projectile_attack"))
	return true

func _is_on_screen(candidate: Node2D) -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return true
	var visible_rect := viewport.get_visible_rect()
	if visible_rect.size.x <= 0.0 or visible_rect.size.y <= 0.0:
		return true
	var screen_position := viewport.get_canvas_transform() * candidate.global_position
	var screen_rect := Rect2(Vector2.ZERO, visible_rect.size).grow(GameConfig.WEAPON_SCREEN_MARGIN_PIXELS)
	return screen_rect.has_point(screen_position)

func _projectile_parent() -> Node:
	if projectile_parent_override != null and is_instance_valid(projectile_parent_override):
		return projectile_parent_override
	var current := player.get_parent() if player != null else get_parent()
	while current != null:
		var container := current.get_node_or_null("ProjectileContainer")
		if container != null:
			return container
		current = current.get_parent()
	return player.get_parent() if player != null else get_parent()

func _enemy_container() -> Node:
	var current := player.get_parent() if player != null else get_parent()
	while current != null:
		var container := current.get_node_or_null("EnemyContainer")
		if container != null:
			return container
		current = current.get_parent()
	return null
