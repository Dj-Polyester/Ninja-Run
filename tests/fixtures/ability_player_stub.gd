extends Node

var velocity := Vector2.ZERO
var global_position_stub := Vector2.ZERO
var gravity_direction := 1.0
var supported := false
var on_wall := false
var wall_normal := Vector2.LEFT
var detectable := true
var abilities_enabled := true
var jump_calls := 0
var last_jump_wall_normal := Vector2.ZERO

func can_activate_abilities() -> bool:
	return abilities_enabled

func is_supported() -> bool:
	return supported

func is_on_wall() -> bool:
	return on_wall

func get_wall_normal() -> Vector2:
	return wall_normal

func perform_jump(p_wall_normal: Vector2 = Vector2.ZERO) -> void:
	jump_calls += 1
	last_jump_wall_normal = p_wall_normal
	velocity.y = -100.0 * gravity_direction

func set_gravity_direction(direction: float) -> void:
	gravity_direction = -1.0 if direction < 0.0 else 1.0

func set_detectable(value: bool) -> void:
	detectable = value
