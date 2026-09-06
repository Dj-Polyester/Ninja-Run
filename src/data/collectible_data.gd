class_name CollectibleData
extends Resource

enum Kind { COIN, GEM }

@export var id: StringName = &"collectible"
@export var display_name := "Collectible"
@export_enum("Coin", "Gem") var kind: int = Kind.COIN
@export_file("*.png") var texture_path := ""
@export_range(1, 10000, 1) var gold_value := 1
@export var spawnable := true
@export var droppable := true

func is_gem() -> bool:
	return kind == Kind.GEM

func is_valid() -> bool:
	return not String(id).is_empty() and gold_value > 0 and not texture_path.is_empty()
