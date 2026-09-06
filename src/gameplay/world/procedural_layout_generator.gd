class_name ProceduralLayoutGenerator
extends RefCounted

enum Archetype {
	FLAT,
	FLYING_PLATFORMS,
	MOUNTAIN,
	CAVE,
	STAIRS,
	STACKED_PLATFORMS,
	GAPS,
}

const ARCHETYPE_NAMES := {
	Archetype.FLAT: "flat",
	Archetype.FLYING_PLATFORMS: "flying_platforms",
	Archetype.MOUNTAIN: "mountain",
	Archetype.CAVE: "cave",
	Archetype.STAIRS: "stairs",
	Archetype.STACKED_PLATFORMS: "stacked_platforms",
	Archetype.GAPS: "gaps",
}

var rng := RandomNumberGenerator.new()
var current_height_tile := GameConfig.BASE_PLATFORM_HEIGHT
var generated_until_tile := GameConfig.START_PLATFORM_START_TILE + GameConfig.START_PLATFORM_WIDTH
var run_seed := 1
var effective_max_jump_tiles := GameConfig.MAX_JUMP

func reset(seed_value: int) -> void:
	run_seed = seed_value
	rng.seed = seed_value ^ 0x31E7B45D
	current_height_tile = GameConfig.BASE_PLATFORM_HEIGHT
	generated_until_tile = GameConfig.START_PLATFORM_START_TILE + GameConfig.START_PLATFORM_WIDTH
	effective_max_jump_tiles = GameConfig.MAX_JUMP

func next_chunk(biome: BiomeData, max_end_tile: int, forced_archetype: int = -1) -> Dictionary:
	var remaining := max_end_tile - generated_until_tile
	if remaining <= 0:
		return {}
	effective_max_jump_tiles = BiomeMechanics.effective_max_jump(run_seed, generated_until_tile, biome)
	var span := mini(rng.randi_range(GameConfig.CHUNK_MIN_SPAN, GameConfig.CHUNK_MAX_SPAN), remaining)
	if span < 3:
		span = remaining
	var archetype := forced_archetype if forced_archetype >= 0 else choose_archetype(biome)
	if span < _minimum_span_for(archetype):
		archetype = Archetype.FLAT

	var start_tile := generated_until_tile
	var spec := _build_chunk(archetype, start_tile, span)
	spec["biome_id"] = biome.id
	spec["biome_name"] = biome.display_name
	spec["archetype"] = archetype
	spec["archetype_name"] = ARCHETYPE_NAMES[archetype]
	spec["start_tile"] = start_tile
	spec["end_tile"] = start_tile + span
	generated_until_tile = start_tile + span
	return spec

func choose_archetype(biome: BiomeData) -> int:
	var total := biome.total_layout_weight()
	if total <= 0.0:
		return Archetype.FLAT
	var roll := rng.randf() * total
	for archetype in ARCHETYPE_NAMES:
		var key: String = ARCHETYPE_NAMES[archetype]
		roll -= maxf(0.0, float(biome.layout_weights.get(key, 0.0)))
		if roll <= 0.0:
			return archetype
	return Archetype.FLAT

func max_reachable_gap_tiles(height_step: int, max_jump_tiles: float = -1.0) -> float:
	var jump_tiles := effective_max_jump_tiles if max_jump_tiles <= 0.0 else max_jump_tiles
	var jump_speed := sqrt(2.0 * GameConfig.GRAVITY * GameConfig.tiles_to_pixels(jump_tiles))
	var vertical_delta := float(height_step) * GameConfig.TILE_SIZE
	var discriminant := jump_speed * jump_speed + 2.0 * GameConfig.GRAVITY * vertical_delta
	if discriminant < 0.0:
		return 0.0
	var landing_time := (jump_speed + sqrt(discriminant)) / GameConfig.GRAVITY
	return GameConfig.SPEED * landing_time

func is_transition_reachable(from_segment: Dictionary, to_segment: Dictionary) -> bool:
	var from_end := int(from_segment.start_tile) + int(from_segment.width_tiles)
	var gap := maxi(0, int(to_segment.start_tile) - from_end)
	var height_step := int(to_segment.height_tile) - int(from_segment.height_tile)
	if -height_step > ceili(effective_max_jump_tiles):
		return false
	return float(gap) <= max_reachable_gap_tiles(height_step) + 0.001

func _build_chunk(archetype: int, start_tile: int, span: int) -> Dictionary:
	var platforms: Array[Dictionary] = []
	var bonus_spawn_tiles: Array[Vector2i] = []
	match archetype:
		Archetype.FLYING_PLATFORMS:
			platforms = _build_islands(start_tile, span, true)
		Archetype.MOUNTAIN:
			platforms = _build_mountain(start_tile, span)
		Archetype.CAVE:
			platforms = _build_cave(start_tile, span)
		Archetype.STAIRS:
			platforms = _build_stairs(start_tile, span)
		Archetype.STACKED_PLATFORMS:
			platforms = _build_stacked(start_tile, span)
		Archetype.GAPS:
			platforms = _build_islands(start_tile, span, false)
		_:
			platforms = [_segment(start_tile, span, current_height_tile)]

	var mandatory := _mandatory_segments(platforms)
	if not mandatory.is_empty():
		current_height_tile = int(mandatory[-1].height_tile)
	for platform in platforms:
		if bool(platform.get("optional_route", false)):
			var width := int(platform.width_tiles)
			if width >= 2:
				bonus_spawn_tiles.append(Vector2i(int(platform.start_tile) + width / 2, int(platform.height_tile) - 1))
	return {"platforms": platforms, "bonus_spawn_tiles": bonus_spawn_tiles}

func _build_islands(start_tile: int, span: int, elevated: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var cursor := start_tile
	var end_tile := start_tile + span
	var height := current_height_tile
	while cursor < end_tile:
		var remaining := end_tile - cursor
		if remaining <= 4:
			result.append(_segment(cursor, remaining, height))
			break
		var width := mini(rng.randi_range(3, 5), remaining)
		result.append(_segment(cursor, width, height))
		cursor += width
		if cursor >= end_tile:
			break
		var height_step := _random_height_step()
		var next_height := clampi(height + height_step, GameConfig.WORLD_MIN_HEIGHT_TILE, GameConfig.WORLD_MAX_HEIGHT_TILE)
		height_step = next_height - height
		var max_gap := floori(max_reachable_gap_tiles(height_step))
		var desired_gap := rng.randi_range(GameConfig.PLATFORM_MIN_GAP, GameConfig.PLATFORM_MAX_GAP)
		var gap := mini(mini(desired_gap, maxi(1, max_gap)), end_tile - cursor - 2)
		if gap <= 0:
			continue
		cursor += gap
		height = next_height
	if elevated and result.size() >= 2 and rng.randf() < GameConfig.OPTIONAL_ROUTE_CHANCE:
		var first: Dictionary = result[0]
		var optional_width := mini(4, span / 3)
		if optional_width >= 2:
			result.append(_segment(int(first.start_tile) + int(first.width_tiles) + 1, optional_width, clampi(current_height_tile - 2, GameConfig.WORLD_MIN_HEIGHT_TILE, GameConfig.WORLD_MAX_HEIGHT_TILE), true))
	return result

func _build_mountain(start_tile: int, span: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var pieces := mini(5, maxi(3, span / 2))
	var widths := _partition_span(span, pieces)
	var cursor := start_tile
	var height := current_height_tile
	for index in widths.size():
		if index > 0:
			var direction := -1 if index <= widths.size() / 2 else 1
			height = clampi(height + direction, GameConfig.WORLD_MIN_HEIGHT_TILE, GameConfig.WORLD_MAX_HEIGHT_TILE)
		result.append(_segment(cursor, widths[index], height))
		cursor += widths[index]
	return result

func _build_cave(start_tile: int, span: int) -> Array[Dictionary]:
	var floor_segment := _segment(start_tile, span, current_height_tile)
	var ceiling_height := maxi(1, current_height_tile - GameConfig.CAVE_CLEARANCE_TILES)
	var ceiling := _segment(start_tile + 1, maxi(1, span - 2), ceiling_height, false, true)
	return [floor_segment, ceiling]

func _build_stairs(start_tile: int, span: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var pieces := mini(4, maxi(2, span / 2))
	var widths := _partition_span(span, pieces)
	var cursor := start_tile
	var height := current_height_tile
	var direction := -1 if rng.randf() < 0.5 else 1
	for index in widths.size():
		if index > 0:
			height = clampi(height + direction, GameConfig.WORLD_MIN_HEIGHT_TILE, GameConfig.WORLD_MAX_HEIGHT_TILE)
		result.append(_segment(cursor, widths[index], height))
		cursor += widths[index]
	return result

func _build_stacked(start_tile: int, span: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = [_segment(start_tile, span, current_height_tile)]
	if span >= 6:
		var optional_width := maxi(3, span / 2)
		var optional_start := start_tile + (span - optional_width) / 2
		var optional_height := clampi(current_height_tile - 2, GameConfig.WORLD_MIN_HEIGHT_TILE, GameConfig.WORLD_MAX_HEIGHT_TILE)
		result.append(_segment(optional_start, optional_width, optional_height, true))
	return result

func _segment(start_tile: int, width_tiles: int, height_tile: int, optional_route: bool = false, ceiling: bool = false) -> Dictionary:
	return {
		"start_tile": start_tile,
		"width_tiles": maxi(1, width_tiles),
		"height_tile": height_tile,
		"optional_route": optional_route,
		"ceiling": ceiling,
		"breakable": true,
	}

func _mandatory_segments(platforms: Array[Dictionary]) -> Array[Dictionary]:
	var mandatory: Array[Dictionary] = []
	for platform in platforms:
		if not bool(platform.get("optional_route", false)) and not bool(platform.get("ceiling", false)):
			mandatory.append(platform)
	mandatory.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.start_tile) < int(b.start_tile))
	return mandatory

func _random_height_step() -> int:
	return rng.randi_range(-GameConfig.PLATFORM_MAX_HEIGHT_STEP, GameConfig.PLATFORM_MAX_HEIGHT_STEP)

func _partition_span(span: int, pieces: int) -> Array[int]:
	var widths: Array[int] = []
	var base := span / pieces
	var remainder := span % pieces
	for index in pieces:
		widths.append(base + (1 if index < remainder else 0))
	return widths

func _minimum_span_for(archetype: int) -> int:
	match archetype:
		Archetype.FLYING_PLATFORMS, Archetype.GAPS:
			return 8
		Archetype.MOUNTAIN, Archetype.STAIRS:
			return 6
		Archetype.STACKED_PLATFORMS:
			return 6
		Archetype.CAVE:
			return 4
		_:
			return 1
