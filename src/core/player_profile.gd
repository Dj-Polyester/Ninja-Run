class_name PlayerProfile
extends RefCounted

const GAME_CONFIG_SCRIPT := preload("res://src/core/game_config.gd")

const CURRENT_SAVE_VERSION := 1
const DEFAULT_CHARACTER_ID := 1
const DEFAULT_ABILITY_ID := "jump"
const REVIVAL_POTION_ID := "revival_potion"
const ACTION_BUTTON_SIDE_RIGHT := "right"
const ACTION_BUTTON_SIDE_LEFT := "left"

const DEFAULT_DATA := {
	"save_version": CURRENT_SAVE_VERSION,
	"gold": 0,
	"unlocked_characters": [DEFAULT_CHARACTER_ID],
	"selected_character": DEFAULT_CHARACTER_ID,
	"stat_levels": {
		"maximum_health": 0,
		"defense_multiplier": 0,
		"melee_power": 0,
		"enemy_fire_interval_multiplier": 0,
		"invisibility_duration": 0,
		"slow_down_duration": 0,
	},
	"unlocked_abilities": [DEFAULT_ABILITY_ID],
	"equipped_abilities": [DEFAULT_ABILITY_ID],
	"ability_levels": {DEFAULT_ABILITY_ID: 1},
	"unlocked_weapons": [],
	"equipped_weapons": [],
	"consumables": {REVIVAL_POTION_ID: 1},
	"settings": {"action_button_side": ACTION_BUTTON_SIDE_RIGHT},
	# Phase 4 gameplay reads these values directly. Phase 6 will derive them
	# from stat definitions/levels while retaining the persisted progression.
	"maximum_health": 100.0,
	"defense_multiplier": 1.0,
	# Compatibility alias for Phase 4 callers. GameState keeps this synchronized
	# with consumables.revival_potion through its consumable API.
	"revival_potions": 1,
}

static func create_default() -> Dictionary:
	return DEFAULT_DATA.duplicate(true)

static func sanitize(raw: Dictionary) -> Dictionary:
	if int(raw.get("save_version", -1)) != CURRENT_SAVE_VERSION:
		return {}

	var result := create_default()
	result["gold"] = maxi(0, _safe_int(raw.get("gold"), int(result.gold)))

	var unlocked_characters := _sanitize_int_array(raw.get("unlocked_characters"), [DEFAULT_CHARACTER_ID], 1)
	if not unlocked_characters.has(DEFAULT_CHARACTER_ID):
		unlocked_characters.push_front(DEFAULT_CHARACTER_ID)
	result["unlocked_characters"] = unlocked_characters
	var selected_character := _safe_int(raw.get("selected_character"), DEFAULT_CHARACTER_ID)
	if not unlocked_characters.has(selected_character):
		selected_character = DEFAULT_CHARACTER_ID
	result["selected_character"] = selected_character

	result["stat_levels"] = _sanitize_level_dictionary(raw.get("stat_levels"), result.stat_levels)

	var unlocked_abilities := _sanitize_string_array(raw.get("unlocked_abilities"), [DEFAULT_ABILITY_ID])
	if not unlocked_abilities.has(DEFAULT_ABILITY_ID):
		unlocked_abilities.push_front(DEFAULT_ABILITY_ID)
	result["unlocked_abilities"] = unlocked_abilities
	result["equipped_abilities"] = _sanitize_equipped(
		raw.get("equipped_abilities"),
		unlocked_abilities,
		GAME_CONFIG_SCRIPT.NUM_EQUIPABLE_ABILITIES,
		[DEFAULT_ABILITY_ID]
	)
	result["ability_levels"] = _sanitize_level_dictionary(raw.get("ability_levels"), result.ability_levels, 1)

	var unlocked_weapons := _sanitize_string_array(raw.get("unlocked_weapons"), [])
	result["unlocked_weapons"] = unlocked_weapons
	result["equipped_weapons"] = _sanitize_equipped(
		raw.get("equipped_weapons"),
		unlocked_weapons,
		GAME_CONFIG_SCRIPT.NUM_EQUIPPABLE_WEAPONS,
		[]
	)

	var consumables: Dictionary = result.consumables.duplicate(true)
	var raw_consumables = raw.get("consumables")
	if raw_consumables is Dictionary:
		for key in raw_consumables:
			var id := String(key)
			if id.is_empty():
				continue
			consumables[id] = maxi(0, _safe_int(raw_consumables[key], int(consumables.get(id, 0))))
	# Prefer the legacy alias when present so Phase 4 callers that mutate the
	# dictionary directly still round-trip correctly.
	if raw.has("revival_potions"):
		consumables[REVIVAL_POTION_ID] = maxi(0, _safe_int(raw.revival_potions, int(consumables[REVIVAL_POTION_ID])))
	result["consumables"] = consumables
	result["revival_potions"] = int(consumables[REVIVAL_POTION_ID])

	var settings: Dictionary = result.settings.duplicate(true)
	var raw_settings = raw.get("settings")
	if raw_settings is Dictionary:
		var side := String(raw_settings.get("action_button_side", settings.action_button_side)).to_lower()
		if side == ACTION_BUTTON_SIDE_LEFT or side == ACTION_BUTTON_SIDE_RIGHT:
			settings["action_button_side"] = side
	result["settings"] = settings

	result["maximum_health"] = maxf(1.0, _safe_float(raw.get("maximum_health"), float(result.maximum_health)))
	result["defense_multiplier"] = maxf(0.0, _safe_float(raw.get("defense_multiplier"), float(result.defense_multiplier)))
	return result

static func _sanitize_int_array(value, fallback: Array, minimum: int) -> Array:
	if not value is Array:
		return fallback.duplicate()
	var result: Array = []
	for item in value:
		var parsed := _safe_int(item, minimum - 1)
		if parsed >= minimum and not result.has(parsed):
			result.append(parsed)
	return result

static func _sanitize_string_array(value, fallback: Array) -> Array:
	if not value is Array:
		return fallback.duplicate()
	var result: Array = []
	for item in value:
		if not item is String and not item is StringName:
			continue
		var parsed := String(item).strip_edges()
		if not parsed.is_empty() and not result.has(parsed):
			result.append(parsed)
	return result

static func _sanitize_equipped(value, unlocked: Array, limit: int, fallback: Array) -> Array:
	var requested := _sanitize_string_array(value, fallback)
	var result: Array = []
	for id in requested:
		if unlocked.has(id) and not result.has(id):
			result.append(id)
			if result.size() >= limit:
				break
	return result

static func _sanitize_level_dictionary(value, fallback: Dictionary, minimum: int = 0) -> Dictionary:
	var result := fallback.duplicate(true)
	if not value is Dictionary:
		return result
	for key in value:
		var id := String(key)
		if id.is_empty():
			continue
		result[id] = maxi(minimum, _safe_int(value[key], int(result.get(id, minimum))))
	return result

static func _safe_int(value, fallback: int) -> int:
	if value is int or value is float:
		return int(value)
	return fallback

static func _safe_float(value, fallback: float) -> float:
	if value is int or value is float:
		return float(value)
	return fallback
