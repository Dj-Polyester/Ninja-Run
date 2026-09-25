class_name AbilityCatalog
extends RefCounted

const Definition = preload("res://scripts/abilities/ability_definition.gd")

static func definitions() -> Array[Definition]:
	return [
		Definition.new(&"jump", 3, true, Definition.TRIGGER_JUMP),
		Definition.new(&"climb", 2, true, Definition.TRIGGER_JUMP),
		Definition.new(&"glide", 1, true, Definition.TRIGGER_JUMP),
		Definition.new(&"reverse_gravity", 1, false, Definition.TRIGGER_JUMP),
		Definition.new(&"fly", 1, true, Definition.TRIGGER_JUMP),
		Definition.new(&"dash", 1, false, Definition.TRIGGER_SLOT),
		Definition.new(&"shooting", 1, false, Definition.TRIGGER_SLOT),
		Definition.new(&"explode", 1, false, Definition.TRIGGER_SLOT),
		Definition.new(&"slow_down_time", 1, false, Definition.TRIGGER_SLOT),
		Definition.new(&"invisibility", 1, false, Definition.TRIGGER_SLOT),
	]

static func by_id(id: StringName) -> Definition:
	for definition: Definition in definitions():
		if definition.id == id:
			return definition
	return null

static func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition: Definition in definitions():
		result.append(definition.id)
	result.sort()
	return result
