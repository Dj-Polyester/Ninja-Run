class_name AbilityDefinition
extends RefCounted

const TRIGGER_JUMP: StringName = &"jump"
const TRIGGER_SLOT: StringName = &"slot"
const TRIGGERS: Array[StringName] = [TRIGGER_JUMP, TRIGGER_SLOT]

var id: StringName
var max_level: int
var cooldown_exempt: bool
var trigger: StringName

func _init(new_id: StringName = &"", new_max_level: int = 1, new_cooldown_exempt: bool = false, new_trigger: StringName = TRIGGER_SLOT) -> void:
	id = new_id
	max_level = new_max_level
	cooldown_exempt = new_cooldown_exempt
	trigger = new_trigger

func is_valid() -> bool:
	return not id.is_empty() and max_level >= 1 and trigger in TRIGGERS
