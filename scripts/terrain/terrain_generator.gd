class_name TerrainGenerator
extends RefCounted
## Stateless, order-independent production terrain generation.

const Hazard = preload("res://scripts/terrain/hazard_descriptor.gd")

const BIOMES: Array[StringName] = [&"grass", &"tundra", &"snow", &"desert", &"astro", &"fort"]
const BIOME_RANDOM_CHANNEL := 31
const HAZARD_CANDIDATE_CHANNEL := 47

static func validate_snapshot(snapshot: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for name: StringName in [&"tile_size", &"gravity", &"speed", &"max_jump_tiles", &"snow_min_jump_multiplier", &"snow_max_jump_multiplier", &"slowdown_speed_multiplier", &"base_surface_y", &"run_origin_x"]:
		var value := float(snapshot.get(name, NAN))
		if not is_finite(value) or value <= 0.0:
			errors.append("Terrain config %s must be positive finite." % name)
	var chunk_width := int(snapshot.get(&"chunk_width", 0))
	var seam_columns := int(snapshot.get(&"safe_seam_columns", -1))
	var biome_interval := int(snapshot.get(&"biome_interval", 0))
	var selector_version := int(snapshot.get(&"biome_selector_version", 0))
	var hazard_version := int(snapshot.get(&"hazard_descriptor_version", 0))
	if chunk_width <= 0:
		errors.append("Terrain chunk width must be positive.")
	if seam_columns < 2:
		errors.append("Terrain safe seam columns must preserve a two-column landing.")
	if chunk_width < seam_columns * 2 + 4:
		errors.append("Terrain chunk width cannot fit seam landings and form geometry.")
	if biome_interval <= 0:
		errors.append("Terrain biome interval must be positive.")
	if selector_version <= 0:
		errors.append("Terrain biome selector version must be positive.")
	if hazard_version <= 0:
		errors.append("Terrain hazard descriptor version must be positive.")
	if float(snapshot.get(&"slowdown_speed_multiplier", 0.0)) > 1.0:
		errors.append("Terrain slowdown multiplier must not exceed one.")
	if float(snapshot.get(&"snow_min_jump_multiplier", 0.0)) > float(snapshot.get(&"snow_max_jump_multiplier", 0.0)):
		errors.append("Terrain snow multipliers are inverted.")
	var envelope := MovementEnvelope.from_snapshot(snapshot)
	errors.append_array(envelope.validate())
	if envelope.validate().is_empty() and envelope.maximum_rise_pixels() < float(snapshot.get(&"tile_size", INF)):
		errors.append("Terrain movement envelope cannot clear a one-tile rise at worst-case Snow jump.")
	return errors

static func generate(snapshot: Dictionary, version: int, run_seed: int, chunk_index: int) -> ChunkDescription:
	var width := int(snapshot.get(&"chunk_width", 0))
	if version <= 0 or width <= 0 or not validate_snapshot(snapshot).is_empty():
		return ChunkDescription.new(version, run_seed, chunk_index, 0, 0)
	var x_begin := chunk_index * width
	var description := ChunkDescription.new(version, run_seed, chunk_index, x_begin, x_begin + width)
	description.config_identity = GameConfig.terrain_config_identity(snapshot)
	var form_index := _stream(run_seed, chunk_index, 1) % 3
	description.form = [&"platform", &"mountain", &"cave"][form_index]
	var seam_buffer: int = mini(int(snapshot.get(&"safe_seam_columns", 0)), width / 2)
	var form_begin: int = maxi(seam_buffer, width / 3)
	var form_end: int = mini(width - seam_buffer, width * 2 / 3)
	var heights: Array[int] = []
	var materials: Array[StringName] = []
	for local_x in width:
		var column := x_begin + local_x
		var height := 0
		if description.form == &"mountain":
			height = -1 if local_x >= form_begin and local_x < form_end else 0
		elif description.form == &"cave":
			height = 1 if local_x >= form_begin and local_x < form_end else 0
		heights.append(height)
		var biome := biome_for_column(snapshot, run_seed, column)
		materials.append(biome)
		description.biome_at_column[column] = biome
		_add_column(description, column, height, biome, &"main_route")
	_add_main_surfaces(description, heights, materials)
	# Add an optional landing-wide elevated platform. It never replaces the main route.
	if description.form == &"platform" or (description.form == &"mountain" and _stream(run_seed, chunk_index, 2) % 2 == 0):
		var platform_begin := x_begin + 3
		var platform_end: int = mini(description.x_end - 1, platform_begin + 4)
		if platform_end > platform_begin:
			for column in range(platform_begin, platform_end):
				_add_cell(description, Vector2i(column, -2), biome_for_column(snapshot, run_seed, column), &"floating_platform")
			_add_surfaces_for_span(description, chunk_index, &"platform", platform_begin, platform_end, -2, &"floating_platform")
	# A cave has a genuine roof, held high enough to preserve standing clearance.
	if description.form == &"cave":
		for column in range(x_begin + 3, x_begin + width - 3):
			_add_cell(description, Vector2i(column, -7), biome_for_column(snapshot, run_seed, column), &"cave_roof")
	if chunk_index % 2 == 0:
		_add_clear_anchor(description, heights, snapshot, run_seed)
	_add_hazard_candidates(description, snapshot, run_seed)
	if not _validate_description(description, snapshot):
		return ChunkDescription.new(version, run_seed, chunk_index, 0, 0)
	return description

static func _add_column(description: ChunkDescription, column: int, height: int, material: StringName, kind: StringName) -> void:
	# Surface row is height; lower rows are occupied dirt, in absolute tile space.
	for row in range(height, height + 3):
		_add_cell(description, Vector2i(column, row), material, kind)

static func _add_main_surfaces(description: ChunkDescription, heights: Array[int], materials: Array[StringName]) -> void:
	var start := description.x_begin
	var current := heights[0]
	var current_material := materials[0]
	for offset in range(1, heights.size() + 1):
		if offset == heights.size() or heights[offset] != current or materials[offset] != current_material:
			description.surfaces.append(TerrainSurface.new(_surface_id(description.chunk_index, &"main", start), description.chunk_index, start, description.x_begin + offset, current, &"main_route", current_material))
			if offset < heights.size():
				start = description.x_begin + offset
				current = heights[offset]
				current_material = materials[offset]

static func _add_surfaces_for_span(description: ChunkDescription, chunk_index: int, id_kind: StringName, begin: int, end: int, row: int, kind: StringName) -> void:
	var start := begin
	var material := StringName(description.biome_at_column.get(begin, &"grass"))
	for column in range(begin + 1, end + 1):
		if column == end or StringName(description.biome_at_column.get(column, &"")) != material:
			description.surfaces.append(TerrainSurface.new(_surface_id(chunk_index, id_kind, start), chunk_index, start, column, row, kind, material))
			if column < end:
				start = column
				material = StringName(description.biome_at_column.get(column, &"grass"))

static func _add_clear_anchor(description: ChunkDescription, heights: Array[int], snapshot: Dictionary, run_seed: int) -> void:
	# Anchors are placed above a main-route tile outside cave roof columns.
	var local := 1
	var column := description.x_begin + local
	var row := heights[local] - 1
	var support_id := _surface_id(description.chunk_index, &"main", description.x_begin)
	for surface in description.surfaces:
		if surface.kind == &"main_route" and surface.contains_column(column):
			support_id = surface.id
			break
	var biome := biome_for_column(snapshot, run_seed, column)
	description.anchors.append(SpawnAnchor.new("anchor:%d:%d" % [description.chunk_index, column], &"generic", description.chunk_index, column, row, support_id, 3, &"future_spawn", &"right", biome))

static func _add_hazard_candidates(description: ChunkDescription, _snapshot: Dictionary, run_seed: int) -> void:
	# This uses an independent local stream and reads completed geometry only. It
	# cannot perturb the pre-existing form or biome-selection streams.
	for surface: TerrainSurface in description.surfaces:
		if surface.kind != &"main_route":
			continue
		var hazard_type := _hazard_type_for_biome(surface.material)
		if hazard_type.is_empty():
			continue
		var span := surface.x_end - surface.x_begin
		if span <= 0:
			continue
		var row := surface.y - (3 if surface.material == &"astro" else 1)
		var stream := _stream(run_seed, surface.x_begin, HAZARD_CANDIDATE_CHANNEL)
		var column := -1
		var support_tile_id: StringName = &""
		# A deterministic probe sequence retains the independent stream while
		# skipping an occupied floating platform or a cave-clearance conflict.
		for offset in span:
			var candidate := surface.x_begin + posmod(stream + offset, span)
			if not _hazard_space_is_clear(description, candidate, row):
				continue
			var support_cell: Dictionary = description.occupied.get(Vector2i(candidate, surface.y), {})
			var candidate_tile_id := StringName(support_cell.get(&"tile_id", &""))
			if candidate_tile_id.is_empty():
				continue
			column = candidate
			support_tile_id = candidate_tile_id
			break
		if column < surface.x_begin:
			continue
		var phase := float(posmod(_stream(run_seed, column, HAZARD_CANDIDATE_CHANNEL + 1), 10000)) / 10000.0
		var parameters := {
			&"clearance_tiles": 2,
			&"height_tiles": surface.y - row,
			&"stream_channel": HAZARD_CANDIDATE_CHANNEL,
		}
		description.hazards.append(Hazard.new("hazard:%d:%s:%d" % [description.chunk_index, hazard_type, column], int(_snapshot[&"hazard_descriptor_version"]), description.config_identity, description.chunk_index, Vector2i(column, row), surface.id, support_tile_id, surface.material, hazard_type, phase, parameters))

static func _hazard_type_for_biome(biome: StringName) -> StringName:
	if biome == &"desert":
		return &"desert_flame_candidate"
	if biome == &"astro":
		return &"astro_fall_candidate"
	if biome == &"fort":
		return &"fort_spike_candidate"
	return &""

static func _hazard_space_is_clear(description: ChunkDescription, column: int, row: int) -> bool:
	# Candidate origin and two cells of standing/head clearance must be empty;
	# cave roofs and occupied terrain therefore cannot receive a descriptor.
	for clear_row in range(row - 1, row + 1):
		if description.occupied.has(Vector2i(column, clear_row)):
			return false
	return true

static func _validate_description(description: ChunkDescription, snapshot: Dictionary) -> bool:
	var envelope := MovementEnvelope.from_snapshot(snapshot)
	if not envelope.validate().is_empty():
		return false
	# Material-labelled surfaces split at biome boundaries. Merge only for the
	# movement proof: adjacent collision runs at the same height remain one
	# continuous physical landing even though future M3c rendering needs their
	# distinct palette metadata.
	var route := traversal_surfaces(description.surfaces, &"main_route")
	for index in range(1, route.size()):
		if not envelope.can_reach_transition(route[index - 1], route[index]):
			return false
	# Optional platforms are only emitted where one main run can reach them and
	# where a clear descent to the following main run is also possible.
	for platform in traversal_surfaces(description.surfaces, &"floating_platform"):
		var enterable := false
		var exitable := false
		for main in route:
			if main.x_begin <= platform.x_begin and envelope.can_reach_transition(main, platform):
				enterable = true
			if envelope.can_reach_transition(platform, main):
				exitable = true
		if not enterable or not exitable:
			return false
	for column in range(description.x_begin, description.x_end):
		var biome := biome_for_column(snapshot, description.seed, column)
		if StringName(description.biome_at_column.get(column, &"")) != biome:
			return false
		for row in range(-8, 4):
			var cell: Dictionary = description.occupied.get(Vector2i(column, row), {})
			if not cell.is_empty() and StringName(cell.get(&"material", &"")) != biome:
				return false
	for surface in description.surfaces:
		for column in range(surface.x_begin, surface.x_end):
			if surface.material != biome_for_column(snapshot, description.seed, column):
				return false
	for anchor in description.anchors:
		if anchor.biome != biome_for_column(snapshot, description.seed, anchor.column):
			return false
	for hazard in description.hazards:
		if hazard.biome != biome_for_column(snapshot, description.seed, hazard.absolute_position.x) or not _hazard_type_for_biome(hazard.biome) == hazard.type:
			return false
		if description.occupied.has(hazard.absolute_position) or not _hazard_space_is_clear(description, hazard.absolute_position.x, hazard.absolute_position.y):
			return false
		var support_surface: TerrainSurface = null
		for surface in description.surfaces:
			if surface.id == hazard.supporting_surface_id:
				support_surface = surface
				break
		if support_surface == null:
			return false
		var support: Dictionary = description.occupied.get(Vector2i(hazard.absolute_position.x, support_surface.y), {})
		if StringName(support.get(&"tile_id", &"")) != hazard.supporting_tile_id:
			return false
	if description.form == &"cave":
		for surface in route:
			# Roof occupies row -7, so its underside is the top of row -6.
			if not envelope.has_vertical_clearance(float(surface.y - (-6)) * float(snapshot[&"tile_size"]) - envelope.body_height):
				return false
		for platform in description.surfaces:
			if platform.kind == &"floating_platform" and not envelope.has_vertical_clearance(float(platform.y - (-6)) * float(snapshot[&"tile_size"]) - envelope.body_height):
				return false
	return description.is_valid()

static func traversal_surfaces(surfaces: Array[TerrainSurface], kind: StringName) -> Array[TerrainSurface]:
	var result: Array[TerrainSurface] = []
	for surface in surfaces:
		if surface.kind != kind:
			continue
		if not result.is_empty():
			var previous: TerrainSurface = result.back()
			if previous.x_end == surface.x_begin and previous.y == surface.y:
				previous.x_end = surface.x_end
				continue
		result.append(TerrainSurface.new(surface.id, surface.chunk_index, surface.x_begin, surface.x_end, surface.y, kind, surface.material))
	return result

static func generate_flat_fallback(snapshot: Dictionary, version: int, run_seed: int, chunk_index: int) -> ChunkDescription:
	if version <= 0 or not validate_snapshot(snapshot).is_empty():
		return ChunkDescription.new(version, run_seed, chunk_index, 0, 0)
	var width := int(snapshot[&"chunk_width"])
	var x_begin := chunk_index * width
	var description := ChunkDescription.new(version, run_seed, chunk_index, x_begin, x_begin + width)
	description.config_identity = GameConfig.terrain_config_identity(snapshot)
	description.form = &"platform"
	for column in range(x_begin, x_begin + width):
		var biome := biome_for_column(snapshot, run_seed, column)
		description.biome_at_column[column] = biome
		_add_column(description, column, 0, biome, &"main_route")
	var materials: Array[StringName] = []
	for column in range(x_begin, x_begin + width):
		materials.append(biome_for_column(snapshot, run_seed, column))
	var heights: Array[int] = []
	for _column in width:
		heights.append(0)
	_add_main_surfaces(description, heights, materials)
	if chunk_index % 2 == 0:
		_add_clear_anchor(description, heights, snapshot, run_seed)
	_add_hazard_candidates(description, snapshot, run_seed)
	return description

static func _add_cell(description: ChunkDescription, location: Vector2i, material: StringName, kind: StringName) -> void:
	description.occupied[location] = {&"material": material, &"kind": kind, &"tile_id": "tile:%d:%d" % [location.x, location.y]}

static func _surface_id(chunk_index: int, kind: StringName, column: int) -> StringName:
	return "surface:%d:%s:%d" % [chunk_index, kind, column]

static func biome_for_column(snapshot: Dictionary, run_seed: int, column: int) -> StringName:
	if column < 0:
		return BIOMES[0]
	var interval := int(snapshot.get(&"biome_interval", 0))
	if interval <= 0:
		return &""
	return biome_for_encounter(run_seed, column / interval)

static func biome_visit_for_column(snapshot: Dictionary, run_seed: int, column: int) -> int:
	if column < 0:
		return 0
	var interval := int(snapshot.get(&"biome_interval", 0))
	if interval <= 0:
		return 0
	return biome_visit_for_encounter(run_seed, floori(float(column) / float(interval)))

static func biome_visit_for_encounter(run_seed: int, encounter_index: int) -> int:
	if encounter_index < BIOMES.size():
		return 0
	var counts: Dictionary = {}
	for biome in BIOMES:
		counts[biome] = 1
	var previous := BIOMES.size() - 1
	for index in range(BIOMES.size(), encounter_index + 1):
		var choice := _stream(run_seed, index, BIOME_RANDOM_CHANNEL) % (BIOMES.size() - 1)
		if choice >= previous:
			choice += 1
		var biome := BIOMES[choice]
		if index == encounter_index:
			return int(counts.get(biome, 0))
		counts[biome] = int(counts.get(biome, 0)) + 1
		previous = choice
	return 0

static func biome_for_encounter(run_seed: int, encounter_index: int) -> StringName:
	if encounter_index < 0:
		return BIOMES[0]
	if encounter_index < BIOMES.size():
		return BIOMES[encounter_index]
	# Each random encounter is derived only from its absolute index and the run
	# seed. Replaying or generating chunks in a different order cannot alter it.
	# Mapping a five-way roll around the prior biome proves adjacent encounters
	# cannot repeat, including the first random encounter after Fort.
	var previous := BIOMES.size() - 1
	for index in range(BIOMES.size(), encounter_index + 1):
		var choice := _stream(run_seed, index, BIOME_RANDOM_CHANNEL) % (BIOMES.size() - 1)
		if choice >= previous:
			choice += 1
		previous = choice
	return BIOMES[previous]

static func _stream(seed: int, chunk_index: int, channel: int) -> int:
	# Integer mixing is deliberately local and does not mutate global RNG state.
	var value := seed ^ (chunk_index * 1103515245) ^ (channel * 12345) ^ 0x6d2b79f5
	value = (value ^ (value >> 16)) * 0x45d9f3b
	value = value ^ (value >> 16)
	return abs(value)
