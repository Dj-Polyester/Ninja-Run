class_name PlayerInputRouter
extends Node

const ABILITY_CATALOG_SCRIPT := preload("res://src/data/ability_catalog.gd")

signal ability_slots_changed

const GESTURE_ABILITY_IDS := {
	"jump": true,
	"climb": true,
	"glide": true,
	"reverse_gravity": true,
	"fly": true,
}
const PASSIVE_ABILITY_IDS := {
	"shooting": true,
}

var _ability_slots: Array[StringName] = []
@onready var player = get_parent()

func _ready() -> void:
	_refresh_ability_slots()
	if not GameState.profile_changed.is_connected(_on_profile_changed):
		GameState.profile_changed.connect(_on_profile_changed)

func _exit_tree() -> void:
	if GameState.profile_changed.is_connected(_on_profile_changed):
		GameState.profile_changed.disconnect(_on_profile_changed)

func _unhandled_input(event: InputEvent) -> void:
	if handle_input_event(event):
		get_viewport().set_input_as_handled()

func handle_input_event(event: InputEvent) -> bool:
	if event.is_action_pressed(&"jump"):
		press_jump()
		return true
	if event.is_action_released(&"jump"):
		release_jump()
		return true
	if event.is_action_pressed(&"roll"):
		press_roll()
		return true

	for slot in range(GameConfig.NUM_EQUIPABLE_ABILITIES):
		var action := StringName("ability_%d" % (slot + 1))
		if event.is_action_pressed(action):
			press_ability_slot(slot)
			return true
		if event.is_action_released(action):
			release_ability_slot(slot)
			return true
	return false

func press_jump() -> void:
	if player != null and player.has_method(&"trigger_jump"):
		player.call(&"trigger_jump")

func release_jump() -> void:
	if player != null and player.has_method(&"release_jump"):
		player.call(&"release_jump")

func press_roll() -> void:
	if player != null and player.has_method(&"trigger_roll"):
		player.call(&"trigger_roll")

func press_ability_slot(slot: int) -> bool:
	var ability_id := ability_id_for_slot(slot)
	if ability_id == &"":
		return false
	if player == null or not player.has_method(&"trigger_ability"):
		return false
	return bool(player.call(&"trigger_ability", ability_id))

func release_ability_slot(slot: int) -> void:
	# Direct-action abilities are edge-triggered. Jump-family hold/release
	# semantics are handled by the dedicated jump action instead of number keys.
	pass

func ability_slots() -> Array[StringName]:
	return _ability_slots.duplicate()

func ability_id_for_slot(slot: int) -> StringName:
	if slot < 0 or slot >= _ability_slots.size():
		return &""
	return _ability_slots[slot]

func ability_display_name_for_slot(slot: int) -> String:
	var ability_id := ability_id_for_slot(slot)
	var data = ABILITY_CATALOG_SCRIPT.get_by_id(ability_id)
	return data.display_name if data != null else String(ability_id)

func ability_cooldown_remaining_for_slot(slot: int) -> float:
	var ability_id := ability_id_for_slot(slot)
	if ability_id == &"" or player == null or not player.has_method(&"ability_cooldown_remaining"):
		return 0.0
	return maxf(0.0, float(player.call(&"ability_cooldown_remaining", ability_id)))

func mobile_button_slots() -> Array[int]:
	var result: Array[int] = []
	for slot in _ability_slots.size():
		result.append(slot)
	return result

func is_gesture_ability(ability_id: StringName) -> bool:
	return GESTURE_ABILITY_IDS.has(String(ability_id))

func is_passive_ability(ability_id: StringName) -> bool:
	return PASSIVE_ABILITY_IDS.has(String(ability_id))

func _refresh_ability_slots() -> void:
	var refreshed: Array[StringName] = []
	var equipped = GameState.profile.get("equipped_abilities", [])
	if equipped is Array:
		for raw_id in equipped:
			if refreshed.size() >= GameConfig.NUM_EQUIPABLE_ABILITIES:
				break
			var ability_id := StringName(String(raw_id))
			if ability_id == &"" or ABILITY_CATALOG_SCRIPT.get_by_id(ability_id) == null or refreshed.has(ability_id):
				continue
			# The task reserves Jump and Roll as dedicated actions. Climb, Glide,
			# Reverse Gravity and Fly are all driven by Jump semantics, while
			# Shooting is automatic. Only abilities with their own explicit action
			# receive numbered desktop slots / touch buttons.
			if is_gesture_ability(ability_id) or is_passive_ability(ability_id):
				continue
			refreshed.append(ability_id)
	if refreshed == _ability_slots:
		return
	_ability_slots = refreshed
	ability_slots_changed.emit()

func _on_profile_changed() -> void:
	_refresh_ability_slots()
