class_name EnemySpawnDescriptor
extends RefCounted
## Deterministic, stream-safe spawn intent. Runtime nodes must validate this
## against the streamer before materializing it.

var id: StringName
var catalog_version: int
var run_seed: int
var definition_id: StringName
var variant_id: StringName
var chunk_index: int
var chunk_epoch: int
var anchor_id: StringName
var support_surface_id: StringName
var support_tile_id: StringName
var column: int
var row: int
var biome: StringName
var biome_visit: int
var tier: int
var anchor_facing: StringName
var support_x_begin: int
var support_x_end: int

func _init(new_id: StringName = &"", new_catalog_version: int = 1, new_run_seed: int = 0, new_definition_id: StringName = &"", new_chunk_index: int = 0, new_chunk_epoch: int = 0, new_anchor_id: StringName = &"", new_support_surface_id: StringName = &"", new_support_tile_id: StringName = &"", new_column: int = 0, new_row: int = 0, new_biome: StringName = &"", new_biome_visit: int = 0, new_tier: int = 1, new_anchor_facing: StringName = &"right", new_support_x_begin: int = 0, new_support_x_end: int = 1, new_variant_id: StringName = &"default") -> void:
	id = new_id; catalog_version = new_catalog_version; run_seed = new_run_seed; definition_id = new_definition_id; variant_id = new_variant_id
	chunk_index = new_chunk_index; chunk_epoch = new_chunk_epoch; anchor_id = new_anchor_id
	support_surface_id = new_support_surface_id; support_tile_id = new_support_tile_id
	column = new_column; row = new_row; biome = new_biome; biome_visit = new_biome_visit; tier = new_tier
	anchor_facing = new_anchor_facing; support_x_begin = new_support_x_begin; support_x_end = new_support_x_end

func is_valid() -> bool:
	return not id.is_empty() and catalog_version > 0 and not definition_id.is_empty() and not variant_id.is_empty() and chunk_epoch > 0 and not anchor_id.is_empty() and not support_surface_id.is_empty() and not support_tile_id.is_empty() and biome in [&"grass", &"tundra", &"snow", &"desert", &"astro", &"fort"] and biome_visit >= 0 and tier >= GameConfig.MIN_ENEMY_TIER and tier <= GameConfig.MAX_ENEMY_TIER and anchor_facing in [&"left", &"right"] and support_x_begin <= column and column < support_x_end
