class_name TerrainChunk
extends Node2D
## One batched custom-draw node plus merged static collision runs for a chunk.

const Palette = preload("res://scripts/terrain/terrain_palette.gd")
const HazardRuntime = preload("res://scripts/terrain/hazard_runtime.gd")
const AstroBlock = preload("res://scripts/terrain/astro_fall_block.gd")

const ATLAS_PATH := "res://assets/Spritesheets/spritesheet-tiles-double.png"

var description: ChunkDescription
var tile_size := 64.0
var base_surface_y := 600.0
var run_origin_x := 160.0
var atlas: Texture2D
var support_bodies: Dictionary = {} # StringName -> StaticBody2D
var stable_tile_ids: Dictionary = {}
var hazard_runtimes: Dictionary = {} # StringName -> TerrainHazardRuntime
var astro_blocks: Dictionary = {} # StringName tile id -> AstroFallBlock
var astro_coordinator: AstroFallCoordinator
var generation_epoch := 0
var broken_tile_ids: Dictionary = {}
var runtime_collision_nodes: Array[StaticBody2D] = []
var visual_cell_query: Callable

signal hazard_damage_requested(event: DamageStatus.DamageEvent, runtime)

func configure(new_description: ChunkDescription, snapshot: Dictionary, new_astro_coordinator: AstroFallCoordinator = null, new_generation_epoch: int = 0, new_broken_tile_ids: Dictionary = {}, new_visual_cell_query: Callable = Callable()) -> void:
	description = new_description
	astro_coordinator = new_astro_coordinator
	generation_epoch = new_generation_epoch
	broken_tile_ids = new_broken_tile_ids.duplicate()
	visual_cell_query = new_visual_cell_query
	tile_size = float(snapshot[&"tile_size"])
	base_surface_y = float(snapshot[&"base_surface_y"])
	run_origin_x = float(snapshot[&"run_origin_x"])
	atlas = load(ATLAS_PATH) as Texture2D
	for location: Vector2i in description.occupied:
		stable_tile_ids[description.occupied[location][&"tile_id"]] = location
	_build_collisions()
	_build_astro_blocks()
	_build_hazards()
	queue_redraw()

func atlas_source_is_valid() -> bool:
	return Palette.all_rects_are_valid(atlas)

func source_rect_for_cell(location: Vector2i) -> Rect2:
	if description == null:
		return Palette.source_rect(&"grass", &"block")
	var cell := _visual_cell(location)
	var material := StringName(cell.get(&"material", &"grass"))
	return Palette.source_rect(material, source_variant_for_cell(location))

func source_variant_for_cell(location: Vector2i) -> StringName:
	var cell := _visual_cell(location)
	if cell.is_empty():
		return &"block"
	var material := StringName(cell.get(&"material", &"grass"))
	var left := _same_material_neighbor(location + Vector2i.LEFT, material)
	var right := _same_material_neighbor(location + Vector2i.RIGHT, material)
	var up := _same_material_neighbor(location + Vector2i.UP, material)
	var down := _same_material_neighbor(location + Vector2i.DOWN, material)

	# One-cell-thick ledges and cave roofs expose both vertical faces. The
	# atlas has dedicated horizontal pieces for exactly this topology.
	if not up and not down:
		if left and right:
			return &"horizontal_middle"
		if right:
			return &"horizontal_left"
		if left:
			return &"horizontal_right"
		return &"block"

	# Narrow columns use the atlas vertical pieces.
	if not left and not right:
		if up and down:
			return &"vertical_middle"
		if down:
			return &"vertical_top"
		if up:
			return &"vertical_bottom"
		return &"block"

	if not up and not left:
		return &"block_top_left"
	if not up and not right:
		return &"block_top_right"
	if not down and not left:
		return &"block_bottom_left"
	if not down and not right:
		return &"block_bottom_right"
	if not up:
		return &"block_top"
	if not down:
		return &"block_bottom"
	if not left:
		return &"block_left"
	if not right:
		return &"block_right"
	return &"block_center"

func _same_material_neighbor(location: Vector2i, material: StringName) -> bool:
	var neighbor := _visual_cell(location)
	return not neighbor.is_empty() and StringName(neighbor.get(&"material", &"")) == material

func _visual_cell(location: Vector2i) -> Dictionary:
	if description != null and description.occupied.has(location):
		var local_cell := description.occupied[location] as Dictionary
		var tile_id := StringName(local_cell.get(&"tile_id", &""))
		if tile_id.is_empty() or not broken_tile_ids.has(tile_id):
			return local_cell
	if visual_cell_query.is_valid():
		var external = visual_cell_query.call(location)
		if external is Dictionary:
			return external as Dictionary
	return {}

func world_x(column: int) -> float:
	# Logical column zero is centered on the declared run origin, so production
	# placement can preserve RUN_ORIGIN_X without a hidden offset.
	return run_origin_x + (float(column) - 0.5) * tile_size

func world_y(row: int) -> float:
	return base_surface_y + float(row) * tile_size

func body_for_surface(surface_id: StringName) -> StaticBody2D:
	return support_bodies.get(surface_id) as StaticBody2D

func set_hazard_target(target: CollisionObject2D) -> void:
	for runtime in hazard_runtimes.values():
		runtime.set_target(target)
	for block: AstroFallBlock in astro_blocks.values():
		block.set_target(target)

func advance_hazards(simulation_seconds: float, running: bool) -> void:
	for runtime in hazard_runtimes.values():
		runtime.advance(simulation_seconds, running)

func astro_block_for(tile_id: StringName):
	return astro_blocks.get(tile_id)

func runtime_for_hazard(hazard_id: StringName):
	return hazard_runtimes.get(hazard_id)

func _draw() -> void:
	if atlas == null or description == null:
		return
	for location: Vector2i in description.occupied:
		if _is_astro_cell(location) or _is_broken(location):
			continue
		var destination := Rect2(world_x(location.x), world_y(location.y), tile_size, tile_size)
		draw_texture_rect_region(atlas, destination, source_rect_for_cell(location), Color.WHITE)

func _build_collisions() -> void:
	if not broken_tile_ids.is_empty():
		_build_fragmented_collisions()
		return
	# Surface rectangles are intentionally merged, but their height follows the
	# occupied cells exactly: floating platforms are one tile, main terrain is
	# three tiles, and roofs are real one-tile collision.
	for surface in description.surfaces:
		# Logical surfaces survive for traversal/recovery APIs, but their physical
		# runs are split at every Astro cell. Astro blocks own those cells instead.
		var begin := 0
		var run_active := false
		for column in range(surface.x_begin, surface.x_end + 1):
			var blocked := column == surface.x_end or _surface_column_has_astro(surface, column)
			if not blocked and not run_active:
				begin = column
				run_active = true
			elif blocked and run_active:
				_add_support_run(surface, begin, column)
				run_active = false
	# Cave roofs are actual collision, but are not terrain_support candidates.
	var roof_columns: Array[int] = []
	var roof_row := 0
	for location: Vector2i in description.occupied:
		if StringName(description.occupied[location].get(&"kind", &"")) == &"cave_roof" and not _is_astro_cell(location):
			roof_columns.append(location.x)
			roof_row = location.y
	if not roof_columns.is_empty():
		roof_columns.sort()
		var begin := roof_columns[0]
		var previous := begin
		for column in roof_columns.slice(1):
			if column != previous + 1:
				_add_roof_collision(begin, previous + 1, roof_row)
				begin = column
			previous = column
		_add_roof_collision(begin, previous + 1, roof_row)

func _add_support_run(surface: TerrainSurface, begin: int, end: int) -> void:
	if end <= begin:
		return
	var body := StaticBody2D.new()
	body.name = "Support_%s" % surface.id.replace(":", "_") if begin == surface.x_begin else "Support_%s_%d" % [surface.id.replace(":", "_"), begin]
	body.add_to_group(&"terrain_support")
	body.set_meta(&"terrain_surface_id", surface.id)
	body.set_meta(&"terrain_chunk_index", description.chunk_index)
	body.set_meta(&"terrain_material", surface.material)
	body.set_meta(&"terrain_column_begin", begin)
	body.set_meta(&"terrain_column_end", end)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	var width := float(end - begin) * tile_size
	var depth_tiles := 1.0 if surface.kind == &"floating_platform" else 3.0
	shape.size = Vector2(width, tile_size * depth_tiles)
	collision.shape = shape
	body.position = Vector2(world_x(begin) + width * 0.5, world_y(surface.y) + tile_size * depth_tiles * 0.5)
	body.add_child(collision)
	add_child(body)
	runtime_collision_nodes.append(body)
	if not support_bodies.has(surface.id):
		support_bodies[surface.id] = body

func _build_astro_blocks() -> void:
	if astro_coordinator == null:
		return
	var locations: Array = description.occupied.keys()
	locations.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	for location: Vector2i in locations:
		if not _is_astro_cell(location):
			continue
		var cell: Dictionary = description.occupied[location]
		var tile_id := StringName(cell[&"tile_id"])
		var block := AstroBlock.new()
		block.configure(tile_id, generation_epoch, location.x, location.y, tile_size, atlas, source_rect_for_cell(location), astro_coordinator, Vector2(run_origin_x + float(location.x) * tile_size, world_y(location.y) + tile_size * 0.5), _surface_id_for_cell(location))
		add_child(block)
		astro_blocks[tile_id] = block
		var surface_id := _surface_id_for_cell(location)
		if not surface_id.is_empty() and not support_bodies.has(surface_id):
			support_bodies[surface_id] = block.support_body
		astro_coordinator.register_cell(tile_id, generation_epoch, location.x, location.y, description.chunk_index, block.global_position.y, block)

func _is_astro_cell(location: Vector2i) -> bool:
	return StringName((description.occupied.get(location, {}) as Dictionary).get(&"material", &"")) == &"astro"

func _surface_column_has_astro(surface: TerrainSurface, column: int) -> bool:
	var depth := 1 if surface.kind == &"floating_platform" else 3
	for row in range(surface.y, surface.y + depth):
		if _is_astro_cell(Vector2i(column, row)):
			return true
	return false

func _surface_id_for_cell(location: Vector2i) -> StringName:
	for surface: TerrainSurface in description.surfaces:
		if surface.contains_column(location.x) and location.y >= surface.y and location.y < surface.y + (1 if surface.kind == &"floating_platform" else 3):
			return surface.id
	return &""

func _build_hazards() -> void:
	# Descriptors are generated before chunks, but all active nodes belong to this
	# chunk so normal stream retirement frees contact signals and visuals together.
	for descriptor in description.hazards:
		if descriptor.type == &"astro_fall_candidate":
			continue
		var runtime := HazardRuntime.new()
		runtime.configure(descriptor, tile_size, run_origin_x, base_surface_y)
		runtime.damage_requested.connect(func(event: DamageStatus.DamageEvent, source) -> void:
			hazard_damage_requested.emit(event, source))
		add_child(runtime)
		hazard_runtimes[descriptor.id] = runtime

func _add_roof_collision(begin: int, end: int, row: int) -> void:
	var roof := StaticBody2D.new()
	roof.name = "CaveRoof_%d" % begin
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(float(end - begin) * tile_size, tile_size)
	collision.shape = shape
	roof.position = Vector2(world_x(begin) + shape.size.x * 0.5, world_y(row) + tile_size * 0.5)
	roof.add_child(collision)
	add_child(roof)
	runtime_collision_nodes.append(roof)

func set_broken_tile_ids(new_broken_tile_ids: Dictionary) -> void:
	broken_tile_ids = new_broken_tile_ids.duplicate()
	for body: StaticBody2D in runtime_collision_nodes:
		if body != null and is_instance_valid(body):
			body.collision_layer = 0
			body.queue_free()
	runtime_collision_nodes.clear()
	support_bodies.clear()
	_build_collisions()
	queue_redraw()

func _is_broken(location: Vector2i) -> bool:
	if description == null:
		return false
	var cell: Dictionary = description.occupied.get(location, {})
	var tile_id := StringName(cell.get(&"tile_id", &""))
	return not tile_id.is_empty() and broken_tile_ids.has(tile_id)

func _build_fragmented_collisions() -> void:
	var locations: Array[Vector2i] = []
	for location_variant in description.occupied.keys():
		var location := location_variant as Vector2i
		if _is_astro_cell(location) or _is_broken(location):
			continue
		locations.append(location)
	locations.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	var run_begin := 0
	var run_end := 0
	var run_row := 0
	var run_surface_id: StringName = &""
	var run_support := false
	var run_material: StringName = &""
	var active := false
	for location in locations:
		var cell: Dictionary = description.occupied[location]
		var surface_id := _surface_id_for_cell(location)
		var is_support := _location_is_support_top(location, surface_id) and StringName(cell.get(&"kind", &"")) != &"cave_roof"
		var material := StringName(cell.get(&"material", &"grass"))
		var continues := active and location.y == run_row and location.x == run_end and surface_id == run_surface_id and is_support == run_support and material == run_material
		if not continues and active:
			_add_fragment_collision(run_begin, run_end, run_row, run_surface_id, run_support, run_material)
			active = false
		if not active:
			run_begin = location.x
			run_end = location.x + 1
			run_row = location.y
			run_surface_id = surface_id
			run_support = is_support
			run_material = material
			active = true
		else:
			run_end = location.x + 1
	if active:
		_add_fragment_collision(run_begin, run_end, run_row, run_surface_id, run_support, run_material)

func _location_is_support_top(location: Vector2i, surface_id: StringName) -> bool:
	if surface_id.is_empty():
		return false
	for surface: TerrainSurface in description.surfaces:
		if surface.id == surface_id:
			return location.y == surface.y
	return false

func _add_fragment_collision(begin: int, end: int, row: int, surface_id: StringName, is_support: bool, material: StringName) -> void:
	if end <= begin:
		return
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(float(end - begin) * tile_size, tile_size)
	collision.shape = shape
	body.position = Vector2(world_x(begin) + shape.size.x * 0.5, world_y(row) + tile_size * 0.5)
	body.add_child(collision)
	if is_support and not surface_id.is_empty():
		body.add_to_group(&"terrain_support")
		body.set_meta(&"terrain_surface_id", surface_id)
		body.set_meta(&"terrain_chunk_index", description.chunk_index)
		body.set_meta(&"terrain_material", material)
		body.set_meta(&"terrain_column_begin", begin)
		body.set_meta(&"terrain_column_end", end)
		if not support_bodies.has(surface_id):
			support_bodies[surface_id] = body
	add_child(body)
	runtime_collision_nodes.append(body)
