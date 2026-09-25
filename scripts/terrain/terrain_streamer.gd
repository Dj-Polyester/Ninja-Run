class_name TerrainStreamer
extends Node2D
## Direct chunk reconciliation. Generation never depends on generation history.

const Hazard = preload("res://scripts/terrain/hazard_descriptor.gd")
const AstroCoordinator = preload("res://scripts/terrain/astro_fall_coordinator.gd")

signal chunk_added(chunk_index: int)
signal chunk_removed(chunk_index: int)
signal hazard_damage_requested(event: DamageStatus.DamageEvent)
signal anchor_added(anchor_id: StringName, support_surface_id: StringName, support_tile_id: StringName, chunk_index: int, epoch: int)
signal anchor_invalidated(anchor_id: StringName, support_surface_id: StringName, support_tile_id: StringName, chunk_index: int, epoch: int)
signal anchor_removed(anchor_id: StringName, support_surface_id: StringName, support_tile_id: StringName, chunk_index: int, epoch: int)

var snapshot: Dictionary = {}
var generator_version := GameConfig.TERRAIN_VERSION
var run_seed := 1
var active_chunks: Dictionary = {} # int -> TerrainChunk
var descriptions: Dictionary = {} # int -> ChunkDescription (bounded with nodes)
var surface_registry: Dictionary = {} # StringName -> TerrainSurface
var anchor_registry: Dictionary = {} # StringName -> SpawnAnchor
var anchor_lifecycle: Dictionary = {} # StringName -> immutable identity dictionary
var hazard_registry: Dictionary = {} # StringName -> HazardDescriptor
var active_hazard_runtimes: Dictionary = {} # StringName -> TerrainHazardRuntime
var astro_coordinator := AstroCoordinator.new()
var astro_tile_registry: Dictionary = {} # StringName tile id -> {chunk_index, column, row, surface_id, epoch}
var broken_tile_ids: Dictionary = {} # Run-local destruction overlay; generation stays immutable.
var _live_chunk_epochs: Dictionary = {} # int -> current registration epoch only
var _registration_serial := 0 # Monotonic for this streamer lifetime.
var _hazard_target: CollisionObject2D
var _last_player_column := 0

func _init() -> void:
	_bind_astro_coordinator()

func _bind_astro_coordinator() -> void:
	astro_coordinator.cell_state_changed.connect(_on_astro_state_changed)
	astro_coordinator.set_solid_below_query(_has_non_astro_solid_between)

func setup(new_snapshot: Dictionary, new_seed: int, version: int = GameConfig.TERRAIN_VERSION) -> bool:
	var errors := TerrainGenerator.validate_snapshot(new_snapshot)
	if not errors.is_empty() or version <= 0:
		return false
	# A streamer can be reused by tests/tools. Never mix descriptions generated
	# from different seed/config/version identities in the live registries.
	for index: int in active_chunks.keys():
		_remove_chunk(index)
	active_chunks.clear()
	descriptions.clear()
	surface_registry.clear()
	anchor_registry.clear()
	anchor_lifecycle.clear()
	hazard_registry.clear()
	active_hazard_runtimes.clear()
	astro_coordinator = AstroCoordinator.new()
	_bind_astro_coordinator()
	astro_tile_registry.clear()
	broken_tile_ids.clear()
	_live_chunk_epochs.clear()
	snapshot = new_snapshot.duplicate(true)
	run_seed = new_seed
	generator_version = version
	return true

func reconcile(player_world_position: Vector2, viewport_width: float = 1280.0) -> void:
	if snapshot.is_empty():
		return
	_last_player_column = world_to_column(player_world_position.x)
	var width := int(snapshot[&"chunk_width"])
	var camera_columns := ceili(viewport_width / float(snapshot[&"tile_size"]))
	var current := floori(float(_last_player_column) / width)
	# Keep viewport-visible terrain plus an explicit recovery band live.  The
	# latter is the only registry range recovery is allowed to trust.
	var recovery_band := GameConfig.TERRAIN_RECOVERY_MARGIN_CHUNKS
	var ahead := maxi(GameConfig.TERRAIN_ACTIVE_AHEAD_CHUNKS, ceili(float(camera_columns) / width) + recovery_band)
	var behind := maxi(GameConfig.TERRAIN_ACTIVE_BEHIND_CHUNKS, ceili(float(camera_columns) / (2.0 * width)) + 1)
	var wanted: Dictionary = {}
	for index in range(current - behind, current + ahead + 1):
		wanted[index] = true
		if not active_chunks.has(index):
			_add_chunk(index)
	for index: int in active_chunks.keys():
		if wanted.has(index):
			continue
		# The player's current chunk is always retained even if settings are edited
		# mid-run. This also protects visible/countdown recovery support.
		if _chunk_contains_column(index, _last_player_column):
			continue
		_remove_chunk(index)

func world_to_column(world_x: float) -> int:
	# Tile column zero is centered on run_origin_x; add half a tile so ownership
	# changes exactly at the rendered/collision boundary.
	var tile_size := float(snapshot.get(&"tile_size", GameConfig.TILE_SIZE))
	return floori((world_x - float(snapshot.get(&"run_origin_x", GameConfig.RUN_ORIGIN_X)) + tile_size * 0.5) / tile_size)

func surface_candidates(near_world_position: Vector2, forward_only: bool = false, max_columns: int = 24) -> Array[TerrainSurface]:
	var result: Array[TerrainSurface] = []
	var center := world_to_column(near_world_position.x)
	for surface: TerrainSurface in surface_registry.values():
		if forward_only and surface.x_end <= center:
			continue
		if surface.x_begin > center + max_columns or surface.x_end < center - max_columns:
			continue
		if is_surface_live(surface):
			result.append(surface)
	result.sort_custom(func(a: TerrainSurface, b: TerrainSurface) -> bool:
		var da := absf(float((a.x_begin + a.x_end) / 2 - center))
		var db := absf(float((b.x_begin + b.x_end) / 2 - center))
		return da < db)
	return result

func is_surface_live(surface: TerrainSurface) -> bool:
	var chunk := active_chunks.get(surface.chunk_index) as TerrainChunk
	if chunk == null or chunk.is_queued_for_deletion():
		return false
	var body := chunk.body_for_surface(surface.id)
	return body != null and is_instance_valid(body) and not body.is_queued_for_deletion()

func recovery_max_columns() -> int:
	return (GameConfig.TERRAIN_RECOVERY_MARGIN_CHUNKS + 2) * int(snapshot.get(&"chunk_width", 0))

func world_position_on_surface(surface: TerrainSurface, preferred_column: int = -999999) -> Vector2:
	var column := clampi(preferred_column, surface.x_begin, surface.x_end - 1)
	if preferred_column == -999999:
		column = surface.x_begin + (surface.x_end - surface.x_begin) / 2
	return Vector2(float(snapshot[&"run_origin_x"]) + float(column) * float(snapshot[&"tile_size"]), float(snapshot[&"base_surface_y"]) + float(surface.y) * float(snapshot[&"tile_size"]) - 32.0)

func active_chunk_count() -> int:
	return active_chunks.size()

func set_hazard_target(target: CollisionObject2D) -> void:
	_hazard_target = target
	for chunk in active_chunks.values():
		chunk.set_hazard_target(target)

func tick_hazards(simulation_seconds: float, running: bool) -> void:
	# Astro uses the exact same RUNNING-only simulation time as Desert/Fort.
	astro_coordinator.set_contact_enabled(running)
	astro_coordinator.advance(simulation_seconds, running, float(snapshot.get(&"tile_size", GameConfig.TILE_SIZE)), GameConfig.ASTRO_FALL_SPEED, GameConfig.ASTRO_FALL_DELAY, GameConfig.ASTRO_FALL_FIXED_STEP, GameConfig.ASTRO_FALL_LIMIT)
	for chunk in active_chunks.values():
		chunk.advance_hazards(simulation_seconds, running)

func set_astro_contact_enabled(enabled: bool) -> void:
	astro_coordinator.set_contact_enabled(enabled)

func runtime_for_hazard(hazard_id: StringName):
	return active_hazard_runtimes.get(hazard_id)

func astro_state_for(tile_id: StringName) -> int:
	return astro_coordinator.state_for(tile_id)

func is_astro_tile_stable(tile_id: StringName) -> bool:
	return astro_coordinator.is_stable(tile_id)

func is_durable_support_column(surface: TerrainSurface, column: int) -> bool:
	if not is_surface_live(surface) or column < surface.x_begin or column >= surface.x_end:
		return false
	var cell := _support_cell_for(surface, column)
	if cell.is_empty():
		return false
	var tile_id := StringName(cell.get(&"tile_id", &""))
	if StringName(cell.get(&"material", &"")) == &"astro":
		return false # Stable Astro is never a recovery/revival support.
	return not tile_id.is_empty()

func anchor_identity(anchor_id: StringName) -> Dictionary:
	return (anchor_lifecycle.get(anchor_id, {}) as Dictionary).duplicate(true)

func is_anchor_eligible(anchor_id: StringName, expected_epoch: int = -1, expected_support_tile_id: StringName = &"") -> bool:
	var anchor := anchor_registry.get(anchor_id) as SpawnAnchor
	var identity: Dictionary = anchor_lifecycle.get(anchor_id, {})
	if anchor == null or identity.is_empty() or expected_epoch >= 0 and int(identity.get(&"epoch", -1)) != expected_epoch:
		return false
	if not expected_support_tile_id.is_empty() and StringName(identity.get(&"support_tile_id", &"")) != expected_support_tile_id:
		return false
	var surface := surface_registry.get(anchor.surface_id) as TerrainSurface
	return surface != null and is_surface_live(surface) and is_live_spawn_support_column(surface, anchor.column)

func is_live_spawn_support_column(surface: TerrainSurface, column: int) -> bool:
	# Enemy spawns need a live physical support, not a revival destination.
	# Stable Astro is deliberately valid here; armed/falling/removed Astro is not.
	if not is_surface_live(surface) or column < surface.x_begin or column >= surface.x_end:
		return false
	var cell := _support_cell_for(surface, column)
	var tile_id := StringName(cell.get(&"tile_id", &""))
	if tile_id.is_empty():
		return false
	if StringName(cell.get(&"material", &"")) == &"astro":
		return astro_coordinator.is_stable(tile_id)
	return true

func is_safe_recovery_pose(candidate: Vector2, half_extents: Vector2 = Vector2(18.0, 28.0)) -> bool:
	# Exact logical exclusions complement Level's shape/ray physics check.
	var column := world_to_column(candidate.x)
	for surface: TerrainSurface in surface_registry.values():
		if surface.contains_column(column) and is_durable_support_column(surface, column):
			return not is_live_danger_at(candidate, half_extents)
	return false

func is_live_danger_at(candidate: Vector2, half_extents: Vector2 = Vector2(18.0, 28.0)) -> bool:
	# Existing M3c.2 Area2D hazards are queried geometrically, not by a broad
	# descriptor guess. Astro blocks are excluded through durable support above.
	for runtime in active_hazard_runtimes.values():
		if runtime != null and is_instance_valid(runtime) and runtime.is_damaging():
			var area = runtime.area
			if area != null and is_instance_valid(area):
				var shape := runtime.hitbox.shape as RectangleShape2D
				if shape != null:
					var danger_rect := Rect2(area.global_position - shape.size * 0.5, shape.size).grow(2.0)
					# Physics shape casts do not see Area2D. Validate the full standing
					# body plus its required forward-clear recovery sweep.
					var recovery_sweep := Rect2(candidate - half_extents, half_extents * 2.0 + Vector2(float(snapshot.get(&"tile_size", GameConfig.TILE_SIZE)), 0.0))
					if danger_rect.intersects(recovery_sweep):
						return true
	return false

func invalidate_astro_tile(tile_id: StringName, direction: StringName = &"top") -> bool:
	var cell: Dictionary = astro_tile_registry.get(tile_id, {})
	return not cell.is_empty() and astro_coordinator.arm(tile_id, int(cell.get(&"epoch", -1)), direction)

func _add_chunk(index: int) -> void:
	var description := TerrainGenerator.generate(snapshot, generator_version, run_seed, index)
	if not description.is_valid():
		description = TerrainGenerator.generate_flat_fallback(snapshot, generator_version, run_seed, index)
		if not description.is_valid():
			push_error("Terrain generation and deterministic fallback both failed for chunk %d." % index)
			return
	var chunk := TerrainChunk.new()
	chunk.name = "TerrainChunk_%d" % index
	_registration_serial += 1
	var epoch := _registration_serial
	_live_chunk_epochs[index] = epoch
	# Register the immutable description before configuration so edge selection
	# can see already-live neighboring chunks through the atlas cell query.
	descriptions[index] = description
	chunk.configure(description, snapshot, astro_coordinator, epoch, broken_tile_ids, Callable(self, "_visual_cell_at"))
	if _hazard_target != null and is_instance_valid(_hazard_target):
		chunk.set_hazard_target(_hazard_target)
	chunk.hazard_damage_requested.connect(_on_chunk_hazard_damage_requested)
	add_child(chunk)
	active_chunks[index] = chunk
	for surface in description.surfaces:
		surface_registry[surface.id] = surface
	for anchor in description.anchors:
		anchor_registry[anchor.id] = anchor
		var support_tile_id := _support_tile_id_for(description, anchor.column, anchor.surface_id)
		anchor_lifecycle[anchor.id] = {&"anchor_id": anchor.id, &"support_surface_id": anchor.surface_id, &"support_tile_id": support_tile_id, &"chunk_index": index, &"epoch": epoch}
		anchor_added.emit(anchor.id, anchor.surface_id, support_tile_id, index, epoch)
	for hazard in description.hazards:
		hazard_registry[hazard.id] = hazard
		var runtime = chunk.runtime_for_hazard(hazard.id)
		if runtime != null:
			active_hazard_runtimes[hazard.id] = runtime
	for location: Vector2i in description.occupied:
		var cell: Dictionary = description.occupied[location]
		if StringName(cell.get(&"material", &"")) == &"astro":
			astro_tile_registry[StringName(cell[&"tile_id"])] = {&"chunk_index": index, &"column": location.x, &"row": location.y, &"surface_id": _surface_id_at(description, location), &"epoch": epoch}
	_redraw_active_chunks()
	chunk_added.emit(index)

func _remove_chunk(index: int) -> void:
	var description := descriptions.get(index) as ChunkDescription
	if description != null:
		for surface in description.surfaces:
			surface_registry.erase(surface.id)
		for anchor in description.anchors:
			_remove_anchor(anchor.id)
		for hazard in description.hazards:
			hazard_registry.erase(hazard.id)
			active_hazard_runtimes.erase(hazard.id)
		for location: Vector2i in description.occupied:
			var cell: Dictionary = description.occupied[location]
			if StringName(cell.get(&"material", &"")) == &"astro":
				var tile_id := StringName(cell[&"tile_id"])
				var entry: Dictionary = astro_tile_registry.get(tile_id, {})
				if int(entry.get(&"epoch", -1)) == int(_live_chunk_epochs.get(index, -2)):
					astro_coordinator.retire(tile_id, int(entry[&"epoch"]))
					astro_tile_registry.erase(tile_id)
	var chunk := active_chunks.get(index) as TerrainChunk
	active_chunks.erase(index)
	descriptions.erase(index)
	_live_chunk_epochs.erase(index)
	if is_instance_valid(chunk):
		chunk.queue_free()
	_redraw_active_chunks()
	chunk_removed.emit(index)

func _on_chunk_hazard_damage_requested(event: DamageStatus.DamageEvent, runtime) -> void:
	if runtime == null or runtime.descriptor == null:
		return
	# Ignore an event that arrived from a runtime retired during the same frame.
	if active_hazard_runtimes.get(runtime.descriptor.id) != runtime:
		return
	hazard_damage_requested.emit(event)

func _on_astro_state_changed(tile_id: StringName, epoch: int, _previous: int, next_state: int) -> void:
	if next_state != AstroCoordinator.State.ARMED:
		return
	var entry: Dictionary = astro_tile_registry.get(tile_id, {})
	if entry.is_empty() or int(entry.get(&"epoch", -1)) != epoch:
		return
	# Only anchors whose exact support tile has armed are invalid. A neighboring
	# column on the same logical TerrainSurface is still eligible.
	for anchor_id: StringName in anchor_registry.keys():
		var anchor := anchor_registry[anchor_id] as SpawnAnchor
		if anchor != null and anchor.chunk_index == int(entry[&"chunk_index"]) and anchor.column == int(entry[&"column"]) and anchor.surface_id == StringName(entry[&"surface_id"]):
			_remove_anchor(anchor_id, true)

func _remove_anchor(anchor_id: StringName, invalidated: bool = false) -> void:
	var anchor := anchor_registry.get(anchor_id) as SpawnAnchor
	var identity: Dictionary = anchor_lifecycle.get(anchor_id, {})
	if anchor == null or identity.is_empty():
		anchor_registry.erase(anchor_id)
		anchor_lifecycle.erase(anchor_id)
		return
	anchor_registry.erase(anchor_id)
	anchor_lifecycle.erase(anchor_id)
	var support_tile_id := StringName(identity.get(&"support_tile_id", &""))
	if invalidated:
		anchor_invalidated.emit(anchor_id, anchor.surface_id, support_tile_id, anchor.chunk_index, int(identity.get(&"epoch", -1)))
	else:
		anchor_removed.emit(anchor_id, anchor.surface_id, support_tile_id, anchor.chunk_index, int(identity.get(&"epoch", -1)))

func _has_non_astro_solid_between(column: int, old_bottom_y: float, new_bottom_y: float) -> bool:
	var base := float(snapshot.get(&"base_surface_y", GameConfig.TERRAIN_BASE_SURFACE_Y))
	var size := float(snapshot.get(&"tile_size", GameConfig.TILE_SIZE))
	for description: ChunkDescription in descriptions.values():
		for location: Vector2i in description.occupied:
			if location.x != column:
				continue
			var cell: Dictionary = description.occupied[location]
			var tile_id := StringName(cell.get(&"tile_id", &""))
			if broken_tile_ids.has(tile_id) or StringName(cell.get(&"material", &"")) == &"astro":
				continue
			var top := base + float(location.y) * size
			if old_bottom_y <= top + 0.001 and new_bottom_y >= top - 0.001:
				return true
	return false

func _visual_cell_at(location: Vector2i) -> Dictionary:
	if snapshot.is_empty():
		return {}
	var width := int(snapshot.get(&"chunk_width", 0))
	if width <= 0:
		return {}
	var index := floori(float(location.x) / float(width))
	var description := descriptions.get(index) as ChunkDescription
	if description == null:
		return {}
	var cell := description.occupied.get(location, {}) as Dictionary
	if cell.is_empty():
		return {}
	var tile_id := StringName(cell.get(&"tile_id", &""))
	return {} if not tile_id.is_empty() and broken_tile_ids.has(tile_id) else cell

func _redraw_active_chunks() -> void:
	for chunk: TerrainChunk in active_chunks.values():
		if chunk != null and is_instance_valid(chunk) and not chunk.is_queued_for_deletion():
			chunk.queue_redraw()

func _chunk_contains_column(index: int, column: int) -> bool:
	var width := int(snapshot[&"chunk_width"])
	return column >= index * width and column < (index + 1) * width

func _support_cell_for(surface: TerrainSurface, column: int) -> Dictionary:
	var description := descriptions.get(surface.chunk_index) as ChunkDescription
	if description == null:
		return {}
	var cell := description.occupied.get(Vector2i(column, surface.y), {}) as Dictionary
	var tile_id := StringName(cell.get(&"tile_id", &""))
	return {} if not tile_id.is_empty() and broken_tile_ids.has(tile_id) else cell

func _surface_id_at(description: ChunkDescription, location: Vector2i) -> StringName:
	for surface: TerrainSurface in description.surfaces:
		var depth := 1 if surface.kind == &"floating_platform" else 3
		if surface.contains_column(location.x) and location.y >= surface.y and location.y < surface.y + depth:
			return surface.id
	return &""

func _support_tile_id_for(description: ChunkDescription, column: int, surface_id: StringName) -> StringName:
	for surface: TerrainSurface in description.surfaces:
		if surface.id == surface_id:
			var cell: Dictionary = description.occupied.get(Vector2i(column, surface.y), {})
			return StringName(cell.get(&"tile_id", &""))
	return &""

func is_tile_broken(tile_id: StringName) -> bool:
	return not tile_id.is_empty() and broken_tile_ids.has(tile_id)

func break_tiles_in_radius(center: Vector2, radius_tiles: float) -> Array[StringName]:
	var broken_now: Array[StringName] = []
	if snapshot.is_empty() or not is_finite(radius_tiles) or radius_tiles <= 0.0:
		return broken_now
	var size := float(snapshot.get(&"tile_size", GameConfig.TILE_SIZE))
	var base := float(snapshot.get(&"base_surface_y", GameConfig.TERRAIN_BASE_SURFACE_Y))
	var origin_x := float(snapshot.get(&"run_origin_x", GameConfig.RUN_ORIGIN_X))
	var radius_pixels := radius_tiles * size
	var affected_chunks: Dictionary = {}
	for chunk_variant in descriptions.keys():
		var chunk_index := int(chunk_variant)
		var description := descriptions.get(chunk_index) as ChunkDescription
		if description == null:
			continue
		for location: Vector2i in description.occupied:
			var cell: Dictionary = description.occupied[location]
			if StringName(cell.get(&"material", &"")) == &"astro":
				continue
			var tile_id := StringName(cell.get(&"tile_id", &""))
			if tile_id.is_empty() or broken_tile_ids.has(tile_id):
				continue
			var tile_center := Vector2(origin_x + float(location.x) * size, base + float(location.y) * size + size * 0.5)
			if tile_center.distance_to(center) > radius_pixels:
				continue
			broken_tile_ids[tile_id] = true
			broken_now.append(tile_id)
			affected_chunks[chunk_index] = true
	if broken_now.is_empty():
		return broken_now
	for anchor_variant in anchor_registry.keys().duplicate():
		var anchor_id := StringName(anchor_variant)
		var identity: Dictionary = anchor_lifecycle.get(anchor_id, {})
		if broken_tile_ids.has(StringName(identity.get(&"support_tile_id", &""))):
			_remove_anchor(anchor_id, true)
	for chunk_variant in affected_chunks.keys():
		var chunk_index := int(chunk_variant)
		var chunk := active_chunks.get(chunk_index) as TerrainChunk
		if chunk != null and is_instance_valid(chunk):
			chunk.set_broken_tile_ids(broken_tile_ids)
	# A broken boundary cell can change the exposed edge piece of a neighboring
	# active chunk even when that neighbor owns no newly broken cell.
	_redraw_active_chunks()
	return broken_now
