class_name EquipmentState
extends RefCounted
## Generic unlocked/equipped collection with capacity invariants.

var capacity: int
var unlocked: Dictionary = {}
var equipped: Array[StringName] = []

func _init(new_capacity: int) -> void:
	capacity = max(0, new_capacity)

func unlock(item_id: StringName) -> void:
	unlocked[item_id] = true

func can_equip(item_id: StringName) -> bool:
	return capacity > 0 and unlocked.get(item_id, false) and not item_id in equipped and equipped.size() < capacity

func equip(item_id: StringName) -> bool:
	if not can_equip(item_id):
		return false
	equipped.append(item_id)
	return true

func unequip(item_id: StringName) -> bool:
	var index := equipped.find(item_id)
	if index < 0:
		return false
	equipped.remove_at(index)
	return true

func is_valid() -> bool:
	if capacity <= 0 or equipped.size() > capacity:
		return false
	var seen := {}
	for item_id: StringName in equipped:
		if not unlocked.get(item_id, false) or seen.has(item_id):
			return false
		seen[item_id] = true
	return true
