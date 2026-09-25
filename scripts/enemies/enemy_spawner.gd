class_name EnemySpawner
extends Node2D
## Stream-aware deterministic materializer. A blocked live anchor remains
## pending; only a successful materialization consumes its exact anchor epoch.

const Controller = preload("res://scripts/enemies/enemy_controller.gd")
const AnimationLoader = preload("res://scripts/enemies/enemy_animation_loader.gd")
const Definition = preload("res://scripts/enemies/enemy_definition.gd")
const SpawnDescriptor = preload("res://scripts/enemies/enemy_spawn_descriptor.gd")
const EffectSpec = preload("res://scripts/enemies/enemy_effect_spec.gd")
const Catalog = preload("res://scripts/enemies/enemy_catalog.gd")
const Generator = preload("res://scripts/terrain/terrain_generator.gd")

signal enemy_defeated(enemy_id: StringName, enemy_spawn_id: StringName, world_position: Vector2)

var streamer: TerrainStreamer
var target: PlayerController
var director: RunDirector
var camera: Camera2D
var definitions: Array[Definition] = []
var animation_loader := AnimationLoader.new()
var active: Dictionary = {} # descriptor id -> EnemyController
var anchor_to_descriptor: Dictionary = {} # anchor id -> descriptor id
var consumed: Dictionary = {} # anchor id|epoch -> true
var pending: Dictionary = {} # anchor id -> signal identity
var interval_multiplier := GameConfig.DEFAULT_ENEMY_FIRE_RATE
var target_visibility_resolver: Callable = Callable()
var interval_multiplier_resolver: Callable = Callable()

func configure(new_streamer: TerrainStreamer, new_target: PlayerController, new_director: RunDirector, new_camera: Camera2D, new_interval_multiplier: float = GameConfig.DEFAULT_ENEMY_FIRE_RATE, new_target_visibility_resolver: Callable = Callable(), new_interval_multiplier_resolver: Callable = Callable()) -> void:
	streamer = new_streamer
	target = new_target
	director = new_director
	camera = new_camera
	interval_multiplier = clampf(new_interval_multiplier, GameConfig.MIN_ENEMY_FIRE_RATE, GameConfig.MAX_ENEMY_FIRE_RATE)
	target_visibility_resolver = new_target_visibility_resolver
	interval_multiplier_resolver = new_interval_multiplier_resolver
	definitions = Catalog.definitions()
	if streamer == null:
		return
	if not streamer.anchor_added.is_connected(_on_anchor_added):
		streamer.anchor_added.connect(_on_anchor_added)
	if not streamer.anchor_invalidated.is_connected(_on_anchor_invalidated):
		streamer.anchor_invalidated.connect(_on_anchor_invalidated)
	if not streamer.anchor_removed.is_connected(_on_anchor_removed):
		streamer.anchor_removed.connect(_on_anchor_removed)
	for anchor_id: StringName in streamer.anchor_registry.keys():
		var identity := streamer.anchor_identity(anchor_id)
		_on_anchor_added(
			anchor_id,
			StringName(identity.get(&"support_surface_id", &"")),
			StringName(identity.get(&"support_tile_id", &"")),
			int(identity.get(&"chunk_index", 0)),
			int(identity.get(&"epoch", -1))
		)

func _physics_process(delta: float) -> void:
	if director == null or streamer == null:
		return
	_materialize_pending()
	if director.state != RunDirector.State.RUNNING:
		return
	var camera_rect := _camera_rect()
	for id_variant in active.keys():
		var id := StringName(id_variant)
		var enemy := active.get(id) as Controller
		if enemy == null or not is_instance_valid(enemy):
			active.erase(id)
			continue
		var target_visible := _target_is_visible()
		var in_camera := camera_rect.has_point(enemy.global_position)
		var target_in_camera := target_visible and camera_rect.has_point(target.global_position)
		var los := _has_line_of_sight(enemy.global_position, target.global_position) if target_visible else false
		enemy.update_runtime(delta, director.simulation_time, in_camera, target_in_camera, los, target_visible, _current_interval_multiplier())

func _target_is_visible() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target_visibility_resolver.is_valid():
		var resolved: Variant = target_visibility_resolver.call()
		if resolved is bool:
			return bool(resolved)
	return true

func _current_interval_multiplier() -> float:
	var value := interval_multiplier
	if interval_multiplier_resolver.is_valid():
		var resolved: Variant = interval_multiplier_resolver.call()
		if resolved is float or resolved is int:
			value = float(resolved)
	return clampf(value, GameConfig.MIN_ENEMY_FIRE_RATE, GameConfig.MAX_RUNTIME_ENEMY_INTERVAL_MULTIPLIER)

func _materialize_pending() -> void:
	if director == null or director.state != RunDirector.State.RUNNING:
		return
	for anchor_variant in pending.keys():
		if active.size() >= GameConfig.MAX_ACTIVE_ENEMIES:
			return
		var anchor_id := StringName(anchor_variant)
		var identity: Dictionary = pending.get(anchor_id, {})
		if _try_materialize(anchor_id, identity):
			pending.erase(anchor_id)

func _try_materialize(anchor_id: StringName, identity: Dictionary) -> bool:
	var epoch := int(identity.get(&"epoch", -1))
	var support_tile_id := StringName(identity.get(&"support_tile_id", &""))
	if epoch <= 0 or not streamer.is_anchor_eligible(anchor_id, epoch, support_tile_id):
		return false
	var key := _consume_key(anchor_id, epoch)
	if consumed.has(key):
		return true
	var anchor := streamer.anchor_registry.get(anchor_id) as SpawnAnchor
	if anchor == null or anchor.clearance_tiles < GameConfig.ENEMY_REQUIRED_CLEARANCE_TILES:
		return false
	var surface := streamer.surface_registry.get(anchor.surface_id) as TerrainSurface
	if surface == null or not streamer.is_surface_live(surface):
		return false
	var biome_visit: int = Generator.biome_visit_for_column(streamer.snapshot, director.seed, anchor.column)
	var definition: Definition = select_definition(anchor.biome, biome_visit, director.seed, anchor_id)
	if definition == null:
		return true
	var spawn_position := streamer.world_position_on_surface(surface, anchor.column)
	spawn_position.y += (GameConfig.TILE_SIZE - GameConfig.ENEMY_BODY_HEIGHT) * 0.5
	if not _spawn_pose_is_clear(spawn_position):
		return false
	var variant_id := select_variant(definition, director.seed, anchor_id, epoch)
	var descriptor := SpawnDescriptor.new(
		StringName("enemy:%s:%d" % [anchor_id, epoch]),
		GameConfig.ENEMY_CATALOG_VERSION,
		director.seed,
		definition.id,
		int(identity.get(&"chunk_index", anchor.chunk_index)),
		epoch,
		anchor_id,
		anchor.surface_id,
		support_tile_id,
		anchor.column,
		anchor.row,
		anchor.biome,
		biome_visit,
		definition.tier,
		anchor.facing,
		surface.x_begin,
		surface.x_end,
		variant_id
	)
	if not descriptor.is_valid():
		return false
	var enemy := Controller.new()
	if not enemy.configure(definition, descriptor, target, director, camera, self, animation_loader):
		return false
	enemy.position = spawn_position
	add_child(enemy)
	consumed[key] = true
	active[descriptor.id] = enemy
	anchor_to_descriptor[anchor_id] = descriptor.id
	enemy.hit_requested.connect(func(hit: DamageStatus.HitEnvelope) -> void:
		director.apply_hit(hit, director.now())
	)
	enemy.died.connect(_on_enemy_died)
	return true

func _spawn_pose_is_clear(position: Vector2) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(GameConfig.ENEMY_BODY_WIDTH, GameConfig.ENEMY_BODY_HEIGHT)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, position + Vector2(0, -1))
	query.collision_mask = 1 | GameConfig.ENEMY_COLLISION_LAYER
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _camera_rect() -> Rect2:
	if camera == null:
		return Rect2(Vector2(-10000000, -10000000), Vector2(20000000, 20000000))
	var size := camera.get_viewport_rect().size
	return Rect2(camera.global_position - size * 0.5, size)

func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get(&"collider") == target

func _on_enemy_projectile_resolved(projectile, hit_player: bool) -> void:
	if not hit_player or projectile == null or director == null:
		return
	var envelope := projectile.get("hit") as DamageStatus.HitEnvelope
	if envelope != null:
		director.apply_hit(envelope, director.now())

func _on_anchor_added(anchor_id: StringName, surface_id: StringName, support_tile_id: StringName, chunk_index: int, epoch: int) -> void:
	if streamer == null or epoch <= 0:
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
	var id := StringName(anchor_to_descriptor.get(anchor_id, &""))
	var enemy := active.get(id) as Controller
	if enemy != null and is_instance_valid(enemy):
		enemy.retire()
	active.erase(id)
	anchor_to_descriptor.erase(anchor_id)

func _on_enemy_died(enemy: Controller) -> void:
	if enemy == null or enemy.descriptor == null or enemy.definition == null:
		return
	enemy_defeated.emit(enemy.definition.id, enemy.descriptor.id, enemy.global_position)
	active.erase(enemy.descriptor.id)
	anchor_to_descriptor.erase(enemy.descriptor.anchor_id)

func _consume_key(anchor_id: StringName, epoch: int) -> String:
	return "%s|%d" % [anchor_id, epoch]

func select_definition(biome: StringName, biome_visit: int, seed: int, anchor_id: StringName) -> Definition:
	var eligible: Array[Definition] = []
	for definition: Definition in definitions:
		if definition.biome == biome and definition.tier <= biome_visit + 1:
			eligible.append(definition)
	eligible.sort_custom(func(a: Definition, b: Definition) -> bool:
		return a.id < b.id
	)
	if eligible.is_empty():
		return null
	var mixed: int = absi(seed ^ anchor_id.hash() ^ (biome_visit * 1103515245))
	return eligible[mixed % eligible.size()]

func select_variant(definition: Definition, seed: int, anchor_id: StringName, epoch: int) -> StringName:
	if definition == null:
		return &""
	var variants := definition.variant_ids()
	if variants.is_empty():
		return &""
	var mixed: int = absi(seed ^ anchor_id.hash() ^ (epoch * 1664525))
	return variants[mixed % variants.size()]

func example_definitions() -> Array[Definition]:
	var sprite := "res://assets/Enemies/archer-barbarian-mage/Archer Guy/PNG/PNG Sequences/Idle/Idle_000.png"
	var output: Array[Definition] = []
	output.append(_example(&"example_stationary_melee", &"grass", Definition.MOVEMENT_STATIONARY, true, false, 0.7, 1.0, 1.15, sprite, null))
	output.append(_example(&"example_patrol_ranged", &"tundra", Definition.MOVEMENT_PATROL, false, true, 1.0, 1.2, 4.0, sprite, EffectSpec.new(&"freeze", 1.5, 0.0, 0.0, 0.7, &"freeze", &"example_patrol_ranged")))
	output.append(_example(&"example_ranged", &"desert", Definition.MOVEMENT_STATIONARY, false, true, 1.0, 0.85, 5.0, sprite, EffectSpec.new(&"burn", 2.0, 0.5, 2.0, 1.0, &"", &"example_ranged")))
	output.append(_example(&"example_combined", &"fort", Definition.MOVEMENT_PATROL, true, true, 0.8, 1.35, 4.0, sprite, EffectSpec.new(&"blood_loss", 2.0, 0.5, 2.0, 1.0, &"blood", &"example_combined")))
	output[-1].ranged_kind = Definition.RANGED_BEAM
	return output

func _example(id: StringName, biome: StringName, movement: StringName, melee: bool, ranged: bool, melee_interval: float, ranged_interval: float, vicinity: float, sprite: String, effect: EffectSpec) -> Definition:
	var result := Definition.new(id, biome, 1)
	result.maximum_health = 24.0
	result.contact_damage = 7.0
	result.movement_type = movement
	result.movement_speed = 55.0 if movement == Definition.MOVEMENT_PATROL else 0.0
	result.melee_enabled = melee
	result.ranged_enabled = ranged
	result.melee_interval = melee_interval
	result.ranged_interval = ranged_interval
	result.melee_range_tiles = GameConfig.ENEMY_MELEE_RANGE_TILES
	result.vicinity_tiles = vicinity
	result.requires_line_of_sight = ranged
	result.sprite_path = sprite
	result.scene_path = "res://scenes/level.tscn"
	result.effect_spec = effect
	return result
