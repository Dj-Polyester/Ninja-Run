class_name MovementEnvelope
extends RefCounted
## Conservative baseline movement proof used before geometry is realized.

var tile_size: float
var gravity: float
var speed: float
var minimum_speed: float
var max_jump_tiles: float
var worst_jump_multiplier: float
var maximum_jump_multiplier: float
var body_width: float
var body_height: float
var horizontal_margin: float
var vertical_margin: float
var fixed_timestep: float
var run_up_tiles: float
var landing_tiles: float

static func from_snapshot(snapshot: Dictionary, new_body_width: float = 36.0, new_body_height: float = 64.0, timestep: float = 1.0 / 60.0) -> MovementEnvelope:
	var result := MovementEnvelope.new()
	result.tile_size = float(snapshot.get(&"tile_size", 0.0))
	result.gravity = float(snapshot.get(&"gravity", 0.0))
	result.speed = float(snapshot.get(&"speed", 0.0))
	result.minimum_speed = result.speed * float(snapshot.get(&"slowdown_speed_multiplier", 0.0))
	result.max_jump_tiles = float(snapshot.get(&"max_jump_tiles", 0.0))
	result.worst_jump_multiplier = float(snapshot.get(&"snow_min_jump_multiplier", 0.0))
	result.maximum_jump_multiplier = float(snapshot.get(&"snow_max_jump_multiplier", 0.0))
	result.body_width = new_body_width
	result.body_height = new_body_height
	result.horizontal_margin = new_body_width * 0.5 + result.tile_size * 0.25
	result.vertical_margin = result.tile_size * 0.25
	result.fixed_timestep = timestep
	result.run_up_tiles = 1.0
	result.landing_tiles = 1.0
	return result

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for value in [tile_size, gravity, speed, minimum_speed, max_jump_tiles, worst_jump_multiplier, maximum_jump_multiplier, body_width, body_height, fixed_timestep]:
		if not is_finite(value) or value <= 0.0:
			errors.append("Movement envelope requires positive finite inputs.")
			break
	if worst_jump_multiplier > 1.0:
		errors.append("Worst-case jump multiplier cannot exceed one.")
	if maximum_jump_multiplier < worst_jump_multiplier:
		errors.append("Maximum jump ceiling is below the minimum jump multiplier.")
	return errors

func minimum_jump_height_pixels() -> float:
	return max_jump_tiles * worst_jump_multiplier * tile_size

func maximum_rise_pixels() -> float:
	var integration_error := 0.5 * gravity * fixed_timestep * fixed_timestep
	return maxf(0.0, minimum_jump_height_pixels() - vertical_margin - integration_error)

func maximum_rise_ceiling_pixels() -> float:
	var integration_error := 0.5 * gravity * fixed_timestep * fixed_timestep
	return max_jump_tiles * maximum_jump_multiplier * tile_size + vertical_margin + integration_error

func required_ceiling_clearance_pixels() -> float:
	# Measured from the standing player's head to the roof underside.
	return maximum_rise_ceiling_pixels() + vertical_margin

func has_vertical_clearance(ceiling_distance_pixels: float) -> bool:
	return ceiling_distance_pixels >= required_ceiling_clearance_pixels()

func _jump_velocity() -> float:
	return sqrt(2.0 * gravity * minimum_jump_height_pixels())

func _maximum_jump_velocity() -> float:
	return sqrt(2.0 * gravity * max_jump_tiles * maximum_jump_multiplier * tile_size)

func _arrival_time(vertical_displacement: float) -> float:
	# Descending quadratic root makes a down-step prove a longer traversal.
	var velocity := _jump_velocity()
	var discriminant := velocity * velocity + 2.0 * gravity * vertical_displacement
	if discriminant < 0.0:
		return -1.0
	return (velocity + sqrt(discriminant)) / gravity

func max_horizontal_travel_pixels(vertical_displacement: float = 0.0) -> float:
	var arrival := _arrival_time(vertical_displacement)
	return -1.0 if arrival < 0.0 else minimum_speed * maxf(0.0, arrival - fixed_timestep)

func maximum_horizontal_travel_pixels(vertical_displacement: float = 0.0) -> float:
	var velocity := _maximum_jump_velocity()
	var discriminant := velocity * velocity + 2.0 * gravity * vertical_displacement
	if discriminant < 0.0:
		return -1.0
	var arrival := (velocity + sqrt(discriminant)) / gravity
	return speed * (arrival + fixed_timestep)

func _surface_has_room(surface: TerrainSurface, margin_tiles: float) -> bool:
	return float(surface.x_end - surface.x_begin) * tile_size >= body_width + margin_tiles * tile_size

func can_reach_transition(from: TerrainSurface, to: TerrainSurface) -> bool:
	if not from.exit_allowed or not to.entry_allowed:
		return false
	# A destination may overlap the source (for example, dropping from an
	# elevated platform onto the forward half of the route below), but a surface
	# lying wholly behind the takeoff window is not a forward transition.
	if to.x_end <= from.x_begin:
		return false
	if not _surface_has_room(from, run_up_tiles) or not _surface_has_room(to, landing_tiles):
		return false
	var vertical_displacement := float(to.y - from.y) * tile_size
	if -vertical_displacement > maximum_rise_pixels():
		return false
	var landing_begin := maxi(to.x_begin, from.x_begin)
	var horizontal_gap := maxf(0.0, float(landing_begin - from.x_end) * tile_size)
	if horizontal_gap + horizontal_margin * 2.0 > max_horizontal_travel_pixels(vertical_displacement):
		return false
	# For a mandatory upward jump, the earliest legal takeoff at maximum speed
	# and maximum Snow height must still land inside the destination window.
	if vertical_displacement < 0.0:
		var available_landing_span := float(to.x_end - from.x_begin) * tile_size - (run_up_tiles + landing_tiles) * tile_size - body_width
		if maximum_horizontal_travel_pixels(vertical_displacement) > available_landing_span:
			return false
	return true
