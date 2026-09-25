class_name CharacterCatalog
extends RefCounted

const Definition = preload("res://scripts/characters/character_definition.gd")
const DEFAULT_ID: StringName = &"1"
const COUNT: int = 45

static func definitions() -> Array[Definition]:
	var result: Array[Definition] = []
	for index in range(1, COUNT + 1):
		var id := StringName(str(index))
		var cost := 0 if index == 1 else GameConfig.CHARACTER_UNLOCK_BASE_GOLDS + (index - 2) * GameConfig.CHARACTER_UNLOCK_GOLD_STEP
		result.append(Definition.new(id, "Character %d" % index, "res://assets/Characters/%d/Png/Character Sprite/sprite_frames.tres" % index, cost))
	return result

static func by_id(id: StringName) -> Definition:
	var text := String(id)
	if not text.is_valid_int():
		return null
	var numeric := int(text)
	if numeric < 1 or numeric > COUNT or str(numeric) != text:
		return null
	var cost := 0 if numeric == 1 else GameConfig.CHARACTER_UNLOCK_BASE_GOLDS + (numeric - 2) * GameConfig.CHARACTER_UNLOCK_GOLD_STEP
	return Definition.new(id, "Character %d" % numeric, "res://assets/Characters/%d/Png/Character Sprite/sprite_frames.tres" % numeric, cost)

static func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for index in range(1, COUNT + 1):
		result.append(StringName(str(index)))
	return result
