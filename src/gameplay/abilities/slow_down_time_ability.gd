class_name SlowDownTimeAbility
extends Ability

func activate() -> bool:
	if not super.activate():
		return false
	var duration := maxf(0.0, float(GameState.stat_value(&"slow_down_duration")))
	WorldSpeed.activate_slow(duration)
	active = duration > 0.0
	return true

func tick(delta: float) -> void:
	super.tick(delta)
	if active and not WorldSpeed.is_slow_active():
		active = false

func deactivate() -> void:
	if active:
		WorldSpeed.reset()
	super.deactivate()
