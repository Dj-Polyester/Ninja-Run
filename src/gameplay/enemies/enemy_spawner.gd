class_name EnemySpawner
extends Node

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const ENEMY_CATALOG_SCRIPT := preload("res://src/data/enemy_catalog.gd")

signal enemy_spawned(enemy: Node, chunk_start_tile: int)

var world_streamer: WorldStreamer
var enemy_container: Node2D
var player: Node2D
var projectile_container: Node
var effects_container: Node
var run_seed := 1
var enemies_by_chunk: Dictionary = {}

func configure(streamer: WorldStreamer, container: Node2D, target_player: Node2D, projectiles: Node = null, effects: Node = null) -> void:
	_disconnect_streamer()
	world_streamer = streamer
	enemy_container = container
	player = target_player
	projectile_container = projectiles
	effects_container = effects
	run_seed = int(GameState.run.get("seed", 1))
	if world_streamer != null:
		world_streamer.chunk_generated.connect(_on_chunk_generated)
		world_streamer.chunk_removed.connect(_on_chunk_removed)

func clear() -> void:
	for enemies in enemies_by_chunk.values():
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.queue_free()
	enemies_by_chunk.clear()

func spawn_specs_for_chunk(spec: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if world_streamer == null or spec.is_empty():
		return result
	var biome := BiomeCatalog.get_by_id(int(spec.get("biome_id", BiomeData.Id.GRASS)))
	var tile_x := int(spec.get("start_tile", 0))
	var encounter_number := world_streamer.biome_sequence.get_biome_occurrence_for_tile(tile_x)
	var pool: Array = ENEMY_CATALOG_SCRIPT.available_for_biome(biome, encounter_number)
	if pool.is_empty():
		return result
	var platforms: Array = []
	for platform in spec.get("platforms", []):
		if bool(platform.get("ceiling", false)) or bool(platform.get("optional_route", false)):
			continue
		if int(platform.get("width_tiles", 0)) >= GameConfig.ENEMY_MIN_PLATFORM_WIDTH:
			platforms.append(platform)
	if platforms.is_empty():
		return result

	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for_chunk(tile_x, biome.id)
	var desired := mini(GameConfig.ENEMY_MAX_PER_CHUNK, platforms.size())
	for index in desired:
		if index > 0 and rng.randf() > GameConfig.ENEMY_ADDITIONAL_SPAWN_CHANCE:
			break
		var platform: Dictionary = platforms[(index + rng.randi_range(0, platforms.size() - 1)) % platforms.size()]
		var enemy_data = pool[rng.randi_range(0, pool.size() - 1)]
		var start := int(platform.start_tile)
		var width := int(platform.width_tiles)
		var min_offset := 1 if width >= 3 else 0
		var max_offset := width - 2 if width >= 3 else width - 1
		var spawn_tile := start + rng.randi_range(min_offset, maxi(min_offset, max_offset))
		result.append({
			"enemy_id": enemy_data.id,
			"level": maxi(enemy_data.minimum_encounter, encounter_number),
			"tile_x": spawn_tile,
			"height_tile": int(platform.height_tile),
		})
	return result

func _on_chunk_generated(spec: Dictionary) -> void:
	if enemy_container == null or not is_instance_valid(enemy_container):
		return
	var chunk_key := int(spec.get("start_tile", 0))
	if chunk_key < GameConfig.ENEMY_SPAWN_START_TILE:
		return
	var spawned: Array[Node] = []
	for spawn_spec in spawn_specs_for_chunk(spec):
		var enemy_data = ENEMY_CATALOG_SCRIPT.get_by_id(StringName(spawn_spec.enemy_id))
		if enemy_data == null:
			continue
		var enemy := ENEMY_SCENE.instantiate()
		enemy_container.add_child(enemy)
		var surface := world_streamer.surface_position_for_tile(Vector2i(int(spawn_spec.tile_x), int(spawn_spec.height_tile)))
		enemy.global_position = world_streamer.to_global(surface) - Vector2(0.0, GameConfig.ENEMY_COLLISION_HEIGHT * 0.5)
		enemy.configure(enemy_data, int(spawn_spec.level), player, projectile_container, effects_container)
		spawned.append(enemy)
		enemy_spawned.emit(enemy, chunk_key)
	if not spawned.is_empty():
		enemies_by_chunk[chunk_key] = spawned

func _on_chunk_removed(spec: Dictionary) -> void:
	var chunk_key := int(spec.get("start_tile", 0))
	var enemies: Array = enemies_by_chunk.get(chunk_key, [])
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_by_chunk.erase(chunk_key)

func _disconnect_streamer() -> void:
	if world_streamer == null or not is_instance_valid(world_streamer):
		return
	if world_streamer.chunk_generated.is_connected(_on_chunk_generated):
		world_streamer.chunk_generated.disconnect(_on_chunk_generated)
	if world_streamer.chunk_removed.is_connected(_on_chunk_removed):
		world_streamer.chunk_removed.disconnect(_on_chunk_removed)

func _seed_for_chunk(chunk_start_tile: int, biome_id: int) -> int:
	return run_seed ^ (chunk_start_tile * 1103515245) ^ (biome_id * 2654435761) ^ 0xE11E5
