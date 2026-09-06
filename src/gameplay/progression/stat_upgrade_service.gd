class_name StatUpgradeService
extends RefCounted

const STAT_CATALOG_SCRIPT := preload("res://src/data/stat_catalog.gd")

enum Result {
	SUCCESS,
	UNKNOWN_STAT,
	LOCKED,
	AT_LIMIT,
	NOT_ENOUGH_GOLD,
}

static func upgrade(profile: Dictionary, stat_id: StringName) -> Result:
	var stat = STAT_CATALOG_SCRIPT.get_by_id(stat_id)
	if stat == null:
		return Result.UNKNOWN_STAT
	if not stat.is_unlocked(profile):
		return Result.LOCKED

	var levels = profile.get("stat_levels", {})
	if not levels is Dictionary:
		levels = STAT_CATALOG_SCRIPT.default_levels()
	else:
		levels = STAT_CATALOG_SCRIPT.sanitize_levels(levels)
	var current_level := int(levels.get(String(stat.id), 0))
	if current_level >= stat.max_level():
		return Result.AT_LIMIT

	var current_gold := maxi(0, int(profile.get("gold", 0)))
	if current_gold < stat.upgrade_golds:
		return Result.NOT_ENOUGH_GOLD

	# All preconditions are checked before either persistent field changes.
	levels[String(stat.id)] = current_level + 1
	profile["gold"] = current_gold - stat.upgrade_golds
	profile["stat_levels"] = levels
	STAT_CATALOG_SCRIPT.sync_derived_values(profile)
	return Result.SUCCESS
