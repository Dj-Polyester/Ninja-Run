class_name BiomeMechanics
extends RefCounted

const SNOW_SEED_SALT := 0x5A0B1E

static func encounter_index_for_tile(tile_x: int) -> int:
	return maxi(0, floori(float(tile_x) / float(GameConfig.BIOME_INTERVAL)))

static func snow_jump_modifier(run_seed: int, tile_x: int, biome: BiomeData = BiomeCatalog.SNOW) -> float:
	if biome == null or biome.id != BiomeData.Id.SNOW:
		return 0.0
	var minimum := biome.snow_jump_modifier_min
	var maximum := biome.snow_jump_modifier_max
	if maximum < minimum:
		var swap := minimum
		minimum = maximum
		maximum = swap
	if is_equal_approx(minimum, maximum):
		return minimum
	var encounter_index := encounter_index_for_tile(tile_x)
	var rng := RandomNumberGenerator.new()
	# Derive this stream only from run seed + encounter so terrain generation,
	# hazard placement, and player movement all observe the same Snow modifier.
	rng.seed = run_seed ^ (encounter_index * 1103515245) ^ SNOW_SEED_SALT
	return rng.randf_range(minimum, maximum)

static func effective_max_jump(run_seed: int, tile_x: int, biome: BiomeData) -> float:
	if biome != null and biome.id == BiomeData.Id.SNOW:
		return maxf(0.1, GameConfig.MAX_JUMP + snow_jump_modifier(run_seed, tile_x, biome))
	return GameConfig.MAX_JUMP
