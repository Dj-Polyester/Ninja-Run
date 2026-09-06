class_name JumpAbility
extends Ability

var air_jumps_used := 0

func try_jump() -> bool:
	if not can_activate():
		return false
	if player.is_supported():
		air_jumps_used = 0
		player.perform_jump()
		return true
	if air_jumps_used >= upgrade_level:
		return false
	player.perform_jump()
	air_jumps_used += 1
	return true

func on_support_contact() -> void:
	air_jumps_used = 0

func reset_runtime() -> void:
	super.reset_runtime()
	air_jumps_used = 0
