class_name BiomeSequence
extends RefCounted

var _rng := RandomNumberGenerator.new()
var _encounters: Array[int] = []
var _seed := 1

func _init(seed_value: int = 1) -> void:
	reset(seed_value)

func reset(seed_value: int) -> void:
	_seed = seed_value
	_rng.seed = _biome_seed(seed_value)
	_encounters.clear()
	for biome_id in range(BiomeCatalog.ORDERED.size()):
		_encounters.append(biome_id)

func get_biome_for_tile(tile_x: int) -> BiomeData:
	return BiomeCatalog.get_by_id(get_biome_id_for_tile(tile_x))

func get_biome_id_for_tile(tile_x: int) -> int:
	if tile_x < 0:
		return BiomeData.Id.GRASS
	var encounter := tile_x / GameConfig.BIOME_INTERVAL
	_ensure_encounter(encounter)
	return _encounters[encounter]

func get_encounter_index_for_tile(tile_x: int) -> int:
	if tile_x < 0:
		return 0
	return tile_x / GameConfig.BIOME_INTERVAL

func get_encounter_end_tile(tile_x: int) -> int:
	var encounter := get_encounter_index_for_tile(tile_x)
	return (encounter + 1) * GameConfig.BIOME_INTERVAL

func generated_encounters() -> Array[int]:
	return _encounters.duplicate()

func _ensure_encounter(encounter: int) -> void:
	while _encounters.size() <= encounter:
		var previous := _encounters[-1]
		var candidate := _rng.randi_range(0, BiomeCatalog.ORDERED.size() - 1)
		while candidate == previous:
			candidate = _rng.randi_range(0, BiomeCatalog.ORDERED.size() - 1)
		_encounters.append(candidate)

func _biome_seed(seed_value: int) -> int:
	# Keep biome selection independent from geometry RNG consumption.
	return seed_value ^ 0x5A17C3D1
