class_name HazardDescriptor
extends RefCounted
## Immutable-by-convention metadata for later active biome hazards.
## A descriptor does not create a collider, particle, or damage source in M3c.1.

var id: StringName
var version: int
var config_identity: StringName
var chunk_index: int
var absolute_position: Vector2i
var supporting_surface_id: StringName
var supporting_tile_id: StringName
var biome: StringName
var type: StringName
var phase: float
var parameters: Dictionary

func _init(new_id: StringName = &"", new_version: int = 0, new_config_identity: StringName = &"", new_chunk_index: int = 0, new_position: Vector2i = Vector2i.ZERO, new_surface_id: StringName = &"", new_tile_id: StringName = &"", new_biome: StringName = &"", new_type: StringName = &"", new_phase: float = 0.0, new_parameters: Dictionary = {}) -> void:
	id = new_id
	version = new_version
	config_identity = new_config_identity
	chunk_index = new_chunk_index
	absolute_position = new_position
	supporting_surface_id = new_surface_id
	supporting_tile_id = new_tile_id
	biome = new_biome
	type = new_type
	phase = new_phase
	parameters = new_parameters.duplicate(true)

func stable_signature() -> String:
	var values: Array[String] = []
	var keys: Array = parameters.keys()
	keys.sort()
	for key in keys:
		values.append("%s=%s" % [key, parameters[key]])
	return "%s|%d|%s|%d|%d,%d|%s|%s|%s|%s|%.6f|%s" % [id, version, config_identity, chunk_index, absolute_position.x, absolute_position.y, supporting_surface_id, supporting_tile_id, biome, type, phase, ";".join(values)]

func is_valid() -> bool:
	if id.is_empty() or version <= 0 or config_identity.is_empty() or supporting_surface_id.is_empty() or supporting_tile_id.is_empty() or biome.is_empty() or type.is_empty():
		return false
	if not is_finite(phase) or phase < 0.0 or phase >= 1.0:
		return false
	return (biome == &"desert" and type == &"desert_flame_candidate") or (biome == &"astro" and type == &"astro_fall_candidate") or (biome == &"fort" and type == &"fort_spike_candidate")
