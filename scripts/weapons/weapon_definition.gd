class_name WeaponDefinition
extends RefCounted

const TRAJECTORY_STRAIGHT: StringName = &"straight"
const TRAJECTORY_BALLISTIC: StringName = &"ballistic"
const TRAJECTORIES: Array[StringName] = [TRAJECTORY_STRAIGHT, TRAJECTORY_BALLISTIC]

const AIM_DIRECTED: StringName = &"directed"
const AIM_RANDOM: StringName = &"random"
const AIM_DETERMINED: StringName = &"determined"
const AIM_FORWARD: StringName = &"forward"
const AIM_MODES: Array[StringName] = [AIM_DIRECTED, AIM_RANDOM, AIM_DETERMINED, AIM_FORWARD]

var id: StringName
var asset_path: String
var damage: float
var fire_interval: float
var trajectory: StringName
var aim_mode: StringName
var target_count: int
var projectile_speed: float
var gravity: float
var determined_direction: Vector2

func _init(new_id: StringName = &"") -> void:
	id = new_id
	asset_path = ""
	damage = 1.0
	fire_interval = 1.0
	trajectory = TRAJECTORY_STRAIGHT
	aim_mode = AIM_DIRECTED
	target_count = 1
	projectile_speed = 600.0
	gravity = 0.0
	determined_direction = Vector2.RIGHT

func is_valid() -> bool:
	if id.is_empty() or asset_path.is_empty() or not asset_path.begins_with("res://"):
		return false
	if not is_finite(damage) or damage <= 0.0 or not is_finite(fire_interval) or fire_interval <= 0.0:
		return false
	if not trajectory in TRAJECTORIES or not aim_mode in AIM_MODES or target_count <= 0:
		return false
	if not is_finite(projectile_speed) or projectile_speed <= 0.0 or not is_finite(gravity) or gravity < 0.0:
		return false
	if trajectory == TRAJECTORY_BALLISTIC and gravity <= 0.0:
		return false
	if aim_mode == AIM_DETERMINED and determined_direction.is_zero_approx():
		return false
	return true
