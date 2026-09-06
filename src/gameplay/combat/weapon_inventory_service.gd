class_name WeaponInventoryService
extends RefCounted

const WEAPON_CATALOG_SCRIPT := preload("res://src/data/weapon_catalog.gd")

enum Result {
	SUCCESS,
	UNKNOWN_WEAPON,
	SHOOTING_LOCKED,
	ALREADY_UNLOCKED,
	NOT_UNLOCKED,
	NOT_ENOUGH_GOLD,
	EQUIPMENT_LIMIT,
	ALREADY_EQUIPPED,
	NOT_EQUIPPED,
}

static func shooting_unlocked(profile: Dictionary) -> bool:
	var abilities = profile.get("unlocked_abilities", [])
	return abilities is Array and abilities.has(String(GameConfig.SHOOTING_ABILITY_ID))

static func is_unlocked(profile: Dictionary, weapon_id: StringName) -> bool:
	var unlocked = profile.get("unlocked_weapons", [])
	return unlocked is Array and unlocked.has(String(weapon_id))

static func unlock(profile: Dictionary, weapon_id: StringName) -> int:
	var weapon = WEAPON_CATALOG_SCRIPT.get_by_id(weapon_id)
	if weapon == null:
		return Result.UNKNOWN_WEAPON
	if not shooting_unlocked(profile):
		return Result.SHOOTING_LOCKED
	if is_unlocked(profile, weapon_id):
		return Result.ALREADY_UNLOCKED
	var gold := maxi(0, int(profile.get("gold", 0)))
	if gold < int(weapon.unlock_cost):
		return Result.NOT_ENOUGH_GOLD

	var unlocked: Array = profile.get("unlocked_weapons", []).duplicate()
	unlocked.append(String(weapon.id))
	profile["unlocked_weapons"] = unlocked
	profile["gold"] = gold - int(weapon.unlock_cost)
	return Result.SUCCESS

static func equip(profile: Dictionary, weapon_id: StringName) -> int:
	if WEAPON_CATALOG_SCRIPT.get_by_id(weapon_id) == null:
		return Result.UNKNOWN_WEAPON
	if not shooting_unlocked(profile):
		return Result.SHOOTING_LOCKED
	if not is_unlocked(profile, weapon_id):
		return Result.NOT_UNLOCKED
	var equipped: Array = profile.get("equipped_weapons", []).duplicate()
	var id := String(weapon_id)
	if equipped.has(id):
		return Result.ALREADY_EQUIPPED
	if equipped.size() >= GameConfig.NUM_EQUIPPABLE_WEAPONS:
		return Result.EQUIPMENT_LIMIT
	equipped.append(id)
	profile["equipped_weapons"] = equipped
	return Result.SUCCESS

static func unequip(profile: Dictionary, weapon_id: StringName) -> int:
	if WEAPON_CATALOG_SCRIPT.get_by_id(weapon_id) == null:
		return Result.UNKNOWN_WEAPON
	var equipped: Array = profile.get("equipped_weapons", []).duplicate()
	var id := String(weapon_id)
	if not equipped.has(id):
		return Result.NOT_EQUIPPED
	equipped.erase(id)
	profile["equipped_weapons"] = equipped
	return Result.SUCCESS
