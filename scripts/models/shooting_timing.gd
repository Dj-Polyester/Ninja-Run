class_name ShootingTiming
extends RefCounted
## Timing contract: Shooting activation cooldown is separate from per-weapon automatic fire.

var activation_cooldown: float
var last_activation_at: float = -INF
var weapon_intervals: Dictionary = {}
var last_weapon_fire_at: Dictionary = {}
var is_active: bool = false

func _init(new_activation_cooldown: float = GameConfig.COOLDOWN_PERIOD) -> void:
	activation_cooldown = maxf(0.0, new_activation_cooldown)

func register_weapon(weapon_id: StringName, fire_interval: float) -> bool:
	if fire_interval <= 0.0:
		return false
	weapon_intervals[weapon_id] = fire_interval
	return true

func can_activate(now_seconds: float) -> bool:
	return not is_active and now_seconds >= last_activation_at + activation_cooldown

func activate(now_seconds: float) -> bool:
	if not can_activate(now_seconds):
		return false
	last_activation_at = now_seconds
	is_active = true
	return true

func deactivate() -> void:
	# End an activation without erasing its cooldown or per-weapon cadence history.
	is_active = false

func reset() -> void:
	is_active = false
	last_activation_at = -INF
	last_weapon_fire_at.clear()

func due_weapons(now_seconds: float, equipped_weapon_ids: Array[StringName], enemies_visible: bool) -> Array[StringName]:
	var due: Array[StringName] = []
	if not is_active or not enemies_visible:
		return due
	for weapon_id: StringName in equipped_weapon_ids:
		if not weapon_intervals.has(weapon_id):
			continue
		var last_fired: float = last_weapon_fire_at.get(weapon_id, -INF)
		if now_seconds >= last_fired + float(weapon_intervals[weapon_id]):
			due.append(weapon_id)
	return due

func mark_fired(weapon_id: StringName, now_seconds: float) -> void:
	if weapon_intervals.has(weapon_id):
		last_weapon_fire_at[weapon_id] = now_seconds
