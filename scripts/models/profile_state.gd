class_name ProfileState
extends RefCounted
## Persistent-only data. Health, distance, statuses, and countdowns remain in RunState.

signal changed

const AbilityEquipment = preload("res://scripts/models/ability_equipment_state.gd")
const AbilityCatalogRuntime = preload("res://scripts/abilities/ability_catalog.gd")
const CharacterCatalogRuntime = preload("res://scripts/characters/character_catalog.gd")
const WeaponCatalogRuntime = preload("res://scripts/weapons/weapon_catalog.gd")

var gold: int = 0
var revival_potions: int = 0
var selected_character: StringName = &"1"
var unlocked_characters: Dictionary = {&"1": true}
var abilities = AbilityEquipment.new(GameConfig.NUM_EQUIPABLE_ABILITIES)
var ability_levels: Dictionary = {}
var ability_cooldowns: Dictionary = {}
var weapons := EquipmentState.new(GameConfig.NUM_EQUIPPABLE_WEAPONS)
var mobile_auxiliary_button_corner: StringName = GameConfig.MOBILE_AUXILIARY_BUTTON_CORNER_DEFAULT
var maximum_health: int = GameConfig.DEFAULT_MAXIMUM_HEALTH
var defense_multiplier: float = GameConfig.DEFAULT_DEFENSE
var melee_power: int = GameConfig.DEFAULT_MELEE_POWER
var invisibility_duration: float = GameConfig.DEFAULT_INVISIBILITY_DURATION
var slow_down_duration: float = GameConfig.DEFAULT_SLOW_DOWN_DURATION
## Larger multipliers intentionally make enemy attacks less frequent.
var enemy_fire_interval_multiplier: float = GameConfig.DEFAULT_ENEMY_FIRE_RATE

func _init() -> void:
	unlocked_characters[CharacterCatalogRuntime.DEFAULT_ID] = true
	abilities.unlock(AbilityEligibility.JUMP)
	abilities.equip(AbilityEligibility.JUMP)
	ability_levels[AbilityEligibility.JUMP] = 1

func ability_level(ability_id: StringName) -> int:
	if not abilities.unlocked.get(ability_id, false):
		return 0
	return int(ability_levels.get(ability_id, 1))

func ability_cooldown(ability_id: StringName) -> float:
	if not abilities.unlocked.get(ability_id, false) or AbilityEligibility.is_cooldown_exempt(ability_id):
		return 0.0
	return float(ability_cooldowns.get(ability_id, GameConfig.COOLDOWN_PERIOD))

func initialize_ability_progress(ability_id: StringName) -> bool:
	var definition = AbilityCatalogRuntime.by_id(ability_id)
	if definition == null:
		return false
	abilities.unlock(ability_id)
	if not ability_levels.has(ability_id):
		ability_levels[ability_id] = 1
	if not definition.cooldown_exempt and not ability_cooldowns.has(ability_id):
		ability_cooldowns[ability_id] = GameConfig.COOLDOWN_PERIOD
	return true

func set_ability_level(ability_id: StringName, value: int) -> bool:
	var definition = AbilityCatalogRuntime.by_id(ability_id)
	if definition == null or not abilities.unlocked.get(ability_id, false) or value < 1 or value > definition.max_level:
		return false
	ability_levels[ability_id] = value
	changed.emit()
	return true

func set_ability_cooldown(ability_id: StringName, value: float) -> bool:
	var definition = AbilityCatalogRuntime.by_id(ability_id)
	if definition == null or definition.cooldown_exempt or not abilities.unlocked.get(ability_id, false):
		return false
	if not is_finite(value) or value < GameConfig.MIN_ABILITY_COOLDOWN or value > GameConfig.MAX_ABILITY_COOLDOWN:
		return false
	ability_cooldowns[ability_id] = value
	changed.emit()
	return true

func effective_enemy_fire_interval(base_interval: float) -> float:
	return maxf(0.0, base_interval) * clampf(enemy_fire_interval_multiplier, GameConfig.MIN_ENEMY_FIRE_RATE, GameConfig.MAX_ENEMY_FIRE_RATE)

func set_enemy_fire_interval_multiplier(value: float) -> void:
	enemy_fire_interval_multiplier = clampf(value, GameConfig.MIN_ENEMY_FIRE_RATE, GameConfig.MAX_ENEMY_FIRE_RATE)
	changed.emit()

func set_maximum_health(value: int) -> void:
	maximum_health = clampi(value, GameConfig.MIN_MAXIMUM_HEALTH, GameConfig.MAX_MAXIMUM_HEALTH)
	changed.emit()

func set_defense_multiplier(value: float) -> void:
	defense_multiplier = clampf(value, GameConfig.MIN_DEFENSE, GameConfig.MAX_DEFENSE)
	changed.emit()

func set_melee_power(value: int) -> void:
	melee_power = clampi(value, GameConfig.MIN_MELEE_POWER, GameConfig.MAX_MELEE_POWER)
	changed.emit()

func active_invisibility_duration() -> float:
	return invisibility_duration if abilities.unlocked.get(&"invisibility", false) else 0.0

func active_slow_down_duration() -> float:
	return slow_down_duration if abilities.unlocked.get(&"slow_down_time", false) else 0.0

func set_invisibility_duration(value: float) -> bool:
	if not abilities.unlocked.get(&"invisibility", false) or not is_finite(value) or value < GameConfig.MIN_INVISIBILITY_DURATION or value > GameConfig.MAX_INVISIBILITY_DURATION:
		return false
	invisibility_duration = value
	changed.emit()
	return true

func set_slow_down_duration(value: float) -> bool:
	if not abilities.unlocked.get(&"slow_down_time", false) or not is_finite(value) or value < GameConfig.MIN_SLOW_DOWN_DURATION or value > GameConfig.MAX_SLOW_DOWN_DURATION:
		return false
	slow_down_duration = value
	changed.emit()
	return true

func can_afford(cost: int) -> bool:
	return cost >= 0 and gold >= cost

func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	changed.emit()

func set_revival_potions(amount: int) -> void:
	revival_potions = max(0, amount)
	changed.emit()

func consume_revival_potion() -> bool:
	if revival_potions <= 0:
		return false
	revival_potions -= 1
	changed.emit()
	return true

func is_valid() -> bool:
	if gold < 0 or revival_potions < 0 or maximum_health < GameConfig.MIN_MAXIMUM_HEALTH or maximum_health > GameConfig.MAX_MAXIMUM_HEALTH:
		return false
	if not is_finite(defense_multiplier) or defense_multiplier < GameConfig.MIN_DEFENSE or defense_multiplier > GameConfig.MAX_DEFENSE or melee_power < GameConfig.MIN_MELEE_POWER or melee_power > GameConfig.MAX_MELEE_POWER:
		return false
	if CharacterCatalogRuntime.by_id(selected_character) == null or not unlocked_characters.get(selected_character, false):
		return false
	for character_variant in unlocked_characters.keys():
		if not bool(unlocked_characters[character_variant]) or CharacterCatalogRuntime.by_id(StringName(character_variant)) == null:
			return false
	if not is_finite(invisibility_duration) or invisibility_duration < GameConfig.MIN_INVISIBILITY_DURATION or invisibility_duration > GameConfig.MAX_INVISIBILITY_DURATION:
		return false
	if not is_finite(slow_down_duration) or slow_down_duration < GameConfig.MIN_SLOW_DOWN_DURATION or slow_down_duration > GameConfig.MAX_SLOW_DOWN_DURATION:
		return false
	if not is_finite(enemy_fire_interval_multiplier) or enemy_fire_interval_multiplier < GameConfig.MIN_ENEMY_FIRE_RATE or enemy_fire_interval_multiplier > GameConfig.MAX_ENEMY_FIRE_RATE:
		return false
	if not abilities.is_valid() or not weapons.is_valid() or not mobile_auxiliary_button_corner in [&"bottom_left", &"bottom_right"]:
		return false
	for weapon_variant in weapons.unlocked.keys():
		var weapon_id := StringName(weapon_variant)
		if not bool(weapons.unlocked[weapon_variant]) or WeaponCatalogRuntime.by_id(weapon_id) == null:
			return false
	if (not weapons.unlocked.is_empty() or not weapons.equipped.is_empty()) and not abilities.unlocked.get(AbilityEligibility.SHOOTING, false):
		return false
	for ability_variant in abilities.unlocked.keys():
		var ability_id := StringName(ability_variant)
		var definition = AbilityCatalogRuntime.by_id(ability_id)
		if definition == null:
			return false
		var level := ability_level(ability_id)
		if level < 1 or level > definition.max_level:
			return false
		if not definition.cooldown_exempt:
			var cooldown := ability_cooldown(ability_id)
			if not is_finite(cooldown) or cooldown < GameConfig.MIN_ABILITY_COOLDOWN or cooldown > GameConfig.MAX_ABILITY_COOLDOWN:
				return false
	for ability_variant in ability_levels.keys():
		if not abilities.unlocked.get(StringName(ability_variant), false):
			return false
	for ability_variant in ability_cooldowns.keys():
		if not abilities.unlocked.get(StringName(ability_variant), false):
			return false
	return true
