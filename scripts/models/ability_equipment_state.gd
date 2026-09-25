class_name AbilityEquipmentState
extends EquipmentState
## Ability-only invariant boundary. Generic equipment cannot bypass mutual exclusions.

const AbilityRules = preload("res://scripts/models/ability_eligibility.gd")

func can_equip(item_id: StringName) -> bool:
	return super.can_equip(item_id) and AbilityRules.can_equip(item_id, unlocked, equipped, capacity)

func equip(item_id: StringName) -> bool:
	if not can_equip(item_id):
		return false
	equipped.append(item_id)
	return true

func is_valid() -> bool:
	if not super.is_valid():
		return false
	return not (AbilityRules.JUMP in equipped and AbilityRules.REVERSE_GRAVITY in equipped)
