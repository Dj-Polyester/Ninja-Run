class_name CharacterCatalog
extends RefCounted

const CHARACTER_COUNT := 45
const DATA_ROOT := "res://data/characters"

static func all() -> Array:
	var result: Array = []
	for character_id in range(1, CHARACTER_COUNT + 1):
		var character = get_by_id(character_id)
		if character != null:
			result.append(character)
	return result

static func get_by_id(character_id: int):
	if character_id < 1 or character_id > CHARACTER_COUNT:
		return null
	return ResourceLoader.load(resource_path(character_id))

static func contains(character_id: int) -> bool:
	return get_by_id(character_id) != null

static func resource_path(character_id: int) -> String:
	return "%s/character_%02d.tres" % [DATA_ROOT, character_id]
