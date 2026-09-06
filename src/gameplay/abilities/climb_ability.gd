class_name ClimbAbility
extends Ability

var wall_jumps_used := 0

func try_wall_jump() -> bool:
	if not can_activate() or wall_jumps_used >= upgrade_level or not player.is_on_wall():
		return false
	var wall_normal: Vector2 = player.get_wall_normal()
	player.perform_jump(wall_normal)
	wall_jumps_used += 1
	return true

func on_support_contact() -> void:
	wall_jumps_used = 0

func reset_runtime() -> void:
	super.reset_runtime()
	wall_jumps_used = 0
