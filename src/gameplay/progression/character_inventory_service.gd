class_name CharacterInventoryService
extends RefCounted

const CHARACTER_CATALOG_SCRIPT := preload("res://src/data/character_catalog.gd")

enum Result {
	SUCCESS,
	UNKNOWN_CHARACTER,
	ALREADY_UNLOCKED,
	NOT_UNLOCKED,
	NOT_ENOUGH_GOLD,
	ALREADY_SELECTED,
}

static func is_unlocked(profile: Dictionary, character_id: int) -> bool:
	var unlocked = profile.get("unlocked_characters", [])
	return unlocked is Array and unlocked.has(character_id)

static func unlock(profile: Dictionary, character_id: int) -> int:
	var character = CHARACTER_CATALOG_SCRIPT.get_by_id(character_id)
	if character == null:
		return Result.UNKNOWN_CHARACTER
	if is_unlocked(profile, character_id):
		return Result.ALREADY_UNLOCKED
	var gold := maxi(0, int(profile.get("gold", 0)))
	if gold < int(character.unlock_cost):
		return Result.NOT_ENOUGH_GOLD
	var unlocked: Array = profile.get("unlocked_characters", []).duplicate()
	unlocked.append(character_id)
	profile["unlocked_characters"] = unlocked
	profile["gold"] = gold - int(character.unlock_cost)
	return Result.SUCCESS

static func select(profile: Dictionary, character_id: int) -> int:
	if CHARACTER_CATALOG_SCRIPT.get_by_id(character_id) == null:
		return Result.UNKNOWN_CHARACTER
	if not is_unlocked(profile, character_id):
		return Result.NOT_UNLOCKED
	if int(profile.get("selected_character", 0)) == character_id:
		return Result.ALREADY_SELECTED
	profile["selected_character"] = character_id
	return Result.SUCCESS
