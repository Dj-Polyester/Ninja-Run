class_name WeaponTargetingPolicy
extends RefCounted

const Definition = preload("res://scripts/weapons/weapon_definition.gd")

static func directions_for(definition: Definition, origin: Vector2, target_positions: Array[Vector2], run_seed: int, shot_serial: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if definition == null or not definition.is_valid() or target_positions.is_empty():
		return result
	if definition.aim_mode == Definition.AIM_FORWARD:
		result.append(Vector2.RIGHT)
		return result
	if definition.aim_mode == Definition.AIM_DETERMINED:
		result.append(definition.determined_direction.normalized())
		return result
	if definition.aim_mode == Definition.AIM_RANDOM:
		# Random aim is a seeded forward-hemisphere direction, not random target
		# selection. The run seed + weapon + shot serial makes replay deterministic.
		for index in definition.target_count:
			var mixed: int = absi(run_seed ^ definition.id.hash() ^ (shot_serial * 1664525) ^ (index * 1103515245))
			var fraction := float(mixed % 1000000) / 999999.0
			var angle := lerpf(-PI / 3.0, PI / 3.0, fraction)
			result.append(Vector2.RIGHT.rotated(angle))
		return result
	var candidates := target_positions.duplicate()
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var da := origin.distance_squared_to(a)
		var db := origin.distance_squared_to(b)
		return da < db or (is_equal_approx(da, db) and (a.x < b.x or (is_equal_approx(a.x, b.x) and a.y < b.y)))
	)
	var selected: Array[Vector2] = []
	var count := mini(definition.target_count, candidates.size())
	for index in count:
		selected.append(candidates[index])
	for target_position in selected:
		var direction := (target_position - origin).normalized()
		if definition.trajectory == Definition.TRAJECTORY_BALLISTIC:
			direction = ballistic_direction(origin, target_position, definition.projectile_speed, definition.gravity)
		if not direction.is_zero_approx():
			result.append(direction)
	return result

static func ballistic_direction(origin: Vector2, target: Vector2, speed: float, gravity: float) -> Vector2:
	if speed <= 0.0 or gravity <= 0.0:
		return (target - origin).normalized()
	var delta := target - origin
	var x := absf(delta.x)
	if x <= 0.0001:
		return Vector2(0.0, -1.0 if delta.y < 0.0 else 1.0)
	var y_up := -delta.y
	var speed_sq := speed * speed
	var discriminant := speed_sq * speed_sq - gravity * (gravity * x * x + 2.0 * y_up * speed_sq)
	if discriminant < 0.0:
		return delta.normalized()
	var tan_theta := (speed_sq - sqrt(discriminant)) / (gravity * x)
	var cos_theta := 1.0 / sqrt(1.0 + tan_theta * tan_theta)
	var sin_theta := tan_theta * cos_theta
	return Vector2(signf(delta.x) * cos_theta, -sin_theta).normalized()
