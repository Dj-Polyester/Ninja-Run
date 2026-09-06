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
const MELEE_DUMMY_ENEMY_SCRIPT := preload("res://tests/fixtures/melee_dummy_enemy.gd")
const WEAPON_DATA_SCRIPT := preload("res://src/data/weapon_data.gd")
const WEAPON_CATALOG_SCRIPT := preload("res://src/data/weapon_catalog.gd")
const WEAPON_INVENTORY_SERVICE_SCRIPT := preload("res://src/gameplay/combat/weapon_inventory_service.gd")
const WEAPON_PROJECTILE_SCENE := preload("res://scenes/combat/weapon_projectile.tscn")
const ABILITY_CATALOG_SCRIPT := preload("res://src/data/ability_catalog.gd")
const ABILITY_INVENTORY_SERVICE_SCRIPT := preload("res://src/gameplay/abilities/ability_inventory_service.gd")
const ABILITY_PLAYER_STUB_SCRIPT := preload("res://tests/fixtures/ability_player_stub.gd")
const CLIMB_ABILITY_SCRIPT := preload("res://src/gameplay/abilities/climb_ability.gd")
const GLIDE_ABILITY_SCRIPT := preload("res://src/gameplay/abilities/glide_ability.gd")
const FLY_ABILITY_SCRIPT := preload("res://src/gameplay/abilities/fly_ability.gd")
const ENEMY_DATA_SCRIPT := preload("res://src/data/enemy_data.gd")
const ENEMY_CATALOG_SCRIPT := preload("res://src/data/enemy_catalog.gd")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const ENEMY_SPAWNER_SCRIPT := preload("res://src/gameplay/enemies/enemy_spawner.gd")
const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")
const ENEMY_BEAM_SCENE := preload("res://scenes/enemies/enemy_beam.tscn")
const ENEMY_TARGET_DUMMY_SCRIPT := preload("res://tests/fixtures/enemy_target_dummy.gd")
const STATUS_EFFECT_SCRIPT := preload("res://src/data/status_effect.gd")
const STATUS_EFFECT_CATALOG_SCRIPT := preload("res://src/data/status_effect_catalog.gd")
const STATUS_EFFECT_CONTROLLER_SCRIPT := preload("res://src/gameplay/status/status_effect_controller.gd")
const STATUS_TARGET_DUMMY_SCRIPT := preload("res://tests/fixtures/status_target_dummy.gd")
const RNG_SERVICE_SCRIPT := preload("res://src/core/rng_service.gd")
const COLLECTIBLE_CATALOG_SCRIPT := preload("res://src/data/collectible_catalog.gd")
const COLLECTIBLE_PICKUP_SCENE := preload("res://scenes/items/collectible_pickup.tscn")
const COLLECTIBLE_SPAWNER_SCRIPT := preload("res://src/gameplay/items/collectible_spawner.gd")
const CHARACTER_DATA_SCRIPT := preload("res://src/data/character_data.gd")
const CHARACTER_CATALOG_SCRIPT := preload("res://src/data/character_catalog.gd")
const CHARACTER_INVENTORY_SERVICE_SCRIPT := preload("res://src/gameplay/progression/character_inventory_service.gd")
const MOBILE_ACTION_CONTROLS_SCENE := preload("res://scenes/ui/mobile_action_controls.tscn")

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
	await test_melee_detector_configuration()
	await test_automatic_melee_attacks_nearest_target()
	await test_automatic_melee_uses_upgraded_power_and_damage_info()
	await test_automatic_melee_respects_cooldown()
	await test_automatic_melee_ignores_invalid_targets()
	await test_automatic_melee_stops_when_player_is_dead()
	test_weapon_definitions_are_valid()
	test_weapon_requires_shooting()
	test_weapon_unlock_costs_gold_atomically()
	test_weapon_equipment_limit()
	await test_weapon_target_count()
	await test_weapon_forward_aim()
	await test_weapon_targeted_aim()
	await test_weapon_random_aim_is_seeded()
	await test_weapon_fixed_pattern_aim()
	await test_weapon_ballistic_trajectory()
	await test_weapon_controller_requires_shooting()
	await test_weapon_automatic_firing_and_interval()
	await test_weapon_automatic_target_count()
	await test_weapon_ignores_offscreen_enemy()
	await test_weapon_projectile_damage()
	await test_homing_projectile_steers_to_target()
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
	test_ability_definitions_are_valid()
	test_ability_equipment_limit_and_conflict()
	await test_jump_air_jump_levels()
	test_climb_wall_jump_count()
	test_glide_duration()
	await test_reverse_gravity_semantics()
	test_fly_allows_unlimited_air_jumps()
	await test_dash_distance_and_cooldown()
	await test_explode_damage_and_destructible_terrain()
	await test_slow_down_uses_world_multipliers()
	await test_invisibility_detectability_and_duration()
	test_enemy_biome_restriction()
	test_enemy_level_scaling()
	await test_enemy_patrol()
	await test_stationary_enemy()
	await test_enemy_melee_vicinity()
	await test_enemy_shooting_vicinity()
	await test_enemy_fire_interval()
	await test_enemy_projectile_damage_and_status()
	await test_enemy_death()
	await test_enemy_health_bar_updates()
	await test_enemy_spawner_is_seeded()
	await test_streamed_enemy_cleanup()
	test_status_effect_resources_are_valid()
	test_status_effect_dictionary_compatibility()
	await test_freeze()
	await test_burn()
	await test_blood_loss()
	test_poison()
	test_slow()
	test_status_refresh_policy()
	test_status_stack_policy()
	test_status_expiration()
	await test_status_damage_multiplier()
	await test_enemy_uses_generic_status_controller()
	test_collectible_definitions_are_valid()
	test_gem_value_exceeds_coin()
	await test_pickup_increases_gold()
	test_collectible_spawn_is_seeded()
	test_collectible_difficulty_biases_value()
	test_enemy_drop_tables_are_valid()
	test_enemy_drop_probability_and_count()
	await test_enemy_death_spawns_drops()
	await test_streamed_collectible_cleanup()
	test_level_collectible_architecture()
	test_character_definitions_are_valid()
	test_character_unlock_costs_gold_atomically()
	test_character_selection_requires_unlock()
	test_character_profile_sanitizes_unknown_ids()
	await test_selected_character_drives_player_presentation()
	await test_keyboard_ability_slot_routes_equipped_ability()
	await test_touch_tap_maps_to_jump()
	await test_touch_hold_preserves_jump_hold_semantics()
	await test_swipe_down_maps_to_roll_without_jump()
	await test_mobile_action_buttons_follow_equipped_slots()
	await test_action_button_side_setting_updates_mobile_cluster()
	test_level_has_phase14_input_hud()

	print("\nPhase 1+2+3+4+5+6+7+8+9+10+11+12+13+14 assertions: %d passed, %d failed" % [passed, failures.size()])
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
	_expect(GameConfig.ENEMY_COLLISION_MASK > 0, "enemy collision mask must reserve at least one physics layer")
	_expect(GameConfig.MELEE_RANGE_TILES > 0.0, "melee range must be positive")
	_expect(GameConfig.MELEE_ATTACK_INTERVAL > 0.0, "melee attack interval must be positive")
	_expect(GameConfig.ENEMY_MIN_PLATFORM_WIDTH > 0, "enemy spawning must require a positive platform width")
	_expect(GameConfig.ENEMY_MAX_PER_CHUNK > 0, "enemy spawning must have a positive bounded per-chunk cap")
	_expect(GameConfig.ENEMY_ADDITIONAL_SPAWN_CHANCE >= 0.0 and GameConfig.ENEMY_ADDITIONAL_SPAWN_CHANCE <= 1.0, "additional enemy spawn chance must be a valid probability")
	_expect(GameConfig.ENEMY_PROJECTILE_LIFETIME > 0.0, "enemy projectile lifetime must be positive")
	_expect(GameConfig.ENEMY_BEAM_DURATION > 0.0 and GameConfig.ENEMY_BEAM_MAX_RANGE_TILES > 0.0, "enemy beam duration and range must be positive")
	_expect(GameConfig.NUM_EQUIPABLE_ABILITIES > 0, "ability equipment limit must be positive")
	_expect(GameConfig.MAX_GLIDE_DURATION > 0.0, "Glide duration must be positive")
	_expect(GameConfig.GLIDE_GRAVITY_FACTOR > 0.0 and GameConfig.GLIDE_GRAVITY_FACTOR < 1.0, "Glide gravity factor must reduce but not reverse gravity")
	_expect(GameConfig.DASH_SPEED > GameConfig.SPEED, "Dash speed must exceed normal run speed")
	_expect(GameConfig.DASH_TILES > 0.0, "Dash distance must be positive")
	_expect(GameConfig.EXPLODE_RADIUS > 0.0 and GameConfig.EXPLODE_DAMAGE > 0.0, "Explode radius and damage must be positive")
	_expect(GameConfig.COOLDOWN_PERIOD > 0.0, "common ability cooldown must be positive")

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
	var ability_keys := [KEY_1, KEY_2, KEY_3, KEY_4]
	for index in ability_keys.size():
		var action := StringName("ability_%d" % (index + 1))
		_expect(InputMap.has_action(action), "%s input action must exist" % action)
		_expect(not InputMap.action_get_events(action).is_empty(), "%s must have a keyboard binding" % action)
		_expect(_action_has_physical_key(action, ability_keys[index]), "%s must use physical number key %d" % [action, index + 1])

func test_phase1_assets_exist() -> void:
	const TERRAIN_PATH := "res://assets/Spritesheets/spritesheet-tiles-double.png"
	_expect(FileAccess.file_exists(TERRAIN_PATH), "required terrain spritesheet must exist")
	_expect(_png_decodes(TERRAIN_PATH), "required terrain spritesheet must decode as an image")
	var base := "res://assets/Characters/1/Png/Character Sprite"
	for folder in ["Fast Run", "Jump Before", "Fall", "Roll", "Dead"]:
		var animation_folder := base.path_join(folder)
		var files := PLAYER_SCRIPT.list_character_animation_files(animation_folder)
		var png_count := 0
		var representative_path := ""
		for file_name in files:
			if file_name.to_lower().ends_with(".png"):
				png_count += 1
				if representative_path.is_empty():
					representative_path = animation_folder.path_join(file_name)
		_expect(png_count > 0, "character animation folder '%s' must contain PNG frames" % folder)
		if not representative_path.is_empty():
			_expect(_png_decodes(representative_path), "character animation '%s' must decode as an image" % folder)
			var texture := PLAYER_SCRIPT.load_character_texture(representative_path)
			_expect(texture != null, "character animation '%s' must load as a runtime texture without relying on import cache" % folder)
			if texture != null:
				_expect(texture.get_width() > 0 and texture.get_height() > 0, "character animation '%s' runtime texture must have non-zero dimensions" % folder)

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
	await get_tree().physics_frame
	player.velocity.y = 0.0
	player.trigger_jump()
	_expect(player.velocity.y < 0.0, "default Jump level 1 must allow one air jump")
	player.velocity.y = 0.0
	player.trigger_jump()
	_expect(is_zero_approx(player.velocity.y), "default Jump level 1 must reject a second air jump before landing")
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

func test_melee_detector_configuration() -> void:
	var player = await _spawn_player()
	var detector: Area2D = player.get_node("MeleeDetector")
	var collision: CollisionShape2D = detector.get_node("CollisionShape2D")
	var circle := collision.shape as CircleShape2D
	_expect(detector.collision_layer == 0, "melee detector must not occupy a physics collision layer")
	_expect(detector.collision_mask == GameConfig.ENEMY_COLLISION_MASK, "melee detector must query only the configured enemy layer")
	_expect(detector.monitoring and not detector.monitorable, "melee detector must query overlaps without acting as a target itself")
	_expect(circle != null, "melee detector must use a circular proximity shape")
	if circle != null:
		_expect(is_equal_approx(circle.radius, GameConfig.tiles_to_pixels(GameConfig.MELEE_RANGE_TILES)), "melee detector radius must be derived from MELEE_RANGE_TILES")
	await _free_node(player)

func test_automatic_melee_attacks_nearest_target() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	var near_enemy = _spawn_melee_enemy(player.global_position + Vector2(28.0, 0.0))
	var far_enemy = _spawn_melee_enemy(player.global_position + Vector2(62.0, 0.0))
	for _index in 4:
		await get_tree().physics_frame
		if near_enemy.damage_events > 0:
			break
	_expect(near_enemy.damage_events == 1, "automatic melee must attack the nearest valid enemy in range")
	_expect(far_enemy.damage_events == 0, "automatic melee must not hit a farther target when a nearer valid target exists")
	_expect(player.melee_controller.last_target == near_enemy, "melee controller must record the selected nearest target")
	_expect(player.sprite.animation == &"melee", "automatic melee must play the supplied attack animation")
	await _free_node(near_enemy)
	await _free_node(far_enemy)
	await _free_node(player)

func test_automatic_melee_uses_upgraded_power_and_damage_info() -> void:
	GameState.reset_profile()
	GameState.profile.stat_levels.melee_power = 3
	var expected_damage := float(GameState.stat_value(&"melee_power"))
	var player = await _spawn_player(false)
	var enemy = _spawn_melee_enemy(player.global_position + Vector2(32.0, 0.0))
	var attacked := await _wait_for_melee_attack(player, enemy)
	_expect(attacked, "automatic melee must fire while a valid enemy remains in proximity")
	_expect(is_equal_approx(enemy.current_health, enemy.maximum_health - expected_damage), "melee hit damage must use the upgraded melee_power stat")
	_expect(is_equal_approx(player.melee_controller.last_damage, expected_damage), "melee controller must expose the applied derived damage")
	_expect(enemy.last_damage_info != null, "melee hits must use the shared DamageInfo payload")
	if enemy.last_damage_info != null:
		_expect(enemy.last_damage_info.source == player, "melee DamageInfo source must be the attacking player")
		_expect(enemy.last_damage_info.damage_type == DAMAGE_INFO_SCRIPT.DamageType.MELEE, "automatic melee must tag hits with MELEE damage type")
	await _free_node(enemy)
	await _free_node(player)

func test_automatic_melee_respects_cooldown() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	var enemy = _spawn_melee_enemy(player.global_position + Vector2(32.0, 0.0), 1000.0)
	var attacked := await _wait_for_melee_attack(player, enemy)
	_expect(attacked, "cooldown test requires an initial automatic melee hit")
	var first_count: int = enemy.damage_events
	var remaining: float = player.melee_controller.cooldown_remaining
	_expect(remaining > 0.0, "successful melee hit must start MELEE_ATTACK_INTERVAL cooldown")
	await _follow_melee_target_for_seconds(player, enemy, maxf(0.05, remaining * 0.45))
	_expect(enemy.damage_events == first_count, "enemy staying in range must not be hit again before melee cooldown expires")
	await _follow_melee_target_for_seconds(player, enemy, remaining + 0.15)
	_expect(enemy.damage_events >= first_count + 1, "enemy staying in range must be attacked again after melee cooldown expires")
	await _free_node(enemy)
	await _free_node(player)

func test_automatic_melee_ignores_invalid_targets() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	var blocker := StaticBody2D.new()
	blocker.collision_layer = GameConfig.ENEMY_COLLISION_MASK
	blocker.collision_mask = 0
	var blocker_collision := CollisionShape2D.new()
	var blocker_shape := CircleShape2D.new()
	blocker_shape.radius = 12.0
	blocker_collision.shape = blocker_shape
	blocker.add_child(blocker_collision)
	blocker.global_position = player.global_position + Vector2(18.0, 0.0)
	add_child(blocker)
	var enemy = _spawn_melee_enemy(player.global_position + Vector2(52.0, 0.0))
	for _index in 6:
		blocker.global_position = player.global_position + Vector2(18.0, 0.0)
		enemy.global_position = player.global_position + Vector2(52.0, 0.0)
		await get_tree().physics_frame
		if enemy.damage_events > 0:
			break
	_expect(enemy.damage_events == 1, "non-damageable overlaps must be ignored instead of blocking a valid melee target")
	_expect(player.melee_controller.last_target == enemy, "nearest-target selection must consider only objects implementing the damage contract")
	await _free_node(blocker)
	await _free_node(enemy)
	await _free_node(player)

func test_automatic_melee_stops_when_player_is_dead() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	player.die("test")
	var enemy = _spawn_melee_enemy(player.global_position + Vector2(30.0, 0.0))
	for _index in 5:
		enemy.global_position = player.global_position + Vector2(30.0, 0.0)
		await get_tree().physics_frame
	_expect(enemy.damage_events == 0, "dead players must not continue automatic melee attacks")
	await _free_node(enemy)
	await _free_node(player)

func test_weapon_definitions_are_valid() -> void:
	var weapons: Array = WEAPON_CATALOG_SCRIPT.all()
	_expect(weapons.size() >= 5, "Phase 8 must provide several genuinely different weapons")
	var ids: Dictionary = {}
	var trajectories: Dictionary = {}
	var aim_modes: Dictionary = {}
	var asset_categories: Dictionary = {}
	for weapon in weapons:
		_expect(weapon != null and weapon.is_valid(), "every WeaponData resource must be structurally valid")
		if weapon == null:
			continue
		var id := String(weapon.id)
		_expect(not ids.has(id), "weapon ids must be unique: %s" % id)
		ids[id] = true
		_expect(FileAccess.file_exists(weapon.texture_path), "%s must reference a supplied weapon PNG" % weapon.display_name)
		_expect(weapon.damage > 0.0, "%s must deal positive damage" % weapon.display_name)
		_expect(weapon.fire_interval > 0.0, "%s must define a positive firing interval" % weapon.display_name)
		_expect(weapon.target_count >= 1, "%s must target at least one enemy" % weapon.display_name)
		_expect(weapon.projectile_speed_tiles > 0.0, "%s must define projectile speed in tiles/sec" % weapon.display_name)
		trajectories[int(weapon.trajectory)] = true
		aim_modes[int(weapon.aim_mode)] = true
		for category in ["/Mage/", "/Ranged/", "/Shuriken/", "/Swords/"]:
			if String(weapon.texture_path).contains(category):
				asset_categories[category] = true
	_expect(WEAPON_CATALOG_SCRIPT.get_by_id(&"shuriken") != null, "Shuriken must be available as a weapon definition")
	_expect(WEAPON_CATALOG_SCRIPT.get_by_id(&"magic_orb") != null, "Magic Orb must preserve the persisted Phase 5 weapon id")
	_expect(trajectories.has(WEAPON_DATA_SCRIPT.Trajectory.STRAIGHT), "weapon catalog must include a straight trajectory")
	_expect(trajectories.has(WEAPON_DATA_SCRIPT.Trajectory.BALLISTIC), "weapon catalog must include a ballistic trajectory")
	_expect(trajectories.has(WEAPON_DATA_SCRIPT.Trajectory.HOMING), "weapon catalog must include a homing trajectory")
	for aim_mode in [WEAPON_DATA_SCRIPT.AimMode.FORWARD, WEAPON_DATA_SCRIPT.AimMode.TARGETED, WEAPON_DATA_SCRIPT.AimMode.RANDOM, WEAPON_DATA_SCRIPT.AimMode.FIXED_PATTERN]:
		_expect(aim_modes.has(aim_mode), "weapon catalog must exercise aim mode %d" % aim_mode)
	_expect(asset_categories.size() == 4, "Phase 8 weapons must use supplied Mage, Ranged, Shuriken, and Swords asset categories")

func test_weapon_requires_shooting() -> void:
	GameState.reset_profile()
	GameState.profile.gold = 1000
	var before_gold := int(GameState.profile.gold)
	_expect(not GameState.shooting_unlocked(), "Shooting must start locked")
	_expect(GameState.unlock_weapon(&"shuriken") == WEAPON_INVENTORY_SERVICE_SCRIPT.Result.SHOOTING_LOCKED, "weapon purchase must be unavailable before Shooting is unlocked")
	_expect(int(GameState.profile.gold) == before_gold, "Shooting-locked weapon purchase must not spend gold")
	_expect(not GameState.is_weapon_unlocked(&"shuriken"), "Shooting-locked purchase must not unlock the weapon")
	GameState.profile.unlocked_abilities.append(String(GameConfig.SHOOTING_ABILITY_ID))
	_expect(GameState.shooting_unlocked(), "adding Shooting to unlocked abilities must expose weapon progression")

func test_weapon_unlock_costs_gold_atomically() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_abilities.append(String(GameConfig.SHOOTING_ABILITY_ID))
	var weapon = WEAPON_CATALOG_SCRIPT.SHURIKEN
	GameState.profile.gold = weapon.unlock_cost - 1
	var before_gold := int(GameState.profile.gold)
	_expect(GameState.unlock_weapon(weapon.id) == WEAPON_INVENTORY_SERVICE_SCRIPT.Result.NOT_ENOUGH_GOLD, "weapon unlock must reject insufficient gold")
	_expect(int(GameState.profile.gold) == before_gold and not GameState.is_weapon_unlocked(weapon.id), "failed weapon purchase must be atomic")
	GameState.profile.gold = weapon.unlock_cost + 50
	_expect(GameState.unlock_weapon(weapon.id) == WEAPON_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "affordable weapon must unlock")
	_expect(int(GameState.profile.gold) == 50, "successful weapon unlock must deduct exactly unlock_cost")
	_expect(GameState.is_weapon_unlocked(weapon.id), "successful weapon purchase must persist the unlocked id")
	var gold_after_unlock := int(GameState.profile.gold)
	_expect(GameState.unlock_weapon(weapon.id) == WEAPON_INVENTORY_SERVICE_SCRIPT.Result.ALREADY_UNLOCKED, "already-unlocked weapon must not be purchased twice")
	_expect(int(GameState.profile.gold) == gold_after_unlock, "duplicate weapon unlock must not spend gold")

func test_weapon_equipment_limit() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_abilities.append(String(GameConfig.SHOOTING_ABILITY_ID))
	GameState.profile.gold = 100000
	var weapons: Array = WEAPON_CATALOG_SCRIPT.all()
	for index in range(GameConfig.NUM_EQUIPPABLE_WEAPONS + 1):
		var weapon = weapons[index]
		_expect(GameState.unlock_weapon(weapon.id) == WEAPON_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "equipment-limit fixture weapon %s must unlock" % weapon.display_name)
		if index < GameConfig.NUM_EQUIPPABLE_WEAPONS:
			_expect(GameState.equip_weapon(weapon.id) == WEAPON_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "weapon %s must equip below the configured limit" % weapon.display_name)
		else:
			_expect(GameState.equip_weapon(weapon.id) == WEAPON_INVENTORY_SERVICE_SCRIPT.Result.EQUIPMENT_LIMIT, "equipping beyond NUM_EQUIPPABLE_WEAPONS must be rejected")
	_expect(GameState.profile.equipped_weapons.size() == GameConfig.NUM_EQUIPPABLE_WEAPONS, "equipped weapon count must never exceed NUM_EQUIPPABLE_WEAPONS")
	var first_id := StringName(GameState.profile.equipped_weapons[0])
	_expect(GameState.unequip_weapon(first_id) == WEAPON_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "equipped weapon must be unequippable")
	_expect(GameState.profile.equipped_weapons.size() == GameConfig.NUM_EQUIPPABLE_WEAPONS - 1, "unequip must free one weapon slot")

func test_weapon_target_count() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	var enemies: Array = []
	for offset in [Vector2(220, 0), Vector2(260, 20), Vector2(300, -20), Vector2(340, 0)]:
		enemies.append(_spawn_melee_enemy(player.global_position + offset, 1000.0))
	var targets: Array[Node2D] = player.weapon_controller.select_targets(WEAPON_CATALOG_SCRIPT.MAGIC_ORB, enemies)
	_expect(targets.size() == WEAPON_CATALOG_SCRIPT.MAGIC_ORB.target_count, "weapon target selection must clamp to WeaponData.target_count")
	_expect(targets[0] == enemies[0] and targets[1] == enemies[1], "targeted multi-target weapon must choose nearest enemies first")
	for enemy in enemies:
		await _free_node(enemy)
	await _free_node(player)

func test_weapon_forward_aim() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	var enemy = _spawn_melee_enemy(player.global_position + Vector2(-120.0, -90.0), 1000.0)
	var direction: Vector2 = player.weapon_controller.aim_direction(WEAPON_CATALOG_SCRIPT.ARROW, enemy)
	_expect(direction.is_equal_approx(Vector2.RIGHT), "forward-aim weapon must fire forward even when a target is elsewhere on-screen")
	await _free_node(enemy)
	await _free_node(player)

func test_weapon_targeted_aim() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	var enemy = _spawn_melee_enemy(player.weapon_controller.global_position + Vector2(180.0, -70.0), 1000.0)
	var expected: Vector2 = player.weapon_controller.global_position.direction_to(enemy.global_position)
	var actual: Vector2 = player.weapon_controller.aim_direction(WEAPON_CATALOG_SCRIPT.SHURIKEN, enemy)
	_expect(actual.is_equal_approx(expected), "targeted weapon aim must point directly at the selected enemy")
	await _free_node(enemy)
	await _free_node(player)

func test_weapon_random_aim_is_seeded() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	var enemy = _spawn_melee_enemy(player.global_position + Vector2(250.0, 0.0), 1000.0)
	player.weapon_controller.set_rng_seed(8675309)
	var first: Vector2 = player.weapon_controller.aim_direction(WEAPON_CATALOG_SCRIPT.THROWING_BLADE, enemy)
	player.weapon_controller.set_rng_seed(8675309)
	var repeat: Vector2 = player.weapon_controller.aim_direction(WEAPON_CATALOG_SCRIPT.THROWING_BLADE, enemy)
	_expect(first.is_equal_approx(repeat), "random weapon aim must be reproducible with an injected seed")
	_expect(first.x > 0.0 and not is_zero_approx(first.y), "random aim must produce a forward-hemisphere direction that differs from fixed forward aim")
	player.weapon_controller.set_rng_seed(24680)
	var first_launch: Dictionary = player.weapon_controller.launch_parameters(WEAPON_CATALOG_SCRIPT.THROWING_BLADE, enemy)
	player.weapon_controller.set_rng_seed(24680)
	var repeated_launch: Dictionary = player.weapon_controller.launch_parameters(WEAPON_CATALOG_SCRIPT.THROWING_BLADE, enemy)
	player.weapon_controller.set_rng_seed(13579)
	var different_launch: Dictionary = player.weapon_controller.launch_parameters(WEAPON_CATALOG_SCRIPT.THROWING_BLADE, enemy)
	_expect((first_launch.velocity as Vector2).is_equal_approx(repeated_launch.velocity), "ballistic random-aim launch must remain deterministic for the same RNG seed")
	_expect(not (first_launch.velocity as Vector2).is_equal_approx(different_launch.velocity), "ballistic trajectory must preserve RANDOM aim instead of retargeting every shot")
	_expect(is_equal_approx(float(first_launch.gravity), GameConfig.WEAPON_PROJECTILE_GRAVITY), "ballistic random-aim weapon must still apply projectile gravity")
	await _free_node(enemy)
	await _free_node(player)

func test_weapon_fixed_pattern_aim() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	var enemy = _spawn_melee_enemy(player.global_position + Vector2(280.0, 0.0), 1000.0)
	var left: Vector2 = player.weapon_controller.aim_direction(WEAPON_CATALOG_SCRIPT.SHURIKEN_FAN, enemy, 0, 3)
	var center: Vector2 = player.weapon_controller.aim_direction(WEAPON_CATALOG_SCRIPT.SHURIKEN_FAN, enemy, 1, 3)
	var right: Vector2 = player.weapon_controller.aim_direction(WEAPON_CATALOG_SCRIPT.SHURIKEN_FAN, enemy, 2, 3)
	_expect(left.y < 0.0 and right.y > 0.0, "fixed pattern must spread shots on both sides of the forward axis")
	_expect(center.is_equal_approx(Vector2.RIGHT), "odd fixed-pattern fan must include a centered forward shot")
	_expect(is_equal_approx(absf(left.angle()), absf(right.angle())), "fixed pattern spread must be symmetric")
	await _free_node(enemy)
	await _free_node(player)

func test_weapon_ballistic_trajectory() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	var controller = player.weapon_controller
	var origin: Vector2 = controller.global_position
	var target: Vector2 = origin + Vector2(340.0, 45.0)
	var speed: float = WEAPON_CATALOG_SCRIPT.THROWING_BLADE.projectile_speed_pixels()
	var gravity := GameConfig.WEAPON_PROJECTILE_GRAVITY
	var velocity: Vector2 = controller.ballistic_velocity(origin, target, speed, gravity)
	_expect(velocity.x > 0.0, "ballistic solution must move toward a target ahead")
	_expect(velocity.y < 0.0, "ballistic solution must initially arc upward for the representative target")
	if velocity.x > 0.0:
		var flight_time: float = (target.x - origin.x) / velocity.x
		var simulated_y: float = origin.y + velocity.y * flight_time + 0.5 * gravity * flight_time * flight_time
		_expect(absf(simulated_y - target.y) < 0.75, "ballistic solution must intersect the target height at its horizontal position")
	await _free_node(player)

func test_weapon_controller_requires_shooting() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_weapons = ["shuriken"]
	GameState.profile.equipped_weapons = ["shuriken"]
	var player = await _spawn_player(false)
	var enemy = _spawn_melee_enemy(player.global_position + Vector2(260.0, 0.0), 1000.0, true)
	for _index in 4:
		enemy.global_position = player.global_position + Vector2(260.0, 0.0)
		await get_tree().physics_frame
	_expect(_count_group_descendants(self, &"weapon_projectiles") == 0, "equipped weapons must not fire while Shooting is locked")
	GameState.profile.unlocked_abilities.append(String(GameConfig.SHOOTING_ABILITY_ID))
	for _index in 4:
		enemy.global_position = player.global_position + Vector2(260.0, 0.0)
		await get_tree().physics_frame
		if _count_group_descendants(self, &"weapon_projectiles") > 0:
			break
	_expect(_count_group_descendants(self, &"weapon_projectiles") > 0, "equipped weapon must begin automatic fire after Shooting is unlocked")
	await _free_node(enemy)
	await _free_node(player)
	await _free_group_nodes(&"weapon_projectiles")

func test_weapon_automatic_firing_and_interval() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_abilities.append(String(GameConfig.SHOOTING_ABILITY_ID))
	GameState.profile.unlocked_weapons = ["arrow"]
	GameState.profile.equipped_weapons = ["arrow"]
	var player = await _spawn_player(false)
	var enemy = _spawn_melee_enemy(player.global_position + Vector2(360.0, 0.0), 10000.0, true)
	var fired_count := [0]
	player.weapon_controller.weapon_fired.connect(func(_weapon, _projectile, _target): fired_count[0] += 1)
	for _index in 5:
		enemy.global_position = player.global_position + Vector2(360.0, 0.0)
		await get_tree().physics_frame
		if fired_count[0] > 0:
			break
	_expect(fired_count[0] == 1, "visible enemy must trigger one immediate automatic weapon shot")
	_expect(player.weapon_controller.cooldown_remaining(&"arrow") > 0.0, "successful automatic fire must start the weapon-specific interval")
	var first_count: int = fired_count[0]
	await _follow_weapon_target_for_seconds(player, enemy, WEAPON_CATALOG_SCRIPT.ARROW.fire_interval * 0.45)
	_expect(fired_count[0] == first_count, "automatic weapon must not fire again before its fire_interval expires")
	await _follow_weapon_target_for_seconds(player, enemy, WEAPON_CATALOG_SCRIPT.ARROW.fire_interval * 0.7 + 0.12)
	_expect(fired_count[0] >= first_count + 1, "automatic weapon must fire again after its fire_interval expires while enemies remain on-screen")
	await _free_node(enemy)
	await _free_node(player)
	await _free_group_nodes(&"weapon_projectiles")

func test_weapon_automatic_target_count() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_abilities.append(String(GameConfig.SHOOTING_ABILITY_ID))
	GameState.profile.unlocked_weapons = ["shuriken_fan"]
	GameState.profile.equipped_weapons = ["shuriken_fan"]
	var player = await _spawn_player(false)
	var enemies: Array = []
	for offset in [Vector2(260.0, 70.0), Vector2(300.0, 120.0), Vector2(340.0, 170.0)]:
		enemies.append(_spawn_melee_enemy(player.global_position + offset, 1000.0, true))
	var fired_count := [0]
	player.weapon_controller.weapon_fired.connect(func(_weapon, _projectile, _target): fired_count[0] += 1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(fired_count[0] == WEAPON_CATALOG_SCRIPT.SHURIKEN_FAN.target_count, "automatic fixed-pattern weapon must fire one projectile per configured on-screen target")
	for enemy in enemies:
		await _free_node(enemy)
	await _free_node(player)
	await _free_group_nodes(&"weapon_projectiles")

func test_weapon_ignores_offscreen_enemy() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_abilities.append(String(GameConfig.SHOOTING_ABILITY_ID))
	GameState.profile.unlocked_weapons = ["shuriken"]
	GameState.profile.equipped_weapons = ["shuriken"]
	var player = await _spawn_player(false)
	var enemy = _spawn_melee_enemy(Vector2(5000.0, 200.0), 1000.0, true)
	var fired_count := [0]
	player.weapon_controller.weapon_fired.connect(func(_weapon, _projectile, _target): fired_count[0] += 1)
	for _index in 5:
		await get_tree().physics_frame
	_expect(fired_count[0] == 0, "off-screen enemies must not trigger automatic weapon fire")
	await _free_node(enemy)
	await _free_node(player)

func test_weapon_projectile_damage() -> void:
	GameState.reset_profile()
	var holder := Node2D.new()
	add_child(holder)
	var source := Node2D.new()
	holder.add_child(source)
	var enemy = _spawn_melee_enemy(Vector2(120.0, 220.0), 1000.0)
	enemy.reparent(holder)
	var projectile = WEAPON_PROJECTILE_SCENE.instantiate()
	holder.add_child(projectile)
	projectile.global_position = Vector2(20.0, 220.0)
	projectile.configure(source, WEAPON_CATALOG_SCRIPT.SHURIKEN, Vector2.RIGHT * WEAPON_CATALOG_SCRIPT.SHURIKEN.projectile_speed_pixels())
	var before: float = enemy.current_health
	for _index in 20:
		await get_tree().physics_frame
		if enemy.damage_events > 0:
			break
	_expect(enemy.damage_events == 1, "weapon projectile must damage a collided enemy exactly once")
	_expect(is_equal_approx(enemy.current_health, before - WEAPON_CATALOG_SCRIPT.SHURIKEN.damage), "projectile collision damage must come from WeaponData.damage")
	_expect(enemy.last_damage_info != null, "projectile hit must use shared DamageInfo")
	if enemy.last_damage_info != null:
		_expect(enemy.last_damage_info.source == source, "projectile DamageInfo must preserve the firing source")
		_expect(enemy.last_damage_info.damage_type == DAMAGE_INFO_SCRIPT.DamageType.PROJECTILE, "weapon projectile must tag damage as PROJECTILE")
	await _free_node(holder)

func test_homing_projectile_steers_to_target() -> void:
	GameState.reset_profile()
	var holder := Node2D.new()
	add_child(holder)
	var source := Node2D.new()
	holder.add_child(source)
	var target := Node2D.new()
	target.position = Vector2(600.0, 260.0)
	holder.add_child(target)
	var projectile = WEAPON_PROJECTILE_SCENE.instantiate()
	holder.add_child(projectile)
	projectile.position = Vector2(40.0, 80.0)
	var speed: float = WEAPON_CATALOG_SCRIPT.MAGIC_ORB.projectile_speed_pixels()
	projectile.configure(source, WEAPON_CATALOG_SCRIPT.MAGIC_ORB, Vector2.RIGHT * speed, 0.0, target, GameConfig.WEAPON_HOMING_TURN_RATE)
	for _index in 8:
		await get_tree().physics_frame
	_expect(projectile.velocity.y > 0.0, "homing projectile must steer vertically toward an offset target")
	_expect(absf(projectile.velocity.length() - speed) < 0.1, "homing steering must preserve projectile speed")
	await _free_node(holder)

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

func test_ability_definitions_are_valid() -> void:
	var expected_ids := [
		"jump",
		"climb",
		"glide",
		"reverse_gravity",
		"fly",
		"dash",
		"shooting",
		"explode",
		"slow_down_time",
		"invisibility",
	]
	_expect(ABILITY_CATALOG_SCRIPT.ORDERED.size() == expected_ids.size(), "Phase 9 must define every requested ability plus the existing Shooting ability")
	var seen: Dictionary = {}
	for index in ABILITY_CATALOG_SCRIPT.ORDERED.size():
		var ability = ABILITY_CATALOG_SCRIPT.ORDERED[index]
		_expect(ability.is_valid(), "ability resource '%s' must be valid" % ability.display_name)
		_expect(String(ability.id) == expected_ids[index], "ability catalog order must remain deterministic at index %d" % index)
		_expect(not seen.has(String(ability.id)), "ability ids must be unique")
		seen[String(ability.id)] = true
	_expect(ABILITY_CATALOG_SCRIPT.JUMP.max_level == 3, "Jump must expose three upgrade levels")
	_expect(ABILITY_CATALOG_SCRIPT.CLIMB.max_level == 2, "Climb must expose two upgrade levels")
	_expect(not ABILITY_CATALOG_SCRIPT.JUMP.has_cooldown, "Jump must not use the action-ability cooldown")
	_expect(not ABILITY_CATALOG_SCRIPT.REVERSE_GRAVITY.has_cooldown, "Reverse Gravity must toggle directly on jump input without action cooldown")
	_expect(ABILITY_CATALOG_SCRIPT.DASH.has_cooldown, "Dash must use the common cooldown")
	_expect(ABILITY_CATALOG_SCRIPT.EXPLODE.has_cooldown, "Explode must use the common cooldown")

func test_ability_equipment_limit_and_conflict() -> void:
	var profile: Dictionary = PLAYER_PROFILE_SCRIPT.create_default()
	_expect(
		ABILITY_INVENTORY_SERVICE_SCRIPT.unlock(profile, &"reverse_gravity") == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS,
		"Reverse Gravity must be unlockable through the ability inventory model"
	)
	_expect(
		ABILITY_INVENTORY_SERVICE_SCRIPT.equip(profile, &"reverse_gravity") == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.INCOMPATIBLE,
		"Jump and Reverse Gravity must be rejected as an incompatible equipment pair"
	)
	_expect(ABILITY_INVENTORY_SERVICE_SCRIPT.unequip(profile, &"jump") == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "default Jump must be unequippable")
	_expect(ABILITY_INVENTORY_SERVICE_SCRIPT.equip(profile, &"reverse_gravity") == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "Reverse Gravity must equip after Jump is removed")
	for id in [&"dash", &"glide", &"fly", &"explode"]:
		_expect(ABILITY_INVENTORY_SERVICE_SCRIPT.unlock(profile, id) == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "ability '%s' must unlock" % id)
	var fill_ids := [&"dash", &"glide", &"fly"]
	for id in fill_ids:
		_expect(ABILITY_INVENTORY_SERVICE_SCRIPT.equip(profile, id) == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "ability '%s' must equip within the configured limit" % id)
	_expect(profile.equipped_abilities.size() == GameConfig.NUM_EQUIPABLE_ABILITIES, "ability equipment must stop at NUM_EQUIPABLE_ABILITIES")
	_expect(
		ABILITY_INVENTORY_SERVICE_SCRIPT.equip(profile, &"explode") == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.EQUIPMENT_LIMIT,
		"the fifth simultaneously equipped ability must be rejected"
	)
	_expect(ABILITY_INVENTORY_SERVICE_SCRIPT.upgrade(profile, &"jump") == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "Jump level 1 must upgrade to level 2")
	_expect(ABILITY_INVENTORY_SERVICE_SCRIPT.upgrade(profile, &"jump") == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "Jump level 2 must upgrade to level 3")
	_expect(ABILITY_INVENTORY_SERVICE_SCRIPT.upgrade(profile, &"jump") == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.MAX_LEVEL, "Jump must clamp at level 3")
	var raw: Dictionary = PLAYER_PROFILE_SCRIPT.create_default()
	raw.unlocked_abilities = ["jump", "reverse_gravity"]
	raw.equipped_abilities = ["jump", "reverse_gravity"]
	var sanitized := PLAYER_PROFILE_SCRIPT.sanitize(raw)
	_expect(sanitized.equipped_abilities == ["jump"], "save sanitization must remove incompatible Jump + Reverse Gravity equipment")
	raw.unlocked_abilities = ["jump", "not_a_real_ability"]
	raw.equipped_abilities = ["not_a_real_ability"]
	sanitized = PLAYER_PROFILE_SCRIPT.sanitize(raw)
	_expect(not sanitized.unlocked_abilities.has("not_a_real_ability"), "save sanitization must remove unknown ability ids")
	_expect(sanitized.equipped_abilities.is_empty(), "unknown ability ids must never survive as equipped runtime abilities")

func test_jump_air_jump_levels() -> void:
	for level in range(1, 4):
		GameState.reset_profile()
		GameState.profile.ability_levels["jump"] = level
		var setup := await _spawn_grounded_player(false)
		var player = setup.player
		player.trigger_jump()
		await get_tree().physics_frame
		_expect(not player.is_supported(), "Jump level %d grounded takeoff must leave floor support" % level)
		for air_index in level:
			player.velocity.y = 0.0
			player.trigger_jump()
			_expect(player.velocity.y < 0.0, "Jump level %d must allow air jump %d" % [level, air_index + 1])
		player.velocity.y = 0.0
		player.trigger_jump()
		_expect(is_zero_approx(player.velocity.y), "Jump level %d must reject air jumps beyond its upgrade level" % level)
		var runtime = player.ability_controller.ability(&"jump")
		runtime.on_support_contact()
		player.velocity.y = 0.0
		player.trigger_jump()
		_expect(player.velocity.y < 0.0, "landing reset must restore Jump level %d air-jump budget" % level)
		await _free_node(setup.root)

func test_climb_wall_jump_count() -> void:
	var stub = ABILITY_PLAYER_STUB_SCRIPT.new()
	stub.on_wall = true
	stub.wall_normal = Vector2.LEFT
	var climb = CLIMB_ABILITY_SCRIPT.new().setup(ABILITY_CATALOG_SCRIPT.CLIMB, stub, null, 2)
	_expect(climb.try_wall_jump(), "Climb level 2 must allow the first wall jump")
	_expect(stub.last_jump_wall_normal == Vector2.LEFT, "wall jump must push using the contacted wall normal")
	_expect(climb.try_wall_jump(), "Climb level 2 must allow the second wall jump before landing")
	_expect(not climb.try_wall_jump(), "Climb level 2 must reject a third wall jump before landing")
	climb.on_support_contact()
	_expect(climb.try_wall_jump(), "floor support must reset the Climb wall-jump budget")
	stub.free()

func test_glide_duration() -> void:
	var stub = ABILITY_PLAYER_STUB_SCRIPT.new()
	stub.supported = false
	stub.velocity = Vector2(0.0, 120.0)
	var glide = GLIDE_ABILITY_SCRIPT.new().setup(ABILITY_CATALOG_SCRIPT.GLIDE, stub, null, 1)
	var half_duration := GameConfig.MAX_GLIDE_DURATION * 0.5
	_expect(is_equal_approx(glide.gravity_multiplier(half_duration, true), GameConfig.GLIDE_GRAVITY_FACTOR), "Glide must reduce gravity while jump remains held during a fall")
	_expect(is_equal_approx(glide.gravity_multiplier(half_duration, true), GameConfig.GLIDE_GRAVITY_FACTOR), "Glide must remain active through MAX_GLIDE_DURATION")
	_expect(is_equal_approx(glide.gravity_multiplier(0.01, true), 1.0), "Glide must stop reducing gravity after MAX_GLIDE_DURATION")
	glide.on_support_contact()
	_expect(is_equal_approx(glide.gravity_multiplier(0.01, true), GameConfig.GLIDE_GRAVITY_FACTOR), "landing must reset Glide duration")
	_expect(is_equal_approx(glide.gravity_multiplier(0.01, false), 1.0), "releasing jump must stop Glide immediately")
	stub.free()

func test_reverse_gravity_semantics() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_abilities = ["jump", "reverse_gravity"]
	GameState.profile.equipped_abilities = ["reverse_gravity"]
	var player = await _spawn_player(false)
	_expect(is_equal_approx(player.gravity_direction, 1.0) and player.up_direction == Vector2.UP, "player must start with normal downward gravity")
	player.trigger_jump()
	_expect(is_equal_approx(player.gravity_direction, -1.0), "Reverse Gravity jump activation must invert gravity")
	_expect(player.up_direction == Vector2.DOWN, "Reverse Gravity must invert CharacterBody2D floor/ceiling semantics through up_direction")
	_expect(player.sprite.flip_v, "Reverse Gravity must provide upside-down visual feedback")
	player.trigger_jump()
	_expect(is_equal_approx(player.gravity_direction, 1.0) and player.up_direction == Vector2.UP, "a second Reverse Gravity jump activation must toggle gravity back")
	await _free_node(player)

func test_fly_allows_unlimited_air_jumps() -> void:
	var stub = ABILITY_PLAYER_STUB_SCRIPT.new()
	stub.supported = false
	var fly = FLY_ABILITY_SCRIPT.new().setup(ABILITY_CATALOG_SCRIPT.FLY, stub, null, 1)
	for index in 12:
		stub.velocity.y = 0.0
		_expect(fly.try_jump(), "Fly must permit repeated air jump %d without a finite jump budget" % (index + 1))
	_expect(stub.jump_calls == 12, "Fly must dispatch every requested air jump")
	stub.free()

func test_dash_distance_and_cooldown() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_abilities = ["jump", "dash"]
	GameState.profile.equipped_abilities = ["dash"]
	var player = await _spawn_player(false)
	var start_x: float = player.global_position.x
	_expect(player.trigger_ability(&"dash"), "equipped Dash must activate")
	_expect(player.ability_cooldown_remaining(&"dash") > 0.0, "Dash activation must start the common cooldown")
	var frames := 0
	while player.ability_controller.is_dashing() and frames < 120:
		await get_tree().physics_frame
		frames += 1
	var travelled: float = player.global_position.x - start_x
	var expected := GameConfig.tiles_to_pixels(GameConfig.DASH_TILES)
	_expect(frames < 120, "Dash must finish from travelled distance rather than run indefinitely")
	_expect(absf(travelled - expected) <= 1.0, "Dash must travel exactly DASH_TILES independent of frame count (actual %.3f, expected %.3f)" % [travelled, expected])
	_expect(not player.trigger_ability(&"dash"), "Dash must reject reactivation while cooldown remains")
	await _free_node(player)

	var holder := Node2D.new()
	add_child(holder)
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	var wall_collision := CollisionShape2D.new()
	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2(32.0, 600.0)
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	wall.position = Vector2(160.0, 0.0)
	holder.add_child(wall)
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2.ZERO
	holder.add_child(player)
	await get_tree().process_frame
	start_x = player.global_position.x
	_expect(player.trigger_ability(&"dash"), "a fresh Dash runtime must activate before collision testing")
	frames = 0
	while player.ability_controller.is_dashing() and frames < 120:
		await get_tree().physics_frame
		frames += 1
	travelled = player.global_position.x - start_x
	_expect(frames < 120, "Dash must terminate when a blocking collision prevents progress")
	_expect(travelled > 0.0 and travelled < expected - 1.0, "blocking collision must end Dash before DASH_TILES is reached")
	await _free_node(holder)

func test_explode_damage_and_destructible_terrain() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_abilities = ["jump", "explode"]
	GameState.profile.equipped_abilities = ["explode"]
	var player = await _spawn_player(false)
	var enemy = _spawn_melee_enemy(player.global_position + Vector2(GameConfig.tiles_to_pixels(1.0), 0.0), 200.0, true)
	var far_enemy = _spawn_melee_enemy(player.global_position + Vector2(GameConfig.tiles_to_pixels(GameConfig.EXPLODE_RADIUS + 2.0), 0.0), 200.0, true)
	_expect(player.trigger_ability(&"explode"), "equipped Explode must activate")
	_expect(is_equal_approx(enemy.current_health, 200.0 - GameConfig.EXPLODE_DAMAGE), "Explode must damage enemies inside EXPLODE_RADIUS")
	_expect(is_equal_approx(far_enemy.current_health, 200.0), "Explode must not damage enemies outside EXPLODE_RADIUS")
	await _free_node(enemy)
	await _free_node(far_enemy)
	await _free_node(player)

	var streamer = STREAMER_SCRIPT.new()
	add_child(streamer)
	streamer.reset(91919)
	var protected_coords := Vector2i(0, GameConfig.BASE_PLATFORM_HEIGHT)
	var protected_source: int = streamer.terrain_layer.get_cell_source_id(protected_coords)
	var protected_center: Vector2 = streamer.terrain_layer.to_global(streamer.terrain_layer.map_to_local(protected_coords))
	_expect(protected_source != -1, "Explode terrain test requires the authored starting platform")
	_expect(streamer.break_tiles_in_radius(protected_center, 0.25) == 0, "protected starting terrain must not be destructible")
	_expect(streamer.terrain_layer.get_cell_source_id(protected_coords) == protected_source, "protected terrain must remain after Explode query")
	var breakable_coords := Vector2i.ZERO
	var found_breakable := false
	for raw_coords in streamer.breakable_cells.keys():
		var coords: Vector2i = raw_coords
		if bool(streamer.breakable_cells[coords]) and streamer.terrain_layer.get_cell_source_id(coords) != -1:
			breakable_coords = coords
			found_breakable = true
			break
	_expect(found_breakable, "procedural generator must mark generated terrain as breakable for Explode")
	if found_breakable:
		var breakable_center: Vector2 = streamer.terrain_layer.to_global(streamer.terrain_layer.map_to_local(breakable_coords))
		_expect(streamer.break_tiles_in_radius(breakable_center, 0.25) == 1, "Explode terrain query must erase a breakable generated tile")
		_expect(streamer.terrain_layer.get_cell_source_id(breakable_coords) == -1, "breakable generated tile must be removed from the TileMapLayer")
	await _free_node(streamer)

func test_slow_down_uses_world_multipliers() -> void:
	WorldSpeed.reset()
	GameState.reset_profile()
	GameState.profile.unlocked_abilities = ["jump", "slow_down_time"]
	GameState.profile.equipped_abilities = ["slow_down_time"]
	var player = await _spawn_player(false)
	var engine_scale_before := Engine.time_scale
	_expect(player.trigger_ability(&"slow_down_time"), "equipped Slow Down Time must activate")
	_expect(WorldSpeed.is_slow_active(), "Slow Down Time must activate WorldSpeed state")
	_expect(is_equal_approx(WorldSpeed.player_speed_multiplier, GameConfig.SLOW_TIME_PLAYER_SPEED_MULTIPLIER), "Slow Down Time must apply the configured player-speed multiplier")
	_expect(is_equal_approx(WorldSpeed.enemy_move_multiplier, GameConfig.SLOW_TIME_ENEMY_MOVE_MULTIPLIER), "Slow Down Time must expose the configured enemy movement multiplier")
	_expect(is_equal_approx(WorldSpeed.enemy_fire_interval_multiplier, GameConfig.SLOW_TIME_ENEMY_FIRE_INTERVAL_MULTIPLIER), "Slow Down Time must expose the configured enemy firing-interval multiplier")
	_expect(is_equal_approx(WorldSpeed.projectile_speed_multiplier, GameConfig.SLOW_TIME_PROJECTILE_SPEED_MULTIPLIER), "Slow Down Time must expose the configured projectile-speed multiplier")
	_expect(is_equal_approx(player.run_speed_pixels(), GameConfig.tiles_to_pixels(GameConfig.SPEED) * GameConfig.SLOW_TIME_PLAYER_SPEED_MULTIPLIER), "player auto-run must consume the WorldSpeed player multiplier")
	_expect(is_equal_approx(Engine.time_scale, engine_scale_before), "Slow Down Time must not modify Engine.time_scale")
	WorldSpeed._process(WorldSpeed.slow_remaining + 0.01)
	_expect(not WorldSpeed.is_slow_active(), "WorldSpeed multipliers must reset when slow duration expires")
	_expect(is_equal_approx(WorldSpeed.player_speed_multiplier, 1.0), "expired Slow Down Time must restore player speed")
	await _free_node(player)
	WorldSpeed.reset()

func test_invisibility_detectability_and_duration() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_abilities = ["jump", "invisibility"]
	GameState.profile.equipped_abilities = ["invisibility"]
	var player = await _spawn_player(false)
	_expect(player.detectable, "player must start detectable")
	_expect(player.trigger_ability(&"invisibility"), "equipped Invisibility must activate")
	_expect(not player.detectable and not player.is_detectable(), "Invisibility must change explicit gameplay detectability, not only presentation")
	_expect(is_equal_approx(player.sprite.modulate.a, GameConfig.INVISIBILITY_ALPHA), "Invisibility must provide transparency as visual feedback")
	var runtime = player.ability_controller.ability(&"invisibility")
	_expect(runtime.duration_remaining > 0.0, "Invisibility duration must come from the persistent invisibility-duration stat")
	player.ability_controller.tick(runtime.duration_remaining + 0.01)
	_expect(player.detectable, "Invisibility must restore detectability when its duration expires")
	_expect(is_equal_approx(player.sprite.modulate.a, 1.0), "expired Invisibility must restore player alpha")
	_expect(player.ability_cooldown_remaining(&"invisibility") > 0.0, "Invisibility activation must start the common cooldown")
	await _free_node(player)

func test_enemy_biome_restriction() -> void:
	var all_enemies: Array = ENEMY_CATALOG_SCRIPT.all()
	_expect(all_enemies.size() == 39, "Phase 10 must define every one of the 39 supplied enemy character sets")
	var mapped_ids: Dictionary = {}
	var mapped_animation_roots: Dictionary = {}
	var themed_status_ids: Dictionary = {}
	var has_stationary := false
	var has_patrol := false
	var has_melee_only := false
	var has_shoot_only := false
	var has_both := false
	var has_projectile_shooter := false
	var has_beam_shooter := false

	for biome in BiomeCatalog.all():
		_expect(biome.enemy_pool.size() > 1, "%s biome must map more than one enemy" % biome.display_name)
		var first_encounter: Array = ENEMY_CATALOG_SCRIPT.available_for_biome(biome, 1)
		_expect(first_encounter.size() > 1, "%s biome must expose more than one enemy on its first encounter" % biome.display_name)
		var has_later_enemy := false
		for enemy_id in biome.enemy_pool:
			var id_string := String(enemy_id)
			_expect(not mapped_ids.has(id_string), "enemy '%s' must be assigned to exactly one biome" % id_string)
			mapped_ids[id_string] = biome.id
			var data = ENEMY_CATALOG_SCRIPT.get_by_id(enemy_id)
			_expect(data != null, "biome enemy id '%s' must resolve to EnemyData" % id_string)
			if data == null:
				continue
			_expect(data.biome_id == biome.id, "enemy '%s' EnemyData biome must match its BiomeData pool" % id_string)
			_expect(data.minimum_encounter >= 1, "enemy '%s' minimum encounter must be positive" % id_string)
			has_later_enemy = has_later_enemy or data.minimum_encounter > 1
			var animation_root := String(data.animation_root)
			_expect(not animation_root.is_empty(), "enemy '%s' must reference its supplied animation set" % id_string)
			_expect(not mapped_animation_roots.has(animation_root), "each enemy definition must map a distinct supplied animation set: %s" % animation_root)
			mapped_animation_roots[animation_root] = id_string
			_expect(_directory_has_png(animation_root.path_join(data.idle_animation_folder)), "enemy '%s' idle animation must resolve to supplied PNG frames" % id_string)
			if biome.id != BiomeData.Id.GRASS:
				var status_id := String(data.status_effect.id) if data.status_effect != null else ""
				_expect(data.status_effect is Resource, "non-Grass enemy '%s' must reference a StatusEffect resource" % id_string)
				_expect(not status_id.is_empty(), "non-Grass enemy '%s' must carry themed status metadata" % id_string)
				_expect(not themed_status_ids.has(status_id), "non-Grass enemy status '%s' must be unique" % status_id)
				themed_status_ids[status_id] = id_string
			has_stationary = has_stationary or data.movement_mode == ENEMY_DATA_SCRIPT.MovementMode.STATIONARY
			has_patrol = has_patrol or data.movement_mode == ENEMY_DATA_SCRIPT.MovementMode.PATROL
			var melee: bool = data.has_attack(ENEMY_DATA_SCRIPT.AttackMode.MELEE)
			var shoot: bool = data.has_attack(ENEMY_DATA_SCRIPT.AttackMode.SHOOT)
			has_melee_only = has_melee_only or (melee and not shoot)
			has_shoot_only = has_shoot_only or (shoot and not melee)
			has_both = has_both or (melee and shoot)
			if shoot:
				has_projectile_shooter = has_projectile_shooter or data.ranged_style == ENEMY_DATA_SCRIPT.RangedStyle.PROJECTILE
				has_beam_shooter = has_beam_shooter or data.ranged_style == ENEMY_DATA_SCRIPT.RangedStyle.BEAM
		_expect(has_later_enemy, "%s biome must reserve at least one enemy for a later encounter" % biome.display_name)

	var physical_roots := _physical_enemy_animation_roots()
	_expect(physical_roots.size() == 39, "enemy asset tree must still expose the expected 39 character animation roots")
	_expect(mapped_ids.size() == all_enemies.size(), "every EnemyData resource must appear in exactly one biome pool")
	_expect(mapped_animation_roots.size() == physical_roots.size(), "every supplied enemy animation root must be mapped exactly once")
	for root in physical_roots:
		_expect(mapped_animation_roots.has(root), "supplied enemy animation set must be mapped: %s" % root)
	_expect(has_stationary and has_patrol, "generic enemy data must cover stationary and patrol movement modes")
	_expect(has_melee_only and has_shoot_only and has_both, "generic enemy data must cover melee-only, shoot-only, and hybrid attack modes")
	_expect(has_projectile_shooter and has_beam_shooter, "enemy catalog must exercise both projectile and beam ranged styles")
	var level = LEVEL_SCENE.instantiate()
	_expect(level.has_node("EnemySpawner"), "level scene must own a reusable EnemySpawner")
	level.free()

func test_enemy_level_scaling() -> void:
	var data = ENEMY_CATALOG_SCRIPT.get_by_id(&"death_knight")
	_expect(data != null, "enemy level test requires Death Knight data")
	if data == null:
		return
	_expect(is_equal_approx(data.health_for_level(1), data.base_health), "enemy level 1 health must equal base health")
	_expect(is_equal_approx(data.damage_for_level(1), data.base_damage), "enemy level 1 damage must equal base damage")
	_expect(is_equal_approx(data.health_for_level(3), data.base_health + data.health_per_level * 2.0), "enemy health must scale by health_per_level")
	_expect(is_equal_approx(data.damage_for_level(3), data.base_damage + data.damage_per_level * 2.0), "enemy damage must scale by damage_per_level")
	_expect(data.health_for_level(3) > data.health_for_level(1), "higher-level enemies must have more health")
	_expect(data.damage_for_level(3) > data.damage_for_level(1), "higher-level enemies must deal more damage")
	var sequence = BIOME_SEQUENCE_SCRIPT.new(9191)
	var later_grass_tile := -1
	for encounter in range(BiomeCatalog.ORDERED.size(), 160):
		var tile := encounter * GameConfig.BIOME_INTERVAL
		if sequence.get_biome_id_for_tile(tile) == BiomeData.Id.GRASS:
			later_grass_tile = tile
			break
	_expect(later_grass_tile >= 0, "seeded biome sequence must eventually revisit Grass")
	if later_grass_tile >= 0:
		_expect(sequence.get_biome_occurrence_for_tile(later_grass_tile) >= 2, "biome occurrence counter must distinguish later encounters")
		var later_pool: Array = ENEMY_CATALOG_SCRIPT.available_for_biome(BiomeCatalog.GRASS, sequence.get_biome_occurrence_for_tile(later_grass_tile))
		_expect(later_pool.size() > ENEMY_CATALOG_SCRIPT.available_for_biome(BiomeCatalog.GRASS, 1).size(), "later biome encounters must unlock higher-minimum-encounter enemies")

func test_enemy_patrol() -> void:
	var target = _spawn_enemy_target(Vector2(2000.0, 0.0))
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame
	enemy.global_position = Vector2.ZERO
	enemy.configure(ENEMY_CATALOG_SCRIPT.get_by_id(&"barbarian_warrior"), 1, target)
	var range_pixels := GameConfig.tiles_to_pixels(enemy.data.patrol_range_tiles)
	enemy.patrol_direction = 1.0
	enemy.global_position.x = enemy.spawn_x + range_pixels + 1.0
	enemy._update_movement(1.0 / 60.0)
	_expect(enemy.patrol_direction < 0.0 and enemy.velocity.x < 0.0, "patrol enemy must turn back at the right patrol boundary")
	enemy.patrol_direction = -1.0
	enemy.global_position.x = enemy.spawn_x - range_pixels - 1.0
	enemy._update_movement(1.0 / 60.0)
	_expect(enemy.patrol_direction > 0.0 and enemy.velocity.x > 0.0, "patrol enemy must turn back at the left patrol boundary")
	_expect(is_equal_approx(absf(enemy.velocity.x), GameConfig.tiles_to_pixels(enemy.data.move_speed_tiles) * WorldSpeed.enemy_move_multiplier), "patrol speed must consume EnemyData and WorldSpeed movement tuning")
	await _free_node(enemy)
	await _free_node(target)

func test_stationary_enemy() -> void:
	var target = _spawn_enemy_target(Vector2(2000.0, 0.0))
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame
	enemy.global_position = Vector2.ZERO
	enemy.configure(ENEMY_CATALOG_SCRIPT.get_by_id(&"archer_guy"), 1, target)
	var x_before: float = enemy.global_position.x
	enemy._update_movement(0.1)
	_expect(is_zero_approx(enemy.velocity.x), "stationary enemy must not receive horizontal patrol velocity")
	_expect(is_equal_approx(enemy.global_position.x, x_before), "stationary enemy must remain at its authored horizontal position")
	await _free_node(enemy)
	await _free_node(target)

func test_enemy_melee_vicinity() -> void:
	var target = _spawn_enemy_target(Vector2(24.0, 0.0))
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame
	enemy.global_position = Vector2.ZERO
	enemy.configure(ENEMY_CATALOG_SCRIPT.get_by_id(&"barbarian_warrior"), 2, target)
	var health_before: float = target.current_health
	_expect(enemy._try_melee_attack(), "melee enemy must attack a detectable player inside melee vicinity")
	_expect(is_equal_approx(target.current_health, health_before - enemy.damage_amount()), "enemy melee must apply level-scaled damage")
	_expect(target.last_damage_info != null and target.last_damage_info.damage_type == DAMAGE_INFO_SCRIPT.DamageType.MELEE, "enemy melee must dispatch shared MELEE DamageInfo")
	_expect(not enemy._try_melee_attack(), "enemy melee interval must prevent an immediate repeated hit")
	enemy.melee_cooldown_remaining = 0.0
	target.global_position = Vector2(GameConfig.tiles_to_pixels(enemy.data.melee_range_tiles + 1.0), 0.0)
	_expect(not enemy._try_melee_attack(), "melee enemy must not attack outside its configured melee vicinity")
	target.global_position = Vector2(24.0, 0.0)
	target.set_detectable(false)
	_expect(not enemy._try_melee_attack(), "invisible player must not be acquired for enemy melee")
	await _free_node(enemy)
	await _free_node(target)

func test_enemy_shooting_vicinity() -> void:
	var target = _spawn_enemy_target(Vector2(GameConfig.tiles_to_pixels(3.0), 0.0))
	var projectile_parent := Node2D.new()
	add_child(projectile_parent)
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame
	enemy.global_position = Vector2.ZERO
	enemy.configure(ENEMY_CATALOG_SCRIPT.get_by_id(&"archer_guy"), 1, target, projectile_parent)
	enemy.shooting_cooldown_remaining = 0.0
	_expect(enemy._try_shoot(), "shooting enemy must fire at a detectable player inside its configured vicinity")
	_expect(projectile_parent.get_child_count() == 1, "projectile-style enemy attack must instantiate exactly one projectile")
	var projectile := projectile_parent.get_child(0)
	_expect(projectile is Area2D and projectile.has_node("CollisionShape2D"), "enemy projectile gameplay collision must be an Area2D hitbox")
	_expect(projectile.has_node("Particles"), "enemy projectile visuals must use a separate particle emitter")
	var count_before := projectile_parent.get_child_count()
	enemy.shooting_cooldown_remaining = 0.0
	target.global_position = Vector2(GameConfig.tiles_to_pixels(enemy.data.vicinity_tiles + 1.0), 0.0)
	_expect(not enemy._try_shoot() and projectile_parent.get_child_count() == count_before, "shooting enemy must not fire outside its configured vicinity")
	target.global_position = Vector2(GameConfig.tiles_to_pixels(3.0), 0.0)
	target.set_detectable(false)
	_expect(not enemy._try_shoot(), "invisible player must not be acquired for enemy shooting")
	await _free_node(enemy)
	await _free_node(projectile_parent)
	target.set_detectable(true)

	var beam_parent := Node2D.new()
	add_child(beam_parent)
	var beam_enemy = ENEMY_SCENE.instantiate()
	add_child(beam_enemy)
	await get_tree().process_frame
	beam_enemy.global_position = Vector2.ZERO
	beam_enemy.configure(ENEMY_CATALOG_SCRIPT.get_by_id(&"frost_knight_3"), 3, target, beam_parent)
	beam_enemy.shooting_cooldown_remaining = 0.0
	_expect(beam_enemy._try_shoot(), "beam-style enemy must fire through the same generic shooting interface")
	_expect(beam_parent.get_child_count() == 1, "beam-style attack must instantiate exactly one beam effect")
	var beam := beam_parent.get_child(0)
	_expect(beam.has_node("RayCast2D"), "beam gameplay damage must be resolved by RayCast2D rather than particles")
	_expect(beam.has_node("Line2D") and beam.has_node("ImpactParticles"), "beam visuals must be separate from its gameplay ray")
	await _free_node(beam_enemy)
	await _free_node(beam_parent)
	await _free_node(target)

func test_enemy_fire_interval() -> void:
	WorldSpeed.reset()
	GameState.reset_profile()
	var target = _spawn_enemy_target(Vector2(GameConfig.tiles_to_pixels(3.0), 0.0))
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame
	enemy.configure(ENEMY_CATALOG_SCRIPT.get_by_id(&"archer_guy"), 1, target)
	_expect(is_equal_approx(enemy.effective_shooting_interval(), enemy.data.shooting_interval), "default enemy shooting interval must equal EnemyData cadence")
	var levels: Dictionary = GameState.profile.get("stat_levels", {}).duplicate(true)
	levels["enemy_fire_interval_multiplier"] = 3
	GameState.profile["stat_levels"] = levels
	var profile_multiplier := float(GameState.stat_value(&"enemy_fire_interval_multiplier"))
	_expect(profile_multiplier > 1.0, "enemy fire interval progression test requires an upgraded beneficial multiplier")
	_expect(is_equal_approx(enemy.effective_shooting_interval(), enemy.data.shooting_interval * profile_multiplier), "enemy firing interval must consume the persistent player stat multiplier")
	WorldSpeed.activate_slow(2.0)
	_expect(is_equal_approx(enemy.effective_shooting_interval(), enemy.data.shooting_interval * profile_multiplier * GameConfig.SLOW_TIME_ENEMY_FIRE_INTERVAL_MULTIPLIER), "enemy firing interval must also consume WorldSpeed slow-time multiplier")
	WorldSpeed.reset()
	await _free_node(enemy)
	await _free_node(target)
	GameState.reset_profile()

func test_enemy_projectile_damage_and_status() -> void:
	var target = _spawn_enemy_target(Vector2.ZERO)
	var projectile = ENEMY_PROJECTILE_SCENE.instantiate()
	projectile.global_position = Vector2(160.0, 0.0)
	add_child(projectile)
	await get_tree().process_frame
	var status := {"id": &"freeze", "duration": 1.5}
	projectile.configure(null, target.global_position, 17.0, status, 480.0)
	var health_before: float = target.current_health
	for _index in 60:
		await get_tree().physics_frame
		if target.damage_events > 0:
			break
	_expect(is_equal_approx(target.current_health, health_before - 17.0), "enemy projectile hitbox must apply configured damage through DamageableContract")
	_expect(target.last_damage_info != null and target.last_damage_info.damage_type == DAMAGE_INFO_SCRIPT.DamageType.PROJECTILE, "enemy projectile must dispatch PROJECTILE DamageInfo")
	if target.last_damage_info != null:
		_expect(target.last_damage_info.status_effect != null and String(target.last_damage_info.status_effect.id) == "freeze", "enemy projectile must carry themed EnemyData status metadata independently of visuals")
	_expect(not target.status_effects.is_empty() and String(target.status_effects[-1].id) == "freeze", "damage target must receive projectile status metadata")
	await _free_node(target)

func test_enemy_death() -> void:
	var target = _spawn_enemy_target(Vector2(2000.0, 0.0))
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame
	enemy.configure(ENEMY_CATALOG_SCRIPT.get_by_id(&"barbarian_warrior"), 2, target)
	_expect(DAMAGEABLE_CONTRACT_SCRIPT.supports(enemy), "generic enemy must implement the shared damage contract")
	enemy.take_damage(enemy.maximum_health + 1.0, DAMAGE_INFO_SCRIPT.new(target, DAMAGE_INFO_SCRIPT.DamageType.MELEE))
	_expect(enemy.dead and is_zero_approx(enemy.current_health), "lethal enemy damage must enter dead state at zero health")
	_expect(not enemy.can_receive_melee_attack() and not enemy.can_receive_projectile_attack(), "dead enemy must immediately stop accepting player attacks")
	_expect(not enemy.health_bar.visible, "dead enemy health bar must be hidden")
	await get_tree().process_frame
	_expect(enemy.body_collision.disabled and enemy.hurtbox_collision.disabled, "enemy death must disable body and hurtbox collisions")
	await _free_node(enemy)
	await _free_node(target)

func test_enemy_health_bar_updates() -> void:
	var target = _spawn_enemy_target(Vector2(2000.0, 0.0))
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame
	enemy.configure(ENEMY_CATALOG_SCRIPT.get_by_id(&"barbarian_warrior"), 3, target)
	_expect(is_equal_approx(enemy.health_bar.max_value, enemy.maximum_health), "enemy health bar maximum must match level-scaled maximum health")
	_expect(is_equal_approx(enemy.health_bar.value, enemy.current_health), "enemy health bar value must start at current health")
	_expect(enemy.health_bar.visible, "living enemy health bar must remain visible above the enemy")
	enemy.take_damage(7.0)
	_expect(enemy.health_bar.visible and is_equal_approx(enemy.health_bar.value, enemy.current_health), "enemy health bar must appear and update immediately after damage")
	enemy.heal(enemy.maximum_health)
	_expect(is_equal_approx(enemy.health_bar.value, enemy.maximum_health) and enemy.health_bar.visible, "enemy health bar must stay visible and update after full healing")
	await _free_node(enemy)
	await _free_node(target)

func test_enemy_spawner_is_seeded() -> void:
	var streamer = STREAMER_SCRIPT.new()
	streamer.biome_sequence.reset(424242)
	var spawner = ENEMY_SPAWNER_SCRIPT.new()
	spawner.world_streamer = streamer
	spawner.run_seed = 424242
	var spec := {
		"biome_id": BiomeData.Id.GRASS,
		"start_tile": 16,
		"platforms": [
			{"start_tile": 16, "width_tiles": 8, "height_tile": 8, "optional_route": false, "ceiling": false},
			{"start_tile": 25, "width_tiles": 9, "height_tile": 8, "optional_route": false, "ceiling": false},
		],
	}
	var first: Array[Dictionary] = spawner.spawn_specs_for_chunk(spec)
	var replay: Array[Dictionary] = spawner.spawn_specs_for_chunk(spec)
	_expect(not first.is_empty(), "eligible streamed chunk must produce at least one deterministic enemy spawn spec")
	_expect(first == replay, "enemy spawn selection and placement must replay exactly for the same run seed and chunk")
	_expect(first.size() <= GameConfig.ENEMY_MAX_PER_CHUNK, "enemy chunk spawning must respect the configured per-chunk bound")
	for spawn_spec in first:
		_expect(BiomeCatalog.GRASS.enemy_pool.has(StringName(spawn_spec.enemy_id)), "spawned enemy id must belong to the active biome pool")
		_expect(int(spawn_spec.level) == 1, "first Grass encounter must spawn level-1 eligible enemies")
	streamer.free()
	spawner.free()

func test_streamed_enemy_cleanup() -> void:
	GameState.reset_run(30303)
	var holder := Node2D.new()
	add_child(holder)
	var streamer = STREAMER_SCRIPT.new()
	holder.add_child(streamer)
	var enemy_container := Node2D.new()
	enemy_container.name = "EnemyContainer"
	holder.add_child(enemy_container)
	var projectile_container := Node2D.new()
	projectile_container.name = "ProjectileContainer"
	holder.add_child(projectile_container)
	var effects := Node2D.new()
	effects.name = "Effects"
	holder.add_child(effects)
	var target = ENEMY_TARGET_DUMMY_SCRIPT.new()
	target.global_position = Vector2.ZERO
	holder.add_child(target)
	var spawner = ENEMY_SPAWNER_SCRIPT.new()
	holder.add_child(spawner)
	await get_tree().process_frame
	streamer.biome_sequence.reset(30303)
	spawner.configure(streamer, enemy_container, target, projectile_container, effects)
	var spec := {
		"biome_id": BiomeData.Id.GRASS,
		"start_tile": 16,
		"platforms": [{"start_tile": 16, "width_tiles": 10, "height_tile": 8, "optional_route": false, "ceiling": false}],
	}
	spawner._on_chunk_generated(spec)
	_expect(enemy_container.get_child_count() > 0, "streamed chunk generation must instantiate Enemy scenes into EnemyContainer")
	_expect(spawner.enemies_by_chunk.has(16), "EnemySpawner must track spawned enemies by streamed chunk for bounded cleanup")
	if enemy_container.get_child_count() > 0:
		var spawned_enemy = enemy_container.get_child(0)
		_expect(spawned_enemy.is_in_group(&"enemies"), "streamed Enemy scene must register in the common enemies group")
		_expect(spawned_enemy.data != null and BiomeCatalog.GRASS.enemy_pool.has(spawned_enemy.data.id), "streamed enemy must be configured from the chunk biome pool")
	spawner._on_chunk_removed(spec)
	await get_tree().process_frame
	_expect(enemy_container.get_child_count() == 0, "removing a streamed chunk must release its enemy instances")
	_expect(not spawner.enemies_by_chunk.has(16), "EnemySpawner chunk registry must not retain cleaned enemies")
	await _free_node(holder)

func test_status_effect_resources_are_valid() -> void:
	var effects: Array = STATUS_EFFECT_CATALOG_SCRIPT.all()
	var ids := {}
	_expect(effects.size() >= 35, "Phase 11 status catalog must expose every themed enemy effect plus Freeze/Burn/BloodLoss/Poison/Slow")
	for effect in effects:
		_expect(effect is Resource and effect.get_script() == STATUS_EFFECT_SCRIPT, "status catalog entries must be StatusEffect resources")
		if effect == null:
			continue
		_expect(effect.is_valid(), "status effect '%s' must have valid duration/tick/stack/runtime values" % String(effect.id))
		_expect(not ids.has(effect.id), "status effect ids must be unique: '%s'" % String(effect.id))
		ids[effect.id] = true
	for required_id in [&"freeze", &"burn", &"blood_loss", &"poison", &"slow"]:
		_expect(ids.has(required_id), "status catalog must include required '%s' effect" % String(required_id))

func test_status_effect_dictionary_compatibility() -> void:
	var resolved = STATUS_EFFECT_CATALOG_SCRIPT.resolve({"id": &"freeze", "duration": 2.25})
	_expect(resolved != null and resolved.id == &"freeze", "legacy status dictionaries must resolve to canonical StatusEffect resources")
	_expect(resolved != null and is_equal_approx(resolved.duration, 2.25), "legacy status dictionaries must be able to override canonical duration")
	var canonical = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"freeze")
	_expect(canonical != null and is_equal_approx(canonical.duration, 1.4), "legacy overrides must duplicate rather than mutate the shared canonical status resource")
	var info = DAMAGE_INFO_SCRIPT.new(null, DAMAGE_INFO_SCRIPT.DamageType.FIRE, {"id": &"burn", "duration": 0.75})
	_expect(info.status_effect != null and info.status_effect.id == &"burn", "DamageInfo must normalize old status payloads at the combat boundary")

func test_freeze() -> void:
	WorldSpeed.reset()
	var player = await _spawn_player()
	player.set_physics_process(false)
	var freeze = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"freeze")
	var normal_speed: float = player.run_speed_pixels()
	_expect(player.apply_status(freeze), "Freeze must be accepted by the player's generic status controller")
	_expect(player.status_remaining(&"freeze") > 0.0, "Freeze must track remaining duration")
	_expect(is_equal_approx(player.run_speed_pixels(), normal_speed * freeze.movement_speed_multiplier), "Freeze must slow automatic running through the generic movement multiplier")
	_expect(is_equal_approx(player.sprite.modulate.r, freeze.tint.r) and is_equal_approx(player.sprite.modulate.g, freeze.tint.g) and is_equal_approx(player.sprite.modulate.b, freeze.tint.b), "Freeze must provide ice-blue player modulation feedback")
	player.status_controller.tick(freeze.duration + 0.01)
	_expect(is_zero_approx(player.status_remaining(&"freeze")), "Freeze must expire after its configured duration")
	_expect(is_equal_approx(player.run_speed_pixels(), normal_speed), "Freeze expiration must restore normal automatic run speed")
	await _free_node(player)

func test_burn() -> void:
	var player = await _spawn_player()
	player.set_physics_process(false)
	var burn = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"burn")
	_expect(player.apply_status(burn), "Burn must be accepted by the player's generic status controller")
	_expect(player.status_controller.emits_flames(), "Burn metadata must request flame presentation")
	_expect(player.burn_particles.emitting, "Burn application must activate the player's GPUParticles2D flame feedback")
	_expect(is_equal_approx(player.sprite.modulate.r, burn.tint.r) and is_equal_approx(player.sprite.modulate.g, burn.tint.g), "Burn must tint the player independently of damage collision logic")
	player.status_controller.clear_all()
	_expect(not player.burn_particles.emitting, "removing Burn must stop flame particles immediately")
	await _free_node(player)

func test_blood_loss() -> void:
	var player = await _spawn_player()
	player.set_physics_process(false)
	var blood_loss = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"blood_loss")
	var health_before: float = player.current_health
	player.apply_status(blood_loss)
	player.status_controller.tick(blood_loss.tick_interval)
	var expected_damage: float = blood_loss.tick_damage * player.defense_multiplier
	_expect(is_equal_approx(player.current_health, health_before - expected_damage), "BloodLoss must deal periodic damage through StatusEffect.on_tick")
	_expect(player.status_tick_flash_remaining > 0.0, "BloodLoss ticks must request the periodic red blink feedback")
	_expect(player.sprite.modulate.r > player.sprite.modulate.g and player.sprite.modulate.r > player.sprite.modulate.b, "BloodLoss tick feedback must visibly blink red")
	await _free_node(player)

func test_poison() -> void:
	var target = STATUS_TARGET_DUMMY_SCRIPT.new()
	var controller = STATUS_EFFECT_CONTROLLER_SCRIPT.new()
	controller.configure(target)
	var poison = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"poison")
	controller.apply(poison)
	controller.tick(poison.tick_interval)
	_expect(target.tick_damage_events == 1, "Poison must tick at its configured interval")
	_expect(is_equal_approx(target.total_tick_damage, poison.tick_damage), "Poison must dispatch configured periodic damage")
	_expect(target.ticked_ids == [&"poison"], "Poison on_tick hook must be observable on the affected target")
	controller.free()
	target.free()

func test_slow() -> void:
	var target = STATUS_TARGET_DUMMY_SCRIPT.new()
	var controller = STATUS_EFFECT_CONTROLLER_SCRIPT.new()
	controller.configure(target)
	var slow = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"slow")
	controller.apply(slow)
	_expect(is_equal_approx(controller.movement_speed_multiplier(), slow.movement_speed_multiplier), "Slow must expose its configured movement multiplier through the generic controller")
	_expect(target.tick_damage_events == 0, "Slow must not invent periodic damage when its resource defines none")
	controller.free()
	target.free()

func test_status_refresh_policy() -> void:
	var target = STATUS_TARGET_DUMMY_SCRIPT.new()
	var controller = STATUS_EFFECT_CONTROLLER_SCRIPT.new()
	controller.configure(target)
	var freeze = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"freeze")
	controller.apply(freeze)
	controller.tick(freeze.duration * 0.5)
	_expect(controller.remaining(&"freeze") < freeze.duration, "REFRESH policy fixture must consume duration before reapplication")
	controller.apply(freeze)
	_expect(is_equal_approx(controller.remaining(&"freeze"), freeze.duration), "REFRESH stack policy must reset remaining duration without adding stacks")
	_expect(controller.stacks(&"freeze") == 1, "REFRESH stack policy must keep one stack")
	controller.free()
	target.free()

func test_status_stack_policy() -> void:
	var target = STATUS_TARGET_DUMMY_SCRIPT.new()
	var controller = STATUS_EFFECT_CONTROLLER_SCRIPT.new()
	controller.configure(target)
	var blood_loss = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"blood_loss")
	for _index in 4:
		controller.apply(blood_loss)
	_expect(controller.stacks(&"blood_loss") == blood_loss.max_stacks, "STACK policy must clamp at StatusEffect.max_stacks")
	controller.tick(blood_loss.tick_interval)
	_expect(is_equal_approx(target.total_tick_damage, blood_loss.tick_damage * float(blood_loss.max_stacks)), "stacked periodic status damage must scale with the active stack count")
	controller.free()
	target.free()

func test_status_expiration() -> void:
	var target = STATUS_TARGET_DUMMY_SCRIPT.new()
	var controller = STATUS_EFFECT_CONTROLLER_SCRIPT.new()
	controller.configure(target)
	var slow = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"slow")
	controller.apply(slow)
	controller.tick(slow.duration + 0.1)
	_expect(not controller.has_effect(&"slow") and controller.is_empty(), "expired status effects must be removed from the active controller")
	_expect(target.removed_ids == [&"slow"], "status expiration must call StatusEffect.on_remove exactly once")
	_expect(is_equal_approx(controller.movement_speed_multiplier(), 1.0), "status expiration must restore the neutral movement multiplier")
	controller.free()
	target.free()

func test_status_damage_multiplier() -> void:
	var player = await _spawn_player()
	player.set_physics_process(false)
	var armor_break = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"armor_break")
	player.apply_status(armor_break)
	var health_before: float = player.current_health
	player.invulnerability_remaining = 0.0
	player.take_damage(10.0, DAMAGE_INFO_SCRIPT.new(null, DAMAGE_INFO_SCRIPT.DamageType.MELEE))
	var expected_damage: float = 10.0 * player.defense_multiplier * armor_break.damage_taken_multiplier
	_expect(is_equal_approx(player.current_health, health_before - expected_damage), "damage-amplifying statuses must compose with the player's persistent defense multiplier")
	await _free_node(player)

func test_enemy_uses_generic_status_controller() -> void:
	var target = _spawn_enemy_target(Vector2(2000.0, 0.0))
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	await get_tree().process_frame
	enemy.configure(ENEMY_CATALOG_SCRIPT.get_by_id(&"barbarian_warrior"), 1, target)
	var freeze = STATUS_EFFECT_CATALOG_SCRIPT.get_by_id(&"freeze")
	var info = DAMAGE_INFO_SCRIPT.new(target, DAMAGE_INFO_SCRIPT.DamageType.GENERIC, freeze)
	enemy.take_damage(1.0, info)
	_expect(enemy.status_remaining(&"freeze") > 0.0, "generic Enemy must apply status metadata carried by incoming DamageInfo")
	_expect(is_equal_approx(enemy.status_controller.movement_speed_multiplier(), freeze.movement_speed_multiplier), "Enemy and player must reuse the same StatusEffectController movement semantics")
	_expect(is_equal_approx(enemy.sprite.modulate.b, freeze.tint.b), "generic Enemy must expose status tint feedback through the same resource metadata")
	await _free_node(enemy)
	await _free_node(target)

func test_collectible_definitions_are_valid() -> void:
	var ids: Dictionary = {}
	_expect(COLLECTIBLE_CATALOG_SCRIPT.ALL.size() == 6, "Phase 12 must define bronze/silver/gold coins and three supplied gem variants")
	for collectible in COLLECTIBLE_CATALOG_SCRIPT.ALL:
		_expect(collectible != null and collectible.is_valid(), "every collectible resource must have an id, positive gold value, and texture")
		if collectible == null:
			continue
		var id_string := String(collectible.id)
		_expect(not ids.has(id_string), "collectible ids must be unique: %s" % id_string)
		ids[id_string] = true
		_expect(FileAccess.file_exists(collectible.texture_path), "collectible '%s' must reference a supplied asset" % id_string)
		_expect(collectible.spawnable and collectible.droppable, "Phase 12 collectible definitions must be eligible for procedural placement and data-driven drops")

func test_gem_value_exceeds_coin() -> void:
	_expect(COLLECTIBLE_CATALOG_SCRIPT.minimum_gem_value() > COLLECTIBLE_CATALOG_SCRIPT.maximum_coin_value(), "every gem gold value must exceed every coin gold value")
	_expect(COLLECTIBLE_CATALOG_SCRIPT.BRONZE_COIN.gold_value < COLLECTIBLE_CATALOG_SCRIPT.SILVER_COIN.gold_value, "silver coin must be worth more than bronze coin")
	_expect(COLLECTIBLE_CATALOG_SCRIPT.SILVER_COIN.gold_value < COLLECTIBLE_CATALOG_SCRIPT.GOLD_COIN.gold_value, "gold coin must be worth more than silver coin")

func test_pickup_increases_gold() -> void:
	GameState.reset_profile()
	var pickup = COLLECTIBLE_PICKUP_SCENE.instantiate()
	add_child(pickup)
	pickup.configure(COLLECTIBLE_CATALOG_SCRIPT.SILVER_COIN)
	var before := GameState.gold_count()
	var awarded: int = pickup.collect()
	_expect(awarded == COLLECTIBLE_CATALOG_SCRIPT.SILVER_COIN.gold_value, "collecting a pickup must return its configured gold value")
	_expect(GameState.gold_count() == before + awarded, "collecting a pickup must increase persistent profile gold")
	_expect(pickup.collect() == 0, "a collectible pickup must be idempotent and never award twice")
	await get_tree().process_frame
	GameState.reset_profile()

func test_collectible_spawn_is_seeded() -> void:
	var spawner = COLLECTIBLE_SPAWNER_SCRIPT.new()
	var spec := {
		"biome_id": BiomeData.Id.GRASS,
		"archetype": ProceduralLayoutGenerator.Archetype.GAPS,
		"start_tile": 32,
		"end_tile": 44,
		"platforms": [
			{"start_tile": 32, "width_tiles": 10, "height_tile": 8, "optional_route": false, "ceiling": false},
			{"start_tile": 43, "width_tiles": 8, "height_tile": 7, "optional_route": false, "ceiling": false},
		],
		"bonus_spawn_tiles": [Vector2i(39, 5)],
	}
	var first: Array[Dictionary] = spawner.spawn_specs_for_chunk(spec, RNG_SERVICE_SCRIPT.new(70707))
	var replay: Array[Dictionary] = spawner.spawn_specs_for_chunk(spec, RNG_SERVICE_SCRIPT.new(70707))
	_expect(not first.is_empty(), "a chunk with a risky-route bonus slot must produce at least one collectible")
	_expect(first == replay, "procedural collectible selection must replay exactly with the same injected seed")
	_expect(first.size() <= GameConfig.COLLECTIBLE_MAX_PER_CHUNK, "procedural collectible count must respect the configured per-chunk bound")
	var found_bonus := false
	for spawn_spec in first:
		var collectible = COLLECTIBLE_CATALOG_SCRIPT.get_by_id(StringName(spawn_spec.collectible_id))
		_expect(collectible != null and collectible.spawnable, "procedural collectible ids must resolve to spawnable CollectibleData")
		if bool(spawn_spec.bonus):
			found_bonus = true
			_expect(is_equal_approx(float(spawn_spec.difficulty), 1.0), "risky optional-route collectible slots must carry maximum placement difficulty")
	_expect(found_bonus, "risky-route bonus_spawn_tiles must always be represented in collectible spawn specs")
	spawner.free()

func test_collectible_difficulty_biases_value() -> void:
	var spawner = COLLECTIBLE_SPAWNER_SCRIPT.new()
	var equal_weights := {&"bronze_coin": 1.0, &"gold_coin": 1.0, &"gem": 1.0}
	var easy: Dictionary = spawner.adjusted_spawn_weights(equal_weights, 0.0)
	var risky: Dictionary = spawner.adjusted_spawn_weights(equal_weights, 1.0)
	var easy_premium_ratio := (float(easy[&"gold_coin"]) + float(easy[&"gem"])) / float(easy[&"bronze_coin"])
	var risky_premium_ratio := (float(risky[&"gold_coin"]) + float(risky[&"gem"])) / float(risky[&"bronze_coin"])
	_expect(risky_premium_ratio > easy_premium_ratio, "higher platform difficulty must increase the relative weight of high-value collectibles")
	var flat_spec := {"archetype": ProceduralLayoutGenerator.Archetype.FLAT}
	var gap_spec := {"archetype": ProceduralLayoutGenerator.Archetype.GAPS}
	var platform := {"height_tile": GameConfig.BASE_PLATFORM_HEIGHT, "optional_route": false}
	_expect(spawner.placement_difficulty(gap_spec, platform) > spawner.placement_difficulty(flat_spec, platform), "gap layouts must be treated as riskier collectible placement than flat layouts")
	spawner.free()

func test_enemy_drop_tables_are_valid() -> void:
	for enemy_data in ENEMY_CATALOG_SCRIPT.all():
		_expect(enemy_data.has_valid_drop_table(), "enemy '%s' must carry a valid Phase 12 drop table" % String(enemy_data.id))
		for entry in enemy_data.drop_table:
			var probability := float(entry.get("probability", -1.0))
			var collectible = COLLECTIBLE_CATALOG_SCRIPT.get_by_id(StringName(String(entry.get("collectible_id", ""))))
			_expect(probability >= 0.0 and probability <= 1.0, "enemy '%s' drop probabilities must stay in [0, 1]" % String(enemy_data.id))
			_expect(collectible != null and collectible.droppable, "enemy '%s' drop table must reference droppable collectibles" % String(enemy_data.id))

func test_enemy_drop_probability_and_count() -> void:
	var data = ENEMY_DATA_SCRIPT.new()
	var deterministic_drop_table: Array[Dictionary] = [
		{"collectible_id": &"gold_coin", "probability": 1.0, "min_count": 2, "max_count": 2},
		{"collectible_id": &"gem_blue", "probability": 0.0, "min_count": 1, "max_count": 1},
	]
	data.drop_table = deterministic_drop_table
	var spawner = COLLECTIBLE_SPAWNER_SCRIPT.new()
	var first: Array[Dictionary] = spawner.drop_specs_for_enemy(data, RNG_SERVICE_SCRIPT.new(8888))
	var replay: Array[Dictionary] = spawner.drop_specs_for_enemy(data, RNG_SERVICE_SCRIPT.new(8888))
	_expect(first == replay, "enemy drop rolls must be deterministic for the same injected RNG seed")
	_expect(first.size() == 2, "100% two-count drop must emit exactly two pickup specs while 0% drops emit none")
	for drop_spec in first:
		_expect(StringName(drop_spec.collectible_id) == &"gold_coin", "drop probability test must only include the guaranteed collectible")
	spawner.free()

func test_enemy_death_spawns_drops() -> void:
	GameState.reset_run(42421)
	var holder := Node2D.new()
	add_child(holder)
	var pickup_container := Node2D.new()
	holder.add_child(pickup_container)
	var collectible_spawner = COLLECTIBLE_SPAWNER_SCRIPT.new()
	holder.add_child(collectible_spawner)
	collectible_spawner.pickup_container = pickup_container
	collectible_spawner.run_seed = 42421
	var target = _spawn_enemy_target(Vector2(2000.0, 0.0))
	var enemy = ENEMY_SCENE.instantiate()
	holder.add_child(enemy)
	await get_tree().process_frame
	var guaranteed_data: EnemyData = ENEMY_CATALOG_SCRIPT.get_by_id(&"barbarian_warrior").duplicate(true)
	var guaranteed_drop_table: Array[Dictionary] = [{"collectible_id": &"gold_coin", "probability": 1.0, "min_count": 1, "max_count": 1}]
	guaranteed_data.drop_table = guaranteed_drop_table
	enemy.configure(guaranteed_data, 1, target)
	collectible_spawner._on_enemy_spawned(enemy, 64)
	enemy.die()
	_expect(pickup_container.get_child_count() == 1, "generic Enemy.died signal must spawn its configured collectible drop")
	if pickup_container.get_child_count() == 1:
		var pickup = pickup_container.get_child(0)
		_expect(pickup.data != null and pickup.data.id == &"gold_coin", "enemy death pickup must resolve the EnemyData drop-table collectible")
	await _free_node(holder)
	await _free_node(target)

func test_streamed_collectible_cleanup() -> void:
	var holder := Node2D.new()
	add_child(holder)
	var pickup_container := Node2D.new()
	holder.add_child(pickup_container)
	var spawner = COLLECTIBLE_SPAWNER_SCRIPT.new()
	holder.add_child(spawner)
	spawner.pickup_container = pickup_container
	spawner._spawn_pickup(COLLECTIBLE_CATALOG_SCRIPT.BRONZE_COIN, Vector2.ZERO, 72, &"procedural")
	_expect(pickup_container.get_child_count() == 1 and spawner.pickups_by_chunk.has(72), "CollectibleSpawner must track pickups by streamed chunk")
	spawner._on_chunk_removed({"start_tile": 72})
	await get_tree().process_frame
	_expect(pickup_container.get_child_count() == 0, "removing a streamed chunk must release its collectible instances")
	_expect(not spawner.pickups_by_chunk.has(72), "collectible chunk registry must not retain cleaned pickups")
	await _free_node(holder)

func test_level_collectible_architecture() -> void:
	var level = LEVEL_SCENE.instantiate()
	_expect(level.has_node("CollectibleSpawner"), "level scene must own one reusable CollectibleSpawner")
	_expect(level.has_node("PickupContainer"), "level scene must own the Phase 12 pickup container")
	_expect(level.has_node("HUD/MarginContainer/VBoxContainer/GoldLabel"), "level HUD must expose persistent gold earned from collectibles")
	level.free()

func test_character_definitions_are_valid() -> void:
	var characters := CHARACTER_CATALOG_SCRIPT.all()
	_expect(characters.size() == 45, "CharacterCatalog must expose all 45 supplied playable character sets")
	var seen_ids: Dictionary = {}
	for index in characters.size():
		var character = characters[index]
		_expect(character != null, "character resource %d must load" % [index + 1])
		if character == null:
			continue
		_expect(character.get_script() == CHARACTER_DATA_SCRIPT, "character %d must use CharacterData" % character.id)
		_expect(character.is_valid(), "character %d definition must resolve every required animation folder" % character.id)
		_expect(int(character.id) == index + 1, "character resources must remain ordered by their numbered asset set")
		_expect(not seen_ids.has(int(character.id)), "character ids must be unique")
		seen_ids[int(character.id)] = true
		_expect(String(character.animation_root) == "res://assets/Characters/%d/Png/Character Sprite" % character.id, "character %d must reference its matching bundled asset folder" % character.id)
		_expect(int(character.unlock_cost) >= 0, "character unlock costs must never be negative")
		var run_folder := String(character.animation_root).path_join("Fast Run")
		var run_files := CHARACTER_DATA_SCRIPT.list_animation_files(run_folder)
		var representative_texture: Texture2D
		for file_name in run_files:
			if file_name.to_lower().ends_with(".png"):
				representative_texture = CHARACTER_DATA_SCRIPT.load_texture(run_folder.path_join(file_name))
				break
		_expect(representative_texture != null, "character %d must expose at least one decodable runtime animation texture" % character.id)
		var frames: SpriteFrames = character.build_sprite_frames(true)
		for animation_name in CHARACTER_DATA_SCRIPT.REQUIRED_ANIMATIONS.keys():
			_expect(frames.has_animation(animation_name), "character %d SpriteFrames must define '%s'" % [character.id, animation_name])
	_expect(int(characters[0].unlock_cost) == 0, "the default character must not charge an unlock cost")
	for index in range(1, characters.size()):
		_expect(int(characters[index].unlock_cost) > 0, "non-default character %d must have a purchasable gold cost" % characters[index].id)

func test_character_unlock_costs_gold_atomically() -> void:
	GameState.reset_profile()
	var character = CHARACTER_CATALOG_SCRIPT.get_by_id(2)
	_expect(character != null, "character purchase test requires character 2")
	if character == null:
		return
	var cost := int(character.unlock_cost)
	GameState.profile.gold = cost - 1
	var before := GameState.profile.duplicate(true)
	var insufficient := CHARACTER_INVENTORY_SERVICE_SCRIPT.unlock(GameState.profile, 2)
	_expect(insufficient == CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.NOT_ENOUGH_GOLD, "character purchase must reject insufficient gold")
	_expect(GameState.profile == before, "failed character purchase must not partially mutate profile state")
	GameState.profile.gold = cost + 17
	var success := GameState.unlock_character(2)
	_expect(success == CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "character purchase must succeed when enough gold is available")
	_expect(GameState.is_character_unlocked(2), "successful purchase must append the character to unlocked_characters")
	_expect(GameState.gold_count() == 17, "successful purchase must deduct exactly CharacterData.unlock_cost")
	var after_success := GameState.profile.duplicate(true)
	var duplicate := GameState.unlock_character(2)
	_expect(duplicate == CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.ALREADY_UNLOCKED, "already unlocked characters must not be purchased twice")
	_expect(GameState.profile == after_success, "duplicate character purchase must be atomic")
	var unknown_before := GameState.profile.duplicate(true)
	var unknown := GameState.unlock_character(999)
	_expect(unknown == CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.UNKNOWN_CHARACTER, "unknown character ids must be rejected")
	_expect(GameState.profile == unknown_before, "unknown character purchase must not mutate profile state")

func test_character_selection_requires_unlock() -> void:
	GameState.reset_profile()
	_expect(GameState.selected_character_id() == PLAYER_PROFILE_SCRIPT.DEFAULT_CHARACTER_ID, "default character must begin selected")
	var locked := GameState.select_character(3)
	_expect(locked == CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.NOT_UNLOCKED, "locked characters cannot be selected")
	_expect(GameState.selected_character_id() == PLAYER_PROFILE_SCRIPT.DEFAULT_CHARACTER_ID, "failed selection must preserve the previous character")
	var character = CHARACTER_CATALOG_SCRIPT.get_by_id(3)
	GameState.profile.gold = int(character.unlock_cost)
	_expect(GameState.unlock_character(3) == CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "selection test must unlock character 3")
	_expect(GameState.select_character(3) == CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS, "unlocked character must be selectable")
	_expect(GameState.selected_character_id() == 3, "selection must persist the chosen character id in PlayerProfile")
	_expect(GameState.selected_character_data() != null and int(GameState.selected_character_data().id) == 3, "GameState must resolve selected_character to CharacterData")
	_expect(GameState.select_character(3) == CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.ALREADY_SELECTED, "selecting the active character should be a no-op result")

func test_character_profile_sanitizes_unknown_ids() -> void:
	var raw := PLAYER_PROFILE_SCRIPT.create_default()
	raw.unlocked_characters = [1, 7, 999, 7, -4]
	raw.selected_character = 999
	var sanitized := PLAYER_PROFILE_SCRIPT.sanitize(raw)
	_expect(sanitized.unlocked_characters == [1, 7], "profile sanitation must remove duplicate/unknown character ids")
	_expect(int(sanitized.selected_character) == PLAYER_PROFILE_SCRIPT.DEFAULT_CHARACTER_ID, "invalid selected character must fall back to the default")
	raw.selected_character = 7
	sanitized = PLAYER_PROFILE_SCRIPT.sanitize(raw)
	_expect(int(sanitized.selected_character) == 7, "a known unlocked selected character must survive sanitation")

func test_selected_character_drives_player_presentation() -> void:
	GameState.reset_profile()
	GameState.profile.unlocked_characters = [1, 12]
	GameState.profile.selected_character = 12
	var player = await _spawn_player(false)
	_expect(player.character_data != null, "spawned player must resolve selected CharacterData")
	if player.character_data != null:
		_expect(int(player.character_data.id) == 12, "spawned player presentation must use PlayerProfile.selected_character")
		_expect(String(player.character_data.animation_root).contains("/Characters/12/"), "selected CharacterData must point at character 12 assets")
	for animation_name in CHARACTER_DATA_SCRIPT.REQUIRED_ANIMATIONS.keys():
		_expect(player.sprite.sprite_frames.has_animation(animation_name), "selected player SpriteFrames must include '%s'" % animation_name)
	await _free_node(player)

func test_keyboard_ability_slot_routes_equipped_ability() -> void:
	var raw := PLAYER_PROFILE_SCRIPT.create_default()
	raw.unlocked_abilities = ["jump", "invisibility"]
	raw.equipped_abilities = ["invisibility"]
	raw.ability_levels = {"jump": 1, "invisibility": 1}
	GameState.set_profile(raw)
	var player = await _spawn_player(false)
	_expect(player.input_router.ability_id_for_slot(0) == &"invisibility", "ability slot 1 must resolve the first equipped ability")
	var event := InputEventAction.new()
	event.action = &"ability_1"
	event.pressed = true
	_expect(player.input_router.handle_input_event(event), "ability_1 keyboard action must be consumed by PlayerInputRouter")
	_expect(not player.detectable, "ability_1 must activate the equipped Invisibility ability through the logical input router")
	await _free_node(player)

func test_touch_tap_maps_to_jump() -> void:
	var setup := await _spawn_grounded_player()
	var player = setup.player
	var controls = MOBILE_ACTION_CONTROLS_SCENE.instantiate()
	add_child(controls)
	await get_tree().process_frame
	controls.configure(player.input_router)
	var adapter: TouchInputAdapter = controls.touch_input_adapter
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 7
	touch_down.pressed = true
	touch_down.position = Vector2(120.0, 220.0)
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 7
	touch_up.pressed = false
	touch_up.position = Vector2(124.0, 224.0)
	_expect(adapter.handle_touch_event(touch_down), "touch adapter must claim the first touch in a gesture")
	_expect(adapter.handle_touch_event(touch_up), "touch adapter must consume a completed tap")
	_expect(player.velocity.y < 0.0, "mobile tap must dispatch the same logical jump action used by desktop")
	_expect(adapter.active_touch_index == -1, "completed tap must reset touch gesture state")
	await _free_node(controls)
	await _free_node(setup.root)

func test_touch_hold_preserves_jump_hold_semantics() -> void:
	var raw := PLAYER_PROFILE_SCRIPT.create_default()
	raw.unlocked_abilities = ["jump", "glide"]
	raw.equipped_abilities = ["jump", "glide"]
	raw.ability_levels = {"jump": 1, "glide": 1}
	GameState.set_profile(raw)
	var setup := await _spawn_grounded_player(false)
	var player = setup.player
	var controls = MOBILE_ACTION_CONTROLS_SCENE.instantiate()
	add_child(controls)
	await get_tree().process_frame
	controls.configure(player.input_router)
	var adapter: TouchInputAdapter = controls.touch_input_adapter
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 11
	touch_down.pressed = true
	touch_down.position = Vector2(240.0, 200.0)
	adapter.handle_touch_event(touch_down)
	adapter._process(GameConfig.MOBILE_JUMP_HOLD_DELAY + 0.01)
	_expect(player.ability_controller.jump_held, "holding a stationary touch must preserve jump-held semantics for Glide")
	_expect(player.velocity.y < 0.0, "touch hold must still dispatch the initial jump")
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 11
	touch_up.pressed = false
	touch_up.position = touch_down.position
	adapter.handle_touch_event(touch_up)
	_expect(not player.ability_controller.jump_held, "releasing a held touch must release the logical jump action")
	await _free_node(controls)
	await _free_node(setup.root)

func test_swipe_down_maps_to_roll_without_jump() -> void:
	var setup := await _spawn_grounded_player()
	var player = setup.player
	var controls = MOBILE_ACTION_CONTROLS_SCENE.instantiate()
	add_child(controls)
	await get_tree().process_frame
	controls.configure(player.input_router)
	var adapter: TouchInputAdapter = controls.touch_input_adapter
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 3
	touch_down.pressed = true
	touch_down.position = Vector2(180.0, 120.0)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = touch_down.position + Vector2(8.0, GameConfig.MOBILE_SWIPE_MIN_DISTANCE + 12.0)
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 3
	touch_up.pressed = false
	touch_up.position = drag.position
	adapter.handle_touch_event(touch_down)
	_expect(adapter.handle_touch_event(drag), "touch adapter must consume an active downward drag")
	_expect(player.state == PLAYER_SCRIPT.State.ROLLING, "downward swipe must dispatch the logical roll action")
	_expect(is_zero_approx(player.velocity.y), "a consumed downward swipe must not also dispatch a tap jump")
	adapter.handle_touch_event(touch_up)
	_expect(player.state == PLAYER_SCRIPT.State.ROLLING, "releasing a consumed swipe must not replace roll with jump")
	await _free_node(controls)
	await _free_node(setup.root)

func test_mobile_action_buttons_follow_equipped_slots() -> void:
	var raw := PLAYER_PROFILE_SCRIPT.create_default()
	raw.unlocked_abilities = ["jump", "dash", "shooting", "explode"]
	raw.equipped_abilities = ["jump", "dash", "shooting", "explode"]
	raw.ability_levels = {"jump": 1, "dash": 1, "shooting": 1, "explode": 1}
	GameState.set_profile(raw)
	var player = await _spawn_player(false)
	var controls = MOBILE_ACTION_CONTROLS_SCENE.instantiate()
	add_child(controls)
	await get_tree().process_frame
	controls.configure(player.input_router)
	var buttons: Array[Node] = controls.action_cluster.get_children()
	_expect(buttons.size() == 2, "mobile action cluster must only render active abilities not already represented by gestures/passive behavior")
	if buttons.size() == 2:
		_expect(String(buttons[0].text).begins_with("1  Dash"), "mobile Dash button must use the first direct-action slot")
		_expect(String(buttons[1].text).begins_with("2  Explode"), "mobile Explode button must use the second direct-action slot")
	_expect(player.input_router.ability_slots() == [&"dash", &"explode"], "numbered mappings must exclude Jump-family actions and passive Shooting")
	_expect(player.input_router.mobile_button_slots() == [0, 1], "mobile buttons must use the same dense active-action slots as desktop")
	await _free_node(controls)
	await _free_node(player)

func test_action_button_side_setting_updates_mobile_cluster() -> void:
	GameState.reset_profile()
	var player = await _spawn_player(false)
	var controls = MOBILE_ACTION_CONTROLS_SCENE.instantiate()
	add_child(controls)
	await get_tree().process_frame
	controls.configure(player.input_router)
	_expect(GameState.action_button_side() == PLAYER_PROFILE_SCRIPT.ACTION_BUTTON_SIDE_RIGHT, "mobile action cluster must default to RIGHT")
	_expect(is_equal_approx(controls.action_cluster.anchor_left, 1.0), "RIGHT setting must anchor mobile action buttons to the right")
	_expect(GameState.set_action_button_side("LEFT"), "action button side API must accept LEFT case-insensitively")
	_expect(GameState.action_button_side() == PLAYER_PROFILE_SCRIPT.ACTION_BUTTON_SIDE_LEFT, "LEFT setting must be stored in normalized form")
	_expect(is_zero_approx(controls.action_cluster.anchor_left), "LEFT setting must move the mobile action cluster to the left")
	_expect(not GameState.set_action_button_side("center"), "invalid action button side must be rejected")
	_expect(GameState.action_button_side() == PLAYER_PROFILE_SCRIPT.ACTION_BUTTON_SIDE_LEFT, "invalid side must not mutate the current setting")
	_expect(GameState.set_action_button_side("right"), "action button side API must allow switching back to RIGHT")
	_expect(is_equal_approx(controls.action_cluster.anchor_left, 1.0), "RIGHT setting must move the mobile action cluster back to the right")
	await _free_node(controls)
	await _free_node(player)

func test_level_has_phase14_input_hud() -> void:
	var level = LEVEL_SCENE.instantiate()
	_expect(level.has_node("Player/InputRouter"), "Phase 14 player scene must contain a source-agnostic InputRouter")
	_expect(level.has_node("HUD/AbilityMappingPanel/AbilityMappingLabel"), "Phase 14 HUD must show equipped desktop ability slots in the lower-left")
	_expect(level.has_node("HUD/MobileActionControls/TouchInputAdapter"), "Phase 14 HUD must provide a separate touch input adapter")
	_expect(level.has_node("HUD/MobileActionControls/ActionCluster"), "Phase 14 HUD must provide a configurable mobile action-button cluster")
	level.free()

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

func _directory_has_png(folder: String) -> bool:
	var files := ResourceLoader.list_directory(folder)
	if files.is_empty():
		files = DirAccess.get_files_at(folder)
	for file_name in files:
		if file_name.to_lower().ends_with(".png"):
			return true
	return false

func _physical_enemy_animation_roots() -> Array[String]:
	var result: Array[String] = []
	var root_path := "res://assets/Enemies"
	var root := DirAccess.open(root_path)
	if root == null:
		return result
	var families := root.get_directories()
	families.sort()
	for family in families:
		var family_path := root_path.path_join(family)
		var family_dir := DirAccess.open(family_path)
		if family_dir == null:
			continue
		var enemy_names := family_dir.get_directories()
		enemy_names.sort()
		for enemy_name in enemy_names:
			var animation_root := family_path.path_join(enemy_name).path_join("PNG/PNG Sequences")
			if DirAccess.open(animation_root) != null:
				result.append(animation_root)
	result.sort()
	return result

func _spawn_enemy_target(position: Vector2):
	var target = ENEMY_TARGET_DUMMY_SCRIPT.new()
	target.collision_layer = GameConfig.PLAYER_COLLISION_LAYER
	target.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	collision.shape = shape
	target.add_child(collision)
	target.global_position = position
	add_child(target)
	return target

func _spawn_player(reset_profile: bool = true):
	if reset_profile:
		GameState.reset_profile()
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame
	return player

func _spawn_grounded_player(reset_profile: bool = true) -> Dictionary:
	if reset_profile:
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

func _spawn_melee_enemy(position: Vector2, health: float = 200.0, register_as_enemy: bool = false):
	var enemy = MELEE_DUMMY_ENEMY_SCRIPT.new()
	enemy.maximum_health = health
	enemy.current_health = health
	enemy.collision_layer = GameConfig.ENEMY_COLLISION_MASK
	enemy.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	collision.shape = shape
	enemy.add_child(collision)
	enemy.global_position = position
	if register_as_enemy:
		enemy.add_to_group(&"enemies")
	add_child(enemy)
	return enemy

func _wait_for_melee_attack(player: Node2D, enemy: Node2D, max_frames: int = 12) -> bool:
	for _index in max_frames:
		enemy.global_position = player.global_position + Vector2(32.0, 0.0)
		await get_tree().physics_frame
		if int(enemy.damage_events) > 0:
			return true
	return false

func _follow_melee_target_for_seconds(player: Node2D, enemy: Node2D, seconds: float) -> void:
	var elapsed := 0.0
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	while elapsed < seconds:
		enemy.global_position = player.global_position + Vector2(32.0, 0.0)
		await get_tree().physics_frame
		elapsed += tick

func _follow_weapon_target_for_seconds(player: Node2D, enemy: Node2D, seconds: float) -> void:
	var elapsed := 0.0
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	while elapsed < seconds:
		enemy.global_position = player.global_position + Vector2(360.0, 0.0)
		await get_tree().physics_frame
		elapsed += tick

func _free_group_nodes(group_name: StringName) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if node != null and is_instance_valid(node):
			node.queue_free()
	await get_tree().process_frame

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
