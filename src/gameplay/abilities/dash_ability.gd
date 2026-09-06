class_name DashAbility
extends Ability

var remaining_distance := 0.0

func activate() -> bool:
	if not super.activate():
		return false
	remaining_distance = GameConfig.tiles_to_pixels(GameConfig.DASH_TILES)
	return true

func horizontal_speed(delta: float) -> float:
	if not active or remaining_distance <= 0.0:
		return 0.0
	var speed := GameConfig.tiles_to_pixels(GameConfig.DASH_SPEED)
	if delta > 0.0:
		speed = minf(speed, remaining_distance / delta)
	return speed

func after_move(previous_x: float) -> void:
	if not active:
		return
	var travelled := maxf(0.0, player.global_position.x - previous_x)
	remaining_distance = maxf(0.0, remaining_distance - travelled)
	if remaining_distance <= 0.5 or player.is_on_wall() or travelled <= 0.001:
		deactivate()

func deactivate() -> void:
	super.deactivate()
	remaining_distance = 0.0
