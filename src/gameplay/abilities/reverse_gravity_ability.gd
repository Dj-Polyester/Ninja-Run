class_name ReverseGravityAbility
extends Ability

func activate() -> bool:
	if not super.activate():
		return false
	player.set_gravity_direction(-player.gravity_direction)
	active = false
	return true
