class_name ChunkDescription
extends RefCounted
## Immutable-by-convention output of a versioned, pure terrain generation call.

const Hazard = preload("res://scripts/terrain/hazard_descriptor.gd")

var version: int
var seed: int
var chunk_index: int
var x_begin: int
var x_end: int # Half-open absolute tile bounds.
var occupied: Dictionary = {} # Vector2i -> { material, kind, tile_id }
# Every absolute column in [x_begin, x_end) has one logical biome. This keeps
# selection independent from geometry and lets future systems query ownership
# without inferring it from a particular occupied row.
var biome_at_column: Dictionary = {} # int -> StringName
var surfaces: Array[TerrainSurface] = []
var anchors: Array[SpawnAnchor] = []
var hazards: Array = [] # HazardDescriptor instances; preload avoids editor-class-cache reliance.
var form: StringName = &"platform"
var config_identity: StringName = &""

func _init(new_version: int = 1, new_seed: int = 0, new_chunk_index: int = 0, begin: int = 0, end: int = 0) -> void:
	version = new_version
	seed = new_seed
	chunk_index = new_chunk_index
	x_begin = begin
	x_end = end

func stable_signature() -> String:
	return "%d|%s|%d|%d|%s|%s" % [version, config_identity, seed, chunk_index, geometry_signature(), hazard_signature()]

func geometry_signature() -> String:
	var cells: Array[String] = []
	var locations: Array = occupied.keys()
	locations.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	for location: Vector2i in locations:
		var cell: Dictionary = occupied[location]
		cells.append("%d,%d:%s:%s" % [location.x, location.y, cell.get(&"material", ""), cell.get(&"kind", "")])
	var anchors_text: Array[String] = []
	for anchor in anchors:
		anchors_text.append("%s:%s:%d:%d:%s:%d:%s:%s:%s" % [anchor.id, anchor.type, anchor.column, anchor.row, anchor.surface_id, anchor.clearance_tiles, anchor.intended_purpose, anchor.facing, anchor.biome])
	var surfaces_text: Array[String] = []
	for surface in surfaces:
		surfaces_text.append("%s:%d:%d:%d:%s:%s:%s" % [surface.id, surface.x_begin, surface.x_end, surface.y, surface.material, surface.kind, str(surface.entry_allowed) + ":" + str(surface.exit_allowed)])
	var biomes: Array[String] = []
	for column in range(x_begin, x_end):
		biomes.append("%d:%s" % [column, biome_at_column.get(column, "")])
	return "%d|%d|%s|%s" % [x_begin, x_end, form, ";".join(cells) + "/" + ";".join(surfaces_text) + "/" + ";".join(anchors_text) + "/" + ";".join(biomes)]

func hazard_signature() -> String:
	var hazards_text: Array[String] = []
	for hazard in hazards:
		hazards_text.append(hazard.stable_signature())
	return ";".join(hazards_text)

func is_valid() -> bool:
	if x_end <= x_begin or config_identity.is_empty():
		return false
	for column in range(x_begin, x_end):
		if StringName(biome_at_column.get(column, &"")) == &"":
			return false
	for surface in surfaces:
		if not surface.is_valid() or surface.x_begin < x_begin or surface.x_end > x_end:
			return false
	for anchor in anchors:
		if not anchor.is_valid() or anchor.column < x_begin or anchor.column >= x_end:
			return false
	for hazard in hazards:
		if not hazard.is_valid() or hazard.chunk_index != chunk_index or hazard.absolute_position.x < x_begin or hazard.absolute_position.x >= x_end:
			return false
	return true
