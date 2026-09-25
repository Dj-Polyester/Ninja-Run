class_name CollectibleSpawner
extends Node2D
## Stream-aware route pickups plus deterministic enemy-drop materialization.

const Pickup = preload("res://scripts/collectibles/collectible_pickup.gd")
const Catalog = preload("res://scripts/collectibles/collectible_catalog.gd")
const Definition = preload("res://scripts/collectibles/collectible_definition.gd")
const Loot = preload("res://scripts/models/loot_rolls.gd")
const EnemySpawnerRuntime = preload("res://scripts/enemies/enemy_spawner.gd")

var streamer: TerrainStreamer
var target: PlayerController
var director: RunDirector
var enemy_spawner: EnemySpawnerRuntime
var definitions: Dictionary = {}
var active: Dictionary = {} # pickup id -> CollectiblePickup
var anchor_to_pickup: Dictionary = {} # anchor id -> pickup id
var consumed: Dictionary = {} # anchor id|epoch -> true
var pending: Dictionary = {} # anchor id -> signal identity
var drop_ids: Dictionary = {} # pickup id -> true

func configure(new_streamer: TerrainStreamer, new_target: PlayerController, new_director: RunDirector, new_enemy_spawner: EnemySpawnerRuntime) -> void:
	streamer = new_streamer
	target = new_target
	director = new_director
	enemy_spawner = new_enemy_spawner
	definitions.clear()
	for definition: Definition in Catalog.definitions():
		definitions[definition.id] = definition
	if streamer != null:
		if not streamer.anchor_added.is_connected(_on_anchor_added):
			streamer.anchor_added.connect(_on_anchor_added)
		if not streamer.anchor_invalidated.is_connected(_on_anchor_invalidated):
			streamer.anchor_invalidated.connect(_on_anchor_invalidated)
		if not streamer.anchor_removed.is_connected(_on_anchor_removed):
			streamer.anchor_removed.connect(_on_anchor_removed)
		for anchor_variant in streamer.anchor_registry.keys():
			var anchor_id := StringName(anchor_variant)
			var identity := streamer.anchor_identity(anchor_id)
			_on_anchor_added(anchor_id, StringName(identity.get(&"support_surface_id", &"")), StringName(identity.get(&"support_tile_id", &"")), int(identity.get(&"chunk_index", 0)), int(identity.get(&"epoch", -1)))
	if enemy_spawner != null and not enemy_spawner.enemy_defeated.is_connected(_on_enemy_defeated):
		enemy_spawner.enemy_defeated.connect(_on_enemy_defeated)

func _physics_process(_delta: float) -> void:
	if director == null:
		return
	_materialize_pending()
	if target == null or not is_instance_valid(target):
		return
	var retire_before := target.global_position.x - float(GameConfig.TERRAIN_CHUNK_WIDTH * (GameConfig.TERRAIN_ACTIVE_BEHIND_CHUNKS + 2)) * GameConfig.TILE_SIZE
	for pickup_variant in active.keys():
		var pickup_id := StringName(pickup_variant)
		var pickup := active.get(pickup_id) as Pickup
		if pickup == null or not is_instance_valid(pickup):
			active.erase(pickup_id)
			drop_ids.erase(pickup_id)
			continue
		if pickup.is_drop and pickup.global_position.x < retire_before:
			_forget_pickup(pickup)
			pickup.retire()

func _materialize_pending() -> void:
	if director == null or streamer == null or director.state != RunDirector.State.RUNNING:
		return
	for anchor_variant in pending.keys():
		var anchor_id := StringName(anchor_variant)
		var identity: Dictionary = pending.get(anchor_id, {})
		if _try_materialize_anchor(anchor_id, identity):
			pending.erase(anchor_id)

func _try_materialize_anchor(anchor_id: StringName, identity: Dictionary) -> bool:
	var epoch := int(identity.get(&"epoch", -1))
	var support_tile_id := StringName(identity.get(&"support_tile_id", &""))
	if epoch <= 0 or not streamer.is_anchor_eligible(anchor_id, epoch, support_tile_id):
		return false
	var key := _consume_key(anchor_id, epoch)
	if consumed.has(key):
		return true
	var anchor := streamer.anchor_registry.get(anchor_id) as SpawnAnchor
	if anchor == null:
		return false
	var surface := streamer.surface_registry.get(anchor.surface_id) as TerrainSurface
	if surface == null or not streamer.is_surface_live(surface):
		return false
	var spawnable := Catalog.spawnable_ids()
	if spawnable.is_empty():
		return true
	var mixed: int = absi(director.seed ^ anchor_id.hash() ^ (epoch * 22695477))
	var collectible_id := spawnable[mixed % spawnable.size()]
	var definition := definitions.get(collectible_id) as Definition
	if definition == null:
		return true
	var position := streamer.world_position_on_surface(surface, anchor.column)
	position.y -= GameConfig.COLLECTIBLE_SPAWN_HEIGHT_TILES * GameConfig.TILE_SIZE
	var pickup_id := StringName("spawn:%s:%d" % [anchor_id, epoch])
	var pickup := _spawn_pickup(definition, pickup_id, position, anchor_id, false)
	if pickup == null:
		return false
	consumed[key] = true
	anchor_to_pickup[anchor_id] = pickup_id
	return true

func _spawn_pickup(definition: Definition, pickup_id: StringName, position: Vector2, anchor_id: StringName, is_drop: bool) -> Pickup:
	if definition == null or active.has(pickup_id):
		return null
	var pickup := Pickup.new()
	if not pickup.configure(definition, pickup_id, anchor_id, is_drop):
		pickup.free()
		return null
	pickup.position = position
	pickup.collected.connect(_on_pickup_collected)
	add_child(pickup)
	active[pickup_id] = pickup
	if is_drop:
		drop_ids[pickup_id] = true
	return pickup

func _on_pickup_collected(pickup: Pickup) -> void:
	if pickup == null or pickup.definition == null or director == null:
		return
	var definition: Definition = pickup.definition
	if definition.kind == Definition.KIND_GOLD:
		director.run.add_earned_gold(definition.gold_value)
	elif definition.kind == Definition.KIND_HEALTH:
		director.apply_heal(definition.heal_amount)
	_forget_pickup(pickup)
	pickup.queue_free()

func _on_enemy_defeated(enemy_id: StringName, enemy_spawn_id: StringName, world_position: Vector2) -> void:
	if director == null or director.state != RunDirector.State.RUNNING:
		return
	var drop_ids_for_enemy := Loot.drops_for(director.seed, enemy_spawn_id, enemy_id)
	var offset_index := 0
	for collectible_id in drop_ids_for_enemy:
		if drop_ids.size() >= GameConfig.MAX_ACTIVE_DROPS:
			break
		var definition := definitions.get(collectible_id) as Definition
		if definition == null or not definition.droppable:
			continue
		var pickup_id := StringName("drop:%s:%s" % [enemy_spawn_id, collectible_id])
		var offset := Vector2(float(offset_index - 1) * 18.0, -24.0)
		_spawn_pickup(definition, pickup_id, world_position + offset, &"", true)
		offset_index += 1

func _forget_pickup(pickup: Pickup) -> void:
	if pickup == null:
		return
	active.erase(pickup.pickup_id)
	drop_ids.erase(pickup.pickup_id)
	if not pickup.anchor_id.is_empty():
		anchor_to_pickup.erase(pickup.anchor_id)

func _on_anchor_added(anchor_id: StringName, surface_id: StringName, support_tile_id: StringName, chunk_index: int, epoch: int) -> void:
	if epoch <= 0:
		return
	var key := _consume_key(anchor_id, epoch)
	if consumed.has(key):
		return
	pending[anchor_id] = {
		&"support_surface_id": surface_id,
		&"support_tile_id": support_tile_id,
		&"chunk_index": chunk_index,
		&"epoch": epoch,
	}

func _on_anchor_invalidated(anchor_id: StringName, _surface_id: StringName, _tile_id: StringName, _chunk_index: int, epoch: int) -> void:
	pending.erase(anchor_id)
	_retire_anchor(anchor_id)
	consumed.erase(_consume_key(anchor_id, epoch))

func _on_anchor_removed(anchor_id: StringName, _surface_id: StringName, _tile_id: StringName, _chunk_index: int, epoch: int) -> void:
	pending.erase(anchor_id)
	_retire_anchor(anchor_id)
	consumed.erase(_consume_key(anchor_id, epoch))

func _retire_anchor(anchor_id: StringName) -> void:
	var pickup_id := StringName(anchor_to_pickup.get(anchor_id, &""))
	var pickup := active.get(pickup_id) as Pickup
	if pickup != null and is_instance_valid(pickup):
		_forget_pickup(pickup)
		pickup.retire()
	else:
		active.erase(pickup_id)
		anchor_to_pickup.erase(anchor_id)

func _consume_key(anchor_id: StringName, epoch: int) -> String:
	return "%s|%d" % [anchor_id, epoch]
