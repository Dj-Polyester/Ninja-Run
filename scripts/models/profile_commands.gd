class_name ProfileCommands
extends RefCounted
## Mutation entry points for profile operations; UI should request these commands.

const AbilityCatalogRuntime = preload("res://scripts/abilities/ability_catalog.gd")
const CharacterCatalogRuntime = preload("res://scripts/characters/character_catalog.gd")
const WeaponCatalogRuntime = preload("res://scripts/weapons/weapon_catalog.gd")

static func spend_gold(profile: ProfileState, cost: int) -> bool:
	if profile == null or not profile.can_afford(cost):
		return false
	profile.add_gold(-cost)
	return true

static func buy_revival_potion(profile: ProfileState, cost: int = GameConfig.REVIVAL_POTION_GOLDS) -> bool:
	if profile == null or not profile.can_afford(cost):
		return false
	# This is one economic transaction, so observers receive one coherent update.
	profile.gold -= cost
	profile.revival_potions += 1
	profile.changed.emit()
	return true

static func unlock_ability(profile: ProfileState, ability_id: StringName) -> bool:
	if profile == null or not profile.is_valid() or AbilityCatalogRuntime.by_id(ability_id) == null:
		return false
	if profile.abilities.unlocked.get(ability_id, false):
		return false
	if not profile.initialize_ability_progress(ability_id):
		return false
	profile.changed.emit()
	return true

static func unlock_and_equip_ability(profile: ProfileState, ability_id: StringName) -> bool:
	if profile == null or not profile.is_valid() or AbilityCatalogRuntime.by_id(ability_id) == null:
		return false
	var prospective_unlocks: Dictionary = profile.abilities.unlocked.duplicate()
	prospective_unlocks[ability_id] = true
	if not AbilityEligibility.can_equip(ability_id, prospective_unlocks, profile.abilities.equipped, profile.abilities.capacity):
		return false
	if not profile.initialize_ability_progress(ability_id):
		return false
	if not profile.abilities.equip(ability_id):
		return false
	profile.changed.emit()
	return true

static func unlock_weapon(profile: ProfileState, weapon_id: StringName) -> bool:
	if profile == null or not profile.is_valid() or weapon_id.is_empty():
		return false
	if not profile.abilities.unlocked.get(AbilityEligibility.SHOOTING, false):
		return false
	if profile.weapons.unlocked.get(weapon_id, false):
		return false
	profile.weapons.unlock(weapon_id)
	profile.changed.emit()
	return true

static func equip_weapon(profile: ProfileState, weapon_id: StringName) -> bool:
	if profile == null or not profile.is_valid():
		return false
	if not profile.abilities.unlocked.get(AbilityEligibility.SHOOTING, false):
		return false
	if not profile.weapons.equip(weapon_id):
		return false
	profile.changed.emit()
	return true

static func unequip_weapon(profile: ProfileState, weapon_id: StringName) -> bool:
	if profile == null or not profile.weapons.unequip(weapon_id):
		return false
	profile.changed.emit()
	return true
