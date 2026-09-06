class_name InvisibilityAbility
extends Ability

var duration_remaining := 0.0

func activate() -> bool:
	if not super.activate():
		return false
	duration_remaining = maxf(0.0, float(GameState.stat_value(&"invisibility_duration")))
	player.set_detectable(false)
	active = duration_remaining > 0.0
	if not active:
		player.set_detectable(true)
	return true

func tick(delta: float) -> void:
	super.tick(delta)
	if not active:
		return
	duration_remaining = maxf(0.0, duration_remaining - delta)
	if duration_remaining <= 0.0:
		deactivate()

func deactivate() -> void:
	duration_remaining = 0.0
	if player != null and is_instance_valid(player):
		player.set_detectable(true)
	super.deactivate()
