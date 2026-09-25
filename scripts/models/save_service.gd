class_name SaveService
extends RefCounted
## Versioned profile persistence. RunState is deliberately absent from this schema.

const Profile = preload("res://scripts/models/profile_state.gd")
const AbilityCatalogRuntime = preload("res://scripts/abilities/ability_catalog.gd")
const WeaponCatalogRuntime = preload("res://scripts/weapons/weapon_catalog.gd")
const CharacterCatalogRuntime = preload("res://scripts/characters/character_catalog.gd")

const DEFAULT_PATH := "user://profile.json"

static func profile_to_data(profile: ProfileState) -> Dictionary:
	if profile == null or not profile.is_valid():
		return {}
	return {
		"schema_version": GameConfig.PROFILE_SCHEMA_VERSION,
		"gold": profile.gold,
		"revival_potions": profile.revival_potions,
		"selected_character": String(profile.selected_character),
		"unlocked_characters": _true_key_strings(profile.unlocked_characters),
		"stats": {
			"maximum_health": profile.maximum_health,
			"defense_multiplier": profile.defense_multiplier,
			"melee_power": profile.melee_power,
			"enemy_fire_interval_multiplier": profile.enemy_fire_interval_multiplier,
			"invisibility_duration": profile.invisibility_duration,
			"slow_down_duration": profile.slow_down_duration,
		},
		"abilities": {
			"unlocked": _true_key_strings(profile.abilities.unlocked),
			"equipped": _string_name_array(profile.abilities.equipped),
			"levels": _string_key_dictionary(profile.ability_levels),
			"cooldowns": _string_key_dictionary(profile.ability_cooldowns),
		},
		"weapons": {
			"unlocked": _true_key_strings(profile.weapons.unlocked),
			"equipped": _string_name_array(profile.weapons.equipped),
		},
		"settings": {
			"mobile_auxiliary_button_corner": String(profile.mobile_auxiliary_button_corner),
		},
	}

static func data_to_profile(data: Variant) -> ProfileState:
	var fallback := Profile.new()
	if not data is Dictionary:
		return fallback
	var source: Dictionary = (data as Dictionary).duplicate(true)
	var schema := int(source.get("schema_version", 0))
	if schema < 0 or schema > GameConfig.PROFILE_SCHEMA_VERSION:
		return fallback
	# Version 0 predates the finalized field names. Migrate known aliases while
	# leaving absent/new fields on current safe defaults.
	if schema == 0:
		if source.has("potions") and not source.has("revival_potions"):
			source["revival_potions"] = source["potions"]
		if source.has("character") and not source.has("selected_character"):
			source["selected_character"] = source["character"]
		source["schema_version"] = GameConfig.PROFILE_SCHEMA_VERSION

	var profile := Profile.new()
	profile.gold = maxi(0, int(source.get("gold", profile.gold)))
	profile.revival_potions = maxi(0, int(source.get("revival_potions", profile.revival_potions)))

	var stats := _dictionary_or_empty(source.get("stats", {}))
	profile.maximum_health = clampi(int(stats.get("maximum_health", profile.maximum_health)), GameConfig.MIN_MAXIMUM_HEALTH, GameConfig.MAX_MAXIMUM_HEALTH)
	profile.defense_multiplier = clampf(float(stats.get("defense_multiplier", profile.defense_multiplier)), GameConfig.MIN_DEFENSE, GameConfig.MAX_DEFENSE)
	profile.melee_power = clampi(int(stats.get("melee_power", profile.melee_power)), GameConfig.MIN_MELEE_POWER, GameConfig.MAX_MELEE_POWER)
	profile.enemy_fire_interval_multiplier = clampf(float(stats.get("enemy_fire_interval_multiplier", profile.enemy_fire_interval_multiplier)), GameConfig.MIN_ENEMY_FIRE_RATE, GameConfig.MAX_ENEMY_FIRE_RATE)
	profile.invisibility_duration = clampf(float(stats.get("invisibility_duration", profile.invisibility_duration)), GameConfig.MIN_INVISIBILITY_DURATION, GameConfig.MAX_INVISIBILITY_DURATION)
	profile.slow_down_duration = clampf(float(stats.get("slow_down_duration", profile.slow_down_duration)), GameConfig.MIN_SLOW_DOWN_DURATION, GameConfig.MAX_SLOW_DOWN_DURATION)

	_restore_characters(profile, source)
	_restore_abilities(profile, _dictionary_or_empty(source.get("abilities", {})))
	_restore_weapons(profile, _dictionary_or_empty(source.get("weapons", {})))

	var settings := _dictionary_or_empty(source.get("settings", {}))
	var corner := StringName(String(settings.get("mobile_auxiliary_button_corner", String(GameConfig.MOBILE_AUXILIARY_BUTTON_CORNER_DEFAULT))))
	if corner in [&"bottom_left", &"bottom_right"]:
		profile.mobile_auxiliary_button_corner = corner

	return profile if profile.is_valid() else fallback

static func save_profile(profile: ProfileState, path: String = DEFAULT_PATH) -> bool:
	var data := profile_to_data(profile)
	if data.is_empty() or path.is_empty():
		return false
	var absolute := ProjectSettings.globalize_path(path)
	var directory := absolute.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory) != OK and not DirAccess.dir_exists_absolute(directory):
		return false
	var temp := absolute + ".tmp"
	var backup := absolute + ".bak"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()

	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	if FileAccess.file_exists(absolute):
		if DirAccess.rename_absolute(absolute, backup) != OK:
			DirAccess.remove_absolute(temp)
			return false
	if DirAccess.rename_absolute(temp, absolute) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, absolute)
		DirAccess.remove_absolute(temp)
		return false
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	return true

static func load_profile(path: String = DEFAULT_PATH) -> ProfileState:
	if path.is_empty():
		return Profile.new()
	var absolute := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute):
		return Profile.new()
	var file := FileAccess.open(absolute, FileAccess.READ)
	if file == null:
		return Profile.new()
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return Profile.new()
	return data_to_profile(parser.data)

static func _restore_characters(profile: ProfileState, source: Dictionary) -> void:
	profile.unlocked_characters.clear()
	profile.unlocked_characters[CharacterCatalogRuntime.DEFAULT_ID] = true
	for value in source.get("unlocked_characters", []):
		var id := StringName(String(value))
		if CharacterCatalogRuntime.by_id(id) != null:
			profile.unlocked_characters[id] = true
	var selected := StringName(String(source.get("selected_character", String(CharacterCatalogRuntime.DEFAULT_ID))))
	profile.selected_character = selected if CharacterCatalogRuntime.by_id(selected) != null and profile.unlocked_characters.get(selected, false) else CharacterCatalogRuntime.DEFAULT_ID

static func _restore_abilities(profile: ProfileState, data: Dictionary) -> void:
	profile.abilities.unlocked.clear()
	profile.abilities.equipped.clear()
	profile.ability_levels.clear()
	profile.ability_cooldowns.clear()
	profile.initialize_ability_progress(AbilityEligibility.JUMP)

	for value in data.get("unlocked", []):
		var id := StringName(String(value))
		if AbilityCatalogRuntime.by_id(id) != null:
			profile.initialize_ability_progress(id)

	var levels := data.get("levels", {}) as Dictionary
	for key in levels.keys():
		var id := StringName(String(key))
		var definition = AbilityCatalogRuntime.by_id(id)
		if definition != null and profile.abilities.unlocked.get(id, false):
			profile.ability_levels[id] = clampi(int(levels[key]), 1, definition.max_level)

	var cooldowns := data.get("cooldowns", {}) as Dictionary
	for key in cooldowns.keys():
		var id := StringName(String(key))
		var definition = AbilityCatalogRuntime.by_id(id)
		if definition != null and not definition.cooldown_exempt and profile.abilities.unlocked.get(id, false):
			profile.ability_cooldowns[id] = clampf(float(cooldowns[key]), GameConfig.MIN_ABILITY_COOLDOWN, GameConfig.MAX_ABILITY_COOLDOWN)

	for value in data.get("equipped", []):
		var id := StringName(String(value))
		if profile.abilities.unlocked.get(id, false):
			profile.abilities.equip(id)
	if profile.abilities.equipped.is_empty():
		profile.abilities.equip(AbilityEligibility.JUMP)

static func _restore_weapons(profile: ProfileState, data: Dictionary) -> void:
	profile.weapons.unlocked.clear()
	profile.weapons.equipped.clear()
	if not profile.abilities.unlocked.get(AbilityEligibility.SHOOTING, false):
		return
	for value in data.get("unlocked", []):
		var id := StringName(String(value))
		if WeaponCatalogRuntime.by_id(id) != null:
			profile.weapons.unlock(id)
	for value in data.get("equipped", []):
		var id := StringName(String(value))
		if profile.weapons.unlocked.get(id, false):
			profile.weapons.equip(id)

static func _true_key_strings(dictionary: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in dictionary.keys():
		if bool(dictionary[key]):
			result.append(String(key))
	result.sort()
	return result

static func _string_name_array(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result

static func _string_key_dictionary(dictionary: Dictionary) -> Dictionary:
	var result := {}
	for key in dictionary.keys():
		result[String(key)] = dictionary[key]
	return result

static func _dictionary_or_empty(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}
