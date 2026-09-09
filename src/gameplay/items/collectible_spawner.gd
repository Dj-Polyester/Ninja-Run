class_name CollectibleSpawner
extends Node

const PICKUP_SCENE := preload("res://scenes/items/collectible_pickup.tscn")

signal collectible_spawned(pickup: Node, chunk_start_tile: int, source: StringName)

var world_streamer: WorldStreamer
var pickup_container: Node2D
var enemy_spawner: EnemySpawner
var run_seed := 1
var pickups_by_chunk: Dictionary = {}

func configure(streamer: WorldStreamer, container: Node2D, enemies: EnemySpawner = null) -> void:
	_disconnect_sources()
	world_streamer = streamer
	pickup_container = container
	enemy_spawner = enemies
	run_seed = int(GameState.run.get("seed", 1))
	if world_streamer != null:
		world_streamer.chunk_generated.connect(_on_chunk_generated)
		world_streamer.chunk_removed.connect(_on_chunk_removed)
	if enemy_spawner != null:
		enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)

func clear() -> void:
	for pickups in pickups_by_chunk.values():
		for pickup in pickups:
			if is_instance_valid(pickup):
				pickup.queue_free()
	pickups_by_chunk.clear()

func spawn_specs_for_chunk(spec: Dictionary, injected_rng: RngService = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if spec.is_empty():
		return result
	var biome := BiomeCatalog.get_by_id(int(spec.get("biome_id", BiomeData.Id.GRASS)))
	if biome == null or biome.collectible_weights.is_empty():
		return result
	var rng := injected_rng if injected_rng != null else RngService.new(_seed_for_chunk(int(spec.get("start_tile", 0)), biome.id))
	var candidates := _candidate_slots(spec)
	for candidate in candidates:
		if result.size() >= GameConfig.COLLECTIBLE_MAX_PER_CHUNK:
			break
		var difficulty := clampf(float(candidate.difficulty), 0.0, 1.0)
		var placement_chance := 1.0 if bool(candidate.get("bonus", false)) else lerpf(GameConfig.COLLECTIBLE_BASE_SPAWN_CHANCE, GameConfig.COLLECTIBLE_MAX_SPAWN_CHANCE, difficulty)
		if not rng.chance(placement_chance):
			continue
		var weights := adjusted_spawn_weights(biome.collectible_weights, difficulty)
		var selected_key = rng.weighted_key(weights)
		if selected_key == null:
			continue
		var collectible = CollectibleCatalog.resolve_weight_key(selected_key, rng)
		if collectible == null or not collectible.spawnable:
			continue
		result.append({
			"collectible_id": collectible.id,
			"tile_x": int(candidate.tile_x),
			"height_tile": int(candidate.height_tile),
			"difficulty": difficulty,
			"bonus": bool(candidate.get("bonus", false)),
		})
	return result

func adjusted_spawn_weights(base_weights: Dictionary, difficulty: float) -> Dictionary:
	var adjusted := {}
	var normalized_difficulty := clampf(difficulty, 0.0, 1.0)
	for raw_key in base_weights.keys():
		var key := StringName(String(raw_key))
		var base_weight := maxf(0.0, float(base_weights[raw_key]))
		var representative = _representative_collectible(key)
		var premium := 0.0
		if representative != null:
			premium = clampf(float(representative.gold_value - 1) / float(maxi(1, CollectibleCatalog.minimum_gem_value() - 1)), 0.0, 2.5)
		elif key == &"gem":
			premium = 1.0
		adjusted[key] = base_weight * (1.0 + normalized_difficulty * premium * GameConfig.COLLECTIBLE_DIFFICULTY_VALUE_BONUS)
	return adjusted

func drop_specs_for_enemy(enemy_data: EnemyData, injected_rng: RngService) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if enemy_data == null or injected_rng == null:
		return result
	for raw_entry in enemy_data.drop_table:
		if not raw_entry is Dictionary:
			continue
		var collectible_id := StringName(String(raw_entry.get("collectible_id", "")))
		var collectible = CollectibleCatalog.get_by_id(collectible_id)
		if collectible == null or not collectible.droppable:
			continue
		var probability := float(raw_entry.get("probability", 0.0))
		if probability < 0.0 or probability > 1.0 or not injected_rng.chance(probability):
			continue
		var min_count := maxi(0, int(raw_entry.get("min_count", 1)))
		var max_count := maxi(min_count, int(raw_entry.get("max_count", min_count)))
		var count := injected_rng.range_i(min_count, max_count)
		for _index in count:
			result.append({"collectible_id": collectible.id})
	return result

func _on_chunk_generated(spec: Dictionary) -> void:
	if pickup_container == null or not is_instance_valid(pickup_container) or world_streamer == null:
		return
	var chunk_key := int(spec.get("start_tile", 0))
	for spawn_spec in spawn_specs_for_chunk(spec):
		var collectible = CollectibleCatalog.get_by_id(StringName(spawn_spec.collectible_id))
		if collectible == null:
			continue
		var surface := world_streamer.surface_position_for_tile(Vector2i(int(spawn_spec.tile_x), int(spawn_spec.height_tile)))
		var global_spawn := world_streamer.to_global(surface) - Vector2(0.0, GameConfig.COLLECTIBLE_VERTICAL_OFFSET)
		_spawn_pickup(collectible, global_spawn, chunk_key, &"procedural")

func _on_chunk_removed(spec: Dictionary) -> void:
	var chunk_key := int(spec.get("start_tile", 0))
	var pickups: Array = pickups_by_chunk.get(chunk_key, [])
	for pickup in pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	pickups_by_chunk.erase(chunk_key)

func _on_enemy_spawned(enemy: Node, chunk_start_tile: int) -> void:
	if enemy == null or not enemy.has_signal(&"died"):
		return
	enemy.died.connect(_on_enemy_died.bind(chunk_start_tile))

func _on_enemy_died(enemy: Enemy, chunk_start_tile: int) -> void:
	if enemy == null or enemy.data == null or pickup_container == null or not is_instance_valid(pickup_container):
		return
	var rng := RngService.new(_seed_for_enemy(enemy, chunk_start_tile))
	var drop_specs := drop_specs_for_enemy(enemy.data, rng)
	for index in drop_specs.size():
		var collectible = CollectibleCatalog.get_by_id(StringName(drop_specs[index].collectible_id))
		if collectible == null:
			continue
		var centered_index := float(index) - float(drop_specs.size() - 1) * 0.5
		var offset := Vector2(centered_index * GameConfig.COLLECTIBLE_DROP_SPACING, -GameConfig.COLLECTIBLE_DROP_LIFT)
		_spawn_pickup(collectible, enemy.global_position + offset, chunk_start_tile, &"enemy_drop")

func _spawn_pickup(collectible: CollectibleData, global_spawn: Vector2, chunk_key: int, source: StringName) -> Node:
	if collectible == null:
		return null
	if source == &"procedural" and not collectible.spawnable:
		return null
	if source == &"enemy_drop" and not collectible.droppable:
		return null
	if OS.is_debug_build() and collectible.is_gem():
		assert(source == &"enemy_drop", "Gem collectibles may only spawn from enemy drops.")
	var pickup := PICKUP_SCENE.instantiate() as CollectiblePickup
	pickup_container.add_child(pickup)
	pickup.global_position = global_spawn
	pickup.configure(collectible, source)
	var tracked: Array = pickups_by_chunk.get(chunk_key, [])
	tracked.append(pickup)
	pickups_by_chunk[chunk_key] = tracked
	collectible_spawned.emit(pickup, chunk_key, source)
	return pickup

func _candidate_slots(spec: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for platform in spec.get("platforms", []):
		if bool(platform.get("ceiling", false)) or bool(platform.get("optional_route", false)):
			continue
		var width := int(platform.get("width_tiles", 0))
		if width < 2:
			continue
		var difficulty := placement_difficulty(spec, platform)
		candidates.append({
			"tile_x": int(platform.start_tile) + width / 2,
			"height_tile": int(platform.height_tile),
			"difficulty": difficulty,
			"bonus": false,
		})
		if width >= 9:
			candidates.append({
				"tile_x": int(platform.start_tile) + width / 4,
				"height_tile": int(platform.height_tile),
				"difficulty": minf(1.0, difficulty + 0.08),
				"bonus": false,
			})
	for bonus_tile in spec.get("bonus_spawn_tiles", []):
		if bonus_tile is Vector2i:
			candidates.append({
				"tile_x": bonus_tile.x,
				"height_tile": bonus_tile.y + 1,
				"difficulty": 1.0,
				"bonus": true,
			})
	return candidates

func placement_difficulty(spec: Dictionary, platform: Dictionary) -> float:
	var archetype := int(spec.get("archetype", ProceduralLayoutGenerator.Archetype.FLAT))
	var archetype_difficulty: float = float({
		ProceduralLayoutGenerator.Archetype.FLAT: 0.10,
		ProceduralLayoutGenerator.Archetype.FLYING_PLATFORMS: 0.72,
		ProceduralLayoutGenerator.Archetype.MOUNTAIN: 0.42,
		ProceduralLayoutGenerator.Archetype.CAVE: 0.28,
		ProceduralLayoutGenerator.Archetype.STAIRS: 0.38,
		ProceduralLayoutGenerator.Archetype.STACKED_PLATFORMS: 0.62,
		ProceduralLayoutGenerator.Archetype.GAPS: 0.82,
	}.get(archetype, 0.25))
	var elevation := clampf(absf(float(int(platform.get("height_tile", GameConfig.BASE_PLATFORM_HEIGHT)) - GameConfig.BASE_PLATFORM_HEIGHT)) / 4.0, 0.0, 1.0)
	var optional_bonus := 0.20 if bool(platform.get("optional_route", false)) else 0.0
	return clampf(archetype_difficulty + elevation * 0.18 + optional_bonus, 0.0, 1.0)

func _representative_collectible(weight_key: StringName):
	if weight_key == &"gem":
		return CollectibleCatalog.GEM_BLUE
	return CollectibleCatalog.get_by_id(weight_key)

func _seed_for_chunk(chunk_start_tile: int, biome_id: int) -> int:
	return run_seed ^ (chunk_start_tile * 214013) ^ (biome_id * 2531011) ^ 0xC011EC7

func _seed_for_enemy(enemy: Enemy, chunk_start_tile: int) -> int:
	var enemy_hash := String(enemy.data.id).hash() if enemy != null and enemy.data != null else 0
	var position_hash := roundi(enemy.global_position.x) * 31 + roundi(enemy.global_position.y) * 17
	return run_seed ^ (chunk_start_tile * 1103515245) ^ enemy_hash ^ position_hash ^ (enemy.enemy_level * 7919) ^ 0xD20F5

func _disconnect_sources() -> void:
	if world_streamer != null and is_instance_valid(world_streamer):
		if world_streamer.chunk_generated.is_connected(_on_chunk_generated):
			world_streamer.chunk_generated.disconnect(_on_chunk_generated)
		if world_streamer.chunk_removed.is_connected(_on_chunk_removed):
			world_streamer.chunk_removed.disconnect(_on_chunk_removed)
	if enemy_spawner != null and is_instance_valid(enemy_spawner) and enemy_spawner.enemy_spawned.is_connected(_on_enemy_spawned):
		enemy_spawner.enemy_spawned.disconnect(_on_enemy_spawned)
