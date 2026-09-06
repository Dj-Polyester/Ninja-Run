class_name FlyAbility
extends Ability

func try_jump() -> bool:
	if not can_activate():
		return false
	player.perform_jump()
	return true
