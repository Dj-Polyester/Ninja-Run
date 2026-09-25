class_name AbilityActionRouter
extends RefCounted

const Catalog = preload("res://scripts/abilities/ability_catalog.gd")
const Definition = preload("res://scripts/abilities/ability_definition.gd")

static func auxiliary_equipped(profile: ProfileState) -> Array[StringName]:
	var result: Array[StringName] = []
	if profile == null:
		return result
	for ability_id: StringName in profile.abilities.equipped:
		var definition: Definition = Catalog.by_id(ability_id)
		if definition != null and definition.trigger == Definition.TRIGGER_SLOT:
			result.append(ability_id)
	return result

static func ability_for_slot(profile: ProfileState, slot: int) -> StringName:
	if slot < 0:
		return &""
	var auxiliary := auxiliary_equipped(profile)
	if slot >= auxiliary.size():
		return &""
	return auxiliary[slot]

static func jump_family_equipped(profile: ProfileState) -> Array[StringName]:
	var result: Array[StringName] = []
	if profile == null:
		return result
	for ability_id: StringName in profile.abilities.equipped:
		var definition: Definition = Catalog.by_id(ability_id)
		if definition != null and definition.trigger == Definition.TRIGGER_JUMP:
			result.append(ability_id)
	return result
