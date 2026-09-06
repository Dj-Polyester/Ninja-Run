extends Node

signal slow_state_changed(active: bool, remaining: float)

var player_speed_multiplier := 1.0
var enemy_move_multiplier := 1.0
var enemy_fire_interval_multiplier := 1.0
var projectile_speed_multiplier := 1.0
var slow_remaining := 0.0

func _process(delta: float) -> void:
	if slow_remaining <= 0.0:
		return
	slow_remaining = maxf(0.0, slow_remaining - delta)
	if slow_remaining <= 0.0:
		reset()

func activate_slow(duration: float) -> void:
	if duration <= 0.0:
		return
	slow_remaining = maxf(slow_remaining, duration)
	player_speed_multiplier = GameConfig.SLOW_TIME_PLAYER_SPEED_MULTIPLIER
	enemy_move_multiplier = GameConfig.SLOW_TIME_ENEMY_MOVE_MULTIPLIER
	enemy_fire_interval_multiplier = GameConfig.SLOW_TIME_ENEMY_FIRE_INTERVAL_MULTIPLIER
	projectile_speed_multiplier = GameConfig.SLOW_TIME_PROJECTILE_SPEED_MULTIPLIER
	slow_state_changed.emit(true, slow_remaining)

func reset() -> void:
	var was_active := slow_remaining > 0.0 or not is_equal_approx(player_speed_multiplier, 1.0)
	slow_remaining = 0.0
	player_speed_multiplier = 1.0
	enemy_move_multiplier = 1.0
	enemy_fire_interval_multiplier = 1.0
	projectile_speed_multiplier = 1.0
	if was_active:
		slow_state_changed.emit(false, 0.0)

func is_slow_active() -> bool:
	return slow_remaining > 0.0
