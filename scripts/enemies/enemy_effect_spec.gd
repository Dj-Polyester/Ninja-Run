class_name EnemyEffectSpec
extends RefCounted
## Immutable content-facing status payload. It is intentionally pure so it can
## be used by enemy attacks, projectiles, and tests without scene ownership.

var status_id: StringName
var duration_seconds: float
var tick_interval_seconds: float
var periodic_damage: float
var movement_multiplier: float
var appearance: StringName
var source_id: StringName

func _init(new_status_id: StringName = &"", new_duration_seconds: float = 0.0, new_tick_interval_seconds: float = 0.0, new_periodic_damage: float = 0.0, new_movement_multiplier: float = 1.0, new_appearance: StringName = &"", new_source_id: StringName = &"") -> void:
	status_id = new_status_id
	duration_seconds = new_duration_seconds
	tick_interval_seconds = new_tick_interval_seconds
	periodic_damage = new_periodic_damage
	movement_multiplier = new_movement_multiplier
	appearance = new_appearance
	source_id = new_source_id

func is_valid() -> bool:
	if status_id.is_empty() or not is_finite(duration_seconds) or duration_seconds < GameConfig.MIN_STATUS_DURATION or duration_seconds > GameConfig.MAX_STATUS_DURATION:
		return false
	if not is_finite(tick_interval_seconds) or not is_finite(periodic_damage) or not is_finite(movement_multiplier):
		return false
	if tick_interval_seconds < 0.0 or periodic_damage < 0.0 or periodic_damage > GameConfig.MAX_STATUS_PERIODIC_DAMAGE:
		return false
	if periodic_damage > 0.0 and tick_interval_seconds < GameConfig.MIN_STATUS_TICK_INTERVAL:
		return false
	return movement_multiplier >= GameConfig.MIN_SLOWDOWN_SPEED_MULTIPLIER and movement_multiplier <= 1.0

func to_timed_status(now_seconds: float, fallback_source: StringName = &"") -> DamageStatus.TimedStatus:
	return DamageStatus.TimedStatus.new(status_id, duration_seconds, now_seconds, tick_interval_seconds, periodic_damage, source_id if not source_id.is_empty() else fallback_source, movement_multiplier, appearance)
