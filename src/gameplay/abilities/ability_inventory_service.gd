class_name AbilityInventoryService
extends RefCounted

const ABILITY_CATALOG_SCRIPT := preload("res://src/data/ability_catalog.gd")

enum Result {
	SUCCESS,
	UNKNOWN_ABILITY,
	ALREADY_UNLOCKED,
	NOT_UNLOCKED,
	ALREADY_EQUIPPED,
	NOT_EQUIPPED,
	EQUIPMENT_LIMIT,
	INCOMPATIBLE,
	MAX_LEVEL,
}

static func is_unlocked(profile: Dictionary, ability_id: StringName) -> bool:
	var unlocked = profile.get("unlocked_abilities", [])
	return unlocked is Array and unlocked.has(String(ability_id))

static func is_equipped(profile: Dictionary, ability_id: StringName) -> bool:
	var equipped = profile.get("equipped_abilities", [])
	return equipped is Array and equipped.has(String(ability_id))

static func unlock(profile: Dictionary, ability_id: StringName) -> int:
	if ABILITY_CATALOG_SCRIPT.get_by_id(ability_id) == null:
		return Result.UNKNOWN_ABILITY
	if is_unlocked(profile, ability_id):
		return Result.ALREADY_UNLOCKED
	var unlocked: Array = profile.get("unlocked_abilities", []).duplicate()
	unlocked.append(String(ability_id))
	profile["unlocked_abilities"] = unlocked
	var levels: Dictionary = profile.get("ability_levels", {}).duplicate(true)
	levels[String(ability_id)] = maxi(1, int(levels.get(String(ability_id), 1)))
	profile["ability_levels"] = levels
	return Result.SUCCESS
static func equip(profile: Dictionary, ability_id: StringName) -> int:
	if ABILITY_CATALOG_SCRIPT.get_by_id(ability_id) == null:
		return Result.UNKNOWN_ABILITY
	if not is_unlocked(profile, ability_id):
		return Result.NOT_UNLOCKED
	if is_equipped(profile, ability_id):
		return Result.ALREADY_EQUIPPED
	var equipped: Array = profile.get("equipped_abilities", []).duplicate()
	if equipped.size() >= GameConfig.NUM_EQUIPABLE_ABILITIES:
		return Result.EQUIPMENT_LIMIT
	for other_id in equipped:
		if not ABILITY_CATALOG_SCRIPT.are_compatible(ability_id, StringName(other_id)):
			return Result.INCOMPATIBLE
	equipped.append(String(ability_id))
	profile["equipped_abilities"] = equipped
	return Result.SUCCESS

static func unequip(profile: Dictionary, ability_id: StringName) -> int:
	if ABILITY_CATALOG_SCRIPT.get_by_id(ability_id) == null:
		return Result.UNKNOWN_ABILITY
	var equipped: Array = profile.get("equipped_abilities", []).duplicate()
	var id := String(ability_id)
	if not equipped.has(id):
		return Result.NOT_EQUIPPED
	equipped.erase(id)
	profile["equipped_abilities"] = equipped
	return Result.SUCCESS

static func upgrade(profile: Dictionary, ability_id: StringName) -> int:
	var ability = ABILITY_CATALOG_SCRIPT.get_by_id(ability_id)
	if ability == null:
		return Result.UNKNOWN_ABILITY
	if not is_unlocked(profile, ability_id):
		return Result.NOT_UNLOCKED
	var levels: Dictionary = profile.get("ability_levels", {}).duplicate(true)
	var id := String(ability_id)
	var current := clampi(int(levels.get(id, 1)), 1, ability.max_level)
	if current >= ability.max_level:
		return Result.MAX_LEVEL
	levels[id] = current + 1
	profile["ability_levels"] = levels
	return Result.SUCCESS
