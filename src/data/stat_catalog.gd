class_name StatCatalog
extends RefCounted

const MAXIMUM_HEALTH = preload("res://data/stats/maximum_health.tres")
const DEFENSE_MULTIPLIER = preload("res://data/stats/defense_multiplier.tres")
const MELEE_POWER = preload("res://data/stats/melee_power.tres")
const ENEMY_FIRE_INTERVAL_MULTIPLIER = preload("res://data/stats/enemy_fire_interval_multiplier.tres")
const INVISIBILITY_DURATION = preload("res://data/stats/invisibility_duration.tres")
const SLOW_DOWN_DURATION = preload("res://data/stats/slow_down_duration.tres")

const ORDERED = [
	MAXIMUM_HEALTH,
	DEFENSE_MULTIPLIER,
	MELEE_POWER,
	ENEMY_FIRE_INTERVAL_MULTIPLIER,
	INVISIBILITY_DURATION,
	SLOW_DOWN_DURATION,
]

static func all() -> Array:
	return ORDERED.duplicate()

static func get_by_id(stat_id: StringName) -> Variant:
	for stat in ORDERED:
		if stat.id == stat_id:
			return stat
	return null

static func default_levels() -> Dictionary:
	var levels := {}
	for stat in ORDERED:
		levels[String(stat.id)] = 0
	return levels

static func sanitize_levels(raw, fallback: Dictionary = {}) -> Dictionary:
	var result := default_levels()
	for key in fallback:
		var fallback_stat: Variant = get_by_id(StringName(key))
		if fallback_stat != null:
			result[String(fallback_stat.id)] = clampi(int(fallback[key]), 0, fallback_stat.max_level())
	if not raw is Dictionary:
		return result
	for key in raw:
		var stat: Variant = get_by_id(StringName(key))
		if stat == null:
			continue
		var raw_level = raw[key]
		if raw_level is int or raw_level is float:
			result[String(stat.id)] = clampi(int(raw_level), 0, stat.max_level())
	return result

static func value_for_profile(profile: Dictionary, stat_id: StringName) -> Variant:
	var stat: Variant = get_by_id(stat_id)
	if stat == null:
		return 0.0
	var levels = profile.get("stat_levels", {})
	var level := int(levels.get(String(stat.id), 0)) if levels is Dictionary else 0
	return stat.value_for_level(level)

static func sync_derived_values(profile: Dictionary) -> void:
	for stat in ORDERED:
		profile[String(stat.id)] = value_for_profile(profile, stat.id)
