class_name TerrainSurface
extends RefCounted
## A traversable horizontal surface in absolute logical tile coordinates.

var id: StringName
var chunk_index: int
var x_begin: int
var x_end: int # Half-open.
var y: int
var material: StringName = &"grass"
var kind: StringName = &"main_route"
var entry_allowed := true
var exit_allowed := true

func _init(new_id: StringName = &"", new_chunk_index: int = 0, begin: int = 0, end: int = 0, surface_y: int = 0, surface_kind: StringName = &"main_route", new_material: StringName = &"grass") -> void:
	id = new_id
	chunk_index = new_chunk_index
	x_begin = begin
	x_end = end
	y = surface_y
	kind = surface_kind
	material = new_material

func contains_column(column: int) -> bool:
	return column >= x_begin and column < x_end

func is_valid() -> bool:
	return not id.is_empty() and x_end > x_begin
