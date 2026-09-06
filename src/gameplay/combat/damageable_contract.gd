class_name DamageableContract
extends RefCounted

const REQUIRED_METHODS: Array[StringName] = [
	&"take_damage",
	&"heal",
	&"apply_status",
	&"die",
]

static func supports(target: Object) -> bool:
	if target == null:
		return false
	for method_name in REQUIRED_METHODS:
		if not target.has_method(method_name):
			return false
	return true

