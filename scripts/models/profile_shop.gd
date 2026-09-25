class_name ProfileShop
extends RefCounted
## Persistent economy transactions. Every successful purchase emits one profile
## change after all preconditions pass; rejected transactions mutate nothing.

const CharacterCatalogRuntime = preload("res://scripts/characters/character_catalog.gd")
const AbilityCatalogRuntime = preload("res://scripts/abilities/ability_catalog.gd")
const WeaponCatalogRuntime = preload("res://scripts/weapons/weapon_catalog.gd")

const STAT_MAXIMUM_HEALTH: StringName = &"maximum_health"
const STAT_DEFENSE: StringName = &"defense"
const STAT_MELEE_POWER: StringName = &"melee_power"
const STAT_ENEMY_FIRE_RATE: StringName = &"enemy_fire_rate"
const STAT_INVISIBILITY_DURATION: StringName = &"invisibility_duration"
const STAT_SLOW_DOWN_DURATION: StringName = &"slow_down_duration"

static func purchase_revival_potion(profile: ProfileState) -> bool:
	return _purchase_potion(profile, GameConfig.REVIVAL_POTION_GOLDS)

static func purchase_character(profile: ProfileState, character_id: StringName) -> bool:
	if profile == null or not profile.is_valid():
		return false
	var definition = CharacterCatalogRuntime.by_id(character_id)
	if definition == null or profile.unlocked_characters.get(character_id, false) or not profile.can_afford(definition.unlock_cost):
		return false
	profile.gold -= definition.unlock_cost
	profile.unlocked_characters[character_id] = true
	profile.changed.emit()
	return true

static func select_character(profile: ProfileState, character_id: StringName) -> bool:
	if profile == null or CharacterCatalogRuntime.by_id(character_id) == null or not profile.unlocked_characters.get(character_id, false) or profile.selected_character == character_id:
		return false
	profile.selected_character = character_id
	profile.changed.emit()
	return true

static func purchase_ability(profile: ProfileState, ability_id: StringName) -> bool:
	if profile == null or not profile.is_valid() or AbilityCatalogRuntime.by_id(ability_id) == null:
		return false
	if profile.abilities.unlocked.get(ability_id, false) or not profile.can_afford(GameConfig.ABILITY_UNLOCK_GOLDS):
		return false
	profile.gold -= GameConfig.ABILITY_UNLOCK_GOLDS
	if not profile.initialize_ability_progress(ability_id):
		profile.gold += GameConfig.ABILITY_UNLOCK_GOLDS
		return false
	profile.changed.emit()
	return true

static func purchase_weapon(profile: ProfileState, weapon_id: StringName) -> bool:
	if profile == null or not profile.is_valid() or WeaponCatalogRuntime.by_id(weapon_id) == null:
		return false
	if not profile.abilities.unlocked.get(AbilityEligibility.SHOOTING, false) or profile.weapons.unlocked.get(weapon_id, false) or not profile.can_afford(GameConfig.WEAPON_UNLOCK_GOLDS):
		return false
	profile.gold -= GameConfig.WEAPON_UNLOCK_GOLDS
	profile.weapons.unlock(weapon_id)
	profile.changed.emit()
	return true

static func set_ability_equipped(profile: ProfileState, ability_id: StringName, equipped: bool) -> bool:
	if profile == null or not profile.is_valid() or not profile.abilities.unlocked.get(ability_id, false):
		return false
	var changed_state := profile.abilities.equip(ability_id) if equipped else profile.abilities.unequip(ability_id)
	if not changed_state:
		return false
	profile.changed.emit()
	return true

static func set_weapon_equipped(profile: ProfileState, weapon_id: StringName, equipped: bool) -> bool:
	if profile == null or not profile.is_valid() or WeaponCatalogRuntime.by_id(weapon_id) == null or not profile.weapons.unlocked.get(weapon_id, false):
		return false
	var changed_state := profile.weapons.equip(weapon_id) if equipped else profile.weapons.unequip(weapon_id)
	if not changed_state:
		return false
	profile.changed.emit()
	return true

static func set_mobile_auxiliary_button_corner(profile: ProfileState, corner: StringName) -> bool:
	if profile == null or not profile.is_valid() or not corner in [&"bottom_left", &"bottom_right"] or profile.mobile_auxiliary_button_corner == corner:
		return false
	profile.mobile_auxiliary_button_corner = corner
	profile.changed.emit()
	return true

static func upgrade_ability_level(profile: ProfileState, ability_id: StringName) -> bool:
	if profile == null or not profile.is_valid() or not profile.abilities.unlocked.get(ability_id, false):
		return false
	var definition = AbilityCatalogRuntime.by_id(ability_id)
	if definition == null:
		return false
	var current := profile.ability_level(ability_id)
	if current >= definition.max_level or not profile.can_afford(GameConfig.ABILITY_LEVEL_UPGRADE_GOLDS):
		return false
	profile.gold -= GameConfig.ABILITY_LEVEL_UPGRADE_GOLDS
	profile.ability_levels[ability_id] = current + 1
	profile.changed.emit()
	return true

static func upgrade_ability_cooldown(profile: ProfileState, ability_id: StringName) -> bool:
	if profile == null or not profile.is_valid() or not profile.abilities.unlocked.get(ability_id, false) or AbilityEligibility.is_cooldown_exempt(ability_id):
		return false
	var current := profile.ability_cooldown(ability_id)
	var next := current + GameConfig.ABILITY_COOLDOWN_UPGRADE
	if next < GameConfig.MIN_ABILITY_COOLDOWN - 0.000001 or next > GameConfig.MAX_ABILITY_COOLDOWN + 0.000001 or is_equal_approx(current, GameConfig.MIN_ABILITY_COOLDOWN):
		return false
	if not profile.can_afford(GameConfig.ABILITY_COOLDOWN_UPGRADE_GOLDS):
		return false
	profile.gold -= GameConfig.ABILITY_COOLDOWN_UPGRADE_GOLDS
	profile.ability_cooldowns[ability_id] = clampf(next, GameConfig.MIN_ABILITY_COOLDOWN, GameConfig.MAX_ABILITY_COOLDOWN)
	profile.changed.emit()
	return true

static func upgrade_stat(profile: ProfileState, stat_id: StringName) -> bool:
	if profile == null or not profile.is_valid():
		return false
	match stat_id:
		STAT_MAXIMUM_HEALTH:
			return _upgrade_int(profile, &"maximum_health", profile.maximum_health, GameConfig.MAXIMUM_HEALTH_UPGRADE, GameConfig.MIN_MAXIMUM_HEALTH, GameConfig.MAX_MAXIMUM_HEALTH, GameConfig.MAXIMUM_HEALTH_UPGRADE_GOLDS)
		STAT_DEFENSE:
			return _upgrade_float(profile, &"defense", profile.defense_multiplier, GameConfig.DEFENSE_UPGRADE, GameConfig.MIN_DEFENSE, GameConfig.MAX_DEFENSE, GameConfig.DEFENSE_UPGRADE_GOLDS)
		STAT_MELEE_POWER:
			return _upgrade_int(profile, &"melee_power", profile.melee_power, GameConfig.MELEE_POWER_UPGRADE, GameConfig.MIN_MELEE_POWER, GameConfig.MAX_MELEE_POWER, GameConfig.MELEE_POWER_UPGRADE_GOLDS)
		STAT_ENEMY_FIRE_RATE:
			return _upgrade_float(profile, &"enemy_fire_rate", profile.enemy_fire_interval_multiplier, GameConfig.ENEMY_FIRE_RATE_UPGRADE, GameConfig.MIN_ENEMY_FIRE_RATE, GameConfig.MAX_ENEMY_FIRE_RATE, GameConfig.ENEMY_FIRE_RATE_UPGRADE_GOLDS)
		STAT_INVISIBILITY_DURATION:
			if not profile.abilities.unlocked.get(&"invisibility", false):
				return false
			return _upgrade_float(profile, &"invisibility_duration", profile.invisibility_duration, GameConfig.INVISIBILITY_DURATION_UPGRADE, GameConfig.MIN_INVISIBILITY_DURATION, GameConfig.MAX_INVISIBILITY_DURATION, GameConfig.INVISIBILITY_DURATION_UPGRADE_GOLDS)
		STAT_SLOW_DOWN_DURATION:
			if not profile.abilities.unlocked.get(&"slow_down_time", false):
				return false
			return _upgrade_float(profile, &"slow_down_duration", profile.slow_down_duration, GameConfig.SLOW_DOWN_DURATION_UPGRADE, GameConfig.MIN_SLOW_DOWN_DURATION, GameConfig.MAX_SLOW_DOWN_DURATION, GameConfig.SLOW_DOWN_DURATION_UPGRADE_GOLDS)
	return false

static func _purchase_potion(profile: ProfileState, cost: int) -> bool:
	if profile == null or not profile.is_valid() or cost <= 0 or not profile.can_afford(cost):
		return false
	profile.gold -= cost
	profile.revival_potions += 1
	profile.changed.emit()
	return true

static func _upgrade_int(profile: ProfileState, field: StringName, current: int, step: int, minimum: int, maximum: int, cost: int) -> bool:
	var next := current + step
	if next < minimum or next > maximum or not profile.can_afford(cost):
		return false
	profile.gold -= cost
	match field:
		&"maximum_health": profile.maximum_health = next
		&"melee_power": profile.melee_power = next
		_: return false
	profile.changed.emit()
	return true

static func _upgrade_float(profile: ProfileState, field: StringName, current: float, step: float, minimum: float, maximum: float, cost: int) -> bool:
	var next := current + step
	if not is_finite(next) or next < minimum - 0.000001 or next > maximum + 0.000001 or not profile.can_afford(cost):
		return false
	profile.gold -= cost
	var clamped := clampf(next, minimum, maximum)
	match field:
		&"defense": profile.defense_multiplier = clamped
		&"enemy_fire_rate": profile.enemy_fire_interval_multiplier = clamped
		&"invisibility_duration": profile.invisibility_duration = clamped
		&"slow_down_duration": profile.slow_down_duration = clamped
		_: return false
	profile.changed.emit()
	return true
