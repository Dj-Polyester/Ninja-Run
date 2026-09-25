class_name AbilityEligibility
extends RefCounted
## Pure unlock/equip rules; execution and cooldown behavior belongs to later milestones.

const JUMP: StringName = &"jump"
const REVERSE_GRAVITY: StringName = &"reverse_gravity"
const SHOOTING: StringName = &"shooting"

static func can_equip(ability_id: StringName, unlocked: Dictionary, equipped: Array[StringName], capacity: int) -> bool:
	if capacity <= 0 or not unlocked.get(ability_id, false) or ability_id in equipped:
		return false
	if equipped.size() >= capacity:
		return false
	if ability_id == JUMP and REVERSE_GRAVITY in equipped:
		return false
	if ability_id == REVERSE_GRAVITY and JUMP in equipped:
		return false
	return true

static func is_cooldown_exempt(ability_id: StringName) -> bool:
	return ability_id in [&"jump", &"climb", &"glide", &"fly"]

static func cooldown_stat_is_available(ability_id: StringName, unlocked: Dictionary) -> bool:
	return unlocked.get(ability_id, false) and not is_cooldown_exempt(ability_id)
