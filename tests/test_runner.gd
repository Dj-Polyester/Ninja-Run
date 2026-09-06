extends Node

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const PLAYER_SCRIPT := preload("res://src/gameplay/player/player.gd")
const LEVEL_SCENE := preload("res://scenes/level/level.tscn")
const STREAMER_SCRIPT := preload("res://src/gameplay/world/world_streamer.gd")
const BIOME_SEQUENCE_SCRIPT := preload("res://src/gameplay/world/biome_sequence.gd")
const LAYOUT_GENERATOR_SCRIPT := preload("res://src/gameplay/world/procedural_layout_generator.gd")
const TILESET_FACTORY_SCRIPT := preload("res://src/gameplay/world/terrain_tileset_factory.gd")
const DESERT_HAZARD_SCENE := preload("res://scenes/hazards/desert_hazard.tscn")
const FALLING_TILE_SCENE := preload("res://scenes/hazards/falling_tile.tscn")
const SPIKE_HAZARD_SCENE := preload("res://scenes/hazards/spike_hazard.tscn")
const FALLING_TILE_SCRIPT := preload("res://src/gameplay/hazards/falling_tile.gd")
const SPIKE_HAZARD_SCRIPT := preload("res://src/gameplay/hazards/spike_hazard.gd")
const DAMAGE_INFO_SCRIPT := preload("res://src/gameplay/combat/damage_info.gd")
const DAMAGEABLE_CONTRACT_SCRIPT := preload("res://src/gameplay/combat/damageable_contract.gd")
const PLAYER_PROFILE_SCRIPT := preload("res://src/core/player_profile.gd")
const STAT_DATA_SCRIPT := preload("res://src/data/stat_data.gd")
const STAT_CATALOG_SCRIPT := preload("res://src/data/stat_catalog.gd")
const STAT_UPGRADE_SERVICE_SCRIPT := preload("res://src/gameplay/progression/stat_upgrade_service.gd")

var failures: Array[String] = []
var passed := 0

func _ready() -> void:
	await _run()

func _run() -> void:
	test_config_values_are_valid()
	test_game_state_reset_is_seeded()
	test_input_actions_configured()
	test_phase1_assets_exist()
	test_level_scene_has_phase1_architecture()
	test_biome_data_is_valid()
	test_first_biomes_are_ordered()
	test_biome_changes_after_interval()
	test_later_biomes_are_seeded_random_without_immediate_repeat()
	test_seed_reproduces_biome_sequence()
	test_world_streamer_is_deterministic()
	test_generated_platform_specs_are_reachable()
	test_all_geometry_archetypes_generate_reachable_routes()
	test_generator_respects_biome_boundaries()
	test_long_generator_smoke_is_reachable_and_deterministic()
	test_optional_routes_expose_bonus_spawn_slots()
	test_tileset_uses_required_atlas_and_collisions()
	await test_world_streamer_generates_ahead()
	await test_world_streamer_cleans_behind()
	await test_player_auto_run_speed()
	await test_player_jump_limit()
	await test_roll_changes_hitbox()
	await test_roll_duration_restores_hitbox()
	await test_animation_state_selection()
	await test_common_damage_contract()
	await test_damage_applies_defense()
	await test_damage_invulnerability_window()
	await test_damage_flashes_red()
	await test_fall_sets_health_zero()
	await test_camera_tracks_x_only()
	await test_level_advances_distance()
	await test_zero_health_triggers_countdown()
	await test_stuck_player_triggers_countdown()
	await test_safe_checkpoint_tracks_stable_progress()
	await test_revive_consumes_potion()
	await test_revive_restores_checkpoint()
	await test_countdown_without_potion_ends_run()
	await test_stuck_detection_is_suspended_during_revival()
	test_profile_defaults_cover_phase5_progression()
	test_profile_and_run_state_are_separate()
	await test_run_state_is_not_persisted()
	await test_save_profile_round_trip()
	test_missing_save_creates_defaults()
	test_corrupted_save_creates_defaults()
	test_unsupported_save_version_creates_defaults()
	test_legacy_v1_profile_backfills_phase5_defaults()
	test_stat_definitions_are_valid()
	test_stat_values_follow_levels()
	test_upgrade_costs_gold()
	test_each_stat_upgrade_uses_definition()
	test_upgrade_requires_enough_gold_is_atomic()
	test_unknown_stat_upgrade_is_atomic()
	test_upgrade_clamped_to_maximum()
	test_decreasing_stat_clamped_to_minimum()
	test_locked_stat_cannot_upgrade()
	test_stat_levels_sanitize_to_limits()
	await test_runtime_player_uses_upgraded_stats()
	test_run_health_uses_upgraded_maximum_health()
	test_phase3_biome_metadata()
	test_snow_modifier_is_seeded_and_bounded()
	test_snow_generator_uses_effective_jump()
	await test_snow_changes_player_jump_temporarily()
	await test_desert_hazard_damage_and_burn()
	await test_astro_falling_tile_sequence()
	await test_astro_chain_fall_uses_support_links()
	await test_fort_spike_damage_only_when_exposed()
	await test_fort_spike_cycles_states()
	await test_streamer_spawns_phase3_hazards()
	await test_all_astro_terrain_uses_falling_tiles()
	await test_hazard_placement_is_seeded()
	await test_streamer_cleans_runtime_hazards()
	await test_level_applies_biome_context()

	print("\nPhase 1+2+3+4+5+6 assertions: %d passed, %d failed" % [passed, failures.size()])
	for failure in failures:
		printerr("FAIL: %s" % failure)
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func test_config_values_are_valid() -> void:
	_expect(GameConfig.SPEED > 0.0, "SPEED must be positive")
	_expect(GameConfig.MAX_JUMP > 0.0, "MAX_JUMP must be positive")
	_expect(GameConfig.ROLL_DURATION > 0.0, "ROLL_DURATION must be positive")
	_expect(GameConfig.TILE_SIZE > 0.0, "TILE_SIZE must be positive")
	_expect(GameConfig.PLATFORM_MAX_GAP > 0, "platform gaps must be positive")
	_expect(GameConfig.CHUNK_MIN_SPAN > 0, "minimum chunk span must be positive")
	_expect(GameConfig.CHUNK_MAX_SPAN >= GameConfig.CHUNK_MIN_SPAN, "chunk span range must be ordered")
	_expect(GameConfig.BIOME_INTERVAL > GameConfig.CHUNK_MIN_SPAN, "biome interval must fit procedural chunks")
	_expect(GameConfig.GAME_OVER_NUMBER_OF_SECS > 0.0, "stuck game-over delay must be positive")
	_expect(GameConfig.COUNTDOWN_SECS > 0.0, "revival countdown must be positive")
	_expect(GameConfig.STUCK_PROGRESS_THRESHOLD > 0.0, "stuck progress threshold must be positive")
	_expect(GameConfig.SAFE_CHECKPOINT_INTERVAL_TILES > 0.0, "safe checkpoint interval must be positive")

func test_game_state_reset_is_seeded() -> void:
	GameState.reset_run(4242)
	_expect(int(GameState.run.seed) == 4242, "reset_run must preserve an injected seed")
	_expect(int(GameState.run.distance_tiles) == 0, "new runs start at zero distance")
	_expect(not bool(GameState.run.game_over), "new runs must not start game-over")

func test_input_actions_configured() -> void:
	_expect(InputMap.has_action("jump"), "jump input action must exist")
	_expect(InputMap.has_action("roll"), "roll input action must exist")
	_expect(not InputMap.action_get_events("jump").is_empty(), "jump input action must have a key binding")
	_expect(not InputMap.action_get_events("roll").is_empty(), "roll input action must have a key binding")
	_expect(_action_has_physical_key("jump", KEY_UP), "jump must be mapped to the physical Up arrow key")
	_expect(_action_has_physical_key("roll", KEY_DOWN), "roll must be mapped to the physical Down arrow key")

func test_phase1_assets_exist() -> void:
	const TERRAIN_PATH := "res://assets/Spritesheets/spritesheet-tiles-double.png"
	_expect(FileAccess.file_exists(TERRAIN_PATH), "required terrain spritesheet must exist")
	_expect(_png_decodes(TERRAIN_PATH), "required terrain spritesheet must decode as an image")
	var base := "res://assets/Characters/1/Png/Character Sprite"
	for folder in ["Fast Run", "Jump Before", "Fall", "Roll", "Dead"]:
		var files := DirAccess.get_files_at(base.path_join(folder))
		var png_count := 0
		var representative_path := ""
		for file_name in files:
			if file_name.to_lower().ends_with(".png"):
				png_count += 1
				if representative_path.is_empty():
					representative_path = base.path_join(folder).path_join(file_name)
		_expect(png_count > 0, "character animation folder '%s' must contain PNG frames" % folder)
		if not representative_path.is_empty():
			_expect(_png_decodes(representative_path), "character animation '%s' must decode as an image" % folder)

func test_level_scene_has_phase1_architecture() -> void:
	var level = LEVEL_SCENE.instantiate()
	for path in ["WorldStreamer", "Player", "EnemyContainer", "ProjectileContainer", "PickupContainer", "Effects", "Camera2D", "HUD"]:
		_expect(level.has_node(path), "level scene must provide '%s'" % path)
	level.free()

func test_biome_data_is_valid() -> void:
	_expect(BiomeCatalog.ORDERED.size() == 6, "Phase 2 must define exactly the six requested initial biomes")
	var expected_names := ["Grass", "Tundra", "Snow", "Desert", "Astro", "Fort"]
	for index in BiomeCatalog.ORDERED.size():
		var biome: BiomeData = BiomeCatalog.ORDERED[index]
		_expect(biome.id == index, "biome id must match its catalog order for %s" % expected_names[index])
		_expect(biome.display_name == expected_names[index], "biome name must match the requested sequence at index %d" % index)
		_expect(biome.total_layout_weight() > 0.0, "%s must define positive layout weights" % biome.display_name)
		for key in LAYOUT_GENERATOR_SCRIPT.ARCHETYPE_NAMES.values():
			_expect(float(biome.layout_weights.get(key, 0.0)) >= 0.0, "%s layout weight '%s' must be non-negative" % [biome.display_name, key])

func test_first_biomes_are_ordered() -> void:
	var sequence = BIOME_SEQUENCE_SCRIPT.new(12345)
	var expected := [
		BiomeData.Id.GRASS,
		BiomeData.Id.TUNDRA,
		BiomeData.Id.SNOW,
		BiomeData.Id.DESERT,
		BiomeData.Id.ASTRO,
		BiomeData.Id.FORT,
	]
	for index in expected.size():
		var tile_x := index * GameConfig.BIOME_INTERVAL
		_expect(sequence.get_biome_id_for_tile(tile_x) == expected[index], "initial biome encounter %d must use the required order" % index)

func test_biome_changes_after_interval() -> void:
	var sequence = BIOME_SEQUENCE_SCRIPT.new(7)
	for index in 5:
		var start := index * GameConfig.BIOME_INTERVAL
		var end := start + GameConfig.BIOME_INTERVAL - 1
		_expect(sequence.get_biome_id_for_tile(start) == sequence.get_biome_id_for_tile(end), "a biome must remain stable for the full BIOME_INTERVAL")
		_expect(sequence.get_biome_id_for_tile(end) != sequence.get_biome_id_for_tile(end + 1), "the first traversal must change biome exactly at BIOME_INTERVAL")

func test_later_biomes_are_seeded_random_without_immediate_repeat() -> void:
	var first = BIOME_SEQUENCE_SCRIPT.new(101)
	var second = BIOME_SEQUENCE_SCRIPT.new(202)
	var first_random: Array[int] = []
	var second_random: Array[int] = []
	for encounter in range(6, 30):
		var tile_x := encounter * GameConfig.BIOME_INTERVAL
		var first_id: int = first.get_biome_id_for_tile(tile_x)
		var second_id: int = second.get_biome_id_for_tile(tile_x)
		first_random.append(first_id)
		second_random.append(second_id)
		var previous_id := first.get_biome_id_for_tile(tile_x - GameConfig.BIOME_INTERVAL)
		_expect(first_id != previous_id, "random biome phase must not immediately repeat the previous biome")
	_expect(first_random != second_random, "different run seeds must produce different post-traversal biome sequences")

func test_seed_reproduces_biome_sequence() -> void:
	var first = BIOME_SEQUENCE_SCRIPT.new(424242)
	var second = BIOME_SEQUENCE_SCRIPT.new(424242)
	for encounter in 40:
		var tile_x := encounter * GameConfig.BIOME_INTERVAL
		_expect(first.get_biome_id_for_tile(tile_x) == second.get_biome_id_for_tile(tile_x), "same seed must reproduce biome encounter %d" % encounter)

func test_world_streamer_is_deterministic() -> void:
	var first = LAYOUT_GENERATOR_SCRIPT.new()
	var second = LAYOUT_GENERATOR_SCRIPT.new()
	first.reset(77)
	second.reset(77)
	var sequence = BIOME_SEQUENCE_SCRIPT.new(77)
	for _index in 20:
		var biome := sequence.get_biome_for_tile(first.generated_until_tile)
		var end_tile := sequence.get_encounter_end_tile(first.generated_until_tile)
		_expect(first.next_chunk(biome, end_tile) == second.next_chunk(biome, end_tile), "same seed must produce the same chunk specs")

func test_generated_platform_specs_are_reachable() -> void:
	var streamer = STREAMER_SCRIPT.new()
	streamer.rng.seed = 2468
	streamer.generated_until_tile = GameConfig.START_PLATFORM_START_TILE + GameConfig.START_PLATFORM_WIDTH
	streamer.current_height_tile = GameConfig.BASE_PLATFORM_HEIGHT
	var jump_speed := sqrt(2.0 * GameConfig.GRAVITY * GameConfig.tiles_to_pixels(GameConfig.MAX_JUMP))
	for _index in 100:
		var spec: Dictionary = streamer.next_platform_spec()
		var height_step := int(spec.height_step)
		var upward_displacement := -float(height_step) * GameConfig.TILE_SIZE
		var discriminant := jump_speed * jump_speed - 2.0 * GameConfig.GRAVITY * upward_displacement
		_expect(discriminant >= 0.0, "generated platform height must be vertically reachable")
		if discriminant >= 0.0:
			var landing_time := (jump_speed + sqrt(discriminant)) / GameConfig.GRAVITY
			var reachable_gap_tiles := GameConfig.SPEED * landing_time
			_expect(float(spec.gap_tiles) <= reachable_gap_tiles, "generated gap must be reachable at SPEED/MAX_JUMP")
		streamer.generated_until_tile = int(spec.start_tile) + int(spec.width_tiles)
	streamer.free()

func test_all_geometry_archetypes_generate_reachable_routes() -> void:
	var biome: BiomeData = BiomeCatalog.GRASS
	for archetype in LAYOUT_GENERATOR_SCRIPT.Archetype.size():
		var generator = LAYOUT_GENERATOR_SCRIPT.new()
		generator.reset(9000 + archetype)
		generator.generated_until_tile = 0
		generator.current_height_tile = GameConfig.BASE_PLATFORM_HEIGHT
		var spec: Dictionary = generator.next_chunk(biome, GameConfig.CHUNK_MAX_SPAN, archetype)
		_expect(int(spec.archetype) == archetype, "forced geometry archetype %d must be generated" % archetype)
		var mandatory: Array[Dictionary] = _mandatory_segments(spec)
		_expect(not mandatory.is_empty(), "geometry archetype %d must provide a mandatory route" % archetype)
		for index in range(1, mandatory.size()):
			_expect(generator.is_transition_reachable(mandatory[index - 1], mandatory[index]), "mandatory route in archetype %d must be physically reachable" % archetype)

func test_generator_respects_biome_boundaries() -> void:
	var sequence = BIOME_SEQUENCE_SCRIPT.new(31337)
	var generator = LAYOUT_GENERATOR_SCRIPT.new()
	generator.reset(31337)
	for _index in 80:
		var start_tile: int = generator.generated_until_tile
		var biome := sequence.get_biome_for_tile(start_tile)
		var biome_end := sequence.get_encounter_end_tile(start_tile)
		var spec: Dictionary = generator.next_chunk(biome, biome_end)
		_expect(int(spec.start_tile) >= start_tile, "generated chunk must not move backward")
		_expect(int(spec.end_tile) <= biome_end, "generated chunk must not cross a biome boundary")
		_expect(int(spec.biome_id) == biome.id, "chunk biome metadata must match its sequence assignment")

func test_long_generator_smoke_is_reachable_and_deterministic() -> void:
	for seed_value in range(16):
		var sequence = BIOME_SEQUENCE_SCRIPT.new(seed_value)
		var first = LAYOUT_GENERATOR_SCRIPT.new()
		var second = LAYOUT_GENERATOR_SCRIPT.new()
		first.reset(seed_value)
		second.reset(seed_value)
		var previous: Dictionary = {
			"start_tile": GameConfig.START_PLATFORM_START_TILE,
			"width_tiles": GameConfig.START_PLATFORM_WIDTH,
			"height_tile": GameConfig.BASE_PLATFORM_HEIGHT,
		}
		while first.generated_until_tile < 1000:
			var biome := sequence.get_biome_for_tile(first.generated_until_tile)
			var biome_end := sequence.get_encounter_end_tile(first.generated_until_tile)
			var first_spec: Dictionary = first.next_chunk(biome, biome_end)
			var second_spec: Dictionary = second.next_chunk(biome, biome_end)
			_expect(first_spec == second_spec, "generator must stay deterministic through long seed %d runs" % seed_value)
			var mandatory: Array[Dictionary] = _mandatory_segments(first_spec)
			for segment in mandatory:
				_expect(first.is_transition_reachable(previous, segment), "seed %d generated an unreachable mandatory transition near tile %d" % [seed_value, int(segment.start_tile)])
				previous = segment

func test_optional_routes_expose_bonus_spawn_slots() -> void:
	var found_optional := false
	for seed_value in 64:
		var generator = LAYOUT_GENERATOR_SCRIPT.new()
		generator.reset(seed_value)
		generator.generated_until_tile = 0
		var spec: Dictionary = generator.next_chunk(BiomeCatalog.ASTRO, GameConfig.CHUNK_MAX_SPAN, LAYOUT_GENERATOR_SCRIPT.Archetype.STACKED_PLATFORMS)
		if not spec.bonus_spawn_tiles.is_empty():
			found_optional = true
			for spawn_tile in spec.bonus_spawn_tiles:
				_expect(spawn_tile is Vector2i, "optional-route bonus spawn metadata must use tile coordinates")
			break
	_expect(found_optional, "at least one risky/stacked route must expose a bonus collectible spawn slot")

func test_tileset_uses_required_atlas_and_collisions() -> void:
	_expect(FileAccess.file_exists(TILESET_FACTORY_SCRIPT.TERRAIN_TEXTURE_PATH), "TileSet factory must point at the supplied double terrain spritesheet")
	var tile_set: TileSet = TILESET_FACTORY_SCRIPT.build()
	_expect(tile_set.get_terrain_sets_count() == 1, "terrain TileSet must define one biome terrain set")
	_expect(tile_set.get_terrains_count(0) == 6, "terrain TileSet must define all six biome terrains")
	_expect(tile_set.has_source(TILESET_FACTORY_SCRIPT.SOURCE_ID), "terrain TileSet must define its atlas source")
	var source := tile_set.get_source(TILESET_FACTORY_SCRIPT.SOURCE_ID) as TileSetAtlasSource
	_expect(source != null, "terrain source must be a TileSetAtlasSource")
	if source == null:
		return
	_expect(source.texture != null and source.texture.get_size() == Vector2(2321, 2321), "TileSet must use the 2321x2321 supplied double atlas")
	_expect(source.texture_region_size == Vector2i(128, 128), "terrain atlas must use 128x128 source cells")
	_expect(source.separation == Vector2i.ONE, "terrain atlas must account for the one-pixel spritesheet separation")
	for biome in BiomeCatalog.ORDERED:
		for coords in [biome.terrain_top_atlas, biome.terrain_center_atlas, biome.terrain_left_atlas, biome.terrain_middle_atlas, biome.terrain_right_atlas]:
			_expect(source.has_tile(coords), "%s terrain atlas coordinate %s must exist" % [biome.display_name, coords])
			if source.has_tile(coords):
				var tile_data := source.get_tile_data(coords, 0)
				_expect(tile_data != null and tile_data.get_collision_polygons_count(0) > 0, "%s terrain tile %s must carry collision" % [biome.display_name, coords])
		_expect(source.get_alternative_tiles_count(biome.terrain_middle_atlas) > 1, "%s must expose an alternative terrain tile" % biome.display_name)

func test_world_streamer_generates_ahead() -> void:
	var streamer = STREAMER_SCRIPT.new()
	add_child(streamer)
	streamer.reset(99)
	await get_tree().process_frame
	_expect(streamer.generated_until_tile >= GameConfig.GENERATION_DISTANCE_AHEAD, "streamer must generate ahead of the player")
	_expect(streamer.terrain_layer is TileMapLayer, "streamer must render static terrain through TileMapLayer")
	_expect(not streamer.terrain_layer.get_used_cells().is_empty(), "streamer TileMapLayer must contain generated terrain cells")
	_expect(streamer.active_chunks.size() > 1, "streamer must retain multiple generated chunk specs ahead of the player")
	await _free_node(streamer)

func test_world_streamer_cleans_behind() -> void:
	var streamer = STREAMER_SCRIPT.new()
	add_child(streamer)
	streamer.reset(123)
	streamer.update_for_player(GameConfig.tiles_to_pixels(100.0))
	await get_tree().process_frame
	var cutoff := 100 - GameConfig.CLEANUP_DISTANCE_BEHIND
	var retained_old_chunk := false
	for spec in streamer.active_chunks:
		if int(spec.end_tile) < cutoff:
			retained_old_chunk = true
	_expect(not retained_old_chunk, "streamer must release chunks behind the cleanup distance")
	_expect(streamer.terrain_layer.get_cell_source_id(Vector2i(0, GameConfig.BASE_PLATFORM_HEIGHT)) == -1, "streamer must erase old terrain cells behind the player")
	_expect(streamer.active_chunks.size() < 16, "streamer retained chunk count must stay bounded")
	await _free_node(streamer)

func test_player_auto_run_speed() -> void:
	var player = await _spawn_player()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(
		is_equal_approx(player.velocity.x, player.run_speed_pixels()),
		"player horizontal velocity must be forced to SPEED (actual %.3f, expected %.3f)" % [player.velocity.x, player.run_speed_pixels()]
	)
	await _free_node(player)

func test_player_jump_limit() -> void:
	var setup := await _spawn_grounded_player()
	var player = setup.player
	player.trigger_jump()
	_expect(player.velocity.y < 0.0, "grounded jump must apply upward velocity")
	var first_velocity: float = player.velocity.y
	player.trigger_jump()
	_expect(is_equal_approx(player.velocity.y, first_velocity), "Phase 1 jump must not allow an air jump")
	await _free_node(setup.root)

func test_roll_changes_hitbox() -> void:
	var setup := await _spawn_grounded_player()
	var player = setup.player
	player.trigger_roll()
	_expect(player.state == PLAYER_SCRIPT.State.ROLLING, "roll input must enter ROLLING state")
	_expect(player.standing_collision.disabled, "standing hitbox must disable during roll")
	_expect(not player.rolling_collision.disabled, "short hitbox must enable during roll")
	await _free_node(setup.root)

func test_roll_duration_restores_hitbox() -> void:
	var setup := await _spawn_grounded_player()
	var player = setup.player
	player.trigger_roll()
	var elapsed := 0.0
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	while elapsed <= GameConfig.ROLL_DURATION + 0.1:
		await get_tree().physics_frame
		elapsed += tick
	_expect(player.state != PLAYER_SCRIPT.State.ROLLING, "roll must finish after ROLL_DURATION")
	_expect(not player.standing_collision.disabled and player.rolling_collision.disabled, "standing hitbox must be restored after roll")
	await _free_node(setup.root)

func test_animation_state_selection() -> void:
	var setup := await _spawn_grounded_player()
	var player = setup.player
	_expect(player.sprite.animation == &"run", "grounded automatic movement must select the run animation")
	player.trigger_jump()
	_expect(player.sprite.animation == &"jump", "jumping must select the jump animation")
	await _free_node(setup.root)

	setup = await _spawn_grounded_player()
	player = setup.player
	player.trigger_roll()
	_expect(player.sprite.animation == &"roll", "rolling must select the roll animation")
	player.global_position.y = GameConfig.KILL_PLANE_Y + 10.0
	await get_tree().physics_frame
	_expect(player.sprite.animation == &"dead", "death must select the dead animation")
	await _free_node(setup.root)

func test_common_damage_contract() -> void:
	var player = await _spawn_player()
	_expect(DAMAGEABLE_CONTRACT_SCRIPT.supports(player), "player must expose the common take_damage/heal/apply_status/die contract")
	var before_health: float = player.current_health
	var before_velocity: Vector2 = player.velocity
	var knockback := Vector2(13.0, -27.0)
	var damage_info = DAMAGE_INFO_SCRIPT.new(
		player,
		DAMAGE_INFO_SCRIPT.DamageType.FIRE,
		{"id": &"burn", "duration": 0.75},
		knockback
	)
	player.take_damage(5.0, damage_info)
	_expect(player.last_damage_info == damage_info, "damageable targets must receive the shared DamageInfo object")
	_expect(damage_info.source == player, "DamageInfo must retain its damage source")
	_expect(damage_info.damage_type == DAMAGE_INFO_SCRIPT.DamageType.FIRE, "DamageInfo must retain its damage type")
	_expect(player.status_remaining(&"burn") > 0.0, "DamageInfo status payload must be applied by the common damage path")
	_expect(player.velocity == before_velocity + knockback, "DamageInfo knockback must be applied by the common damage path")
	_expect(is_equal_approx(player.current_health, before_health - 5.0), "common damage path must still reduce health")
	await _free_node(player)

func test_damage_applies_defense() -> void:
	GameState.reset_profile()
	GameState.profile.stat_levels.defense_multiplier = STAT_CATALOG_SCRIPT.DEFENSE_MULTIPLIER.max_level()
	var player = await _spawn_player(false)
	var before: float = player.current_health
	player.take_damage(20.0)
	_expect(is_equal_approx(player.current_health, before - 10.0), "damage must be multiplied by defense_multiplier")
	await _free_node(player)

func test_damage_invulnerability_window() -> void:
	var player = await _spawn_player()
	var initial_health: float = player.current_health
	player.take_damage(10.0)
	player.take_damage(10.0)
	_expect(is_equal_approx(player.current_health, initial_health - 10.0), "damage received inside the invulnerability window must be ignored")
	var elapsed := 0.0
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	while elapsed <= GameConfig.DAMAGE_INVULNERABILITY + tick:
		await get_tree().physics_frame
		elapsed += tick
	player.take_damage(10.0)
	_expect(is_equal_approx(player.current_health, initial_health - 20.0), "damage must apply again after the invulnerability window expires")
	await _free_node(player)

func test_damage_flashes_red() -> void:
	var player = await _spawn_player()
	player.take_damage(1.0)
	_expect(player.sprite.modulate.r > player.sprite.modulate.g, "taking damage must flash the player red")
	var elapsed := 0.0
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	while elapsed <= GameConfig.DAMAGE_FLASH_DURATION + 0.05:
		await get_tree().physics_frame
		elapsed += tick
	_expect(player.sprite.modulate == Color.WHITE, "damage flash must clear after DAMAGE_FLASH_DURATION")
	await _free_node(player)

func test_fall_sets_health_zero() -> void:
	var player = await _spawn_player()
	player.global_position.y = GameConfig.KILL_PLANE_Y + 10.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(is_zero_approx(player.current_health), "falling below the kill plane must set health to zero")
	_expect(player.state == PLAYER_SCRIPT.State.DEAD, "falling below the kill plane must kill the player")
	await _free_node(player)

func test_camera_tracks_x_only() -> void:
	var level = LEVEL_SCENE.instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player = level.get_node("Player")
	var camera: Camera2D = level.get_node("Camera2D")
	var expected_x: float = player.global_position.x + GameConfig.tiles_to_pixels(GameConfig.CAMERA_LOOK_AHEAD)
	_expect(is_equal_approx(camera.global_position.x, expected_x), "camera must track player X with configured look-ahead")
	_expect(is_equal_approx(camera.global_position.y, 360.0), "camera Y must remain stable during the runner loop")
	await _free_node(level)

func test_level_advances_distance() -> void:
	var level = LEVEL_SCENE.instantiate()
	add_child(level)
	await get_tree().process_frame
	var player = level.get_node("Player")
	var start_x: float = player.global_position.x
	for _index in 20:
		await get_tree().physics_frame
	_expect(player.global_position.x > start_x, "the level player must make automatic horizontal progress")
	_expect(int(GameState.run.distance_tiles) >= 1, "automatic progress must update run distance in tiles")
	await _free_node(level)

func test_zero_health_triggers_countdown() -> void:
	GameState.reset_profile()
	GameState.profile.revival_potions = 1
	var level = LEVEL_SCENE.instantiate()
	add_child(level)
	await get_tree().process_frame
	var player = level.get_node("Player")
	player.take_damage(player.maximum_health)
	_expect(bool(level.game_over_active), "zero health must halt the active runner loop")
	_expect(bool(level.revival_active), "zero health must enter the revival countdown")
	_expect(player.state == PLAYER_SCRIPT.State.REVIVAL_WAIT, "death must transition the player into REVIVAL_WAIT while the countdown is active")
	_expect(not bool(GameState.run.game_over), "the run must not become final game-over until the revival countdown expires")
	_expect(bool(GameState.run.revival_active), "GameState must expose an active revival countdown")
	_expect(is_equal_approx(float(GameState.run.revival_countdown), GameConfig.COUNTDOWN_SECS), "revival countdown must start at COUNTDOWN_SECS")
	_expect(level.get_node("HUD/GameOverPanel").visible, "death must show the revival/game-over panel")
	_expect(level.get_node("HUD/GameOverPanel/VBoxContainer/ReviveButton").visible, "revival potion button must be visible when inventory is positive")
	_expect(level.get_node("WorldStreamer").process_mode == Node.PROCESS_MODE_DISABLED, "world gameplay must halt during revival")
	await _free_node(level)

func test_stuck_player_triggers_countdown() -> void:
	GameState.reset_profile()
	var level = LEVEL_SCENE.instantiate()
	add_child(level)
	await get_tree().process_frame
	var player = level.get_node("Player")
	level.last_progress_x = player.global_position.x
	level.stuck_elapsed = 0.0
	level._update_stuck_detection(GameConfig.GAME_OVER_NUMBER_OF_SECS + 0.01)
	_expect(bool(level.revival_active), "lack of horizontal progress for GAME_OVER_NUMBER_OF_SECS must trigger revival")
	_expect(String(GameState.run.death_reason) == "stuck", "stuck detection must report the stuck death reason")
	_expect(is_zero_approx(player.current_health), "stuck detection must enter the same zero-health death path")
	await _free_node(level)

func test_safe_checkpoint_tracks_stable_progress() -> void:
	GameState.reset_profile()
	var level = LEVEL_SCENE.instantiate()
	add_child(level)
	await get_tree().process_frame
	var initial_tile: int = int(level.safe_checkpoint.tile_index)
	for _index in 75:
		await get_tree().physics_frame
	_expect(bool(level.safe_checkpoint.valid), "level must always retain a valid safe checkpoint")
	_expect(int(level.safe_checkpoint.tile_index) > initial_tile, "stable grounded progress must advance the safe checkpoint")
	var stored: Dictionary = GameState.run.get("safe_checkpoint", {})
	_expect(bool(stored.get("valid", false)), "safe checkpoint must be mirrored into RunState")
	_expect(int(stored.get("tile_index", -1)) == int(level.safe_checkpoint.tile_index), "RunState checkpoint tile must match the level checkpoint")
	await _free_node(level)

func test_revive_consumes_potion() -> void:
	GameState.reset_profile()
	GameState.profile.revival_potions = 2
	var level = LEVEL_SCENE.instantiate()
	add_child(level)
	await get_tree().process_frame
	var player = level.get_node("Player")
	player.die("damage")
	level._on_revive_pressed()
	_expect(GameState.revival_potion_count() == 1, "successful revival must consume exactly one revival potion")
	_expect(not bool(level.revival_active), "successful revival must close the revival countdown")
	_expect(not bool(level.game_over_active), "successful revival must resume the active run")
	_expect(not bool(GameState.run.game_over), "successful revival must keep the run alive")
	_expect(level.get_node("WorldStreamer").process_mode == Node.PROCESS_MODE_INHERIT, "successful revival must resume world gameplay")
	await _free_node(level)

func test_revive_restores_checkpoint() -> void:
	GameState.reset_profile()
	GameState.profile.revival_potions = 1
	var level = LEVEL_SCENE.instantiate()
	add_child(level)
	await get_tree().process_frame
	var player = level.get_node("Player")
	var checkpoint_position: Vector2 = player.global_position + Vector2(48.0, -16.0)
	var checkpoint_tile: int = floori(GameConfig.pixels_to_tiles(checkpoint_position.x))
	level._capture_checkpoint(checkpoint_position, checkpoint_tile)
	player.apply_status({"id": &"burn", "duration": 5.0})
	player.global_position += Vector2(300.0, 120.0)
	player.die("damage")
	level._on_revive_pressed()
	_expect(player.global_position == checkpoint_position, "revival must teleport the player to the last safe checkpoint")
	_expect(is_equal_approx(player.current_health, player.maximum_health), "revival must restore player health")
	_expect(player.active_statuses.is_empty(), "revival must clear lethal/temporary statuses")
	_expect(player.invulnerability_remaining >= GameConfig.REVIVE_INVULNERABILITY, "revival must grant a short protection window")
	_expect(player.state == PLAYER_SCRIPT.State.FALLING, "revived player must return to a live movement state")
	_expect(not level.get_node("HUD/GameOverPanel").visible, "revival must hide the countdown panel")
	await _free_node(level)

func test_countdown_without_potion_ends_run() -> void:
	GameState.reset_profile()
	GameState.profile.revival_potions = 0
	var level = LEVEL_SCENE.instantiate()
	add_child(level)
	await get_tree().process_frame
	var player = level.get_node("Player")
	player.die("damage")
	var revive_button: Button = level.get_node("HUD/GameOverPanel/VBoxContainer/ReviveButton")
	_expect(not revive_button.visible, "revival button must be hidden when no potion is available")
	level._process(GameConfig.COUNTDOWN_SECS + 0.01)
	_expect(bool(level.final_game_over), "expired revival countdown must transition to final game-over")
	_expect(not bool(level.revival_active), "final game-over must end the revival window")
	_expect(bool(GameState.run.game_over), "expired countdown without revival must end the run")
	_expect(level.get_node("HUD/GameOverPanel/VBoxContainer/Title").text == "GAME OVER", "expired countdown must show final game-over UI")
	await _free_node(level)

func test_stuck_detection_is_suspended_during_revival() -> void:
	GameState.reset_profile()
	var level = LEVEL_SCENE.instantiate()
	add_child(level)
	await get_tree().process_frame
	var player = level.get_node("Player")
	player.die("damage")
	level.stuck_elapsed = 1.25
	level._physics_process(GameConfig.GAME_OVER_NUMBER_OF_SECS * 2.0)
	_expect(is_equal_approx(level.stuck_elapsed, 1.25), "stuck detection must not advance while revival/game-over processing has halted the run")
	await _free_node(level)

func test_profile_defaults_cover_phase5_progression() -> void:
	GameState.reset_profile()
	var required_keys := [
		"save_version",
		"gold",
		"unlocked_characters",
		"selected_character",
		"stat_levels",
		"unlocked_abilities",
		"equipped_abilities",
		"ability_levels",
		"unlocked_weapons",
		"equipped_weapons",
		"consumables",
		"settings",
	]
	for key in required_keys:
		_expect(GameState.profile.has(key), "Phase 5 profile must define '%s'" % key)
	_expect(int(GameState.profile.save_version) == PLAYER_PROFILE_SCRIPT.CURRENT_SAVE_VERSION, "default profile must use the current save version")
	_expect(int(GameState.profile.gold) == 0, "new profiles must start with zero gold")
	_expect(GameState.profile.unlocked_characters == [PLAYER_PROFILE_SCRIPT.DEFAULT_CHARACTER_ID], "default character must start unlocked")
	_expect(int(GameState.profile.selected_character) == PLAYER_PROFILE_SCRIPT.DEFAULT_CHARACTER_ID, "default character must start selected")
	_expect(GameState.profile.unlocked_abilities == [PLAYER_PROFILE_SCRIPT.DEFAULT_ABILITY_ID], "Jump must be the default unlocked ability")
	_expect(GameState.profile.equipped_abilities == [PLAYER_PROFILE_SCRIPT.DEFAULT_ABILITY_ID], "Jump must be equipped by default")
	_expect(GameState.profile.unlocked_weapons.is_empty() and GameState.profile.equipped_weapons.is_empty(), "weapons must begin locked/unequipped")
	_expect(GameState.revival_potion_count() == 1, "default consumables must include one revival potion")
	_expect(String(GameState.profile.settings.action_button_side) == PLAYER_PROFILE_SCRIPT.ACTION_BUTTON_SIDE_RIGHT, "mobile action buttons must default to the right side")

func test_profile_and_run_state_are_separate() -> void:
	GameState.reset_profile()
	GameState.profile.gold = 37
	GameState.reset_run(9191)
	GameState.set_distance_tiles(42)
	GameState.set_current_biome(BiomeData.Id.DESERT)
	GameState.set_temporary_effect(&"test_effect", {"duration": 1.5})
	GameState.set_safe_checkpoint({"valid": true, "tile_index": 39})
	_expect(int(GameState.run.seed) == 9191, "RunState must retain the injected run seed")
	_expect(int(GameState.run.distance_tiles) == 42, "RunState must own horizontal run distance")
	_expect(int(GameState.run.current_biome) == BiomeData.Id.DESERT, "RunState must own current biome")
	_expect(GameState.run.temporary_effects.has("test_effect"), "RunState must own temporary effects")
	_expect(int(GameState.run.checkpoint.tile_index) == 39, "RunState must own the current checkpoint")
	_expect(not GameState.run.has("gold"), "persistent gold must not leak into RunState")
	_expect(not GameState.profile.has("distance_tiles"), "transient run distance must not leak into PlayerProfile")
	_expect(int(GameState.profile.gold) == 37, "resetting RunState must not reset persistent profile progression")

func test_run_state_is_not_persisted() -> void:
	const TEST_SAVE_PATH := "user://phase5_profile_only_save.json"
	_remove_test_save(TEST_SAVE_PATH)
	GameState.reset_profile()
	GameState.profile.gold = 123
	GameState.reset_run(8080)
	GameState.set_distance_tiles(77)
	GameState.set_current_biome(BiomeData.Id.FORT)
	_expect(SaveManager.save_profile(TEST_SAVE_PATH), "profile-only save fixture must be writable")
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	_expect(file != null, "profile-only save fixture must be readable")
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		_expect(parsed is Dictionary, "saved profile must be a JSON dictionary")
		if parsed is Dictionary:
			_expect(not parsed.has("distance_tiles"), "save data must not serialize transient run distance")
			_expect(not parsed.has("seed"), "save data must not serialize the run seed")
			_expect(not parsed.has("current_biome"), "save data must not serialize current biome")
	GameState.set_distance_tiles(88)
	_expect(SaveManager.load_profile(TEST_SAVE_PATH), "profile-only save fixture must load")
	_expect(int(GameState.profile.gold) == 123, "profile load must restore persistent progression")
	_expect(int(GameState.run.distance_tiles) == 88, "profile load must not overwrite live RunState")
	_expect(int(GameState.run.seed) == 8080, "profile load must not overwrite the live run seed")
	_remove_test_save(TEST_SAVE_PATH)
	await get_tree().process_frame

func test_save_profile_round_trip() -> void:
	const TEST_SAVE_PATH := "user://phase5_test_save.json"
	_remove_test_save(TEST_SAVE_PATH)
	GameState.reset_profile()
	GameState.profile.gold = 987
	GameState.profile.unlocked_characters = [1, 7, 12]
	GameState.profile.selected_character = 7
	GameState.profile.stat_levels = {
		"maximum_health": 2,
		"defense_multiplier": 3,
		"melee_power": 4,
		"enemy_fire_interval_multiplier": 1,
		"invisibility_duration": 2,
		"slow_down_duration": 1,
	}
	GameState.profile.unlocked_abilities = ["jump", "dash", "invisibility"]
	GameState.profile.equipped_abilities = ["jump", "dash"]
	GameState.profile.ability_levels = {"jump": 3, "dash": 1, "invisibility": 2}
	GameState.profile.unlocked_weapons = ["shuriken", "magic_orb"]
	GameState.profile.equipped_weapons = ["shuriken"]
	GameState.profile.settings = {"action_button_side": "left"}
	GameState.profile.maximum_health = 150.0
	GameState.profile.defense_multiplier = 0.85
	GameState.set_consumable_count(&"revival_potion", 4)
	_expect(SaveManager.save_profile(TEST_SAVE_PATH), "SaveManager must write a valid profile")
	GameState.reset_profile()
	_expect(SaveManager.load_profile(TEST_SAVE_PATH), "SaveManager must load a valid profile")
	_expect(int(GameState.profile.gold) == 987, "gold must survive a save/load round trip")
	_expect(GameState.profile.unlocked_characters == [1, 7, 12], "unlocked characters must survive a save/load round trip")
	_expect(int(GameState.profile.selected_character) == 7, "selected character must survive a save/load round trip")
	_expect(int(GameState.profile.stat_levels.melee_power) == 4, "stat levels must survive a save/load round trip")
	_expect(GameState.profile.unlocked_abilities == ["jump", "dash", "invisibility"], "unlocked abilities must survive a save/load round trip")
	_expect(GameState.profile.equipped_abilities == ["jump", "dash"], "equipped abilities must survive a save/load round trip")
	_expect(int(GameState.profile.ability_levels.jump) == 3, "ability levels must survive a save/load round trip")
	_expect(GameState.profile.unlocked_weapons == ["shuriken", "magic_orb"], "unlocked weapons must survive a save/load round trip")
	_expect(GameState.profile.equipped_weapons == ["shuriken"], "equipped weapons must survive a save/load round trip")
	_expect(String(GameState.profile.settings.action_button_side) == "left", "settings must survive a save/load round trip")
	_expect(is_equal_approx(float(GameState.profile.maximum_health), 150.0), "maximum health must be re-derived from its persisted level")
	_expect(is_equal_approx(float(GameState.profile.defense_multiplier), 0.85), "defense multiplier must be re-derived from its persisted level")
	_expect(int(GameState.profile.revival_potions) == 4, "revival potion inventory must survive a save/load round trip")
	_expect(int(GameState.profile.consumables.revival_potion) == 4, "nested consumable inventory must survive a save/load round trip")
	_remove_test_save(TEST_SAVE_PATH)
	await get_tree().process_frame

func test_missing_save_creates_defaults() -> void:
	const MISSING_SAVE_PATH := "user://phase5_missing_save.json"
	_remove_test_save(MISSING_SAVE_PATH)
	GameState.profile.maximum_health = 999.0
	_expect(not SaveManager.load_profile(MISSING_SAVE_PATH), "loading a missing save must report that no save was loaded")
	_expect(is_equal_approx(float(GameState.profile.maximum_health), 100.0), "missing saves must restore default profile values")
	_expect(GameState.revival_potion_count() == 1, "missing saves must restore the default revival potion inventory")
	_expect(int(GameState.profile.gold) == 0, "missing saves must restore default persistent progression")

func test_corrupted_save_creates_defaults() -> void:
	const CORRUPTED_SAVE_PATH := "user://phase5_corrupted_save.json"
	_remove_test_save(CORRUPTED_SAVE_PATH)
	_write_test_save(CORRUPTED_SAVE_PATH, "{ this is not valid json")
	GameState.profile.gold = 555
	_expect(not SaveManager.load_profile(CORRUPTED_SAVE_PATH), "corrupted JSON saves must be rejected")
	_expect(int(GameState.profile.gold) == 0, "corrupted saves must restore a safe default profile")
	_expect(GameState.profile.unlocked_abilities == [PLAYER_PROFILE_SCRIPT.DEFAULT_ABILITY_ID], "corrupted saves must restore default ability progression")
	_remove_test_save(CORRUPTED_SAVE_PATH)

func test_unsupported_save_version_creates_defaults() -> void:
	const FUTURE_SAVE_PATH := "user://phase5_future_save.json"
	_remove_test_save(FUTURE_SAVE_PATH)
	_write_test_save(FUTURE_SAVE_PATH, JSON.stringify({"save_version": PLAYER_PROFILE_SCRIPT.CURRENT_SAVE_VERSION + 1, "gold": 999}))
	GameState.profile.gold = 555
	_expect(not SaveManager.load_profile(FUTURE_SAVE_PATH), "unsupported save versions must be rejected instead of guessed")
	_expect(int(GameState.profile.gold) == 0, "unsupported save versions must restore safe defaults")
	_remove_test_save(FUTURE_SAVE_PATH)

func test_legacy_v1_profile_backfills_phase5_defaults() -> void:
	const LEGACY_SAVE_PATH := "user://phase5_legacy_save.json"
	_remove_test_save(LEGACY_SAVE_PATH)
	var legacy_profile := {
		"save_version": 1,
		"selected_character": 1,
		"maximum_health": 150.0,
		"defense_multiplier": 0.75,
		"revival_potions": 3,
	}
	_write_test_save(LEGACY_SAVE_PATH, JSON.stringify(legacy_profile))
	_expect(SaveManager.load_profile(LEGACY_SAVE_PATH), "the additive Phase 5 schema must load existing version-1 profiles")
	_expect(is_equal_approx(float(GameState.profile.maximum_health), 150.0), "legacy v1 maximum health must be preserved")
	_expect(int(GameState.profile.stat_levels.maximum_health) == 2, "legacy v1 maximum health must migrate to the equivalent stat level")
	_expect(int(GameState.profile.stat_levels.defense_multiplier) == 5, "legacy v1 defense must migrate to the equivalent stat level")
	_expect(GameState.revival_potion_count() == 3, "legacy v1 potion inventory must migrate into consumables")
	_expect(int(GameState.profile.consumables.revival_potion) == 3, "legacy potion inventory must populate the Phase 5 consumables dictionary")
	_expect(int(GameState.profile.gold) == 0, "missing Phase 5 gold must backfill its default")
	_expect(GameState.profile.unlocked_abilities == [PLAYER_PROFILE_SCRIPT.DEFAULT_ABILITY_ID], "missing Phase 5 abilities must backfill defaults")
	_remove_test_save(LEGACY_SAVE_PATH)

func test_stat_definitions_are_valid() -> void:
	var expected_ids := [
		&"maximum_health",
		&"defense_multiplier",
		&"melee_power",
		&"enemy_fire_interval_multiplier",
		&"invisibility_duration",
		&"slow_down_duration",
	]
	_expect(STAT_CATALOG_SCRIPT.ORDERED.size() == expected_ids.size(), "Phase 6 must define all six requested player stats")
	for index in expected_ids.size():
		var stat = STAT_CATALOG_SCRIPT.ORDERED[index]
		_expect(stat.id == expected_ids[index], "stat catalog order/id must remain deterministic at index %d" % index)
		_expect(stat.is_valid(), "%s must define a valid range, step, and gold cost" % stat.display_name)
		_expect(stat.max_level() > 0, "%s must expose at least one upgrade level" % stat.display_name)
	_expect(STAT_CATALOG_SCRIPT.MAXIMUM_HEALTH.direction == STAT_DATA_SCRIPT.Direction.INCREASING, "maximum health must be increasing")
	_expect(STAT_CATALOG_SCRIPT.DEFENSE_MULTIPLIER.direction == STAT_DATA_SCRIPT.Direction.DECREASING, "defense multiplier must be decreasing")
	_expect(STAT_CATALOG_SCRIPT.ENEMY_FIRE_INTERVAL_MULTIPLIER.direction == STAT_DATA_SCRIPT.Direction.INCREASING, "enemy firing interval multiplier must increase as a beneficial upgrade")
	_expect(STAT_CATALOG_SCRIPT.INVISIBILITY_DURATION.required_ability == &"invisibility", "invisibility duration must require invisibility unlock")
	_expect(STAT_CATALOG_SCRIPT.SLOW_DOWN_DURATION.required_ability == &"slow_down_time", "slow-down duration must require slow-down-time unlock")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.MAXIMUM_HEALTH.minimum_value, GameConfig.MIN_MAXIMUM_HEALTH), "maximum-health resource minimum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.MAXIMUM_HEALTH.maximum_value, GameConfig.MAX_MAXIMUM_HEALTH), "maximum-health resource maximum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.MAXIMUM_HEALTH.upgrade_step, GameConfig.MAXIMUM_HEALTH_UPGRADE), "maximum-health resource step must match GameConfig")
	_expect(STAT_CATALOG_SCRIPT.MAXIMUM_HEALTH.upgrade_golds == GameConfig.MAXIMUM_HEALTH_UPGRADE_GOLDS, "maximum-health resource cost must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.DEFENSE_MULTIPLIER.minimum_value, GameConfig.MIN_DEFENSE_MULTIPLIER), "defense resource minimum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.DEFENSE_MULTIPLIER.maximum_value, GameConfig.MAX_DEFENSE_MULTIPLIER), "defense resource maximum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.DEFENSE_MULTIPLIER.upgrade_step, GameConfig.DEFENSE_MULTIPLIER_UPGRADE), "defense resource step must match GameConfig")
	_expect(STAT_CATALOG_SCRIPT.DEFENSE_MULTIPLIER.upgrade_golds == GameConfig.DEFENSE_MULTIPLIER_UPGRADE_GOLDS, "defense resource cost must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.MELEE_POWER.minimum_value, GameConfig.MIN_MELEE_POWER), "melee resource minimum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.MELEE_POWER.maximum_value, GameConfig.MAX_MELEE_POWER), "melee resource maximum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.MELEE_POWER.upgrade_step, GameConfig.MELEE_POWER_UPGRADE), "melee resource step must match GameConfig")
	_expect(STAT_CATALOG_SCRIPT.MELEE_POWER.upgrade_golds == GameConfig.MELEE_POWER_UPGRADE_GOLDS, "melee resource cost must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.ENEMY_FIRE_INTERVAL_MULTIPLIER.minimum_value, GameConfig.MIN_ENEMY_FIRE_INTERVAL_MULTIPLIER), "enemy-fire interval resource minimum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.ENEMY_FIRE_INTERVAL_MULTIPLIER.maximum_value, GameConfig.MAX_ENEMY_FIRE_INTERVAL_MULTIPLIER), "enemy-fire interval resource maximum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.ENEMY_FIRE_INTERVAL_MULTIPLIER.upgrade_step, GameConfig.ENEMY_FIRE_INTERVAL_MULTIPLIER_UPGRADE), "enemy-fire interval resource step must match GameConfig")
	_expect(STAT_CATALOG_SCRIPT.ENEMY_FIRE_INTERVAL_MULTIPLIER.upgrade_golds == GameConfig.ENEMY_FIRE_INTERVAL_MULTIPLIER_UPGRADE_GOLDS, "enemy-fire interval resource cost must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.INVISIBILITY_DURATION.minimum_value, GameConfig.MIN_INVISIBILITY_DURATION), "invisibility duration resource minimum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.INVISIBILITY_DURATION.maximum_value, GameConfig.MAX_INVISIBILITY_DURATION), "invisibility duration resource maximum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.INVISIBILITY_DURATION.upgrade_step, GameConfig.INVISIBILITY_DURATION_UPGRADE), "invisibility duration resource step must match GameConfig")
	_expect(STAT_CATALOG_SCRIPT.INVISIBILITY_DURATION.upgrade_golds == GameConfig.INVISIBILITY_DURATION_UPGRADE_GOLDS, "invisibility duration resource cost must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.SLOW_DOWN_DURATION.minimum_value, GameConfig.MIN_SLOW_DOWN_DURATION), "slow-down duration resource minimum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.SLOW_DOWN_DURATION.maximum_value, GameConfig.MAX_SLOW_DOWN_DURATION), "slow-down duration resource maximum must match GameConfig")
	_expect(is_equal_approx(STAT_CATALOG_SCRIPT.SLOW_DOWN_DURATION.upgrade_step, GameConfig.SLOW_DOWN_DURATION_UPGRADE), "slow-down duration resource step must match GameConfig")
	_expect(STAT_CATALOG_SCRIPT.SLOW_DOWN_DURATION.upgrade_golds == GameConfig.SLOW_DOWN_DURATION_UPGRADE_GOLDS, "slow-down duration resource cost must match GameConfig")

func test_stat_values_follow_levels() -> void:
	GameState.reset_profile()
	GameState.profile.stat_levels.maximum_health = 2
	GameState.profile.stat_levels.defense_multiplier = 3
	GameState.profile.stat_levels.melee_power = 4
	GameState.profile.stat_levels.enemy_fire_interval_multiplier = 5
	_expect(int(GameState.stat_value(&"maximum_health")) == 150, "maximum health must increase by 25 per level")
	_expect(is_equal_approx(float(GameState.stat_value(&"defense_multiplier")), 0.85), "defense multiplier must decrease by 0.05 per level")
	_expect(int(GameState.stat_value(&"melee_power")) == 30, "melee power must increase by 5 per level")
	_expect(is_equal_approx(float(GameState.stat_value(&"enemy_fire_interval_multiplier")), 1.5), "enemy firing interval multiplier must increase by 0.1 per level")

func test_upgrade_costs_gold() -> void:
	GameState.reset_profile()
	GameState.profile.gold = GameConfig.MAXIMUM_HEALTH_UPGRADE_GOLDS
	var result := GameState.upgrade_stat(&"maximum_health")
	_expect(result == STAT_UPGRADE_SERVICE_SCRIPT.Result.SUCCESS, "an unlocked stat with enough gold must upgrade")
	_expect(int(GameState.profile.gold) == 0, "successful stat upgrade must deduct its fixed gold cost exactly once")
	_expect(int(GameState.stat_level(&"maximum_health")) == 1, "successful stat upgrade must increment level exactly once")
	_expect(int(GameState.stat_value(&"maximum_health")) == 125, "successful maximum-health upgrade must update the derived value")
	_expect(int(GameState.profile.maximum_health) == 125, "successful upgrade must synchronize compatibility value fields")

func test_each_stat_upgrade_uses_definition() -> void:
	for stat in STAT_CATALOG_SCRIPT.ORDERED:
		GameState.reset_profile()
		if stat.required_ability != &"":
			GameState.profile.unlocked_abilities.append(String(stat.required_ability))
		GameState.profile.gold = stat.upgrade_golds
		var result := GameState.upgrade_stat(stat.id)
		_expect(result == STAT_UPGRADE_SERVICE_SCRIPT.Result.SUCCESS, "%s must upgrade when its own preconditions are satisfied" % stat.display_name)
		_expect(int(GameState.profile.gold) == 0, "%s must deduct its configured fixed cost" % stat.display_name)
		_expect(GameState.stat_level(stat.id) == 1, "%s must advance exactly one level per purchase" % stat.display_name)
		var expected_value = stat.value_for_level(1)
		if expected_value is int:
			_expect(int(GameState.stat_value(stat.id)) == expected_value, "%s must derive its configured first-level integer value" % stat.display_name)
		else:
			_expect(is_equal_approx(float(GameState.stat_value(stat.id)), float(expected_value)), "%s must derive its configured first-level value" % stat.display_name)

func test_upgrade_requires_enough_gold_is_atomic() -> void:
	GameState.reset_profile()
	GameState.profile.gold = GameConfig.MELEE_POWER_UPGRADE_GOLDS - 1
	var before_levels: Dictionary = GameState.profile.stat_levels.duplicate(true)
	var result := GameState.upgrade_stat(&"melee_power")
	_expect(result == STAT_UPGRADE_SERVICE_SCRIPT.Result.NOT_ENOUGH_GOLD, "stat upgrade must reject insufficient gold")
	_expect(int(GameState.profile.gold) == GameConfig.MELEE_POWER_UPGRADE_GOLDS - 1, "failed upgrade must not deduct gold")
	_expect(GameState.profile.stat_levels == before_levels, "failed upgrade must not mutate stat levels")

func test_unknown_stat_upgrade_is_atomic() -> void:
	GameState.reset_profile()
	GameState.profile.gold = 500
	var before_profile: Dictionary = GameState.profile.duplicate(true)
	var result := GameState.upgrade_stat(&"not_a_real_stat")
	_expect(result == STAT_UPGRADE_SERVICE_SCRIPT.Result.UNKNOWN_STAT, "unknown stat ids must be rejected explicitly")
	_expect(GameState.profile == before_profile, "unknown-stat rejection must not mutate any profile field")

func test_upgrade_clamped_to_maximum() -> void:
	GameState.reset_profile()
	var stat = STAT_CATALOG_SCRIPT.MAXIMUM_HEALTH
	GameState.profile.stat_levels.maximum_health = stat.max_level() - 1
	GameState.profile.gold = stat.upgrade_golds * 2
	_expect(GameState.upgrade_stat(stat.id) == STAT_UPGRADE_SERVICE_SCRIPT.Result.SUCCESS, "penultimate increasing-stat level must upgrade to its maximum")
	_expect(int(GameState.stat_level(stat.id)) == stat.max_level(), "increasing stat must reach but not exceed max level")
	_expect(is_equal_approx(float(GameState.stat_value(stat.id)), stat.maximum_value), "increasing stat must clamp exactly to maximum value")
	var gold_at_limit := int(GameState.profile.gold)
	_expect(GameState.upgrade_stat(stat.id) == STAT_UPGRADE_SERVICE_SCRIPT.Result.AT_LIMIT, "upgrade at maximum level must be rejected")
	_expect(int(GameState.profile.gold) == gold_at_limit, "rejected at-limit upgrade must not spend gold")

func test_decreasing_stat_clamped_to_minimum() -> void:
	GameState.reset_profile()
	var stat = STAT_CATALOG_SCRIPT.DEFENSE_MULTIPLIER
	GameState.profile.stat_levels.defense_multiplier = stat.max_level() - 1
	GameState.profile.gold = stat.upgrade_golds * 2
	_expect(GameState.upgrade_stat(stat.id) == STAT_UPGRADE_SERVICE_SCRIPT.Result.SUCCESS, "penultimate decreasing-stat level must upgrade to its limit")
	_expect(is_equal_approx(float(GameState.stat_value(stat.id)), stat.minimum_value), "decreasing stat must clamp exactly to minimum value")
	var gold_at_limit := int(GameState.profile.gold)
	_expect(GameState.upgrade_stat(stat.id) == STAT_UPGRADE_SERVICE_SCRIPT.Result.AT_LIMIT, "decreasing stat must reject upgrades after its minimum is reached")
	_expect(int(GameState.profile.gold) == gold_at_limit, "at-limit decreasing stat must not spend gold")

func test_locked_stat_cannot_upgrade() -> void:
	GameState.reset_profile()
	GameState.profile.gold = 1000
	var before_gold := int(GameState.profile.gold)
	_expect(not GameState.is_stat_unlocked(&"invisibility_duration"), "invisibility duration must start locked")
	_expect(GameState.upgrade_stat(&"invisibility_duration") == STAT_UPGRADE_SERVICE_SCRIPT.Result.LOCKED, "locked invisibility duration must not upgrade")
	_expect(int(GameState.profile.gold) == before_gold and int(GameState.stat_level(&"invisibility_duration")) == 0, "locked upgrade rejection must be atomic")
	GameState.profile.unlocked_abilities.append("invisibility")
	_expect(GameState.is_stat_unlocked(&"invisibility_duration"), "unlocking invisibility must make its duration stat available")
	_expect(GameState.upgrade_stat(&"invisibility_duration") == STAT_UPGRADE_SERVICE_SCRIPT.Result.SUCCESS, "unlocked invisibility duration must become upgradeable")
	_expect(not GameState.is_stat_unlocked(&"slow_down_duration"), "slow-down duration must remain independently locked")

func test_stat_levels_sanitize_to_limits() -> void:
	var raw := PLAYER_PROFILE_SCRIPT.create_default()
	raw.stat_levels.maximum_health = 999
	raw.stat_levels.defense_multiplier = -12
	raw.stat_levels.melee_power = 999
	var sanitized := PLAYER_PROFILE_SCRIPT.sanitize(raw)
	_expect(int(sanitized.stat_levels.maximum_health) == STAT_CATALOG_SCRIPT.MAXIMUM_HEALTH.max_level(), "persisted increasing stat level must clamp to its maximum")
	_expect(int(sanitized.stat_levels.defense_multiplier) == 0, "negative persisted stat level must clamp to zero")
	_expect(int(sanitized.stat_levels.melee_power) == STAT_CATALOG_SCRIPT.MELEE_POWER.max_level(), "every persisted stat level must clamp using its own definition")
	_expect(int(sanitized.maximum_health) == int(STAT_CATALOG_SCRIPT.MAXIMUM_HEALTH.maximum_value), "sanitization must derive compatibility values from clamped levels")

func test_runtime_player_uses_upgraded_stats() -> void:
	GameState.reset_profile()
	GameState.profile.stat_levels.maximum_health = 2
	GameState.profile.stat_levels.defense_multiplier = 5
	var player = await _spawn_player(false)
	_expect(is_equal_approx(player.maximum_health, 150.0), "new player instances must derive maximum health from stat progression")
	_expect(is_equal_approx(player.defense_multiplier, 0.75), "new player instances must derive defense multiplier from stat progression")
	var before: float = player.current_health
	player.take_damage(20.0)
	_expect(is_equal_approx(player.current_health, before - 15.0), "runtime damage must use the upgraded defense multiplier")
	await _free_node(player)

func test_run_health_uses_upgraded_maximum_health() -> void:
	GameState.reset_profile()
	GameState.profile.stat_levels.maximum_health = 4
	GameState.reset_run(6060)
	_expect(is_equal_approx(float(GameState.run.health), 200.0), "new RunState health must start from the derived maximum-health stat")

func test_phase3_biome_metadata() -> void:
	var expected_hazards := [
		BiomeData.HazardType.NONE,
		BiomeData.HazardType.NONE,
		BiomeData.HazardType.SNOW_VARIANCE,
		BiomeData.HazardType.DESERT_HEAT,
		BiomeData.HazardType.ASTRO_FALLING_TILE,
		BiomeData.HazardType.FORT_SPIKES,
	]
	for index in BiomeCatalog.ORDERED.size():
		var biome: BiomeData = BiomeCatalog.ORDERED[index]
		_expect(not String(biome.terrain_set).is_empty(), "%s must define a terrain_set id" % biome.display_name)
		_expect(biome.background_color.a > 0.0, "%s must define a visible background color" % biome.display_name)
		_expect(not biome.enemy_pool.is_empty(), "%s must expose a data-driven enemy pool" % biome.display_name)
		_expect(not biome.collectible_weights.is_empty(), "%s must expose collectible weights" % biome.display_name)
		_expect(biome.hazard_type == expected_hazards[index], "%s must use the expected Phase 3 mechanic" % biome.display_name)
		_expect(biome.hazard_spawn_chance >= 0.0 and biome.hazard_spawn_chance <= 1.0, "%s hazard chance must be a probability" % biome.display_name)
	_expect(BiomeCatalog.GRASS.hazard_type == BiomeData.HazardType.NONE, "Grass must remain the baseline biome")
	_expect(BiomeCatalog.TUNDRA.hazard_type == BiomeData.HazardType.NONE, "Tundra must stay mechanically distinct from Snow")
	_expect(is_equal_approx(BiomeCatalog.SNOW.snow_jump_modifier_min, GameConfig.SNOW_JUMP_MODIFIER_MIN), "Snow minimum jump variance must be configured centrally")
	_expect(is_equal_approx(BiomeCatalog.SNOW.snow_jump_modifier_max, GameConfig.SNOW_JUMP_MODIFIER_MAX), "Snow maximum jump variance must be configured centrally")
	_expect(FileAccess.file_exists(BiomeCatalog.DESERT.particle_effect), "Desert must reference a bundled flame particle texture")

func test_snow_modifier_is_seeded_and_bounded() -> void:
	var snow_tile := BiomeData.Id.SNOW * GameConfig.BIOME_INTERVAL
	var first := BiomeMechanics.snow_jump_modifier(123456, snow_tile, BiomeCatalog.SNOW)
	var repeat := BiomeMechanics.snow_jump_modifier(123456, snow_tile, BiomeCatalog.SNOW)
	_expect(is_equal_approx(first, repeat), "Snow jump modifier must be reproducible for the same run seed/encounter")
	_expect(first >= GameConfig.SNOW_JUMP_MODIFIER_MIN and first <= GameConfig.SNOW_JUMP_MODIFIER_MAX, "Snow jump modifier must remain inside configured bounds")
	var saw_difference := false
	for seed_value in range(10, 30):
		var modifier := BiomeMechanics.snow_jump_modifier(seed_value, snow_tile, BiomeCatalog.SNOW)
		_expect(modifier >= GameConfig.SNOW_JUMP_MODIFIER_MIN and modifier <= GameConfig.SNOW_JUMP_MODIFIER_MAX, "every seeded Snow modifier must remain bounded")
		if not is_equal_approx(modifier, first):
			saw_difference = true
	_expect(saw_difference, "different run seeds must be able to produce different Snow modifiers")
	_expect(is_zero_approx(BiomeMechanics.snow_jump_modifier(123456, 0, BiomeCatalog.GRASS)), "non-Snow biomes must not receive a Snow jump modifier")

func test_snow_generator_uses_effective_jump() -> void:
	var seed_value := 8765
	var snow_tile := BiomeData.Id.SNOW * GameConfig.BIOME_INTERVAL
	var generator = LAYOUT_GENERATOR_SCRIPT.new()
	generator.reset(seed_value)
	generator.generated_until_tile = snow_tile
	generator.current_height_tile = GameConfig.BASE_PLATFORM_HEIGHT
	var expected := BiomeMechanics.effective_max_jump(seed_value, snow_tile, BiomeCatalog.SNOW)
	var spec: Dictionary = generator.next_chunk(BiomeCatalog.SNOW, snow_tile + GameConfig.BIOME_INTERVAL, LAYOUT_GENERATOR_SCRIPT.Archetype.GAPS)
	_expect(not spec.is_empty(), "Snow generator must still produce geometry")
	_expect(is_equal_approx(generator.effective_max_jump_tiles, expected), "Snow generator must use the encounter's effective jump height")
	var expected_jump_speed := sqrt(2.0 * GameConfig.GRAVITY * GameConfig.tiles_to_pixels(expected))
	var expected_time := (expected_jump_speed + sqrt(expected_jump_speed * expected_jump_speed)) / GameConfig.GRAVITY
	_expect(is_equal_approx(generator.max_reachable_gap_tiles(0), GameConfig.SPEED * expected_time), "Snow gap reachability must use effective MAX_JUMP")

func test_snow_changes_player_jump_temporarily() -> void:
	var player = await _spawn_player()
	var baseline: float = float(player.jump_speed_pixels())
	player.set_biome_context(BiomeCatalog.SNOW, GameConfig.SNOW_JUMP_MODIFIER_MIN)
	_expect(is_equal_approx(player.effective_max_jump_tiles(), GameConfig.MAX_JUMP + GameConfig.SNOW_JUMP_MODIFIER_MIN), "Snow must change only the player's effective jump height")
	_expect(player.jump_speed_pixels() < baseline, "negative Snow variance must reduce jump launch speed")
	player.set_biome_context(BiomeCatalog.TUNDRA, GameConfig.SNOW_JUMP_MODIFIER_MAX)
	_expect(is_equal_approx(player.effective_max_jump_tiles(), GameConfig.MAX_JUMP), "leaving Snow must clear the temporary jump modifier")
	_expect(is_equal_approx(player.jump_speed_pixels(), baseline), "Tundra must retain the baseline jump mechanic")
	await _free_node(player)

func test_desert_hazard_damage_and_burn() -> void:
	var hazard = DESERT_HAZARD_SCENE.instantiate()
	add_child(hazard)
	var player = await _spawn_player()
	await get_tree().process_frame
	var before: float = player.current_health
	_expect(hazard.apply_contact_damage(player), "Desert heat must accept damageable players")
	_expect(is_equal_approx(player.current_health, before - GameConfig.DESERT_CONTACT_DAMAGE), "Desert contact must inflict configured fire damage")
	_expect(player.status_remaining(&"burn") > 0.0, "Desert contact must apply a temporary burn status")
	_expect(player.burn_particles.emitting, "burn status must enable player flame particles")
	player.invulnerability_remaining = 0.0
	var after_contact: float = player.current_health
	_expect(hazard.apply_burn_tick(player), "Desert hazard timer path must support burn damage ticks")
	_expect(is_equal_approx(player.current_health, after_contact - GameConfig.DESERT_BURN_TICK_DAMAGE), "Desert burn tick must use configured damage")
	await _free_node(hazard)
	await _free_node(player)

func test_astro_falling_tile_sequence() -> void:
	var tile = FALLING_TILE_SCENE.instantiate()
	add_child(tile)
	await get_tree().process_frame
	tile.configure(Vector2i(4, 8), BiomeCatalog.ASTRO.terrain_middle_atlas)
	_expect(tile.state == FALLING_TILE_SCRIPT.State.STABLE, "Astro falling tile must begin stable")
	_expect(tile.trigger_fall(), "touch-equivalent trigger must start Astro warning")
	_expect(tile.state == FALLING_TILE_SCRIPT.State.WARNING, "Astro tile must warn before falling")
	await _wait_physics_seconds(GameConfig.ASTRO_FALL_WARNING_DURATION + 0.08)
	_expect(tile.state == FALLING_TILE_SCRIPT.State.FALLING, "Astro tile must fall after its warning delay")
	_expect(tile.velocity.y > 0.0, "falling Astro tile must accelerate downward")
	await _free_node(tile)

func test_astro_chain_fall_uses_support_links() -> void:
	var lower = FALLING_TILE_SCENE.instantiate()
	var upper = FALLING_TILE_SCENE.instantiate()
	add_child(lower)
	add_child(upper)
	await get_tree().process_frame
	lower.configure(Vector2i(3, 8), BiomeCatalog.ASTRO.terrain_middle_atlas)
	upper.configure(Vector2i(3, 7), BiomeCatalog.ASTRO.terrain_middle_atlas)
	upper.set_support_below(lower)
	_expect(lower.supported_tiles.has(upper), "Astro support graph must explicitly register blocks above")
	lower.begin_falling_immediately()
	_expect(lower.state == FALLING_TILE_SCRIPT.State.FALLING, "support tile must enter falling state")
	_expect(upper.state == FALLING_TILE_SCRIPT.State.WARNING, "supported block must lose support and enter warning")
	_expect(upper.support_below == null, "chain reaction must clear the lost support link")
	await _wait_physics_seconds(GameConfig.ASTRO_FALL_WARNING_DURATION + 0.05)
	_expect(upper.state == FALLING_TILE_SCRIPT.State.FALLING, "unsupported Astro block must fall after its warning")
	await _free_node(lower)
	await _free_node(upper)

func test_fort_spike_damage_only_when_exposed() -> void:
	var spike = SPIKE_HAZARD_SCENE.instantiate()
	add_child(spike)
	var player = await _spawn_player()
	await get_tree().process_frame
	var before: float = player.current_health
	_expect(spike.state == SPIKE_HAZARD_SCRIPT.State.RETRACTED, "Fort spike must begin retracted")
	_expect(not spike.is_damage_enabled(), "Fort spike hitbox must be disabled while retracted")
	_expect(not spike.try_damage(player), "retracted Fort spike must not damage the player")
	_expect(is_equal_approx(player.current_health, before), "retracted Fort spike must leave health unchanged")
	spike.set_state(SPIKE_HAZARD_SCRIPT.State.EXPOSED)
	_expect(spike.is_damage_enabled(), "Fort spike hitbox must enable only in EXPOSED state")
	_expect(spike.try_damage(player), "exposed Fort spike must damage the player")
	_expect(is_equal_approx(player.current_health, before - GameConfig.FORT_SPIKE_DAMAGE), "Fort spike must use configured piercing damage")
	player.invulnerability_remaining = 0.0
	spike.set_state(SPIKE_HAZARD_SCRIPT.State.LOWERING)
	_expect(not spike.is_damage_enabled(), "Fort spike hitbox must disable while lowering")
	_expect(not spike.try_damage(player), "lowering Fort spike must not damage the player")
	await _free_node(spike)
	await _free_node(player)

func test_fort_spike_cycles_states() -> void:
	var spike = SPIKE_HAZARD_SCENE.instantiate()
	add_child(spike)
	await get_tree().process_frame
	_expect(spike.state == SPIKE_HAZARD_SCRIPT.State.RETRACTED, "Fort spike cycle must start retracted")
	await _wait_physics_seconds(GameConfig.FORT_SPIKE_RETRACTED_DURATION + 0.04)
	_expect(spike.state == SPIKE_HAZARD_SCRIPT.State.RISING, "Fort spike must rise after its retracted interval")
	_expect(not spike.is_damage_enabled(), "Fort spike must remain harmless while rising")
	await _wait_physics_seconds(GameConfig.FORT_SPIKE_RISE_DURATION + 0.04)
	_expect(spike.state == SPIKE_HAZARD_SCRIPT.State.EXPOSED, "Fort spike must become exposed after rising")
	_expect(spike.is_damage_enabled(), "Fort spike hitbox must become live when the timed cycle reaches EXPOSED")
	await _wait_physics_seconds(GameConfig.FORT_SPIKE_EXPOSED_DURATION + 0.04)
	_expect(spike.state == SPIKE_HAZARD_SCRIPT.State.LOWERING, "Fort spike must lower after its exposed interval")
	_expect(not spike.is_damage_enabled(), "Fort spike must stop damaging immediately when lowering starts")
	await _wait_physics_seconds(GameConfig.FORT_SPIKE_LOWER_DURATION + 0.04)
	_expect(spike.state == SPIKE_HAZARD_SCRIPT.State.RETRACTED, "Fort spike cycle must return to retracted")
	await _free_node(spike)

func test_streamer_spawns_phase3_hazards() -> void:
	var streamer = STREAMER_SCRIPT.new()
	add_child(streamer)
	streamer.reset(30303)
	streamer.update_for_player(GameConfig.tiles_to_pixels(float(BiomeData.Id.DESERT * GameConfig.BIOME_INTERVAL + 4)))
	await get_tree().process_frame
	_expect(_count_group_descendants(streamer, &"desert_hazard") > 0, "Desert chunks must instantiate DesertHazard scenes")
	streamer.update_for_player(GameConfig.tiles_to_pixels(float(BiomeData.Id.ASTRO * GameConfig.BIOME_INTERVAL + 4)))
	await get_tree().process_frame
	_expect(_count_group_descendants(streamer, &"astro_falling_tile") > 0, "Astro chunks must replace selected static cells with FallingTile scenes")
	_expect(not streamer.falling_tiles_by_coord.is_empty(), "streamer must retain an explicit Astro support registry")
	streamer.update_for_player(GameConfig.tiles_to_pixels(float(BiomeData.Id.FORT * GameConfig.BIOME_INTERVAL + 4)))
	await get_tree().process_frame
	_expect(_count_group_descendants(streamer, &"fort_spike_hazard") > 0, "Fort chunks must instantiate cycling SpikeHazard scenes")
	await _free_node(streamer)

func test_all_astro_terrain_uses_falling_tiles() -> void:
	var streamer = STREAMER_SCRIPT.new()
	add_child(streamer)
	streamer.reset(616161)
	streamer.update_for_player(GameConfig.tiles_to_pixels(float(BiomeData.Id.ASTRO * GameConfig.BIOME_INTERVAL + 4)))
	await get_tree().process_frame
	var expected_astro_cells := 0
	for spec in streamer.active_chunks:
		if int(spec.biome_id) != BiomeData.Id.ASTRO:
			continue
		for platform in spec.platforms:
			expected_astro_cells += int(platform.width_tiles)
	_expect(expected_astro_cells > 0, "Astro streaming test must retain generated Astro terrain")
	_expect(streamer.falling_tiles_by_coord.size() == expected_astro_cells, "every retained Astro terrain cell must be represented by a FallingTile scene")
	for tile_coord in streamer.falling_tiles_by_coord.keys():
		_expect(streamer.terrain_layer.get_cell_source_id(tile_coord) == -1, "Astro FallingTile cells must not also exist as static TileMap terrain")
	await _free_node(streamer)

func test_hazard_placement_is_seeded() -> void:
	var first = STREAMER_SCRIPT.new()
	var second = STREAMER_SCRIPT.new()
	add_child(first)
	add_child(second)
	first.reset(515151)
	second.reset(515151)
	var desert_x := GameConfig.tiles_to_pixels(float(BiomeData.Id.DESERT * GameConfig.BIOME_INTERVAL + 4))
	first.update_for_player(desert_x)
	second.update_for_player(desert_x)
	await get_tree().process_frame
	var first_positions := _group_positions(first, &"desert_hazard")
	var second_positions := _group_positions(second, &"desert_hazard")
	_expect(not first_positions.is_empty(), "seeded Desert generation must produce hazard positions")
	_expect(first_positions == second_positions, "same run seed must reproduce Phase 3 hazard placement")
	await _free_node(first)
	await _free_node(second)

func test_streamer_cleans_runtime_hazards() -> void:
	var streamer = STREAMER_SCRIPT.new()
	add_child(streamer)
	streamer.reset(40404)
	streamer.update_for_player(GameConfig.tiles_to_pixels(float(BiomeData.Id.ASTRO * GameConfig.BIOME_INTERVAL + 6)))
	await get_tree().process_frame
	_expect(not streamer.runtime_nodes_by_chunk.is_empty(), "hazard biomes must register runtime nodes by chunk")
	streamer.update_for_player(GameConfig.tiles_to_pixels(420.0))
	await get_tree().process_frame
	var active_starts: Dictionary = {}
	for spec in streamer.active_chunks:
		active_starts[int(spec.start_tile)] = true
	for chunk_start in streamer.runtime_nodes_by_chunk.keys():
		_expect(active_starts.has(int(chunk_start)), "runtime hazards must never outlive their streamed chunk")
	for tile_coord in streamer.falling_tiles_by_coord.keys():
		var tile = streamer.falling_tiles_by_coord[tile_coord]
		_expect(is_instance_valid(tile) and not tile.is_queued_for_deletion(), "Astro support registry must not retain freed tiles")
	await _free_node(streamer)

func test_level_applies_biome_context() -> void:
	var level = LEVEL_SCENE.instantiate()
	add_child(level)
	await get_tree().process_frame
	var player = level.get_node("Player")
	var background: ColorRect = level.get_node("BackgroundLayer/Background")
	var biome_label: Label = level.get_node("HUD/MarginContainer/VBoxContainer/BiomeLabel")
	var snow_tile := BiomeData.Id.SNOW * GameConfig.BIOME_INTERVAL
	level.apply_biome_for_tile(snow_tile)
	var expected_modifier := BiomeMechanics.snow_jump_modifier(int(GameState.run.seed), snow_tile, BiomeCatalog.SNOW)
	_expect(level.current_biome_id == BiomeData.Id.SNOW, "level must track the player's current biome")
	_expect(is_equal_approx(player.temporary_jump_modifier, expected_modifier), "level and streamer must apply the same seeded Snow modifier to the player")
	_expect(background.color == BiomeCatalog.SNOW.background_color, "biome transition must update presentation from BiomeData")
	_expect(biome_label.text == "Biome: Snow", "HUD must expose the active biome")
	level.apply_biome_for_tile(BiomeData.Id.TUNDRA * GameConfig.BIOME_INTERVAL)
	_expect(is_zero_approx(player.temporary_jump_modifier), "Tundra must clear Snow's temporary modifier")
	await _free_node(level)

func _remove_test_save(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)

func _write_test_save(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "test fixture must be able to write '%s'" % path)
	if file == null:
		return
	file.store_string(contents)
	file.close()

func _mandatory_segments(spec: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for segment in spec.get("platforms", []):
		if not bool(segment.get("optional_route", false)) and not bool(segment.get("ceiling", false)):
			result.append(segment)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.start_tile) < int(b.start_tile))
	return result

func _action_has_physical_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false

func _png_decodes(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var image := Image.new()
	return image.load_png_from_buffer(file.get_buffer(file.get_length())) == OK and not image.is_empty()

func _spawn_player(reset_profile: bool = true):
	if reset_profile:
		GameState.reset_profile()
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame
	return player

func _spawn_grounded_player() -> Dictionary:
	GameState.reset_profile()
	var holder := Node2D.new()
	add_child(holder)
	var floor := StaticBody2D.new()
	floor.collision_layer = 2
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(500, 64)
	floor_shape.shape = rectangle
	floor.add_child(floor_shape)
	floor.position = Vector2(0, 128)
	holder.add_child(floor)
	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(0, 66)
	holder.add_child(player)
	for _index in 6:
		await get_tree().physics_frame
	return {"root": holder, "player": player}

func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
	await get_tree().process_frame

func _wait_physics_seconds(seconds: float) -> void:
	var elapsed := 0.0
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	while elapsed < seconds:
		await get_tree().physics_frame
		elapsed += tick

func _count_group_descendants(root: Node, group_name: StringName) -> int:
	var count := 0
	for node in root.find_children("*", "", true, false):
		if node.is_in_group(group_name):
			count += 1
	return count

func _group_positions(root: Node, group_name: StringName) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for node in root.find_children("*", "", true, false):
		if node is Node2D and node.is_in_group(group_name):
			positions.append(node.position)
	positions.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		if not is_equal_approx(a.x, b.x):
			return a.x < b.x
		return a.y < b.y
	)
	return positions

func _expect(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failures.append(message)
