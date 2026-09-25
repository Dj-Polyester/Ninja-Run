class_name SpawnAnchor
extends RefCounted
## Generic future spawn contract; no M3a system assumes an enemy/collectible type.

var id: StringName
var type: StringName
var chunk_index: int
var column: int
var row: int
var tags: PackedStringArray = []
var surface_id: StringName
var clearance_tiles: int = 0
var intended_purpose: StringName = &"generic"
var facing: StringName = &"right"
var biome: StringName = &"grass"

func _init(new_id: StringName = &"", new_type: StringName = &"generic", new_chunk_index: int = 0, new_column: int = 0, new_row: int = 0, new_surface_id: StringName = &"", new_clearance_tiles: int = 0, new_purpose: StringName = &"generic", new_facing: StringName = &"right", new_biome: StringName = &"grass") -> void:
	id = new_id
	type = new_type
	chunk_index = new_chunk_index
	column = new_column
	row = new_row
	surface_id = new_surface_id
	clearance_tiles = new_clearance_tiles
	intended_purpose = new_purpose
	facing = new_facing
	biome = new_biome

func is_valid() -> bool:
	return not id.is_empty() and not surface_id.is_empty() and clearance_tiles > 0 and facing == &"right" and not biome.is_empty()
