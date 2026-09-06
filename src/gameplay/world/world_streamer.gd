class_name WorldStreamer
extends Node2D

signal chunk_generated(spec: Dictionary)
signal chunk_removed(spec: Dictionary)

const DESERT_HAZARD_SCENE := preload("res://scenes/hazards/desert_hazard.tscn")
const FALLING_TILE_SCENE := preload("res://scenes/hazards/falling_tile.tscn")
const SPIKE_HAZARD_SCENE := preload("res://scenes/hazards/spike_hazard.tscn")

var biome_sequence := BiomeSequence.new()
var generator := ProceduralLayoutGenerator.new()
var active_chunks: Array[Dictionary] = []
var run_seed := 1
var terrain_layer: TileMapLayer
var runtime_nodes_by_chunk: Dictionary = {}
var falling_tiles_by_coord: Dictionary = {}

var generated_until_tile: int:
	get:
		return generator.generated_until_tile
	set(value):
		generator.generated_until_tile = value

var current_height_tile: int:
	get:
		return generator.current_height_tile
	set(value):
		generator.current_height_tile = value

var rng: RandomNumberGenerator:
	get:
		return generator.rng

func _ready() -> void:
	_ensure_terrain_layer()

func reset(seed_value: int) -> void:
	_ensure_terrain_layer()
	_clear_runtime_nodes()
	terrain_layer.clear()
	active_chunks.clear()
	run_seed = seed_value
	biome_sequence.reset(seed_value)
	generator.reset(seed_value)
	_paint_start_platform()
	generate_ahead(0)

func update_for_player(player_x: float) -> void:
	var player_tile := floori(GameConfig.pixels_to_tiles(player_x))
	generate_ahead(player_tile)
	cleanup_behind(player_tile)

func generate_ahead(player_tile: int) -> void:
	var target_tile := player_tile + GameConfig.GENERATION_DISTANCE_AHEAD
	while generated_until_tile < target_tile:
		var biome := biome_sequence.get_biome_for_tile(generated_until_tile)
		var biome_end := biome_sequence.get_encounter_end_tile(generated_until_tile)
		var spec := generator.next_chunk(biome, biome_end)
		if spec.is_empty():
			break
		_paint_chunk(spec)
		active_chunks.append(spec)
		chunk_generated.emit(spec)

func cleanup_behind(player_tile: int) -> void:
	var cutoff := player_tile - GameConfig.CLEANUP_DISTANCE_BEHIND
	var retained: Array[Dictionary] = []
	for spec in active_chunks:
		if int(spec.end_tile) < cutoff:
			_erase_chunk(spec)
			chunk_removed.emit(spec)
		else:
			retained.append(spec)
	active_chunks = retained

func biome_for_tile(tile_x: int) -> BiomeData:
	return biome_sequence.get_biome_for_tile(tile_x)

func effective_max_jump_for_tile(tile_x: int) -> float:
	var biome := biome_for_tile(tile_x)
	return BiomeMechanics.effective_max_jump(run_seed, tile_x, biome)

func snow_jump_modifier_for_tile(tile_x: int) -> float:
	var biome := biome_for_tile(tile_x)
	return BiomeMechanics.snow_jump_modifier(run_seed, tile_x, biome)

func next_platform_spec() -> Dictionary:
	# Compatibility helper for Phase 1 callers/tests. It now derives a single
	# conservative transition without mutating streamed terrain.
	var gap := rng.randi_range(GameConfig.PLATFORM_MIN_GAP, GameConfig.PLATFORM_MAX_GAP)
	var width := rng.randi_range(GameConfig.PLATFORM_MIN_WIDTH, GameConfig.PLATFORM_MAX_WIDTH)
	var height_step := rng.randi_range(-GameConfig.PLATFORM_MAX_HEIGHT_STEP, GameConfig.PLATFORM_MAX_HEIGHT_STEP)
	var next_height := clampi(current_height_tile + height_step, GameConfig.WORLD_MIN_HEIGHT_TILE, GameConfig.WORLD_MAX_HEIGHT_TILE)
	height_step = next_height - current_height_tile
	current_height_tile = next_height
	return {
		"start_tile": generated_until_tile + gap,
		"width_tiles": width,
		"height_tile": current_height_tile,
		"gap_tiles": gap,
		"height_step": height_step,
	}

func _ensure_terrain_layer() -> void:
	if is_instance_valid(terrain_layer):
		return
	terrain_layer = TileMapLayer.new()
	terrain_layer.name = "Terrain"
	terrain_layer.tile_set = TerrainTileSetFactory.build()
	terrain_layer.scale = Vector2.ONE * (GameConfig.TILE_SIZE / float(GameConfig.TERRAIN_SOURCE_TILE_SIZE))
	terrain_layer.collision_enabled = true
	add_child(terrain_layer)

func _paint_start_platform() -> void:
	var start_spec := {
		"biome_id": BiomeData.Id.GRASS,
		"biome_name": "Grass",
		"archetype": ProceduralLayoutGenerator.Archetype.FLAT,
		"archetype_name": "flat",
		"start_tile": GameConfig.START_PLATFORM_START_TILE,
		"end_tile": GameConfig.START_PLATFORM_START_TILE + GameConfig.START_PLATFORM_WIDTH,
		"platforms": [{
			"start_tile": GameConfig.START_PLATFORM_START_TILE,
			"width_tiles": GameConfig.START_PLATFORM_WIDTH,
			"height_tile": GameConfig.BASE_PLATFORM_HEIGHT,
			"optional_route": false,
			"ceiling": false,
		}],
		"bonus_spawn_tiles": [],
		"persistent_start": true,
	}
	_paint_chunk(start_spec)
	active_chunks.append(start_spec)

func _paint_chunk(spec: Dictionary) -> void:
	var biome := BiomeCatalog.get_by_id(int(spec.biome_id))
	var hazard_coords := _select_hazard_coords(spec, biome)
	var skipped_cells: Dictionary = {}
	if biome.hazard_type == BiomeData.HazardType.ASTRO_FALLING_TILE:
		for coords in hazard_coords:
			skipped_cells[coords] = true
	for platform in spec.platforms:
		_paint_segment(platform, biome, skipped_cells)
	_spawn_runtime_hazards(spec, biome, hazard_coords)

func _paint_segment(segment: Dictionary, biome: BiomeData, skipped_cells: Dictionary) -> void:
	var start_tile := int(segment.start_tile)
	var width := int(segment.width_tiles)
	var height := int(segment.height_tile)
	for index in width:
		var map_coords := Vector2i(start_tile + index, height)
		if skipped_cells.has(map_coords):
			continue
		var atlas_coords := biome.atlas_coords_for_segment(index, width)
		terrain_layer.set_cell(map_coords, TerrainTileSetFactory.SOURCE_ID, atlas_coords, 0)

func _erase_chunk(spec: Dictionary) -> void:
	for platform in spec.platforms:
		var start_tile := int(platform.start_tile)
		var width := int(platform.width_tiles)
		var height := int(platform.height_tile)
		for index in width:
			terrain_layer.erase_cell(Vector2i(start_tile + index, height))
	_remove_runtime_nodes(spec)

func _select_hazard_coords(spec: Dictionary, biome: BiomeData) -> Array[Vector2i]:
	var selected: Array[Vector2i] = []
	if biome == null or biome.hazard_type in [BiomeData.HazardType.NONE, BiomeData.HazardType.SNOW_VARIANCE]:
		return selected
	if biome.hazard_type == BiomeData.HazardType.ASTRO_FALLING_TILE:
		# Astro terrain is itself the mechanic: every generated Astro block is an
		# independently simulated FallingTile rather than a random hazard overlay.
		for platform in spec.platforms:
			var astro_start := int(platform.start_tile)
			var astro_width := int(platform.width_tiles)
			var astro_height := int(platform.height_tile)
			for index in astro_width:
				selected.append(Vector2i(astro_start + index, astro_height))
		return selected
	if biome.hazard_spawn_chance <= 0.0:
		return selected
	var candidates: Array[Vector2i] = []
	for platform in spec.platforms:
		if bool(platform.get("ceiling", false)):
			continue
		var start_tile := int(platform.start_tile)
		var width := int(platform.width_tiles)
		var height := int(platform.height_tile)
		if width <= 0:
			continue
		var first_index := 1 if width >= 3 else 0
		var last_index := width - 2 if width >= 3 else width - 1
		for index in range(first_index, last_index + 1):
			candidates.append(Vector2i(start_tile + index, height))
	if candidates.is_empty():
		return selected

	var hazard_rng := RandomNumberGenerator.new()
	hazard_rng.seed = run_seed ^ (int(spec.start_tile) * 2654435761) ^ (biome.id * 97531) ^ 0xB10BE
	for coords in candidates:
		if selected.size() >= 2:
			break
		if hazard_rng.randf() <= biome.hazard_spawn_chance:
			selected.append(coords)
	# Every hazard biome chunk has at least one mechanic instance. The chance
	# controls whether a second cell is selected while avoiding empty encounters.
	if selected.is_empty():
		selected.append(candidates[hazard_rng.randi_range(0, candidates.size() - 1)])
	return selected

func _spawn_runtime_hazards(spec: Dictionary, biome: BiomeData, coords_list: Array[Vector2i]) -> void:
	if coords_list.is_empty():
		return
	var runtime_nodes: Array[Node] = []
	for coords in coords_list:
		match biome.hazard_type:
			BiomeData.HazardType.DESERT_HEAT:
				var hazard := DESERT_HAZARD_SCENE.instantiate() as DesertHazard
				add_child(hazard)
				hazard.position = _surface_position_for_tile(coords)
				runtime_nodes.append(hazard)
			BiomeData.HazardType.ASTRO_FALLING_TILE:
				var falling_tile := FALLING_TILE_SCENE.instantiate() as FallingTile
				add_child(falling_tile)
				falling_tile.position = _center_position_for_tile(coords)
				var segment := _find_segment_for_coord(spec, coords)
				var atlas_index := coords.x - int(segment.get("start_tile", coords.x))
				var atlas_width := int(segment.get("width_tiles", 1))
				falling_tile.configure(coords, biome.atlas_coords_for_segment(atlas_index, atlas_width))
				_register_falling_tile(falling_tile)
				runtime_nodes.append(falling_tile)
			BiomeData.HazardType.FORT_SPIKES:
				var spike := SPIKE_HAZARD_SCENE.instantiate() as SpikeHazard
				add_child(spike)
				spike.position = _surface_position_for_tile(coords)
				runtime_nodes.append(spike)
	if not runtime_nodes.is_empty():
		runtime_nodes_by_chunk[int(spec.start_tile)] = runtime_nodes

func _find_segment_for_coord(spec: Dictionary, coords: Vector2i) -> Dictionary:
	for platform in spec.platforms:
		if int(platform.height_tile) != coords.y:
			continue
		var start_tile := int(platform.start_tile)
		var width := int(platform.width_tiles)
		if coords.x >= start_tile and coords.x < start_tile + width:
			return platform
	return {}

func _center_position_for_tile(coords: Vector2i) -> Vector2:
	return to_local(terrain_layer.to_global(terrain_layer.map_to_local(coords)))

func _surface_position_for_tile(coords: Vector2i) -> Vector2:
	return _center_position_for_tile(coords) + Vector2(0.0, -GameConfig.TILE_SIZE * 0.5)

func _register_falling_tile(tile: FallingTile) -> void:
	falling_tiles_by_coord[tile.grid_coordinate] = tile
	var below_coord := tile.grid_coordinate + Vector2i.DOWN
	var above_coord := tile.grid_coordinate + Vector2i.UP
	var below := falling_tiles_by_coord.get(below_coord) as FallingTile
	if is_instance_valid(below):
		tile.set_support_below(below)
	var above := falling_tiles_by_coord.get(above_coord) as FallingTile
	if is_instance_valid(above):
		above.set_support_below(tile)
	tile.tree_exiting.connect(_on_falling_tile_exiting.bind(tile))

func _on_falling_tile_exiting(tile: FallingTile) -> void:
	if falling_tiles_by_coord.get(tile.grid_coordinate) == tile:
		falling_tiles_by_coord.erase(tile.grid_coordinate)

func _remove_runtime_nodes(spec: Dictionary) -> void:
	var key := int(spec.start_tile)
	var nodes: Array = runtime_nodes_by_chunk.get(key, [])
	for node in nodes:
		if not is_instance_valid(node):
			continue
		if node is FallingTile:
			_on_falling_tile_exiting(node)
		node.queue_free()
	runtime_nodes_by_chunk.erase(key)

func _clear_runtime_nodes() -> void:
	for nodes in runtime_nodes_by_chunk.values():
		for node in nodes:
			if is_instance_valid(node):
				node.queue_free()
	runtime_nodes_by_chunk.clear()
	falling_tiles_by_coord.clear()
