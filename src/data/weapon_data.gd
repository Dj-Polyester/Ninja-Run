class_name WeaponData
extends Resource

enum Trajectory {
	STRAIGHT,
	BALLISTIC,
	ARC,
	HOMING,
}

enum AimMode {
	FORWARD,
	TARGETED,
	RANDOM,
	FIXED_PATTERN,
}

@export var id: StringName = &""
@export var display_name := ""
@export_file("*.png") var texture_path := ""
@export var damage := 1.0
@export var fire_interval := 1.0
@export var trajectory := Trajectory.STRAIGHT
@export var aim_mode := AimMode.FORWARD
@export var target_count := 1
@export var projectile_speed_tiles := 8.0
@export var unlock_cost := 0
@export_range(0.0, 180.0, 1.0) var fixed_pattern_spread_degrees := 30.0

func projectile_speed_pixels() -> float:
	return GameConfig.tiles_to_pixels(projectile_speed_tiles)

func is_valid() -> bool:
	if id == &"" or display_name.strip_edges().is_empty():
		return false
	if texture_path.is_empty() or not texture_path.begins_with("res://"):
		return false
	if damage <= 0.0 or fire_interval <= 0.0 or projectile_speed_tiles <= 0.0:
		return false
	if target_count <= 0 or unlock_cost < 0:
		return false
	return trajectory >= 0 and trajectory < Trajectory.size() and aim_mode >= 0 and aim_mode < AimMode.size()

func trajectory_description() -> String:
	match trajectory:
		Trajectory.STRAIGHT:
			return "Straight"
		Trajectory.BALLISTIC:
			return "Ballistic"
		Trajectory.ARC:
			return "Arc"
		Trajectory.HOMING:
			return "Homing"
	return "Unknown"

func aim_description() -> String:
	match aim_mode:
		AimMode.FORWARD:
			return "Forward"
		AimMode.TARGETED:
			return "Targeted"
		AimMode.RANDOM:
			return "Random"
		AimMode.FIXED_PATTERN:
			return "Fixed pattern"
	return "Unknown"
