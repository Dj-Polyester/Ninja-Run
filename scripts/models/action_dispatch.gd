class_name ActionDispatch
extends RefCounted
## Input-facing action vocabulary. Controllers consume these semantic actions, not devices.

enum Action { JUMP, ROLL, ABILITY_1 }

static func from_input(action_name: StringName) -> int:
	match action_name:
		&"jump", &"touch_tap_jump": return Action.JUMP
		&"roll", &"touch_swipe_roll": return Action.ROLL
	var slot := ability_slot_from_input(action_name)
	if slot >= 0:
		return Action.ABILITY_1 + slot
	return -1

static func ability_slot(action: int) -> int:
	if action < Action.ABILITY_1:
		return -1
	return action - Action.ABILITY_1

static func desktop_ability_input(slot: int) -> StringName:
	return StringName("ability_%d" % (slot + 1))

static func mobile_ability_input(slot: int) -> StringName:
	return StringName("mobile_auxiliary_action_%d" % (slot + 1))

static func ability_slot_from_input(action_name: StringName) -> int:
	var action_text := String(action_name)
	for prefix in ["ability_", "mobile_auxiliary_action_"]:
		if action_text.begins_with(prefix):
			var suffix := action_text.trim_prefix(prefix)
			if suffix.is_valid_int() and int(suffix) > 0:
				return int(suffix) - 1
	return -1

static func ensure_input_actions(capacity: int) -> void:
	for slot in maxi(0, capacity):
		var desktop := desktop_ability_input(slot)
		if not InputMap.has_action(desktop):
			InputMap.add_action(desktop)
			if slot < 9:
				var event := InputEventKey.new()
				event.keycode = 49 + slot
				InputMap.action_add_event(desktop, event)
		var mobile := mobile_ability_input(slot)
		if not InputMap.has_action(mobile):
			InputMap.add_action(mobile)
