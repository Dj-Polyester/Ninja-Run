class_name SafeCheckpoint
extends RefCounted

var position := Vector2.ZERO
var biome_id := 0
var tile_index := 0
var valid := false

func capture(next_position: Vector2, next_biome_id: int, next_tile_index: int) -> void:
	position = next_position
	biome_id = next_biome_id
	tile_index = next_tile_index
	valid = true

func to_dictionary() -> Dictionary:
	return {
		"position": position,
		"biome_id": biome_id,
		"tile_index": tile_index,
		"valid": valid,
	}

