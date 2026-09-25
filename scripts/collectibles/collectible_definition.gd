class_name CollectibleDefinition
extends RefCounted

const KIND_GOLD: StringName = &"gold"
const KIND_HEALTH: StringName = &"health"
const KINDS: Array[StringName] = [KIND_GOLD, KIND_HEALTH]

var id: StringName
var kind: StringName
var asset_path: String
var gold_value: int
var heal_amount: float
var spawnable: bool
var droppable: bool

func _init(new_id: StringName = &"", new_kind: StringName = &"", new_asset_path: String = "", new_gold_value: int = 0, new_heal_amount: float = 0.0, new_spawnable: bool = false, new_droppable: bool = false) -> void:
	id = new_id
	kind = new_kind
	asset_path = new_asset_path
	gold_value = new_gold_value
	heal_amount = new_heal_amount
	spawnable = new_spawnable
	droppable = new_droppable

func is_valid() -> bool:
	if id.is_empty() or not kind in KINDS or asset_path.is_empty() or not asset_path.begins_with("res://"):
		return false
	if not spawnable and not droppable:
		return false
	if kind == KIND_GOLD:
		return gold_value > 0 and is_zero_approx(heal_amount)
	return gold_value == 0 and is_finite(heal_amount) and heal_amount > 0.0
