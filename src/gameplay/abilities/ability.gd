class_name Ability
extends RefCounted

var data: AbilityData
var player
var controller
var cooldown_remaining := 0.0
var upgrade_level := 1
var active := false

func setup(p_data: AbilityData, p_player, p_controller, p_upgrade_level: int) -> Ability:
	data = p_data
	player = p_player
	controller = p_controller
	set_upgrade_level(p_upgrade_level)
	return self

func set_upgrade_level(level: int) -> void:
	var maximum := data.max_level if data != null else 1
	upgrade_level = clampi(level, 1, maximum)

func can_activate() -> bool:
	if data == null or player == null or not is_instance_valid(player):
		return false
	if cooldown_remaining > 0.0:
		return false
	if player.has_method(&"can_activate_abilities") and not bool(player.call(&"can_activate_abilities")):
		return false
	return true

func activate() -> bool:
	if not can_activate():
		return false
	active = true
	if data.has_cooldown:
		cooldown_remaining = GameConfig.COOLDOWN_PERIOD
	return true

func deactivate() -> void:
	active = false

func tick(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

func reset_runtime() -> void:
	deactivate()
	cooldown_remaining = 0.0
