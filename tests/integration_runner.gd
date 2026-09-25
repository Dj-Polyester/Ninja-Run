extends SceneTree
## M2 fail-closed real-scene physics and lifecycle integration suite.

const Director = preload("res://scripts/models/run_director.gd")
const AstroCoordinator = preload("res://scripts/terrain/astro_fall_coordinator.gd")
const AstroBlock = preload("res://scripts/terrain/astro_fall_block.gd")
const TerrainPaletteRuntime = preload("res://scripts/terrain/terrain_palette.gd")
const EnemyControllerRuntime = preload("res://scripts/enemies/enemy_controller.gd")
const EnemySpawnerRuntime = preload("res://scripts/enemies/enemy_spawner.gd")
const EnemyProjectileRuntime = preload("res://scripts/enemies/enemy_projectile.gd")
const EnemySpawnRuntime = preload("res://scripts/enemies/enemy_spawn_descriptor.gd")
const EnemyCatalogRuntime = preload("res://scripts/enemies/enemy_catalog.gd")
const EnemyDefinitionRuntime = preload("res://scripts/enemies/enemy_definition.gd")
const CollectibleCatalogRuntime = preload("res://scripts/collectibles/collectible_catalog.gd")
const CollectibleDefinitionRuntime = preload("res://scripts/collectibles/collectible_definition.gd")
const CollectiblePickupRuntime = preload("res://scripts/collectibles/collectible_pickup.gd")
const LootRollsRuntime = preload("res://scripts/models/loot_rolls.gd")
const WeaponCatalogRuntime = preload("res://scripts/weapons/weapon_catalog.gd")
const WeaponControllerRuntime = preload("res://scripts/weapons/weapon_controller.gd")
const WeaponProjectileRuntime = preload("res://scripts/weapons/weapon_projectile.gd")
const CharacterCatalogRuntime = preload("res://scripts/characters/character_catalog.gd")
const ProfileShopRuntime = preload("res://scripts/models/profile_shop.gd")
const TouchGestureRouterRuntime = preload("res://scripts/ui/touch_gesture_router.gd")
const EXPECTED_TEST_COUNT := 62
var passed := 0
var scheduled := 0
var executed := 0
var failures: Array[String] = []
var test_filter: String = OS.get_environment("NINJA_RUN_TEST_FILTER")
var shard_count: int = maxi(1, int(OS.get_environment("NINJA_RUN_TEST_SHARD_COUNT")))
var shard_index: int = clampi(int(OS.get_environment("NINJA_RUN_TEST_SHARD_INDEX")), 0, shard_count - 1)
var _candidate_index := 0

func _init() -> void:
	var session := root.get_node_or_null("RunSession")
	if session != null and session.has_method("reset_profile_for_tests"):
		session.reset_profile_for_tests()
	call_deferred("_run")

func _run() -> void:
	await _run_test("test_measured_nonstop_displacement_and_distance", test_measured_nonstop_displacement_and_distance)
	await _run_test("test_input_jump_apex_landing_and_camera", test_input_jump_apex_landing_and_camera)
	await _run_test("test_camera_fixed_y_during_fall_and_revival", test_camera_fixed_y_during_fall_and_revival)
	await _run_test("test_validated_support_recovery_and_revalidation", test_validated_support_recovery_and_revalidation)
	await _run_test("test_recovery_rejects_blocked_pose_and_finds_replacement", test_recovery_rejects_blocked_pose_and_finds_replacement)
	await _run_test("test_low_ceiling_roll_posture_and_revival_reset", test_low_ceiling_roll_posture_and_revival_reset)
	await _run_test("test_area2d_melee_only_near_running_enemy", test_area2d_melee_only_near_running_enemy)
	await _run_test("test_hud_widgets_update_from_run_and_profile_signals", test_hud_widgets_update_from_run_and_profile_signals)
	await _run_test("test_grounded_countdown_exact_expiry_and_freeze", test_grounded_countdown_exact_expiry_and_freeze)
	await _run_test("test_thin_wall_sweep_and_stationary_checkpoint_timeout", test_thin_wall_sweep_and_stationary_checkpoint_timeout)
	await _run_test("test_physical_wall_stuck_boundary_and_revival_recovery", test_physical_wall_stuck_boundary_and_revival_recovery)
	await _run_test("test_damage_fall_protection_tint_and_reset", test_damage_fall_protection_tint_and_reset)
	await _run_test("test_safe_support_records_latest_grounded_progress", test_safe_support_records_latest_grounded_progress)
	await _run_test("test_menu_restart_return_profile_lifecycle", test_menu_restart_return_profile_lifecycle)
	await _run_test("test_level_ui_paths_exist", test_level_ui_paths_exist)
	await _run_test("test_production_has_no_floor_and_generated_grass", test_production_has_no_floor_and_generated_grass)
	await _run_test("test_floating_platform_collision_matches_tiles", test_floating_platform_collision_matches_tiles)
	await _run_test("test_generated_route_crosses_chunk_seam_without_teleport", test_generated_route_crosses_chunk_seam_without_teleport)
	await _run_test("test_streamer_far_teleport_reconciles_directly_and_cleans", test_streamer_far_teleport_reconciles_directly_and_cleans)
	await _run_test("test_streamer_bounded_counts_and_stale_anchor_removal", test_streamer_bounded_counts_and_stale_anchor_removal)
	await _run_test("test_streamer_setup_replaces_generation_identity", test_streamer_setup_replaces_generation_identity)
	await _run_test("test_generated_recovery_varied_elevation_and_removed_support", test_generated_recovery_varied_elevation_and_removed_support)
	await _run_test("test_generated_forward_blocker_recovery_and_no_potion_without_support", test_generated_forward_blocker_recovery_and_no_potion_without_support)
	await _run_test("test_generated_player_crosses_grass_tundra_boundary_without_teleport", test_generated_player_crosses_grass_tundra_boundary_without_teleport)
	await _run_test("test_hazard_registry_cleanup_and_reconfigure", test_hazard_registry_cleanup_and_reconfigure)
	await _run_test("test_snow_jump_sampling_physical_bounds_and_revival", test_snow_jump_sampling_physical_bounds_and_revival)
	await _run_test("test_streamed_desert_hazard_contact_defense_and_cadence", test_streamed_desert_hazard_contact_defense_and_cadence)
	await _run_test("test_streamed_fort_phase_hitbox_pause_and_resume", test_streamed_fort_phase_hitbox_pause_and_resume)
	await _run_test("test_astro_cells_have_single_runtime_ownership_and_cascade", test_astro_cells_have_single_runtime_ownership_and_cascade)
	await _run_test("test_astro_recovery_excludes_armed_support_and_anchor_only", test_astro_recovery_excludes_armed_support_and_anchor_only)
	await _run_test("test_astro_area_contact_pause_and_duplicate_delay", test_astro_area_contact_pause_and_duplicate_delay)
	await _run_test("test_astro_real_block_cascade_alignment_and_release", test_astro_real_block_cascade_alignment_and_release)
	await _run_test("test_astro_revival_pause_and_retirement_cleanup", test_astro_revival_pause_and_retirement_cleanup)
	await _run_test("test_negative_chunk_collision_and_zero_crossing", test_negative_chunk_collision_and_zero_crossing)
	await _run_test("test_generated_non_astro_impact_preserves_terrain", test_generated_non_astro_impact_preserves_terrain)
	await _run_test("test_continuous_astro_segment_traversal_with_collapse", test_continuous_astro_segment_traversal_with_collapse)
	await _run_test("test_same_frame_fall_freezes_astro_hazard_tick", test_same_frame_fall_freezes_astro_hazard_tick)
	await _run_test("test_same_frame_stuck_freezes_astro_and_fort", test_same_frame_stuck_freezes_astro_and_fort)
	await _run_test("test_m4_anchor_lifecycle_and_astro_spawn_support", test_m4_anchor_lifecycle_and_astro_spawn_support)
	await _run_test("test_m4a1_spawner_materializes_healthbar_and_retires", test_m4a1_spawner_materializes_healthbar_and_retires)
	await _run_test("test_m4a1_controller_behavior_channels_and_pause", test_m4a1_controller_behavior_channels_and_pause)
	await _run_test("test_m4a1_projectile_sweep_pause_and_hit", test_m4a1_projectile_sweep_pause_and_hit)
	await _run_test("test_m4b_production_catalog_spawn_wiring", test_m4b_production_catalog_spawn_wiring)
	await _run_test("test_m4b_freeze_burn_and_blood_loss_runtime", test_m4b_freeze_burn_and_blood_loss_runtime)
	await _run_test("test_m5a_streamed_collectible_pickup_and_cleanup", test_m5a_streamed_collectible_pickup_and_cleanup)
	await _run_test("test_m5a_player_melee_cadence_death_and_drops", test_m5a_player_melee_cadence_death_and_drops)
	await _run_test("test_m5b_shooting_unlock_visibility_and_cadence", test_m5b_shooting_unlock_visibility_and_cadence)
	await _run_test("test_m5b_multitarget_and_projectile_trajectories", test_m5b_multitarget_and_projectile_trajectories)
	await _run_test("test_m6a_level_desktop_mobile_ability_slot_routing", test_m6a_level_desktop_mobile_ability_slot_routing)
	await _run_test("test_m6b_jump_levels_and_fly", test_m6b_jump_levels_and_fly)
	await _run_test("test_m6b_climb_wall_jumps_and_glide", test_m6b_climb_wall_jumps_and_glide)
	await _run_test("test_m6b_reverse_gravity_fly_and_cooldown", test_m6b_reverse_gravity_fly_and_cooldown)
	await _run_test("test_m6b_dash_distance_speed_and_cooldown", test_m6b_dash_distance_speed_and_cooldown)
	await _run_test("test_m6c_slowdown_invisibility_enemy_runtime", test_m6c_slowdown_invisibility_enemy_runtime)
	await _run_test("test_m6c_explode_enemy_damage_tile_break_and_cooldown", test_m6c_explode_enemy_damage_tile_break_and_cooldown)
	await _run_test("test_m6c_shooting_action_route_and_profile_cooldown", test_m6c_shooting_action_route_and_profile_cooldown)
	await _run_test("test_m7_profile_character_and_stats_apply_to_level", test_m7_profile_character_and_stats_apply_to_level)
	await _run_test("test_m7_run_session_autosave_reload", test_m7_run_session_autosave_reload)
	await _run_test("test_m8_main_menu_shop_and_screen_entry_points", test_m8_main_menu_shop_and_screen_entry_points)
	await _run_test("test_m8_progression_screens_transactions_and_descriptions", test_m8_progression_screens_transactions_and_descriptions)
	await _run_test("test_m8_level_ability_map_and_revival_ui", test_m8_level_ability_map_and_revival_ui)
	await _run_test("test_m9_touch_gestures_buttons_and_parity", test_m9_touch_gestures_buttons_and_parity)
	if test_filter.is_empty() and shard_count == 1 and (scheduled != EXPECTED_TEST_COUNT or executed != EXPECTED_TEST_COUNT):
		failures.append("scheduled %d / executed %d / expected %d" % [scheduled, executed, EXPECTED_TEST_COUNT])
	for failure in failures:
		push_error("FAIL %s" % failure)
	print("INTEGRATION RESULT: %d passed, %d failed (%d scheduled, %d executed)" % [passed, failures.size(), scheduled, executed])
	quit(0 if failures.is_empty() else 1)

func _run_test(name: String, test: Callable) -> void:
	var candidate := _candidate_index
	_candidate_index += 1
	if not test_filter.is_empty() and name != test_filter:
		return
	if test_filter.is_empty() and shard_count > 1 and candidate % shard_count != shard_index:
		return
	scheduled += 1
	var session := root.get_node_or_null("RunSession")
	if session != null and session.has_method("reset_profile_for_tests"):
		session.reset_profile_for_tests()
	var failure: String = await test.call()
	executed += 1
	if failure.is_empty():
		passed += 1
		print("PASS %s" % name)
	else:
		failures.append("%s: %s" % [name, failure])

func _make_level() -> Level:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate() as Level
	# M2 assertions intentionally exercise the isolated flat fixture. Production
	# Level instances never create Floor and use TerrainStreamer instead.
	level.use_flat_fixture = true
	level.enemies_enabled = false
	level.collectibles_enabled = false
	level.weapons_enabled = false
	level.director = Director.new(GameClock.ManualClock.new())
	root.add_child(level)
	return level

func _make_production_level(seed: int = 618, with_enemies: bool = false, with_collectibles: bool = false, with_weapons: bool = false) -> Level:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate() as Level
	level.terrain_seed_override = seed
	level.enemies_enabled = with_enemies
	level.collectibles_enabled = with_collectibles
	level.weapons_enabled = with_weapons
	level.director = Director.new(GameClock.ManualClock.new())
	root.add_child(level)
	return level

func _dispose(node: Node) -> void:
	if is_instance_valid(node):
		node.free()
	await process_frame

func _frames(count: int) -> void:
	for _i in count:
		await physics_frame

func _wait_for_scene(script_path: String, limit: int = 30, exclude: Node = null) -> Node:
	for _i in limit:
		await process_frame
		var scene := current_scene
		if scene != null and scene != exclude and scene.get_script() != null and scene.get_script().resource_path == script_path:
			return scene
	return null

func _wall(level: Level, position: Vector2) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.position = position
	var collision := CollisionShape2D.new()
	collision.name = &"CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 140)
	collision.shape = shape
	wall.add_child(collision)
	level.add_child(wall)
	return wall

func _support_platform(level: Level, position: Vector2, width: float = 80.0) -> StaticBody2D:
	var platform := StaticBody2D.new()
	platform.position = position
	platform.add_to_group(&"terrain_support")
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 40)
	collision.shape = shape
	platform.add_child(collision)
	level.add_child(platform)
	return platform

func _near(a: float, b: float, tolerance: float) -> bool:
	return absf(a - b) <= tolerance

func test_measured_nonstop_displacement_and_distance() -> String:
	var level := _make_level()
	await _frames(8)
	var x := level.player.global_position.x
	var distance: float = level.director.run.distance_tiles
	await _frames(30)
	var moved := level.player.global_position.x - x
	var gained: float = level.director.run.distance_tiles - distance
	var result := "" if moved > GameConfig.SPEED * 0.30 and _near(gained, moved / GameConfig.TILE_SIZE, 0.15) else "measured movement %.2f and distance %.3f diverged" % [moved, gained]
	await _dispose(level)
	return result

func test_input_jump_apex_landing_and_camera() -> String:
	var level := _make_level()
	await _frames(10)
	for _i in 12:
		if level.player.is_on_floor():
			break
		await physics_frame
		await process_frame
	var floor_y := level.player.global_position.y
	var was_active: bool = level.player.runner_active
	var was_grounded: bool = level.player.is_on_floor()
	var jump_event := InputEventKey.new()
	jump_event.keycode = KEY_UP
	jump_event.pressed = true
	level.player._unhandled_input(jump_event)
	await physics_frame
	# The raw Up event reaches only PlayerController; one post-physics
	# consumption proves no second handler claimed the same jump.
	var accepted: bool = level.player.jump_consumptions == 1
	jump_event.pressed = false
	var apex := floor_y
	var camera_x_advanced := false
	for _i in 90:
		await physics_frame
		await process_frame
		apex = minf(apex, level.player.global_position.y)
		camera_x_advanced = camera_x_advanced or level.camera.global_position.x > 160.0
	var height := floor_y - apex
	var expected := GameConfig.MAX_JUMP * GameConfig.TILE_SIZE
	var result := "" if accepted and _near(height, expected, 30.0) and _near(level.player.global_position.y, floor_y, 3.0) and camera_x_advanced and _near(level.camera.global_position.y, 360.0, 0.01) else "jump accepted=%s initial_active=%s initial_floor=%s floor=%s height %.1f expected %.1f, landing %.1f, camera %s" % [accepted, was_active, was_grounded, level.player.is_on_floor(), height, expected, level.player.global_position.y, level.camera.global_position]
	await _dispose(level)
	return result

func test_camera_fixed_y_during_fall_and_revival() -> String:
	var level := _make_level()
	await _frames(8)
	level.profile.set_revival_potions(1)
	level.player.global_position.y = 1001.0
	await physics_frame
	var fall_y_fixed := _near(level.camera.global_position.y, 360.0, 0.01)
	var revived := level.request_revival()
	await _frames(2)
	var result := "" if fall_y_fixed and revived and _near(level.camera.global_position.y, 360.0, 0.01) else "camera y=%s fall_fixed=%s revive=%s state=%s support=%s valid=%s fixture=%s" % [level.camera.global_position.y, fall_y_fixed, revived, level.director.state, level.director.safe_support, level._is_valid_support_position(level.director.safe_support), level.use_flat_fixture]
	await _dispose(level)
	return result

func test_validated_support_recovery_and_revalidation() -> String:
	var level := _make_level()
	await _frames(24)
	level.profile.set_revival_potions(1)
	level.director.safe_support = level.player.global_position
	level.director.fail_fall(0.0)
	var revived := level.director.revive(level.profile, 0.0)
	await _frames(2)
	var placed: bool = revived and level.director.state == Director.State.RUNNING and level._is_valid_support_position(level.player.global_position)
	level.profile.set_revival_potions(1)
	level.director.safe_support = level.player.global_position
	(level.get_node("Floor") as StaticBody2D).collision_layer = 0
	await physics_frame
	level.director.fail_fall(2.0)
	var rejected := not level.director.revive(level.profile, 2.0) and level.profile.revival_potions == 1
	var result := "" if placed and rejected else "support placed=%s rejected=%s state=%s support=%s valid=%s player=%s" % [placed, rejected, level.director.state, level.director.safe_support, level._is_valid_support_position(level.director.safe_support), level.player.global_position]
	await _dispose(level)
	return result

func test_recovery_rejects_blocked_pose_and_finds_replacement() -> String:
	var level := _make_level()
	await _frames(8)
	var candidate: Vector2 = level.director.safe_support
	var ceiling := _wall(level, candidate + Vector2(8, -28))
	(ceiling.get_node("CollisionShape2D") as CollisionShape2D).shape = RectangleShape2D.new()
	((ceiling.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size = Vector2(34, 22)
	var side_wall := _wall(level, candidate + Vector2(28, 0))
	(level.get_node("Floor") as StaticBody2D).collision_layer = 0
	var replacement: Vector2 = candidate + Vector2(GameConfig.TILE_SIZE, 0)
	var platform := _support_platform(level, replacement + Vector2(0, 52))
	await _frames(2)
	var blocked := not level._is_valid_support_position(candidate)
	var replacement_valid := level._is_valid_support_position(replacement)
	level.profile.set_revival_potions(1)
	level.director.safe_support = candidate
	level.director.fail_fall(0.0)
	var revived := level.director.revive(level.profile, 0.0)
	var revived_position := level.player.global_position
	await _frames(2)
	var relocated: bool = revived and level.director.state == Director.State.RUNNING and revived_position == replacement and level._is_valid_support_position(revived_position) and level.profile.revival_potions == 0
	platform.collision_layer = 0
	level.profile.set_revival_potions(1)
	level.director.fail_fall(2.0)
	var rejected: bool = not level.director.revive(level.profile, 2.0) and level.profile.revival_potions == 1 and level.director.state == Director.State.REVIVAL_COUNTDOWN
	var result := "" if blocked and replacement_valid and relocated and rejected else "blocked=%s replacement=%s relocated=%s rejected=%s" % [blocked, replacement_valid, relocated, rejected]
	await _dispose(level)
	return result

func test_low_ceiling_roll_posture_and_revival_reset() -> String:
	var level := _make_level()
	await _frames(8)
	var ceiling := _wall(level, level.player.global_position + Vector2(8, -20))
	var collider := ceiling.get_node("CollisionShape2D") as CollisionShape2D
	(collider.shape as RectangleShape2D).size = Vector2(34, 22)
	await _frames(2)
	ceiling.global_position = level.player.global_position + Vector2(8, -20)
	await physics_frame
	var standing_blocked := not level.player._posture_is_clear(level.player.standing_shape.shape, level.player.standing_shape.position)
	var rolling_clear := level.player._posture_is_clear(level.player.rolling_shape.shape, level.player.rolling_shape.position)
	var entered := level.player.start_roll(level.player.simulation_time)
	await _frames(2)
	var compact_enabled := level.player.standing_shape.disabled and not level.player.rolling_shape.disabled
	# Keep the small offset shoulder obstruction over the runner through roll expiry.
	for _i in 45:
		ceiling.global_position = level.player.global_position + Vector2(8, -20)
		await physics_frame
	var held := level.player.rolling and level.player.standing_shape.disabled and not level.player.rolling_shape.disabled
	ceiling.global_position.y -= 100.0
	await _frames(2)
	var stood := level.player.stop_roll()
	await _frames(2)
	var standing_enabled := not level.player.standing_shape.disabled and level.player.rolling_shape.disabled
	level.player.start_roll(level.player.simulation_time)
	level.profile.set_revival_potions(1)
	level.director.fail_fall(3.0)
	var reset := level.director.revive(level.profile, 3.0) and not level.player.rolling and level.player.velocity == Vector2.ZERO
	var result := "" if standing_blocked and rolling_clear and entered and compact_enabled and held and stood and standing_enabled and reset else "low ceiling blocked=%s rolling_clear=%s entered=%s compact=%s held=%s stood=%s standing=%s reset=%s" % [standing_blocked, rolling_clear, entered, compact_enabled, held, stood, standing_enabled, reset]
	await _dispose(level)
	return result

func test_area2d_melee_only_near_running_enemy() -> String:
	var level := _make_level()
	await _frames(6)
	var enemy := _wall(level, level.player.global_position + Vector2(45, 0))
	enemy.add_to_group(&"enemies")
	var hits := [0]
	level.player.melee_proximity.connect(func(_target: Node2D) -> void: hits[0] += 1)
	await _frames(4)
	var near_hit: bool = hits[0] > 0
	enemy.global_position = level.player.global_position + Vector2(500, 0)
	await _frames(4)
	var distant_count: int = hits[0]
	level.director.fail_fall(0.0)
	enemy.global_position = level.player.global_position + Vector2(45, 0)
	await _frames(4)
	var result := "" if near_hit and hits[0] == distant_count else "melee did not respect Area2D distance/RUNNING gate"
	await _dispose(level)
	return result

func test_hud_widgets_update_from_run_and_profile_signals() -> String:
	var level := _make_level()
	await _frames(3)
	level.profile.add_gold(17)
	level.profile.set_revival_potions(2)
	level.director.run.add_earned_gold(4)
	level.director.run.advance_distance(3.0)
	level.director.run.set_health(150.0, 90.0)
	var bound: bool = level.health_bar.max_value == 150.0 and level.health_bar.value == 90.0 and "21" in level.gold_label.text and "x2" in level.potion_count.text and "3" in level.distance_label.text
	level.director.fail_fall(0.0)
	await physics_frame
	var revive_overlay := not level.state_overlay.text.is_empty() and "REVIVE" in level.state_overlay.text
	(level.director.clock as GameClock.ManualClock).advance(GameConfig.COUNTDOWN_SECS)
	await physics_frame
	var game_over_overlay: bool = level.director.state == Director.State.GAME_OVER and not level.state_overlay.text.is_empty() and "GAME OVER" in level.state_overlay.text
	var result := "" if bound and revive_overlay and game_over_overlay else "HUD binding max=%s value=%s revive=%s game_over=%s" % [level.health_bar.max_value, level.health_bar.value, revive_overlay, game_over_overlay]
	await _dispose(level)
	return result

func test_grounded_countdown_exact_expiry_and_freeze() -> String:
	var level := _make_level()
	await _frames(8)
	var clock: GameClock.ManualClock = level.director.clock
	level.director.apply_damage(DamageStatus.DamageEvent.new(999.0), 0.0)
	var x := level.player.global_position.x
	var distance: float = level.director.run.distance_tiles
	Input.action_press(&"jump")
	await _frames(3)
	Input.action_release(&"jump")
	var frozen := _near(level.player.global_position.x, x, 0.01) and _near(level.director.run.distance_tiles, distance, 0.001) and level.player.velocity == Vector2.ZERO
	clock.advance(GameConfig.COUNTDOWN_SECS - 0.001)
	await physics_frame
	var before_deadline: bool = level.director.state == Director.State.REVIVAL_COUNTDOWN
	clock.advance(0.001)
	await physics_frame
	var game_over: bool = level.director.state == Director.State.GAME_OVER
	var result := "" if frozen and before_deadline and game_over else "countdown exact deadline or freeze failed"
	await _dispose(level)
	return result

func test_thin_wall_sweep_and_stationary_checkpoint_timeout() -> String:
	var level := _make_level()
	await _frames(8)
	var clock: GameClock.ManualClock = level.director.clock
	var checkpoint: Vector2 = level.director.safe_support
	var thin_wall := _wall(level, checkpoint + Vector2(48, 0))
	((thin_wall.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size = Vector2(8, 140)
	await physics_frame
	var thin_wall_rejected := not level._is_valid_support_position(checkpoint)
	await _frames(16)
	var blocked_position := level.player.global_position
	for _i in 16:
		clock.advance(0.25)
		# This mirrors a stationary grounded checkpoint sample; it must not renew
		# progress timing while the real player remains stopped at the thin wall.
		level.director.record_checkpoint(checkpoint)
		await physics_frame
	var timed_out: bool = level.director.state == Director.State.REVIVAL_COUNTDOWN and level.director.failure_reason == Director.FailureReason.STUCK and _near(level.director.failure_position.x, blocked_position.x, 2.0)
	var result := "" if thin_wall_rejected and timed_out and is_instance_valid(thin_wall) else "thin=%s timeout=%s blocked=%s failure=%s" % [thin_wall_rejected, timed_out, blocked_position, level.director.failure_position]
	await _dispose(level)
	return result

func test_physical_wall_stuck_boundary_and_revival_recovery() -> String:
	var level := _make_level()
	await _frames(8)
	var clock: GameClock.ManualClock = level.director.clock
	var approach_start := level.player.global_position
	var wall_again := _wall(level, approach_start + Vector2(GameConfig.TILE_SIZE * 3, 0))
	# The wall exists well before approach, allowing the real checkpoint stream to
	# settle behind it instead of manufacturing a wall next to a checkpoint.
	await _frames(60)
	var blocked_again := level.player.global_position
	for _i in 16:
		clock.advance(0.25)
		await physics_frame
	var countdown: bool = level.director.state == Director.State.REVIVAL_COUNTDOWN and level.director.failure_reason == Director.FailureReason.STUCK and _near(level.director.failure_position.x, blocked_again.x, 2.0)
	level.profile.set_revival_potions(1)
	var revived := level.director.revive(level.profile, clock.now_seconds())
	var resolved_position := level.player.global_position
	await _frames(2)
	var wall_right := wall_again.global_position.x + 10.0
	var relocated := resolved_position.x > wall_right and level._is_valid_support_position(resolved_position)
	var wall_still_valid := is_instance_valid(wall_again)
	for _i in 12:
		clock.advance(0.1)
		await physics_frame
	var recovered: bool = level.player.global_position.x > resolved_position.x + GameConfig.STUCK_PROGRESS_EPSILON and level.director.state == Director.State.RUNNING and is_instance_valid(wall_again)
	var result := "" if countdown and revived and wall_still_valid and relocated and recovered else "physical wall stuck recovery countdown=%s revived=%s valid=%s relocated=%s recovered=%s failure=%s resolved=%s wall=%s" % [countdown, revived, wall_still_valid, relocated, recovered, level.director.failure_position, resolved_position, wall_again.global_position]
	await _dispose(level)
	return result

func test_damage_fall_protection_tint_and_reset() -> String:
	var level := _make_level()
	await _frames(5)
	var clock: GameClock.ManualClock = level.director.clock
	level.director.apply_damage(DamageStatus.DamageEvent.new(20.0), 0.0)
	var sprite: AnimatedSprite2D = level.player.get_node("AnimatedSprite2D")
	var normal := _near(level.director.run.health_owner.current_health, GameConfig.DEFAULT_MAXIMUM_HEALTH - 20.0, 0.01) and sprite.modulate.g < 0.5
	await _frames(12)
	var tint_cleared := sprite.modulate == Color.WHITE
	level.director.run.apply_status(DamageStatus.TimedStatus.new(&"burn", 4.0, 0.0))
	level.director.fail_fall(0.0)
	level.profile.set_revival_potions(1)
	var revived := level.director.revive(level.profile, 0.0)
	var revive_cleared_tint: bool = sprite.modulate == Color.WHITE
	var blocked_before := not level.director.apply_damage(DamageStatus.DamageEvent.new(10.0), clock.now_seconds())
	clock.advance(GameConfig.REVIVAL_PROTECTION)
	var allowed_at_deadline := level.director.apply_damage(DamageStatus.DamageEvent.new(10.0), clock.now_seconds())
	level.player.global_position.y = 1001.0
	await physics_frame
	var fall_zeroes: bool = level.director.run.health_owner.current_health == 0.0
	var cleared: bool = level.director.run.health_owner.statuses.is_empty() and level.player.velocity == Vector2.ZERO
	var result := "" if normal and tint_cleared and revived and revive_cleared_tint and blocked_before and allowed_at_deadline and fall_zeroes and cleared else "damage normal=%s tint=%s revive=%s revive_tint=%s blocked=%s deadline=%s fall=%s cleared=%s" % [normal, tint_cleared, revived, revive_cleared_tint, blocked_before, allowed_at_deadline, fall_zeroes, cleared]
	await _dispose(level)
	return result

func test_safe_support_records_latest_grounded_progress() -> String:
	var level := _make_level()
	await _frames(10)
	var first_x: float = level.director.safe_support.x
	await _frames(20)
	var result := "" if level.player.is_on_floor() and level.director.safe_support.x > first_x and level._is_valid_support_position(level.director.safe_support) else "latest grounded support was not recorded"
	await _dispose(level)
	return result

func test_menu_restart_return_profile_lifecycle() -> String:
	var session = root.get_node("RunSession")
	session.profile.gold = 77
	session.profile.revival_potions = 1
	change_scene_to_file("res://scenes/main_menu.tscn")
	var menu := await _wait_for_scene("res://scripts/main_menu.gd") as MainMenu
	if menu == null:
		return "menu boot transition timed out"
	(menu.get_node("Center/Panel/Content/StartRun") as Button).emit_signal("pressed")
	var level := await _wait_for_scene("res://scripts/level.gd") as Level
	if level == null:
		return "Start button did not enter Level"
	var first_seed: int = level.director.seed
	level.director.run.add_earned_gold(5)
	await physics_frame
	level.director.safe_support = level.player.global_position
	level.director.fail_fall(level.director.now())
	var consumed := level.request_revival()
	var old_director = level.director
	(level.get_node("CanvasLayer/Restart") as Button).emit_signal("pressed")
	var restarted := await _wait_for_scene("res://scripts/level.gd", 30, level) as Level
	if restarted == null:
		return "Restart button did not enter replacement Level"
	var preserved: bool = restarted.profile == session.profile and restarted.profile.gold == 82 and restarted.profile.revival_potions == 0 and restarted.director.run != old_director.run and restarted.director.run.earned_gold == 0 and restarted.director.seed != first_seed
	var restarted_seed: int = restarted.director.seed
	(restarted.get_node("CanvasLayer/Return") as Button).emit_signal("pressed")
	var returned := await _wait_for_scene("res://scripts/main_menu.gd", 30, restarted) as MainMenu
	if returned == null:
		return "Return button did not reach menu"
	(returned.get_node("Center/Panel/Content/StartRun") as Button).emit_signal("pressed")
	var second_level := await _wait_for_scene("res://scripts/level.gd", 30, returned) as Level
	var result := "" if consumed and preserved and second_level != null and second_level.profile == session.profile and second_level.profile.gold == 82 and second_level.profile.revival_potions == 0 and second_level.director.seed != restarted_seed else "navigation consumed=%s preserved=%s second=%s gold=%s potions=%s seeds=%s/%s/%s" % [consumed, preserved, second_level != null, second_level.profile.gold if second_level != null else -1, second_level.profile.revival_potions if second_level != null else -1, first_seed, restarted_seed, second_level.director.seed if second_level != null else -1]
	# Do not leak the final gameplay scene into later physics fixtures. Keeping a
	# second live Player body under SceneTree makes subsequent collision tests
	# interact with the navigation test rather than their own isolated Level.
	change_scene_to_file("res://scenes/main_menu.tscn")
	await _wait_for_scene("res://scripts/main_menu.gd", 30, second_level)
	return result

func test_level_ui_paths_exist() -> String:
	var level := _make_level()
	var result := "" if level.get_node("CanvasLayer/Restart") is Button and level.get_node("CanvasLayer/Return") is Button and level.get_node("CanvasLayer/HudPanel/PotionIcon") is TextureRect else "restart/return/potion UI paths are missing"
	await _dispose(level)
	return result

func test_production_has_no_floor_and_generated_grass() -> String:
	var level := _make_production_level()
	var origin_preserved := is_equal_approx(level.player.global_position.x, GameConfig.RUN_ORIGIN_X) and is_zero_approx(level.director.run.distance_tiles)
	await _frames(4)
	var streamer := level.terrain_streamer
	var chunks := streamer.active_chunk_count()
	var first_chunk := streamer.active_chunks.get(0) as TerrainChunk
	var seam_topology := first_chunk != null and first_chunk.source_variant_for_cell(Vector2i(0, 0)) == &"block_top" and first_chunk.source_variant_for_cell(Vector2i(0, 1)) == &"block_center"
	var result := "" if origin_preserved and not level.has_node("Floor") and chunks > 0 and first_chunk != null and first_chunk.atlas_source_is_valid() and seam_topology and first_chunk.get_node_or_null("Support_surface_0_main_0") != null else "production origin=%s floor=%s chunks=%s chunk=%s atlas=%s seam=%s" % [origin_preserved, level.has_node("Floor"), chunks, first_chunk, first_chunk.atlas_source_is_valid() if first_chunk != null else false, seam_topology]
	await _dispose(level)
	return result

func test_floating_platform_collision_matches_tiles() -> String:
	var platform_seed := 0
	for seed in range(1, 200):
		if TerrainGenerator.generate(GameConfig.terrain_snapshot(), GameConfig.TERRAIN_VERSION, seed, 0).form == &"platform":
			platform_seed = seed
			break
	if platform_seed == 0:
		return "Could not find a deterministic platform-form seed."
	var level := _make_production_level(platform_seed)
	await _frames(3)
	var streamer := level.terrain_streamer
	var platform: TerrainSurface = null
	for surface: TerrainSurface in streamer.surface_registry.values():
		if surface.kind == &"floating_platform" and surface.material != &"astro" and streamer.is_surface_live(surface):
			platform = surface
			break
	if platform == null:
		await _dispose(level)
		return "No floating platform was generated for collision validation."
	var body := streamer.active_chunks[platform.chunk_index].body_for_surface(platform.id) as StaticBody2D
	if body == null:
		await _dispose(level)
		return "Selected non-Astro platform did not have a merged support body."
	var collision := body.get_child(0) as CollisionShape2D
	var exact_depth := collision.shape is RectangleShape2D and is_equal_approx((collision.shape as RectangleShape2D).size.y, GameConfig.TILE_SIZE)
	var probe := RectangleShape2D.new()
	probe.size = Vector2(12, 12)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = probe
	query.collision_mask = level.player.collision_mask
	query.exclude = [level.player.get_rid()]
	var center_x := GameConfig.RUN_ORIGIN_X + float(platform.x_begin) * GameConfig.TILE_SIZE
	query.transform = Transform2D(0.0, Vector2(center_x, GameConfig.TERRAIN_BASE_SURFACE_Y + float(platform.y) * GameConfig.TILE_SIZE + GameConfig.TILE_SIZE * 0.5))
	var tile_collides := not level.get_world_2d().direct_space_state.intersect_shape(query, 8).is_empty()
	query.transform = Transform2D(0.0, Vector2(center_x, GameConfig.TERRAIN_BASE_SURFACE_Y + float(platform.y + 1) * GameConfig.TILE_SIZE + GameConfig.TILE_SIZE * 0.5))
	var underside_clear := level.get_world_2d().direct_space_state.intersect_shape(query, 8).is_empty()
	query.transform = Transform2D(0.0, Vector2(GameConfig.RUN_ORIGIN_X + float(platform.x_end) * GameConfig.TILE_SIZE + 12.0, GameConfig.TERRAIN_BASE_SURFACE_Y + float(platform.y) * GameConfig.TILE_SIZE + GameConfig.TILE_SIZE * 0.5))
	var side_clear := level.get_world_2d().direct_space_state.intersect_shape(query, 8).is_empty()
	var result := "" if exact_depth and tile_collides and underside_clear and side_clear else "platform depth=%s tile=%s underside=%s side_clear=%s" % [exact_depth, tile_collides, underside_clear, side_clear]
	await _dispose(level)
	return result

func test_generated_route_crosses_chunk_seam_without_teleport() -> String:
	var seeds_by_form: Dictionary = {}
	for seed in range(1, 200):
		var form := TerrainGenerator.generate(GameConfig.terrain_snapshot(), GameConfig.TERRAIN_VERSION, seed, 0).form
		if not seeds_by_form.has(form):
			seeds_by_form[form] = seed
		if seeds_by_form.size() == 3:
			break
	for form: StringName in [&"platform", &"mountain", &"cave"]:
		if not seeds_by_form.has(form):
			return "Could not find deterministic seed for generated form %s." % form
		var level := _make_production_level(int(seeds_by_form[form]))
		await _frames(4)
		var start_x := level.player.global_position.x
		var seam_x := GameConfig.RUN_ORIGIN_X + GameConfig.TERRAIN_CHUNK_WIDTH * GameConfig.TILE_SIZE
		for _i in 300:
			if level.player.is_on_floor():
				level.player.request_jump()
			await physics_frame
			if level.player.global_position.x > seam_x + GameConfig.TILE_SIZE:
				break
		var crossed: bool = level.director.state == Director.State.RUNNING and level.player.global_position.x > seam_x + GameConfig.TILE_SIZE and level.player.global_position.x > start_x
		if not crossed:
			var failure := "form %s did not cross seam x=%s seam=%s state=%s" % [form, level.player.global_position.x, seam_x, level.director.state]
			await _dispose(level)
			return failure
		await _dispose(level)
	return ""

func test_streamer_far_teleport_reconciles_directly_and_cleans() -> String:
	var level := _make_production_level()
	await _frames(3)
	var streamer := level.terrain_streamer
	var old_chunk := streamer.active_chunks.get(0) as TerrainChunk
	var target_column := 1200
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + target_column * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	await process_frame
	var target_index := floori(float(target_column) / GameConfig.TERRAIN_CHUNK_WIDTH)
	var direct := streamer.active_chunks.has(target_index) and not streamer.active_chunks.has(0) and streamer.descriptions.size() == streamer.active_chunks.size()
	var old_freed := old_chunk == null or not is_instance_valid(old_chunk)
	var result := "" if direct and old_freed else "teleport direct=%s old_freed=%s active=%s target=%s" % [direct, old_freed, streamer.active_chunks.keys(), target_index]
	await _dispose(level)
	return result

func test_streamer_bounded_counts_and_stale_anchor_removal() -> String:
	var level := _make_production_level(12)
	await _frames(3)
	var streamer := level.terrain_streamer
	var old_anchor := StringName("anchor:0:1")
	var had_anchor := streamer.anchor_registry.has(old_anchor)
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 800 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	await process_frame
	var camera_columns := ceili(1280.0 / GameConfig.TILE_SIZE)
	var behind := maxi(GameConfig.TERRAIN_ACTIVE_BEHIND_CHUNKS, ceili(float(camera_columns) / (2.0 * GameConfig.TERRAIN_CHUNK_WIDTH)) + 1)
	var cap := behind + maxi(GameConfig.TERRAIN_ACTIVE_AHEAD_CHUNKS, ceili(float(camera_columns) / GameConfig.TERRAIN_CHUNK_WIDTH) + GameConfig.TERRAIN_RECOVERY_MARGIN_CHUNKS) + 1
	var result := "" if had_anchor and streamer.active_chunk_count() <= cap and streamer.descriptions.size() <= cap and streamer.get_child_count() <= cap and not streamer.anchor_registry.has(old_anchor) else "bounded=%s descriptions=%s nodes=%s cap=%s stale=%s" % [streamer.active_chunk_count(), streamer.descriptions.size(), streamer.get_child_count(), cap, streamer.anchor_registry.has(old_anchor)]
	await _dispose(level)
	return result

func test_streamer_setup_replaces_generation_identity() -> String:
	var streamer := TerrainStreamer.new()
	root.add_child(streamer)
	var snapshot := GameConfig.terrain_snapshot()
	var first_ok := streamer.setup(snapshot, 111)
	var mapping := streamer.world_to_column(GameConfig.RUN_ORIGIN_X - 31.0) == 0 and streamer.world_to_column(GameConfig.RUN_ORIGIN_X + 31.0) == 0 and streamer.world_to_column(GameConfig.RUN_ORIGIN_X + 33.0) == 1 and streamer.world_to_column(GameConfig.RUN_ORIGIN_X - 33.0) == -1
	streamer.reconcile(Vector2(GameConfig.RUN_ORIGIN_X, 0), 2560.0)
	var old_chunk := streamer.active_chunks.get(0) as TerrainChunk
	var populated := first_ok and mapping and streamer.active_chunks.has(-3) and not streamer.surface_registry.is_empty()
	var second_ok := streamer.setup(snapshot, 222)
	var cleared := second_ok and streamer.active_chunks.is_empty() and streamer.descriptions.is_empty() and streamer.surface_registry.is_empty() and streamer.anchor_registry.is_empty() and old_chunk.is_queued_for_deletion()
	streamer.reconcile(Vector2(GameConfig.RUN_ORIGIN_X, 0))
	var replaced := streamer.descriptions.has(0) and (streamer.descriptions[0] as ChunkDescription).seed == 222
	var result := "" if populated and cleared and replaced else "streamer mapping/populated=%s cleared=%s replaced=%s" % [populated, cleared, replaced]
	await _dispose(streamer)
	return result

func test_generated_recovery_varied_elevation_and_removed_support() -> String:
	var level := _make_production_level(3)
	await _frames(3)
	var streamer := level.terrain_streamer
	var elevated: TerrainSurface = null
	for surface: TerrainSurface in streamer.surface_registry.values():
		var candidate := streamer.world_position_on_surface(surface)
		if surface.y != 0 and streamer.is_surface_live(surface) and level._is_valid_support_position(candidate):
			elevated = surface
			break
	if elevated == null:
		await _dispose(level)
		return "No varied-elevation generated support was available."
	var point := streamer.world_position_on_surface(elevated)
	level.profile.set_revival_potions(1)
	level.director.safe_support = point
	level.director.fail_fall_at(point, 0.0)
	var revived := level.director.revive(level.profile, 0.0)
	var placed := revived and level.player.global_position.is_equal_approx(point) and level.profile.revival_potions == 0
	level.profile.set_revival_potions(1)
	level.director.fail_fall_at(point, 2.0)
	for index: int in streamer.active_chunks.keys():
		streamer._remove_chunk(index)
	var rejected_after_removal := not level.director.revive(level.profile, 2.0) and level.profile.revival_potions == 1 and not streamer.is_surface_live(elevated)
	await _dispose(level)
	return "" if placed and rejected_after_removal else "elevated placed=%s removed_rejected=%s point=%s" % [placed, rejected_after_removal, point]

func test_generated_forward_blocker_recovery_and_no_potion_without_support() -> String:
	var level := _make_production_level(44)
	await _frames(4)
	var streamer := level.terrain_streamer
	var current := streamer.surface_candidates(level.player.global_position, false, 8)[0] as TerrainSurface
	var current_point := streamer.world_position_on_surface(current)
	var blocker := _wall(level, current_point + Vector2(GameConfig.TILE_SIZE, 0))
	await physics_frame
	var blocker_is_physical := not level._is_valid_support_position(blocker.global_position)
	level.director.safe_support = current_point
	level.director.failure_reason = Director.FailureReason.STUCK
	level.director.failure_position = blocker.global_position
	level.director.begin_countdown(0.0)
	level.profile.set_revival_potions(1)
	var revived_forward := level.director.revive(level.profile, 0.0)
	var forward := blocker_is_physical and revived_forward and level.player.global_position.x > blocker.global_position.x + GameConfig.STUCK_PROGRESS_EPSILON and level._is_valid_support_position(level.player.global_position)
	# Mark every chunk stale before the second recovery query. This removes both
	# collision and registry eligibility without synchronously generating a new one.
	level.profile.set_revival_potions(1)
	level.director.safe_support = level.player.global_position
	level.director.fail_fall(2.0)
	for index: int in streamer.active_chunks.keys():
		streamer._remove_chunk(index)
	var rejected := not level.director.revive(level.profile, 2.0) and level.profile.revival_potions == 1
	await _dispose(level)
	return "" if forward and rejected else "forward=%s no_support_rejected=%s" % [forward, rejected]

func test_generated_player_crosses_grass_tundra_boundary_without_teleport() -> String:
	var level := _make_production_level(618)
	await _frames(4)
	var streamer := level.terrain_streamer
	var boundary_column := GameConfig.BIOME_INTERVAL
	# This is test setup, before measurement: position on a real generated Grass
	# support two columns before the boundary, then let ordinary player physics
	# perform the crossing. The observed crossing itself has no teleport.
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + float(boundary_column - 2) * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	await _frames(3)
	var began_on_grass := streamer.world_to_column(level.player.global_position.x) < boundary_column
	var maximum_step := 0.0
	var previous_x := level.player.global_position.x
	var crossed := false
	for _i in 180:
		if level.player.is_on_floor():
			level.player.request_jump()
		await physics_frame
		var current_x := level.player.global_position.x
		maximum_step = maxf(maximum_step, absf(current_x - previous_x))
		previous_x = current_x
		if streamer.world_to_column(current_x) >= boundary_column + 1:
			crossed = true
			break
	var surface_before: TerrainSurface = null
	var surface_after: TerrainSurface = null
	for surface: TerrainSurface in streamer.surface_registry.values():
		if surface.contains_column(boundary_column - 1):
			surface_before = surface
		if surface.contains_column(boundary_column):
			surface_after = surface
	var boundary_is_real := surface_before != null and surface_after != null and surface_before.material == &"grass" and surface_after.material == &"tundra"
	var max_physics_step := GameConfig.SPEED / 30.0
	var result := "" if began_on_grass and crossed and level.director.state == Director.State.RUNNING and boundary_is_real and maximum_step <= max_physics_step else "began_grass=%s crossed=%s state=%s real=%s max_step=%.2f" % [began_on_grass, crossed, level.director.state, boundary_is_real, maximum_step]
	await _dispose(level)
	return result

func test_hazard_registry_cleanup_and_reconfigure() -> String:
	var level := _make_production_level(9182)
	await _frames(3)
	var streamer := level.terrain_streamer
	# Desert begins at column 120; direct reconciliation must own its metadata.
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 125.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	await process_frame
	var desert_hazard: StringName = &""
	for id: StringName in streamer.hazard_registry:
		var hazard = streamer.hazard_registry[id]
		if hazard.biome == &"desert":
			desert_hazard = id
			break
	if desert_hazard.is_empty():
		await _dispose(level)
		return "Desert chunk did not register deterministic hazard metadata."
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 1200.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	await process_frame
	var cleaned := not streamer.hazard_registry.has(desert_hazard) and streamer.runtime_for_hazard(desert_hazard) == null and streamer.hazard_registry.size() <= streamer.active_chunk_count() * 3 and streamer.active_hazard_runtimes.size() <= streamer.active_chunk_count() * 2
	var reconfigured := streamer.setup(GameConfig.terrain_snapshot(), 23) and streamer.hazard_registry.is_empty() and streamer.active_hazard_runtimes.is_empty()
	await _dispose(level)
	return "" if cleaned and reconfigured else "hazard cleanup=%s reconfigure=%s count=%d active=%d" % [cleaned, reconfigured, streamer.hazard_registry.size(), streamer.active_chunk_count()]

func _snow_surface(level: Level) -> TerrainSurface:
	for surface: TerrainSurface in level.terrain_streamer.surface_registry.values():
		if surface.kind == &"main_route" and surface.material == &"snow" and surface.x_end - surface.x_begin >= 3:
			return surface
	return null

func _settle_player_on_surface(level: Level, surface: TerrainSurface) -> bool:
	var column := mini(surface.x_begin + 1, surface.x_end - 1)
	level.player.global_position = level.terrain_streamer.world_position_on_surface(surface, column)
	level.player.velocity = Vector2.ZERO
	await _frames(4)
	return level.player.is_on_floor() and level._takeoff_support_material() == surface.material

func _measure_forced_jump(level: Level, forced_multiplier: float) -> Dictionary:
	var calls := 0
	var samples_before := level.player.snow_jump_samples_consumed()
	level.player.set_jump_height_resolver(func(_material: StringName, _seed: int, _index: int, _minimum: float, _maximum: float) -> float:
		calls += 1
		return forced_multiplier)
	var start_y := level.player.global_position.y
	var accepted := level.player.request_jump()
	var apex := start_y
	var left_floor := false
	for _frame in 180:
		await physics_frame
		apex = minf(apex, level.player.global_position.y)
		left_floor = left_floor or not level.player.is_on_floor()
		if left_floor and level.player.is_on_floor():
			break
	return {&"accepted": accepted, &"height": start_y - apex, &"calls": calls, &"multiplier": level.player.last_jump_multiplier, &"samples_before": samples_before, &"samples_after": level.player.snow_jump_samples_consumed(), &"landed": left_floor and level.player.is_on_floor()}

func test_snow_jump_sampling_physical_bounds_and_revival() -> String:
	var seed := 1
	for candidate in range(1, 100):
		if TerrainGenerator.generate(GameConfig.terrain_snapshot(), GameConfig.TERRAIN_VERSION, candidate, 7).form != &"cave":
			seed = candidate
			break
	var level := _make_production_level(seed)
	# Bring Snow chunk seven (columns 84..95) into the live registry.
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 88.0 * GameConfig.TILE_SIZE
	level.terrain_streamer.reconcile(level.player.global_position)
	await _frames(3)
	var snow := _snow_surface(level)
	var settled := snow != null and await _settle_player_on_surface(level, snow)
	if not settled:
		await _dispose(level)
		return "Could not physically settle on a generated Snow support."
	var player := level.player
	var samples_before := player.snow_jump_samples_consumed()
	player.set_runner_active(false)
	var rejected := not player.request_jump() and player.snow_jump_samples_consumed() == samples_before
	player.set_runner_active(true)
	var minimum := await _measure_forced_jump(level, GameConfig.SNOW_MIN_JUMP_MULTIPLIER)
	var post_minimum_samples := player.snow_jump_samples_consumed()
	# Revival resets movement state but deliberately retains the run-owned Snow index.
	level.profile.set_revival_potions(1)
	level.director.fail_fall_at(player.global_position, 0.0)
	var revived := level.director.revive(level.profile, 0.0)
	var retained: bool = bool(revived and level.director.seed == seed and player.snow_jump_samples_consumed() == post_minimum_samples)
	settled = await _settle_player_on_surface(level, snow)
	if not settled:
		await _dispose(level)
		return "Could not re-settle on Snow after revival."
	var maximum := await _measure_forced_jump(level, GameConfig.SNOW_MAX_JUMP_MULTIPLIER)
	# Snow flight/streaming may have retired the initial Grass chunks; make the
	# real baseline support live again before testing its material query.
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X
	level.terrain_streamer.reconcile(level.player.global_position)
	await _frames(2)
	var grass: TerrainSurface = null
	for surface: TerrainSurface in level.terrain_streamer.surface_registry.values():
		if surface.kind == &"main_route" and surface.material == &"grass" and level.terrain_streamer.is_surface_live(surface):
			grass = surface
			break
	settled = grass != null and await _settle_player_on_surface(level, grass)
	if not settled:
		var detail := "none"
		if grass != null:
			var body := level.terrain_streamer.active_chunks.get(grass.chunk_index) as TerrainChunk
			detail = "surface=%s range=%d..%d live=%s body=%s pos=%s floor=%s material=%s state=%s" % [grass.id, grass.x_begin, grass.x_end, level.terrain_streamer.is_surface_live(grass), body.body_for_surface(grass.id) if body != null else null, player.global_position, player.is_on_floor(), level._takeoff_support_material(), level.director.state]
		await _dispose(level)
		return "Could not settle on actual Grass support for baseline check: %s" % detail
	var before_grass := player.snow_jump_samples_consumed()
	var grass_accepted := player.request_jump()
	var non_snow: bool = bool(grass_accepted and player.last_takeoff_material == &"grass" and is_equal_approx(player.last_jump_multiplier, 1.0) and player.snow_jump_samples_consumed() == before_grass)
	var expected_minimum := GameConfig.MAX_JUMP * GameConfig.TILE_SIZE * GameConfig.SNOW_MIN_JUMP_MULTIPLIER
	var expected_maximum := GameConfig.MAX_JUMP * GameConfig.TILE_SIZE * GameConfig.SNOW_MAX_JUMP_MULTIPLIER
	var physical: bool = bool(minimum.accepted and is_equal_approx(float(minimum.multiplier), GameConfig.SNOW_MIN_JUMP_MULTIPLIER) and minimum.samples_after == minimum.samples_before + 1 and minimum.landed and maximum.accepted and is_equal_approx(float(maximum.multiplier), GameConfig.SNOW_MAX_JUMP_MULTIPLIER) and maximum.samples_after == maximum.samples_before + 1 and maximum.landed and absf(float(minimum.height) - expected_minimum) < 28.0 and absf(float(maximum.height) - expected_maximum) < 30.0 and float(maximum.height) > float(minimum.height) + 30.0)
	var result := "" if rejected and retained and physical and non_snow else "rejected=%s retained=%s physical=%s non_snow=%s min=%s max=%s samples=%d" % [rejected, retained, physical, non_snow, minimum, maximum, player.snow_jump_samples_consumed()]
	await _dispose(level)
	return result

func _streamed_hazard(streamer: TerrainStreamer, hazard_type: StringName):
	for descriptor in streamer.hazard_registry.values():
		if descriptor.type == hazard_type:
			var runtime = streamer.runtime_for_hazard(descriptor.id)
			if runtime != null:
				return runtime
	return null

func test_streamed_desert_hazard_contact_defense_and_cadence() -> String:
	var level := _make_production_level(9182)
	await _frames(3)
	var streamer := level.terrain_streamer
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 125.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	await _frames(3)
	var runtime = _streamed_hazard(streamer, &"desert_flame_candidate")
	if runtime == null:
		await _dispose(level)
		return "No live Desert descriptor was realized as a runtime."
	level.player.global_position = runtime.global_position
	level.player.velocity = Vector2.ZERO
	await _frames(2)
	var overlap: bool = runtime.area.get_overlapping_bodies().has(level.player)
	var centered_on_support: bool = is_equal_approx(runtime.global_position.y, GameConfig.TERRAIN_BASE_SURFACE_Y + float(runtime.descriptor.absolute_position.y + 1) * GameConfig.TILE_SIZE)
	level.director.run.health_owner.defense_multiplier = 0.5
	runtime.cadence.next_damage_at = -INF
	var before: float = level.director.run.health_owner.current_health
	runtime.advance(100.0, true)
	var after_first: float = level.director.run.health_owner.current_health
	runtime.advance(100.0 + GameConfig.DESERT_FLAME_DAMAGE_CADENCE * 0.5, true)
	var after_early: float = level.director.run.health_owner.current_health
	runtime.advance(100.0 + GameConfig.DESERT_FLAME_DAMAGE_CADENCE, true)
	var after_repeat: float = level.director.run.health_owner.current_health
	var expected: float = GameConfig.DESERT_FLAME_DAMAGE * 0.5
	var valid: bool = runtime.particles != null and runtime.particles is GPUParticles2D and overlap and centered_on_support and is_equal_approx(before - after_first, expected) and is_equal_approx(after_first, after_early) and is_equal_approx(after_early - after_repeat, expected)
	await _dispose(level)
	return "" if valid else "desert overlap=%s support=%s damage=[%.2f,%.2f,%.2f] expected=%.2f" % [overlap, centered_on_support, before - after_first, after_first - after_early, after_early - after_repeat, expected]

func test_streamed_fort_phase_hitbox_pause_and_resume() -> String:
	var level := _make_production_level(9182)
	await _frames(3)
	var streamer := level.terrain_streamer
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 205.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	await _frames(3)
	var runtime = _streamed_hazard(streamer, &"fort_spike_candidate")
	if runtime == null:
		await _dispose(level)
		return "No live Fort descriptor was realized as a runtime."
	level.player.global_position = runtime.global_position
	level.player.velocity = Vector2.ZERO
	await _frames(2)
	# Hold the physical overlap steady while selecting exact descriptor-relative
	# phase samples; Level is re-enabled below for the countdown/resume check.
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	# Select exact phase positions despite the deterministic descriptor offset.
	var phase_offset: float = float(runtime.descriptor.phase) * GameConfig.FORT_SPIKE_PERIOD
	runtime.advance(GameConfig.FORT_SPIKE_EXTENDED_SECONDS + 0.1 - phase_offset, true)
	await _frames(1)
	var retracted: bool = not runtime.is_damaging() and not runtime.spike_visual.visible and runtime.hitbox.disabled
	runtime.advance(0.125 - phase_offset, true)
	await _frames(1)
	var shape := runtime.hitbox.shape as RectangleShape2D
	var partial: bool = runtime.extension_ratio > 0.45 and runtime.extension_ratio < 0.55 and runtime.spike_visual.visible and shape != null and is_equal_approx(shape.size.y, GameConfig.FORT_SPIKE_HEIGHT * runtime.extension_ratio) and is_equal_approx(runtime.area.position.y, -shape.size.y * 0.5)
	runtime.advance(0.35 - phase_offset, true)
	await _frames(1)
	var overlap: bool = runtime.area.get_overlapping_bodies().has(level.player)
	level.director.run.health_owner.defense_multiplier = 0.5
	runtime.cadence.next_damage_at = -INF
	var before: float = level.director.run.health_owner.current_health
	runtime.advance(200.0 * GameConfig.FORT_SPIKE_PERIOD + 0.35 - phase_offset, true)
	var damaged: bool = is_equal_approx(before - level.director.run.health_owner.current_health, GameConfig.FORT_SPIKE_DAMAGE * 0.5)
	# Pausing the director freezes the only clock passed to streamed hazards.
	var frozen_time: float = level.hazard_simulation_time
	var frozen_extension: float = runtime.extension_ratio
	level.director.begin_countdown(level.director.now())
	level.set_physics_process(true)
	await _frames(3)
	var paused: bool = is_equal_approx(level.hazard_simulation_time, frozen_time) and is_equal_approx(runtime.extension_ratio, frozen_extension)
	level.director.state = Director.State.RUNNING
	await _frames(2)
	var resumed: bool = level.hazard_simulation_time > frozen_time
	var valid: bool = retracted and partial and overlap and damaged and paused and resumed
	var final_extension: float = runtime.extension_ratio
	await _dispose(level)
	return "" if valid else "fort retracted=%s partial=%s overlap=%s damaged=%s paused=%s resumed=%s extension=%.3f" % [retracted, partial, overlap, damaged, paused, resumed, final_extension]

func test_astro_cells_have_single_runtime_ownership_and_cascade() -> String:
	var level := _make_production_level(9182)
	var streamer := level.terrain_streamer
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 170.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	await _frames(2)
	var selected: TerrainChunk = null
	var ids: Array[StringName] = []
	for chunk: TerrainChunk in streamer.active_chunks.values():
		for location: Vector2i in chunk.description.occupied:
			var cell: Dictionary = chunk.description.occupied[location]
			if StringName(cell.get(&"material", &"")) == &"astro":
				ids.append(StringName(cell[&"tile_id"]))
		if not ids.is_empty():
			selected = chunk
			break
	if selected == null:
		await _dispose(level)
		return "No active Astro chunk was generated."
	var owned := selected.astro_blocks.size() == ids.size()
	var expected_block_count := selected.astro_blocks.size()
	var blocks_ok := true
	for id in ids:
		var block = selected.astro_block_for(id)
		blocks_ok = blocks_ok and block != null and block.support_body != null and block.support_body.get_meta(&"astro_tile_id", &"") == id
	var no_merged_collision := true
	for child in selected.get_children():
		if not child is StaticBody2D or not StringName((child as StaticBody2D).get_meta(&"astro_tile_id", &"")).is_empty():
			continue
		var collision := (child as StaticBody2D).get_child(0) as CollisionShape2D
		var rectangle := collision.shape as RectangleShape2D if collision != null else null
		if rectangle == null:
			continue
		var bounds := Rect2((child as StaticBody2D).global_position - rectangle.size * 0.5, rectangle.size)
		for id in ids:
			var astro_block = selected.astro_block_for(id)
			if astro_block != null and bounds.has_point(astro_block.global_position):
				no_merged_collision = false
	var first := ids[0]
	for id in ids:
		var candidate = selected.astro_block_for(id)
		var current = selected.astro_block_for(first)
		if candidate != null and current != null and candidate.global_position.y < current.global_position.y:
			first = id
	var first_block = selected.astro_block_for(first)
	var arm := streamer.invalidate_astro_tile(first)
	var immediate := arm and not streamer.is_astro_tile_stable(first)
	streamer.tick_hazards(level.hazard_simulation_time + GameConfig.ASTRO_FALL_DELAY + 0.2, true)
	var falling := streamer.astro_state_for(first) == AstroFallCoordinator.State.FALLING or streamer.astro_state_for(first) == AstroFallCoordinator.State.REMOVED
	await _dispose(level)
	return "" if owned and blocks_ok and no_merged_collision and arm and immediate and falling else "astro ownership=%s blocks=%s merged=%s arm=%s immediate=%s falling=%s ids=%d blocks=%d" % [owned, blocks_ok, no_merged_collision, arm, immediate, falling, ids.size(), expected_block_count]

func test_astro_recovery_excludes_armed_support_and_anchor_only() -> String:
	var level := _make_production_level(9182)
	var streamer := level.terrain_streamer
	# Chunk 14 has the deterministic generic anchor at local column one and is
	# in the first Astro biome segment (columns 168..179).
	var column := 169
	level.player.set_runner_active(false)
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + float(column) * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	var tile_id: StringName = &""
	var surface: TerrainSurface = null
	var anchor_id: StringName = &""
	for description: ChunkDescription in streamer.descriptions.values():
		for anchor: SpawnAnchor in description.anchors:
			if anchor.biome != &"astro":
				continue
			column = anchor.column
			anchor_id = anchor.id
			for candidate: TerrainSurface in description.surfaces:
				if candidate.id == anchor.surface_id:
					surface = candidate
					tile_id = StringName((description.occupied.get(Vector2i(column, candidate.y), {}) as Dictionary).get(&"tile_id", &""))
					break
			break
		if surface != null:
			break
	if surface == null or tile_id.is_empty() or anchor_id.is_empty():
		await _dispose(level)
		return "Astro support fixture was unavailable."
	var had_anchor := streamer.anchor_registry.has(anchor_id)
	var unrelated_anchor := StringName("anchor:12:145")
	var had_unrelated := streamer.anchor_registry.has(unrelated_anchor)
	var before_safe := not streamer.is_durable_support_column(surface, column)
	var armed := streamer.invalidate_astro_tile(tile_id)
	var removed_anchor := not streamer.anchor_registry.has(anchor_id)
	var unrelated_intact := streamer.anchor_registry.has(unrelated_anchor)
	await _dispose(level)
	return "" if before_safe and armed and had_anchor and removed_anchor and had_unrelated and unrelated_intact else "astro durable=%s armed=%s had_anchor=%s removed=%s unrelated=%s/%s" % [before_safe, armed, had_anchor, removed_anchor, had_unrelated, unrelated_intact]

func _astro_fixture_block(owner: Node2D, coordinator, tile_id: StringName, epoch: int, chunk_index: int, position: Vector2) -> AstroFallBlock:
	var block := AstroBlock.new()
	block.configure(tile_id, epoch, int(position.x / 64.0), int(position.y / 64.0), 64.0, load(TerrainPaletteRuntime.ATLAS_PATH) as Texture2D, TerrainPaletteRuntime.source_rect(&"astro", &"block"), coordinator, position, &"fixture")
	owner.add_child(block)
	coordinator.register_cell(tile_id, epoch, int(position.x / 64.0), int(position.y / 64.0), chunk_index, position.y, block)
	return block

func _astro_fixture_body(owner: Node2D, position: Vector2) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	body.position = position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28.0, 56.0)
	collision.shape = shape
	body.add_child(collision)
	owner.add_child(body)
	return body

func test_astro_area_contact_pause_and_duplicate_delay() -> String:
	var fixture := Node2D.new()
	root.add_child(fixture)
	var coordinator := AstroCoordinator.new()
	var top := _astro_fixture_block(fixture, coordinator, &"top", 1, 14, Vector2(400, 300))
	var side := _astro_fixture_block(fixture, coordinator, &"side", 1, 14, Vector2(600, 300))
	var head := _astro_fixture_block(fixture, coordinator, &"head", 1, 14, Vector2(800, 300))
	var body := _astro_fixture_body(fixture, top.global_position + Vector2(0, -59))
	top.set_target(body)
	side.set_target(body)
	head.set_target(body)
	# Countdown/game-over contacts cannot queue a stale arm.
	coordinator.set_contact_enabled(false)
	await physics_frame
	var paused_rejected := coordinator.state_for(&"top") == AstroCoordinator.State.STABLE
	coordinator.set_contact_enabled(true)
	await physics_frame
	var top_armed := coordinator.state_for(&"top") == AstroCoordinator.State.ARMED
	# Move the one real body to isolated side/head sensors. Neither overlaps the
	# narrow top strip, so both remain stable after real physics frames.
	body.global_position = side.global_position + Vector2(45, -59)
	await physics_frame
	var side_rejected := coordinator.state_for(&"side") == AstroCoordinator.State.STABLE
	body.global_position = head.global_position + Vector2(0, 45)
	await physics_frame
	var head_rejected := coordinator.state_for(&"head") == AstroCoordinator.State.STABLE
	coordinator.advance(0.08, true, 64.0, 200.0, 0.15, 0.01, 512.0)
	var duplicate := coordinator.arm_from_contact(&"top", 1, &"top")
	coordinator.advance(0.16, true, 64.0, 200.0, 0.15, 0.01, 512.0)
	var no_restart := not duplicate and coordinator.state_for(&"top") == AstroCoordinator.State.FALLING
	fixture.free()
	await process_frame
	return "" if paused_rejected and top_armed and side_rejected and head_rejected and no_restart else "astro contact pause=%s top=%s side=%s head=%s duplicate-delay=%s" % [paused_rejected, top_armed, side_rejected, head_rejected, no_restart]

func test_astro_real_block_cascade_alignment_and_release() -> String:
	var fixture := Node2D.new()
	root.add_child(fixture)
	var coordinator := AstroCoordinator.new()
	var top := _astro_fixture_block(fixture, coordinator, &"cascade_top", 3, 14, Vector2(1000, 200))
	var middle := _astro_fixture_block(fixture, coordinator, &"cascade_mid", 4, 15, Vector2(1000, 264))
	var bottom := _astro_fixture_block(fixture, coordinator, &"cascade_bottom", 4, 15, Vector2(1000, 328))
	var original_y := top.global_position.y
	coordinator.arm(&"cascade_top", 3, &"top")
	coordinator.advance(0.06, true, 64.0, 320.0, 0.05, 0.01, 512.0)
	coordinator.advance(0.30, true, 64.0, 320.0, 0.05, 0.01, 512.0)
	var middle_armed := coordinator.state_for(&"cascade_mid") != AstroCoordinator.State.STABLE
	coordinator.advance(0.65, true, 64.0, 320.0, 0.05, 0.01, 512.0)
	var bottom_armed := coordinator.state_for(&"cascade_bottom") != AstroCoordinator.State.STABLE
	var aligned := is_equal_approx(top.global_position.y, top.support_body.global_position.y) and is_equal_approx(middle.global_position.y, middle.support_body.global_position.y) and is_equal_approx(bottom.global_position.y, bottom.support_body.global_position.y)
	var separated := middle.global_position.y - top.global_position.y >= 63.9 and bottom.global_position.y - middle.global_position.y >= 63.9
	var released := top.global_position.y > original_y + 0.1
	var final_positions := Vector3(top.global_position.y, middle.global_position.y, bottom.global_position.y)
	fixture.free()
	await process_frame
	return "" if middle_armed and bottom_armed and aligned and separated and released else "astro cascade mid=%s bottom=%s aligned=%s separated=%s released=%s positions=%.1f/%.1f/%.1f" % [middle_armed, bottom_armed, aligned, separated, released, final_positions.x, final_positions.y, final_positions.z]

func test_astro_revival_pause_and_retirement_cleanup() -> String:
	var level := _make_production_level(9182)
	var streamer := level.terrain_streamer
	level.player.set_runner_active(false)
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 170.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	var id: StringName = &""
	var epoch := -1
	for candidate: StringName in streamer.astro_tile_registry:
		id = candidate
		epoch = int((streamer.astro_tile_registry[id] as Dictionary)[&"epoch"])
		break
	if id.is_empty():
		await _dispose(level)
		return "No Astro tile available for pause/retirement fixture."
	var armed := streamer.invalidate_astro_tile(id)
	streamer.tick_hazards(level.hazard_simulation_time + GameConfig.ASTRO_FALL_DELAY + 0.2, true)
	var falling_state := streamer.astro_state_for(id)
	level.director.begin_countdown(level.director.now())
	streamer.tick_hazards(level.hazard_simulation_time + 10.0, false)
	var paused := streamer.astro_state_for(id) == falling_state
	# Use Level's unmodified support query. A real Desert flame's support-top
	# pose is physically valid terrain but forbidden by full-body hazard safety.
	var desert = _streamed_hazard(streamer, &"desert_flame_candidate")
	if desert == null:
		await _dispose(level)
		return "No live Desert runtime for hazard-safe recovery fixture."
	var dangerous: Vector2 = (desert as Node2D).global_position + Vector2(0.0, -32.0)
	var original_seed: int = level.director.seed
	level.director.state = Director.State.RUNNING
	level.profile.set_revival_potions(1)
	level.director.safe_support = dangerous
	level.director.fail_fall_at(dangerous, level.director.now())
	var revived := level.request_revival()
	var chosen_safe: bool = revived and level.director.safe_support != dangerous and level._is_valid_support_position(level.director.safe_support)
	var state_preserved: bool = level.director.seed == original_seed and streamer.astro_state_for(id) == falling_state
	# Remove every live logical recovery support while leaving Level's actual
	# support resolver installed; this is the no-safe potion transaction case.
	streamer.surface_registry.clear()
	streamer.anchor_registry.clear()
	level.profile.set_revival_potions(1)
	level.director.fail_fall_at(level.player.global_position, level.director.now())
	var preserved := not level.request_revival() and level.profile.revival_potions == 1
	# Retire the currently active Astro chunk, then prove the old callback epoch
	# cannot mutate a regenerated registry. Several far reconciles also bound
	# live chunk/block/cell/hazard counts rather than relying on setup clearing.
	for column in [2000, 4000, 6000]:
		streamer.reconcile(Vector2(GameConfig.RUN_ORIGIN_X + float(column) * GameConfig.TILE_SIZE, level.player.global_position.y))
	await process_frame
	var retired := not streamer.astro_tile_registry.has(id) and not streamer.astro_coordinator.cells.has(id) and not streamer.astro_coordinator.arm(id, epoch, &"top")
	# Revisiting the exact deterministic tile creates a pristine cell with a new
	# registration serial; stale callbacks from the retired epoch cannot arm it.
	streamer.reconcile(Vector2(GameConfig.RUN_ORIGIN_X + 170.0 * GameConfig.TILE_SIZE, level.player.global_position.y))
	var revisited: Dictionary = streamer.astro_tile_registry.get(id, {})
	var new_epoch := int(revisited.get(&"epoch", -1))
	var regenerated := not revisited.is_empty() and new_epoch != epoch and not streamer.astro_coordinator.arm(id, epoch, &"top") and streamer.astro_state_for(id) == AstroCoordinator.State.STABLE
	var chunk_cap := GameConfig.TERRAIN_ACTIVE_AHEAD_CHUNKS + GameConfig.TERRAIN_ACTIVE_BEHIND_CHUNKS + 1
	var block_count := 0
	for chunk: TerrainChunk in streamer.active_chunks.values():
		block_count += chunk.astro_blocks.size()
	var bounded := streamer.active_chunk_count() <= chunk_cap and streamer.astro_coordinator.cells.size() <= chunk_cap * GameConfig.TERRAIN_CHUNK_WIDTH * 3 and block_count <= chunk_cap * GameConfig.TERRAIN_CHUNK_WIDTH * 3 and streamer.hazard_registry.size() <= chunk_cap * 3 and streamer.anchor_registry.size() <= chunk_cap
	var reconfigured := streamer.setup(GameConfig.terrain_snapshot(), 9193) and streamer.astro_tile_registry.is_empty() and streamer.astro_coordinator.cells.is_empty() and streamer.active_chunk_count() == 0
	await _dispose(level)
	var is_falling := falling_state == AstroCoordinator.State.FALLING
	return "" if armed and is_falling and paused and revived and chosen_safe and state_preserved and preserved and retired and regenerated and bounded and reconfigured else "astro pause/retire armed=%s falling=%s paused=%s revived=%s safe=%s state=%s potion=%s retired=%s regenerated=%s bounded=%s reconfigured=%s" % [armed, is_falling, paused, revived, chosen_safe, state_preserved, preserved, retired, regenerated, bounded, reconfigured]

func test_negative_chunk_collision_and_zero_crossing() -> String:
	var level := _make_production_level(618)
	level.player.global_position = Vector2(GameConfig.RUN_ORIGIN_X - 4.0 * GameConfig.TILE_SIZE, 568.0)
	level.terrain_streamer.reconcile(level.player.global_position)
	await _frames(3)
	var chunk := level.terrain_streamer.active_chunks.get(-2) as TerrainChunk
	var surface: TerrainSurface = null
	if chunk != null:
		for candidate: TerrainSurface in chunk.description.surfaces:
			if candidate.kind == &"main_route" and candidate.x_begin < 0:
				surface = candidate
				break
	var body := chunk.body_for_surface(surface.id) as StaticBody2D if chunk != null and surface != null else null
	var negative_collision := body != null and body.get_child_count() > 0
	var crossed := false
	for _frame in 180:
		if level.player.is_on_floor():
			level.player.request_jump()
		await physics_frame
		if level.terrain_streamer.world_to_column(level.player.global_position.x) >= 0:
			crossed = true
			break
	var alive: bool = level.director.state == Director.State.RUNNING and level.player.global_position.y < 1000.0
	var final_position := level.player.global_position
	await _dispose(level)
	return "" if negative_collision and crossed and alive else "negative collision=%s crossed=%s alive=%s position=%s" % [negative_collision, crossed, alive, final_position]

func test_generated_non_astro_impact_preserves_terrain() -> String:
	var level := _make_production_level(618)
	var streamer := level.terrain_streamer
	await _frames(2)
	var surface: TerrainSurface = null
	for candidate: TerrainSurface in streamer.surface_registry.values():
		if candidate.material != &"astro" and candidate.kind == &"main_route" and streamer.is_surface_live(candidate):
			surface = candidate
			break
	if surface == null:
		await _dispose(level)
		return "No live non-Astro generated support."
	var column := surface.x_begin
	var description := streamer.descriptions[surface.chunk_index] as ChunkDescription
	var location := Vector2i(column, surface.y)
	var original: Dictionary = (description.occupied[location] as Dictionary).duplicate(true)
	var body := streamer.active_chunks[surface.chunk_index].body_for_surface(surface.id) as StaticBody2D
	var fixture := Node2D.new()
	root.add_child(fixture)
	var coordinator := AstroCoordinator.new()
	coordinator.set_solid_below_query(streamer._has_non_astro_solid_between)
	var world := Vector2(GameConfig.RUN_ORIGIN_X + float(column) * GameConfig.TILE_SIZE, GameConfig.TERRAIN_BASE_SURFACE_Y + float(surface.y) * GameConfig.TILE_SIZE - 32.0)
	var block := _astro_fixture_block(fixture, coordinator, &"impact", 99, 99, world)
	coordinator.arm(&"impact", 99, &"top")
	coordinator.advance(0.20, true, 64.0, 320.0, 0.01, 0.01, 512.0)
	var removed := coordinator.state_for(&"impact") == AstroCoordinator.State.REMOVED
	var unchanged: bool = description.occupied[location] == original and body != null and is_instance_valid(body) and not body.is_queued_for_deletion()
	fixture.free()
	await _dispose(level)
	return "" if removed and unchanged else "generated impact removed=%s unchanged=%s state=%d" % [removed, unchanged, coordinator.state_for(&"impact")]

func test_continuous_astro_segment_traversal_with_collapse() -> String:
	var level := _make_production_level(9182)
	var streamer := level.terrain_streamer
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 158.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	await _frames(2)
	var previous_x := level.player.global_position.x
	var max_step := 0.0
	var collapsed := false
	for _frame in 750:
		if level.player.is_on_floor():
			level.player.request_jump()
		await physics_frame
		max_step = maxf(max_step, absf(level.player.global_position.x - previous_x))
		previous_x = level.player.global_position.x
		for state in streamer.astro_coordinator.cells.values():
			if int((state as Dictionary)[&"state"]) != AstroCoordinator.State.STABLE:
				collapsed = true
				break
		if streamer.world_to_column(level.player.global_position.x) >= 202:
			break
	var crossed := streamer.world_to_column(level.player.global_position.x) >= 202
	var cap := GameConfig.TERRAIN_ACTIVE_AHEAD_CHUNKS + GameConfig.TERRAIN_ACTIVE_BEHIND_CHUNKS + 1
	var bounded := streamer.active_chunk_count() <= cap and streamer.astro_tile_registry.size() <= cap * GameConfig.TERRAIN_CHUNK_WIDTH * 3
	var valid: bool = crossed and collapsed and level.director.state == Director.State.RUNNING and max_step <= GameConfig.SPEED / 30.0 and bounded
	var final_column := streamer.world_to_column(level.player.global_position.x)
	await _dispose(level)
	return "" if valid else "astro traversal crossed=%s collapsed=%s state=%s step=%.2f bounded=%s column=%d" % [crossed, collapsed, level.director.state, max_step, bounded, final_column]

func test_same_frame_fall_freezes_astro_hazard_tick() -> String:
	var level := _make_production_level(9182)
	var streamer := level.terrain_streamer
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 170.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	var id: StringName = streamer.astro_tile_registry.keys()[0] if not streamer.astro_tile_registry.is_empty() else &""
	if id.is_empty():
		await _dispose(level)
		return "No Astro fixture for same-frame fall."
	streamer.invalidate_astro_tile(id)
	streamer.tick_hazards(level.hazard_simulation_time + GameConfig.ASTRO_FALL_DELAY + 0.1, true)
	var before_cell := (streamer.astro_coordinator.cells[id] as Dictionary).duplicate(true)
	var before_time := level.hazard_simulation_time
	level.player.global_position.y = 1001.0
	# Invoke exactly the production frame that observes the fall. Awaiting the
	# global physics signal here would also admit scheduler-dependent neighbor
	# frames and would no longer isolate the stale-running regression.
	level._physics_process(0.016)
	var after_cell := streamer.astro_coordinator.cells.get(id, {}) as Dictionary
	var unchanged := int(after_cell.get(&"state", -1)) == int(before_cell.get(&"state", -2)) and is_equal_approx(float(after_cell.get(&"fall_y", after_cell.get(&"world_y", 0.0))), float(before_cell.get(&"fall_y", before_cell.get(&"world_y", 0.0))))
	var frozen: bool = level.director.state == Director.State.REVIVAL_COUNTDOWN and is_equal_approx(level.hazard_simulation_time, before_time) and not streamer.astro_coordinator.contact_enabled
	await _dispose(level)
	return "" if unchanged and frozen else "same-frame fall unchanged=%s frozen=%s before=%s after=%s" % [unchanged, frozen, before_cell, after_cell]

func test_same_frame_stuck_freezes_astro_and_fort() -> String:
	var level := _make_production_level(9182)
	var streamer := level.terrain_streamer
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 170.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position)
	var id: StringName = streamer.astro_tile_registry.keys()[0] if not streamer.astro_tile_registry.is_empty() else &""
	var fort = _streamed_hazard(streamer, &"fort_spike_candidate")
	if id.is_empty() or fort == null:
		await _dispose(level)
		return "Missing Astro/Fort fixture for same-frame stuck."
	streamer.invalidate_astro_tile(id)
	streamer.tick_hazards(0.5, true)
	var before_cell := (streamer.astro_coordinator.cells[id] as Dictionary).duplicate(true)
	var before_extension := float(fort.extension_ratio)
	var before_time := level.hazard_simulation_time
	var clock := level.director.clock as GameClock.ManualClock
	# The setup teleport is not runner progress for this boundary. Synchronize
	# the Director first so the next unchanged sample exercises the stuck branch.
	level.director.initialize_progress(level.player.global_position, clock.now_seconds())
	clock.advance(GameConfig.GAME_OVER_NUMBER_OF_SECS + 0.1)
	# Invoke Level's production physics path: unchanged position makes
	# record_progress enter its genuine stuck countdown branch this frame.
	level._physics_process(0.016)
	var after_cell := streamer.astro_coordinator.cells.get(id, {}) as Dictionary
	var astro_frozen: bool = int(after_cell.get(&"state", -1)) == int(before_cell.get(&"state", -2)) and is_equal_approx(float(after_cell.get(&"fall_y", after_cell.get(&"world_y", 0.0))), float(before_cell.get(&"fall_y", before_cell.get(&"world_y", 0.0))))
	var frozen: bool = level.director.state == Director.State.REVIVAL_COUNTDOWN and is_equal_approx(level.hazard_simulation_time, before_time) and is_equal_approx(float(fort.extension_ratio), before_extension) and not streamer.astro_coordinator.contact_enabled
	var final_state: int = level.director.state
	var final_time: float = level.hazard_simulation_time
	var final_extension: float = fort.extension_ratio
	await _dispose(level)
	return "" if astro_frozen and frozen else "same-frame stuck astro=%s frozen=%s state=%s time=%.3f/%.3f fort=%.3f/%.3f" % [astro_frozen, frozen, final_state, before_time, final_time, before_extension, final_extension]

func test_m4_anchor_lifecycle_and_astro_spawn_support() -> String:
	var level := _make_production_level(618)
	var streamer := level.terrain_streamer
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X + 168.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position, 640.0)
	var added: Array[StringName] = []; var removed: Array[StringName] = []; var invalidated: Array[StringName] = []
	streamer.anchor_added.connect(func(id: StringName, _surface: StringName, _tile: StringName, _chunk: int, _epoch: int) -> void: added.append(id))
	streamer.anchor_removed.connect(func(id: StringName, _surface: StringName, _tile: StringName, _chunk: int, _epoch: int) -> void: removed.append(id))
	streamer.anchor_invalidated.connect(func(id: StringName, _surface: StringName, _tile: StringName, _chunk: int, _epoch: int) -> void: invalidated.append(id))
	# Reconfigure gives the signal observer a complete add lifecycle.
	streamer.setup(GameConfig.terrain_snapshot(), 618)
	streamer.reconcile(level.player.global_position, 640.0)
	var astro_anchor: SpawnAnchor = null
	var removable_anchor: SpawnAnchor = null
	for anchor: SpawnAnchor in streamer.anchor_registry.values():
		if removable_anchor == null: removable_anchor = anchor
		if anchor.biome == &"astro": astro_anchor = anchor
	var stable_live := astro_anchor != null and streamer.is_anchor_eligible(astro_anchor.id, int(streamer.anchor_identity(astro_anchor.id).get(&"epoch", -1)))
	var exact_invalidated := false
	if astro_anchor != null:
		var description := streamer.descriptions.get(astro_anchor.chunk_index) as ChunkDescription
		var tile := StringName((description.occupied.get(Vector2i(astro_anchor.column, astro_anchor.row + 1), {}) as Dictionary).get(&"tile_id", &""))
		if not tile.is_empty(): streamer.invalidate_astro_tile(tile)
		exact_invalidated = invalidated.has(astro_anchor.id) and not streamer.is_anchor_eligible(astro_anchor.id)
	level.player.global_position.x = GameConfig.RUN_ORIGIN_X - 120.0 * GameConfig.TILE_SIZE
	streamer.reconcile(level.player.global_position, 64.0)
	var retired := removable_anchor != null and removed.has(removable_anchor.id)
	await _dispose(level)
	return "" if not added.is_empty() and stable_live and exact_invalidated and retired else "anchor lifecycle added=%s stable=%s invalidated=%s retired=%s" % [added.size(), stable_live, exact_invalidated, retired]

func _m4_runtime_descriptor(definition, serial: int, column: int = 0) -> EnemySpawnRuntime:
	return EnemySpawnRuntime.new(
		StringName("m4a1:%s:%d" % [definition.id, serial]),
		GameConfig.ENEMY_CATALOG_VERSION,
		618,
		definition.id,
		0,
		maxi(1, serial),
		StringName("anchor:m4a1:%d" % serial),
		&"surface:m4a1",
		StringName("tile:m4a1:%d" % serial),
		column,
		0,
		definition.biome,
		0,
		1,
		&"right",
		column - 2,
		column + 3
	)

func _m4_runtime_enemy(level: Level, definition, serial: int, offset: Vector2) -> EnemyControllerRuntime:
	var enemy := EnemyControllerRuntime.new()
	var descriptor := _m4_runtime_descriptor(definition, serial)
	if not enemy.configure(definition, descriptor, level.player, level.director, level.camera, level):
		enemy.free()
		return null
	enemy.position = level.player.position + offset
	level.add_child(enemy)
	return enemy

func test_m4a1_spawner_materializes_healthbar_and_retires() -> String:
	var level := _make_production_level(618, true)
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.enemy_spawner.set_physics_process(false)
	await physics_frame
	level.enemy_spawner._materialize_pending()
	var count := level.enemy_spawner.active.size()
	if count <= 0:
		await _dispose(level)
		return "Production enemy spawner did not materialize any live anchor."
	var first_id := StringName(level.enemy_spawner.active.keys()[0])
	var enemy := level.enemy_spawner.active[first_id] as EnemyControllerRuntime
	if enemy == null or enemy.descriptor == null:
		await _dispose(level)
		return "Spawner active registry did not contain a configured enemy."
	var eligible := level.terrain_streamer.is_anchor_eligible(enemy.descriptor.anchor_id, enemy.descriptor.chunk_epoch, enemy.descriptor.support_tile_id)
	var health_before := enemy.health
	var damaged := enemy.apply_damage(1.0)
	var healthbar_ok := damaged and enemy._health_bar != null and is_equal_approx(enemy._health_bar.value, health_before - 1.0)
	var cache := level.enemy_spawner.animation_loader.cache_stats()
	var cache_ok := int(cache[&"entries"]) > 0 and int(cache[&"references"]) >= 1
	var retired_id := enemy.descriptor.id
	var far_position := Vector2(GameConfig.RUN_ORIGIN_X + 240.0 * GameConfig.TILE_SIZE, level.player.global_position.y)
	level.terrain_streamer.reconcile(far_position, 64.0)
	var retired := not level.enemy_spawner.active.has(retired_id) and enemy.retired
	var bounded := count <= GameConfig.MAX_ACTIVE_ENEMIES
	await _dispose(level)
	return "" if eligible and healthbar_ok and cache_ok and retired and bounded else "spawn count=%d eligible=%s healthbar=%s cache=%s retired=%s bounded=%s" % [count, eligible, healthbar_ok, cache_ok, retired, bounded]

func test_m4a1_controller_behavior_channels_and_pause() -> String:
	var level := _make_level()
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.enemy_spawner.set_physics_process(false)
	var catalog := EnemySpawnerRuntime.new()
	var definitions := catalog.example_definitions()
	var by_id: Dictionary = {}
	for definition in definitions:
		by_id[definition.id] = definition
	var stationary := _m4_runtime_enemy(level, by_id[&"example_stationary_melee"], 1, Vector2(48, 0))
	var stationary_events: Array[StringName] = []
	stationary.melee_attack.connect(func(_enemy) -> void: stationary_events.append(&"melee"))
	stationary.ranged_attack.connect(func(_enemy, _kind) -> void: stationary_events.append(&"ranged"))
	var stationary_x := stationary.global_position.x
	stationary.update_runtime(0.1, 0.0, true, true, true, true, 1.0)
	var stationary_ok := is_equal_approx(stationary.global_position.x, stationary_x) and stationary_events == [&"melee"]
	var patrol := _m4_runtime_enemy(level, by_id[&"example_patrol_ranged"], 2, Vector2(100, 0))
	var patrol_events: Array[StringName] = []
	patrol.melee_attack.connect(func(_enemy) -> void: patrol_events.append(&"melee"))
	patrol.ranged_attack.connect(func(_enemy, _kind) -> void: patrol_events.append(&"ranged"))
	var patrol_x := patrol.global_position.x
	patrol.update_runtime(0.1, 0.0, true, true, true, true, 1.0)
	var patrol_ok := not is_equal_approx(patrol.global_position.x, patrol_x) and patrol_events == [&"ranged"]
	var combined := _m4_runtime_enemy(level, by_id[&"example_combined"], 3, Vector2(56, 0))
	var combined_events: Array[StringName] = []
	combined.melee_attack.connect(func(_enemy) -> void: combined_events.append(&"melee"))
	combined.ranged_attack.connect(func(_enemy, _kind) -> void: combined_events.append(&"ranged"))
	combined.update_runtime(0.1, 0.0, true, true, true, true, 1.0)
	var combined_ok := combined_events.has(&"melee") and combined_events.has(&"ranged")
	var particle_runtime_ok := false
	var beam_runtime_ok := false
	for child in level.get_children():
		if child is GPUParticles2D:
			var particle := child as GPUParticles2D
			particle_runtime_ok = particle.process_material != null and particle.texture != null and particle.one_shot
		elif child is Line2D:
			beam_runtime_ok = (child as Line2D).points.size() == 2
	var death_events: Array[bool] = []
	stationary.died.connect(func(_enemy) -> void: death_events.append(true))
	var killed := stationary.apply_damage(stationary.health)
	var death_ok := killed and stationary.dead and not death_events.is_empty() and stationary._health_bar != null and is_zero_approx(stationary._health_bar.value)
	level.director.begin_countdown(0.0)
	var paused_x := patrol.global_position.x
	var paused_events := patrol_events.size()
	patrol.update_runtime(0.5, 10.0, true, true, true, true, 1.0)
	var pause_ok := is_equal_approx(patrol.global_position.x, paused_x) and patrol_events.size() == paused_events
	catalog.free()
	await _dispose(level)
	return "" if stationary_ok and patrol_ok and combined_ok and particle_runtime_ok and beam_runtime_ok and death_ok and pause_ok else "stationary=%s patrol=%s combined=%s particle=%s beam=%s death=%s pause=%s events=%s/%s/%s" % [stationary_ok, patrol_ok, combined_ok, particle_runtime_ok, beam_runtime_ok, death_ok, pause_ok, stationary_events, patrol_events, combined_events]

func test_m4a1_projectile_sweep_pause_and_hit() -> String:
	var world := Node2D.new()
	root.add_child(world)
	var target := CharacterBody2D.new()
	target.position = Vector2(300, 300)
	target.collision_layer = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(36, 64)
	collision.shape = shape
	target.add_child(collision)
	world.add_child(target)
	await physics_frame
	var director := Director.new(GameClock.ManualClock.new())
	var spawner := EnemySpawnerRuntime.new()
	spawner.director = director
	spawner.set_physics_process(false)
	world.add_child(spawner)
	var hit := DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(5.0, &"m4_projectile"))
	var projectile := EnemyProjectileRuntime.new()
	var configured := projectile.configure(Vector2(200, 300), Vector2.RIGHT, 1000.0, hit, target, director)
	var resolutions: Array[bool] = []
	projectile.resolved.connect(func(_shot, hit_player: bool) -> void: resolutions.append(hit_player))
	projectile.resolved.connect(Callable(spawner, &"_on_enemy_projectile_resolved"))
	world.add_child(projectile)
	projectile.set_physics_process(false)
	director.begin_countdown(0.0)
	var paused_position := projectile.global_position
	var paused_lifetime := projectile.remaining_seconds
	projectile._physics_process(0.1)
	var pause_ok := projectile.global_position == paused_position and is_equal_approx(projectile.remaining_seconds, paused_lifetime) and resolutions.is_empty()
	director.state = Director.State.RUNNING
	var health_before := director.run.health_owner.current_health
	projectile._physics_process(0.2)
	var damage_ok := is_equal_approx(director.run.health_owner.current_health, health_before - 5.0)
	var hit_ok := projectile._finished and resolutions == [true] and damage_ok
	await _dispose(world)
	return "" if configured and pause_ok and hit_ok else "projectile configured=%s pause=%s hit=%s damage=%s resolutions=%s" % [configured, pause_ok, hit_ok, damage_ok, resolutions]

func test_m4b_production_catalog_spawn_wiring() -> String:
	var level := _make_production_level(618, true)
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.enemy_spawner.set_physics_process(false)
	await physics_frame
	level.enemy_spawner._materialize_pending()
	var definitions := EnemyCatalogRuntime.definitions()
	var by_id: Dictionary = {}
	for definition in definitions:
		by_id[definition.id] = definition
	var active_count := level.enemy_spawner.active.size()
	var wiring_ok := active_count > 0 and active_count <= GameConfig.MAX_ACTIVE_ENEMIES and level.enemy_spawner.definitions.size() == EnemyCatalogRuntime.CANONICAL_IDENTITY_COUNT
	for enemy_variant in level.enemy_spawner.active.values():
		var enemy := enemy_variant as EnemyControllerRuntime
		if enemy == null or enemy.definition == null or enemy.descriptor == null:
			wiring_ok = false
			continue
		var definition = by_id.get(enemy.definition.id)
		wiring_ok = wiring_ok and definition != null and definition.id == enemy.definition.id
		wiring_ok = wiring_ok and enemy.definition.biome == enemy.descriptor.biome
		wiring_ok = wiring_ok and enemy.definition.tier == enemy.descriptor.tier and enemy.definition.tier <= enemy.descriptor.biome_visit + 1
		wiring_ok = wiring_ok and enemy.definition.variant_ids().has(enemy.descriptor.variant_id)
		wiring_ok = wiring_ok and enemy._sprite != null and not enemy.definition.idle_frames_for_variant(enemy.descriptor.variant_id).is_empty()
	await _dispose(level)
	return "" if wiring_ok else "M4b production catalog spawn wiring failed with active_count=%d." % active_count

func test_m4b_freeze_burn_and_blood_loss_runtime() -> String:
	var level := _make_level()
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.enemy_spawner.set_physics_process(false)
	var frost = null
	var nomad = null
	var vampire = null
	for definition in EnemyCatalogRuntime.definitions():
		if definition.id == &"frost_knight": frost = definition
		if definition.id == &"desert_nomad": nomad = definition
		if definition.id == &"vampire": vampire = definition
	if frost == null or nomad == null or vampire == null:
		await _dispose(level)
		return "Required M4b effect definitions are missing."
	var owner: DamageStatus.HealthOwner = level.director.run.health_owner
	level.director.state = Director.State.RUNNING
	level.director.simulation_time = 0.0
	owner.current_health = owner.maximum_health
	owner.statuses.clear()
	var freeze_hit := DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(frost.contact_damage, frost.id), frost.effect_spec, frost.id)
	var freeze_result := level.director.apply_hit(freeze_hit, 0.0)
	level.player.damage_tint_until = -1.0
	level.player.simulation_time = 0.0
	var freeze_ok := freeze_result.effect_installed and owner.has_status(frost.effect_spec.status_id, 0.0) and level.player.appearance_state() == &"freeze" and level.player.effective_movement_multiplier() < 1.0
	owner.current_health = owner.maximum_health
	owner.statuses.clear()
	level.director.simulation_time = 0.0
	var burn_hit := DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(nomad.contact_damage, nomad.id), nomad.effect_spec, nomad.id)
	var burn_result := level.director.apply_hit(burn_hit, 0.0)
	var burn_after_hit := owner.current_health
	level.director.advance_simulation(nomad.effect_spec.tick_interval_seconds + 0.01)
	var burn_ok := burn_result.effect_installed and owner.current_health < burn_after_hit
	owner.current_health = owner.maximum_health
	owner.statuses.clear()
	level.director.simulation_time = 0.0
	level.player.simulation_time = 0.0
	var blood_hit := DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(vampire.contact_damage, vampire.id), vampire.effect_spec, vampire.id)
	var blood_result := level.director.apply_hit(blood_hit, 0.0)
	level.player.damage_tint_until = -1.0
	var blood_visual := level.player.appearance_state() == &"blood"
	var blood_after_hit := owner.current_health
	level.player.simulation_time = vampire.effect_spec.tick_interval_seconds + 0.01
	level.director.advance_simulation(vampire.effect_spec.tick_interval_seconds + 0.01)
	var blood_tick_red := level.player.appearance_state() == &"damage"
	var blood_ok := blood_result.effect_installed and blood_visual and owner.current_health < blood_after_hit and blood_tick_red
	await _dispose(level)
	return "" if freeze_ok and burn_ok and blood_ok else "M4b status runtime freeze=%s burn=%s blood=%s installed=%s visual=%s health=%.2f<%.2f red=%s tint=%.3f player_t=%.3f director_t=%.3f." % [freeze_ok, burn_ok, blood_ok, blood_result.effect_installed, blood_visual, owner.current_health, blood_after_hit, blood_tick_red, level.player.damage_tint_until, level.player.simulation_time, level.director.simulation_time]

func test_m5a_streamed_collectible_pickup_and_cleanup() -> String:
	var level := _make_production_level(618, false, true)
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.collectible_spawner.set_physics_process(false)
	await physics_frame
	level.collectible_spawner._materialize_pending()
	var active_count: int = level.collectible_spawner.active.size()
	if active_count <= 0:
		await _dispose(level)
		return "Production collectible spawner did not materialize a live route pickup."
	var first_pickup_id := StringName(level.collectible_spawner.active.keys()[0])
	var streamed_pickup := level.collectible_spawner.active[first_pickup_id] as CollectiblePickupRuntime
	var anchor_id: StringName = streamed_pickup.anchor_id
	var streamed_ok: bool = not anchor_id.is_empty() and streamed_pickup != null and streamed_pickup.definition != null and streamed_pickup.definition.spawnable
	var coin: CollectibleDefinitionRuntime = CollectibleCatalogRuntime.by_id(&"coin_gold")
	var coin_pickup := level.collectible_spawner._spawn_pickup(coin, &"test:coin", level.player.global_position, &"", false) as CollectiblePickupRuntime
	var gold_before: int = int(level.director.run.earned_gold)
	coin_pickup._on_body_entered(level.player)
	var coin_ok: bool = level.director.run.earned_gold == gold_before + GameConfig.COIN_GOLD_GOLD and not level.collectible_spawner.active.has(&"test:coin")
	var heart: CollectibleDefinitionRuntime = CollectibleCatalogRuntime.by_id(&"heart")
	level.director.run.health_owner.current_health = level.director.run.health_owner.maximum_health - 30.0
	var heart_pickup := level.collectible_spawner._spawn_pickup(heart, &"test:heart", level.player.global_position, &"", false) as CollectiblePickupRuntime
	var health_before: float = float(level.director.run.health_owner.current_health)
	heart_pickup._on_body_entered(level.player)
	var expected_health: float = minf(level.director.run.health_owner.maximum_health, health_before + GameConfig.HEALTH_PICKUP_AMOUNT)
	var heart_ok: bool = is_equal_approx(level.director.run.health_owner.current_health, expected_health) and not level.collectible_spawner.active.has(&"test:heart")
	var far_position := Vector2(GameConfig.RUN_ORIGIN_X + 240.0 * GameConfig.TILE_SIZE, level.player.global_position.y)
	level.terrain_streamer.reconcile(far_position, 64.0)
	var retired_ok: bool = not level.collectible_spawner.anchor_to_pickup.has(anchor_id) and not level.collectible_spawner.active.has(first_pickup_id)
	await _dispose(level)
	return "" if streamed_ok and coin_ok and heart_ok and retired_ok else "M5a streamed pickup=%s coin=%s heart=%s retire=%s active=%d." % [streamed_ok, coin_ok, heart_ok, retired_ok, active_count]

func test_m5a_player_melee_cadence_death_and_drops() -> String:
	var level := _make_level()
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.enemy_spawner.set_physics_process(false)
	level.collectible_spawner.set_physics_process(false)
	level.collectible_spawner.configure(level.terrain_streamer, level.player, level.director, level.enemy_spawner)
	var definition: EnemyDefinitionRuntime = null
	for candidate: EnemyDefinitionRuntime in EnemyCatalogRuntime.definitions():
		if candidate.id == &"archer_guy":
			definition = candidate
			break
	if definition == null:
		await _dispose(level)
		return "Archer definition missing for M5a melee test."
	var chosen_spawn_id: StringName = &""
	var expected_drops: Array[StringName] = []
	for serial in 5000:
		var candidate_id := StringName("m5:enemy:%d" % serial)
		var drops: Array[StringName] = LootRollsRuntime.drops_for(level.director.seed, candidate_id, definition.id)
		if not drops.is_empty():
			chosen_spawn_id = candidate_id
			expected_drops = drops
			break
	if chosen_spawn_id.is_empty():
		await _dispose(level)
		return "Could not find deterministic drop fixture within bounded search."
	var descriptor := EnemySpawnRuntime.new(
		chosen_spawn_id, GameConfig.ENEMY_CATALOG_VERSION, level.director.seed, definition.id,
		0, 1, &"anchor:m5", &"surface:m5", &"tile:m5", 0, 0, definition.biome, 0,
		definition.tier, &"right", -2, 3, &"default"
	)
	var enemy := EnemyControllerRuntime.new()
	if not enemy.configure(definition, descriptor, level.player, level.director, level.camera, level.enemy_spawner):
		enemy.free()
		await _dispose(level)
		return "M5a melee enemy configuration failed."
	enemy.position = level.player.position + Vector2(48, 0)
	level.enemy_spawner.add_child(enemy)
	enemy.died.connect(level.enemy_spawner._on_enemy_died)
	var initial_health := enemy.health
	level.player.melee_proximity.emit(enemy)
	var first_hit_ok := is_equal_approx(enemy.health, initial_health - float(level.profile.melee_power))
	level.player.melee_proximity.emit(enemy)
	var cadence_block_ok := is_equal_approx(enemy.health, initial_health - float(level.profile.melee_power))
	level.director.advance_simulation(GameConfig.PLAYER_MELEE_INTERVAL)
	level.player.melee_proximity.emit(enemy)
	var second_hit_ok := is_equal_approx(enemy.health, initial_health - 2.0 * float(level.profile.melee_power))
	level.profile.set_melee_power(GameConfig.MAX_MELEE_POWER)
	level.director.advance_simulation(GameConfig.PLAYER_MELEE_INTERVAL)
	level.player.melee_proximity.emit(enemy)
	var death_ok := enemy.dead
	var drops_ok := level.collectible_spawner.drop_ids.size() == expected_drops.size() and not expected_drops.is_empty()
	for drop_id in level.collectible_spawner.drop_ids.keys():
		var pickup = level.collectible_spawner.active.get(drop_id)
		drops_ok = drops_ok and pickup != null and pickup.is_drop and expected_drops.has(pickup.definition.id)
	var active_drop_keys := level.collectible_spawner.drop_ids.keys()
	level.profile.set_melee_power(GameConfig.DEFAULT_MELEE_POWER)
	await _dispose(level)
	return "" if first_hit_ok and cadence_block_ok and second_hit_ok and death_ok and drops_ok else "M5a melee first=%s block=%s second=%s death=%s drops=%s expected=%s active=%s." % [first_hit_ok, cadence_block_ok, second_hit_ok, death_ok, drops_ok, expected_drops, active_drop_keys]

func _reset_m5_weapon_profile(profile: ProfileState) -> void:
	profile.abilities.unlocked.clear()
	profile.abilities.equipped.clear()
	profile.ability_levels.clear()
	profile.ability_cooldowns.clear()
	profile.initialize_ability_progress(AbilityEligibility.JUMP)
	profile.abilities.equip(AbilityEligibility.JUMP)
	profile.weapons.unlocked.clear()
	profile.weapons.equipped.clear()

func test_m5b_shooting_unlock_visibility_and_cadence() -> String:
	var level := _make_level()
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.enemy_spawner.set_physics_process(false)
	level.weapon_controller.set_physics_process(false)
	_reset_m5_weapon_profile(level.profile)
	level.weapon_controller.configure(level.player, level.enemy_spawner, level.director, level.profile, level.camera)
	var locked_blocked := not level.weapon_controller.activate_shooting()
	level.profile.abilities.unlock(AbilityEligibility.SHOOTING)
	var unequipped_blocked := not level.weapon_controller.activate_shooting()
	var shooting_equipped := level.profile.abilities.equip(AbilityEligibility.SHOOTING)
	level.profile.weapons.unlock(&"arrow")
	var weapon_equipped := level.profile.weapons.equip(&"arrow")
	var activated := level.weapon_controller.activate_shooting()
	var fired: Array[StringName] = []
	level.weapon_controller.weapon_fired.connect(func(weapon_id: StringName, _directions: Array[Vector2]) -> void: fired.append(weapon_id))
	level.weapon_controller._physics_process(0.0)
	var no_target_ok := fired.is_empty() and level.weapon_controller.active_projectiles.is_empty()
	var archer: EnemyDefinitionRuntime = null
	for definition: EnemyDefinitionRuntime in EnemyCatalogRuntime.definitions():
		if definition.id == &"archer_guy":
			archer = definition
			break
	var enemy := _m4_runtime_enemy(level, archer, 81, Vector2(120, 0))
	if enemy == null:
		_reset_m5_weapon_profile(level.profile)
		await _dispose(level)
		return "M5b could not build visible enemy fixture."
	level.enemy_spawner.active[enemy.descriptor.id] = enemy
	level.weapon_controller._physics_process(0.0)
	var first_fire_ok := fired == [&"arrow"] and level.weapon_controller.active_projectiles.size() == 1
	level.weapon_controller._physics_process(0.0)
	var same_time_blocked := fired.size() == 1
	level.director.advance_simulation(0.79)
	level.weapon_controller._physics_process(0.0)
	var early_blocked := fired.size() == 1
	level.director.advance_simulation(0.01)
	level.weapon_controller._physics_process(0.0)
	var cadence_ok := fired.size() == 2
	level.director.begin_countdown(level.director.now())
	level.weapon_controller._physics_process(0.0)
	var pause_ok := fired.size() == 2
	_reset_m5_weapon_profile(level.profile)
	await _dispose(level)
	return "" if locked_blocked and unequipped_blocked and shooting_equipped and weapon_equipped and activated and no_target_ok and first_fire_ok and same_time_blocked and early_blocked and cadence_ok and pause_ok else "M5b shooting gates locked=%s unequipped=%s ability=%s weapon=%s active=%s none=%s first=%s same=%s early=%s cadence=%s pause=%s fired=%s." % [locked_blocked, unequipped_blocked, shooting_equipped, weapon_equipped, activated, no_target_ok, first_fire_ok, same_time_blocked, early_blocked, cadence_ok, pause_ok, fired]

func test_m5b_multitarget_and_projectile_trajectories() -> String:
	var level := _make_level()
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.enemy_spawner.set_physics_process(false)
	level.weapon_controller.set_physics_process(false)
	_reset_m5_weapon_profile(level.profile)
	level.profile.abilities.unlock(AbilityEligibility.SHOOTING)
	level.profile.abilities.equip(AbilityEligibility.SHOOTING)
	level.profile.weapons.unlock(&"triple_mage")
	level.profile.weapons.equip(&"triple_mage")
	level.weapon_controller.configure(level.player, level.enemy_spawner, level.director, level.profile, level.camera)
	var archer: EnemyDefinitionRuntime = null
	for definition: EnemyDefinitionRuntime in EnemyCatalogRuntime.definitions():
		if definition.id == &"archer_guy":
			archer = definition
			break
	var offsets: Array[Vector2] = [Vector2(150, -80), Vector2(180, 0), Vector2(160, 80)]
	var enemies: Array[EnemyControllerRuntime] = []
	for index in offsets.size():
		var enemy := _m4_runtime_enemy(level, archer, 90 + index, offsets[index])
		if enemy != null:
			enemies.append(enemy)
			level.enemy_spawner.active[enemy.descriptor.id] = enemy
	var fired_directions: Array[Vector2] = []
	level.weapon_controller.weapon_fired.connect(func(_weapon_id: StringName, directions: Array[Vector2]) -> void: fired_directions.assign(directions))
	var activated := level.weapon_controller.activate_shooting()
	level.weapon_controller._physics_process(0.0)
	var direction_keys: Dictionary = {}
	for direction in fired_directions:
		direction_keys["%.4f,%.4f" % [direction.x, direction.y]] = true
	var multi_ok := activated and enemies.size() == 3 and fired_directions.size() == 3 and direction_keys.size() == 3 and level.weapon_controller.active_projectiles.size() == 3
	for projectile_variant in level.weapon_controller.active_projectiles.values():
		(projectile_variant as WeaponProjectileRuntime).set_physics_process(false)
	await physics_frame
	# Use a fourth collision body that is deliberately absent from the targeting
	# registry, so the multi-target volley cannot affect this sweep fixture.
	var straight_target := _m4_runtime_enemy(level, archer, 99, Vector2(300, 0))
	await physics_frame
	var straight_ok := false
	if straight_target != null:
		var arrow = WeaponCatalogRuntime.by_id(&"arrow")
		var projectile := WeaponProjectileRuntime.new()
		var origin := straight_target.global_position - Vector2(100, 0)
		if projectile.configure(arrow, origin, Vector2.RIGHT, level.director):
			level.add_child(projectile)
			projectile.set_physics_process(false)
			var health_before := straight_target.health
			projectile._physics_process(0.20)
			straight_ok = projectile._finished and straight_target.health < health_before
	var arc = WeaponCatalogRuntime.by_id(&"mage_arc")
	var ballistic := WeaponProjectileRuntime.new()
	var ballistic_configured := ballistic.configure(arc, level.player.global_position, Vector2(1.0, -0.25), level.director)
	level.add_child(ballistic)
	ballistic.set_physics_process(false)
	var paused_position := ballistic.global_position
	var paused_lifetime := ballistic.remaining_seconds
	level.director.begin_countdown(level.director.now())
	ballistic._physics_process(0.10)
	var ballistic_pause_ok := ballistic.global_position == paused_position and is_equal_approx(ballistic.remaining_seconds, paused_lifetime)
	level.director.state = Director.State.RUNNING
	var vy_before := ballistic.velocity.y
	ballistic._physics_process(0.10)
	var ballistic_motion_ok := ballistic_configured and ballistic.velocity.y > vy_before and ballistic.global_position != paused_position
	var active_projectile_count: int = level.weapon_controller.active_projectiles.size()
	_reset_m5_weapon_profile(level.profile)
	await _dispose(level)
	return "" if multi_ok and straight_ok and ballistic_pause_ok and ballistic_motion_ok else "M5b multi=%s straight=%s ballistic_pause=%s ballistic_motion=%s dirs=%s projectiles=%d." % [multi_ok, straight_ok, ballistic_pause_ok, ballistic_motion_ok, fired_directions, active_projectile_count]

func test_m6a_level_desktop_mobile_ability_slot_routing() -> String:
	var level := _make_level()
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.enemy_spawner.set_physics_process(false)
	level.collectible_spawner.set_physics_process(false)
	level.weapon_controller.set_physics_process(false)
	var profile := level.profile
	profile.abilities.unlocked.clear()
	profile.abilities.equipped.clear()
	profile.ability_levels.clear()
	profile.ability_cooldowns.clear()
	profile.initialize_ability_progress(&"jump")
	profile.abilities.equip(&"jump")
	var dash_ok := ProfileCommands.unlock_and_equip_ability(profile, &"dash")
	var shooting_ok := ProfileCommands.unlock_and_equip_ability(profile, &"shooting")
	var routed: Array[StringName] = []
	level.ability_activation_requested.connect(func(_slot: int, ability_id: StringName) -> void: routed.append(ability_id))
	var direct_dash := level.request_ability_slot(0) == &"dash"
	var direct_shooting := level.request_ability_slot(1) == &"shooting"
	var no_third := level.request_ability_slot(2).is_empty()
	var desktop := InputEventAction.new()
	desktop.action = ActionDispatch.desktop_ability_input(0)
	desktop.pressed = true
	level._unhandled_input(desktop)
	var mobile := InputEventAction.new()
	mobile.action = ActionDispatch.mobile_ability_input(1)
	mobile.pressed = true
	level._unhandled_input(mobile)
	var input_ok := routed == [&"dash", &"shooting", &"dash", &"shooting"]
	level.director.begin_countdown(level.director.now())
	var paused_blocked := level.request_ability_slot(0).is_empty()
	profile.abilities.unlocked.clear()
	profile.abilities.equipped.clear()
	profile.ability_levels.clear()
	profile.ability_cooldowns.clear()
	profile.initialize_ability_progress(&"jump")
	await _dispose(level)
	return "" if dash_ok and shooting_ok and direct_dash and direct_shooting and no_third and input_ok and paused_blocked else "M6a route dash=%s shooting=%s direct=%s/%s third=%s input=%s paused=%s routed=%s." % [dash_ok, shooting_ok, direct_dash, direct_shooting, no_third, input_ok, paused_blocked, routed]

func _m6_reset_abilities(profile: ProfileState) -> void:
	profile.abilities.unlocked.clear()
	profile.abilities.equipped.clear()
	profile.ability_levels.clear()
	profile.ability_cooldowns.clear()
	profile.initialize_ability_progress(&"jump")
	profile.abilities.equip(&"jump")

func _m6_wait_grounded(player: PlayerController, limit: int = 180) -> bool:
	for _index in limit:
		if player.is_on_floor():
			return true
		await physics_frame
	return player.is_on_floor()

func test_m6b_jump_levels_and_fly() -> String:
	var level := _make_level()
	await _frames(10)
	_m6_reset_abilities(level.profile)
	var grounded := await _m6_wait_grounded(level.player)
	level.profile.set_ability_level(&"jump", 1)
	var single_first := level.player.request_jump()
	await _frames(2)
	var single_blocked := not level.player.request_jump()
	var landed_one := await _m6_wait_grounded(level.player)
	level.profile.set_ability_level(&"jump", 3)
	var triple_first := level.player.request_jump()
	await _frames(2)
	var triple_second := level.player.request_jump()
	await physics_frame
	var triple_third := level.player.request_jump()
	var triple_blocked := not level.player.request_jump()
	var landed_three := await _m6_wait_grounded(level.player)
	var reset_ok := level.player.jumps_since_contact == 0
	var fly_unlocked := ProfileCommands.unlock_and_equip_ability(level.profile, &"fly")
	var fly_hits := 0
	for _index in 5:
		if level.player.request_jump():
			fly_hits += 1
	var fly_ok := fly_unlocked and fly_hits == 5
	_m6_reset_abilities(level.profile)
	await _dispose(level)
	return "" if grounded and single_first and single_blocked and landed_one and triple_first and triple_second and triple_third and triple_blocked and landed_three and reset_ok and fly_ok else "M6b jump grounded=%s single=%s/%s landed=%s triple=%s/%s/%s block=%s landed3=%s reset=%s fly=%s(%d)." % [grounded, single_first, single_blocked, landed_one, triple_first, triple_second, triple_third, triple_blocked, landed_three, reset_ok, fly_ok, fly_hits]

func test_m6b_climb_wall_jumps_and_glide() -> String:
	var level := _make_level()
	await _frames(10)
	_m6_reset_abilities(level.profile)
	var climb_unlocked := ProfileCommands.unlock_and_equip_ability(level.profile, &"climb")
	var climb_level := level.profile.set_ability_level(&"climb", 2)
	var glide_unlocked := ProfileCommands.unlock_and_equip_ability(level.profile, &"glide")
	var grounded := await _m6_wait_grounded(level.player)
	var wall := _wall(level, level.player.global_position + Vector2(50.0, -20.0))
	((wall.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size = Vector2(20, 220)
	var ground_jump := level.player.request_jump()
	for _index in 12:
		await physics_frame
		if level.player._touching_wall_on_right():
			break
	var touching := level.player._touching_wall_on_right()
	var wall_one := level.player.request_jump()
	await physics_frame
	var wall_two := level.player.request_jump()
	await physics_frame
	var wall_blocked := not level.player.request_jump()
	wall.queue_free()
	await physics_frame
	level.player.global_position += Vector2(0, -90)
	level.player.velocity.y = 180.0
	level.player.jump_held = true
	level.player.jump_hold_seconds = GameConfig.GLIDE_HOLD_THRESHOLD
	level.player.glide_seconds = 0.0
	level.player.set_physics_process(false)
	level.player._physics_process(0.10)
	var glide_started := level.player.glide_seconds > 0.0 and absf(level.player.velocity.y) < 0.01
	level.player.glide_seconds = GameConfig.MAX_GLIDE_DURATION
	level.player.velocity.y = 0.0
	level.player._physics_process(0.10)
	var glide_ended := level.player.velocity.y > 0.0
	level.player.jump_held = false
	_m6_reset_abilities(level.profile)
	await _dispose(level)
	return "" if climb_unlocked and climb_level and glide_unlocked and grounded and ground_jump and touching and wall_one and wall_two and wall_blocked and glide_started and glide_ended else "M6b climb=%s/%s glide_unlock=%s grounded=%s jump=%s touch=%s walls=%s/%s block=%s glide=%s/%s." % [climb_unlocked, climb_level, glide_unlocked, grounded, ground_jump, touching, wall_one, wall_two, wall_blocked, glide_started, glide_ended]

func test_m6b_reverse_gravity_fly_and_cooldown() -> String:
	var level := _make_level()
	await _frames(4)
	_m6_reset_abilities(level.profile)
	level.profile.abilities.unequip(&"jump")
	var reverse_ok := ProfileCommands.unlock_and_equip_ability(level.profile, &"reverse_gravity")
	var fly_ok := ProfileCommands.unlock_and_equip_ability(level.profile, &"fly")
	level.director.simulation_time = 0.0
	var first := level.player.request_jump()
	var first_toggle := first and level.player.gravity_sign < 0.0 and level.player.up_direction == Vector2.DOWN and level.player.reverse_gravity_toggles == 1
	var fly_during_cooldown := level.player.request_jump()
	var fly_direction_ok := fly_during_cooldown and level.player.reverse_gravity_toggles == 1 and level.player.velocity.y > 0.0
	var cooldown := level.profile.ability_cooldown(&"reverse_gravity")
	level.director.advance_simulation(cooldown - 0.01)
	var before_exact := level.player.request_jump()
	var still_one := before_exact and level.player.reverse_gravity_toggles == 1
	level.director.advance_simulation(0.01)
	var exact := level.player.request_jump()
	var exact_toggle := exact and level.player.reverse_gravity_toggles == 2 and level.player.gravity_sign > 0.0 and level.player.up_direction == Vector2.UP
	level.director.begin_countdown(level.director.now())
	var paused_blocked := not level.player.request_jump()
	var toggle_count := level.player.reverse_gravity_toggles
	_m6_reset_abilities(level.profile)
	await _dispose(level)
	return "" if reverse_ok and fly_ok and first_toggle and fly_direction_ok and still_one and exact_toggle and paused_blocked else "M6b reverse=%s fly=%s first=%s fly-cooldown=%s pre-exact=%s exact=%s paused=%s toggles=%d." % [reverse_ok, fly_ok, first_toggle, fly_direction_ok, still_one, exact_toggle, paused_blocked, toggle_count]

func test_m6b_dash_distance_speed_and_cooldown() -> String:
	var level := _make_level()
	await _frames(10)
	_m6_reset_abilities(level.profile)
	var dash_unlocked := ProfileCommands.unlock_and_equip_ability(level.profile, &"dash")
	var grounded := await _m6_wait_grounded(level.player)
	var start_x := level.player.global_position.x
	var activated_at: float = float(level.director.simulation_time)
	var started := level.player.request_dash()
	await physics_frame
	var first_delta := level.player.global_position.x - start_x
	var fast := first_delta > GameConfig.SPEED / 60.0 * 2.0
	for _index in 90:
		if not level.player.dashing:
			break
		await physics_frame
	var distance := level.player.global_position.x - start_x
	var exact_distance := absf(distance - GameConfig.DASH_TILES * GameConfig.TILE_SIZE) <= 1.5
	var immediate_blocked := not level.player.request_dash()
	var ready_at: float = activated_at + level.profile.ability_cooldown(&"dash")
	if level.director.simulation_time < ready_at:
		level.director.advance_simulation(ready_at - level.director.simulation_time)
	var exact_ready := level.player.request_dash()
	level.player.dashing = false
	level.player.dash_remaining_pixels = 0.0
	level.director.begin_countdown(level.director.now())
	var paused_blocked := not level.player.request_dash()
	_m6_reset_abilities(level.profile)
	await _dispose(level)
	return "" if dash_unlocked and grounded and started and fast and exact_distance and immediate_blocked and exact_ready and paused_blocked else "M6b dash unlock=%s ground=%s start=%s fast=%s delta=%.2f distance=%.2f exact=%s immediate=%s ready=%s paused=%s." % [dash_unlocked, grounded, started, fast, first_delta, distance, exact_distance, immediate_blocked, exact_ready, paused_blocked]

func test_m6c_slowdown_invisibility_enemy_runtime() -> String:
	var level := _make_level()
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.enemy_spawner.set_physics_process(false)
	_m6_reset_abilities(level.profile)
	var slow_unlocked: bool = ProfileCommands.unlock_and_equip_ability(level.profile, &"slow_down_time")
	var invis_unlocked: bool = ProfileCommands.unlock_and_equip_ability(level.profile, &"invisibility")
	level.enemy_spawner.configure(
		level.terrain_streamer,
		level.player,
		level.director,
		level.camera,
		level.profile.enemy_fire_interval_multiplier,
		func() -> bool: return not level.is_invisible(),
		level._current_enemy_interval_multiplier
	)
	var definitions := level.enemy_spawner.example_definitions()
	var ranged_definition: EnemyDefinitionRuntime = null
	for definition: EnemyDefinitionRuntime in definitions:
		if definition.id == &"example_patrol_ranged":
			ranged_definition = definition
			break
	if ranged_definition == null:
		await _dispose(level)
		return "M6c ranged fixture definition missing."
	var enemy := _m4_runtime_enemy(level, ranged_definition, 601, Vector2(96, 0))
	level.enemy_spawner.active[enemy.descriptor.id] = enemy
	var ranged_events: Array[int] = []
	enemy.ranged_attack.connect(func(_enemy, _kind) -> void: ranged_events.append(ranged_events.size()))
	level.director.simulation_time = 0.0
	var slow_started: bool = level.activate_ability(&"slow_down_time")
	var speed_slowed: bool = is_equal_approx(level.player.effective_movement_multiplier(), GameConfig.MIN_SLOWDOWN_SPEED_MULTIPLIER)
	var interval_multiplier: float = level.enemy_spawner._current_interval_multiplier()
	var interval_slowed: bool = is_equal_approx(interval_multiplier, GameConfig.DEFAULT_ENEMY_FIRE_RATE * GameConfig.SLOW_DOWN_ENEMY_INTERVAL_MULTIPLIER)
	enemy.policy.reset()
	enemy.policy.last_ranged_at = 0.0
	level.director.simulation_time = ranged_definition.ranged_interval
	level.enemy_spawner._physics_process(0.0)
	var delayed: bool = ranged_events.is_empty()
	level.director.simulation_time = ranged_definition.ranged_interval * interval_multiplier
	level.enemy_spawner._physics_process(0.0)
	var fired_at_slow_cadence: bool = ranged_events.size() == 1
	var invis_started: bool = level.activate_ability(&"invisibility")
	enemy.policy.reset()
	level.enemy_spawner._physics_process(0.0)
	var hidden_suppressed: bool = ranged_events.size() == 1 and not level.enemy_spawner._target_is_visible()
	level.director.simulation_time = level.invisibility_until
	enemy.policy.reset()
	level.enemy_spawner._physics_process(0.0)
	var visible_again: bool = level.enemy_spawner._target_is_visible() and ranged_events.size() == 2
	_m6_reset_abilities(level.profile)
	await _dispose(level)
	return "" if slow_unlocked and invis_unlocked and slow_started and speed_slowed and interval_slowed and delayed and fired_at_slow_cadence and invis_started and hidden_suppressed and visible_again else "M6c slow/invis unlock=%s/%s start=%s speed=%s interval=%s delayed=%s fired=%s invis=%s hidden=%s visible=%s events=%d." % [slow_unlocked, invis_unlocked, slow_started, speed_slowed, interval_slowed, delayed, fired_at_slow_cadence, invis_started, hidden_suppressed, visible_again, ranged_events.size()]

func test_m6c_explode_enemy_damage_tile_break_and_cooldown() -> String:
	var level := _make_production_level(618)
	await physics_frame
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	_m6_reset_abilities(level.profile)
	var explode_unlocked: bool = ProfileCommands.unlock_and_equip_ability(level.profile, &"explode")
	var definitions := level.enemy_spawner.example_definitions()
	var melee_definition: EnemyDefinitionRuntime = null
	for definition: EnemyDefinitionRuntime in definitions:
		if definition.id == &"example_stationary_melee":
			melee_definition = definition
			break
	if melee_definition == null:
		await _dispose(level)
		return "M6c melee fixture definition missing."
	var enemy := _m4_runtime_enemy(level, melee_definition, 602, Vector2(64, 0))
	level.enemy_spawner.active[enemy.descriptor.id] = enemy
	var health_before: float = enemy.health
	var broken_before: int = level.terrain_streamer.broken_tile_ids.size()
	level.director.simulation_time = 0.0
	var first: bool = level.activate_ability(&"explode")
	var damage_ok: bool = enemy.dead or is_equal_approx(enemy.health, maxf(0.0, health_before - GameConfig.EXPLODE_DAMAGE))
	var broke_tiles: bool = level.terrain_streamer.broken_tile_ids.size() > broken_before
	var immediate_blocked: bool = not level.activate_ability(&"explode")
	var cooldown: float = level.profile.ability_cooldown(&"explode")
	level.director.simulation_time = cooldown - 0.01
	var early_blocked: bool = not level.activate_ability(&"explode")
	level.director.simulation_time = cooldown
	var exact_ready: bool = level.activate_ability(&"explode")
	var astro_untouched: bool = true
	for tile_variant in level.terrain_streamer.astro_tile_registry.keys():
		if level.terrain_streamer.is_tile_broken(StringName(tile_variant)):
			astro_untouched = false
			break
	var broken_count: int = level.terrain_streamer.broken_tile_ids.size()
	_m6_reset_abilities(level.profile)
	await _dispose(level)
	return "" if explode_unlocked and first and damage_ok and broke_tiles and immediate_blocked and early_blocked and exact_ready and astro_untouched else "M6c explode unlock=%s first=%s damage=%s tiles=%s immediate=%s early=%s exact=%s astro=%s broken=%d." % [explode_unlocked, first, damage_ok, broke_tiles, immediate_blocked, early_blocked, exact_ready, astro_untouched, broken_count]

func test_m6c_shooting_action_route_and_profile_cooldown() -> String:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate() as Level
	level.use_flat_fixture = true
	level.enemies_enabled = false
	level.collectibles_enabled = false
	level.weapons_enabled = true
	level.director = Director.new(GameClock.ManualClock.new())
	root.add_child(level)
	await physics_frame
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.weapon_controller.set_physics_process(false)
	_m6_reset_abilities(level.profile)
	var shooting_unlocked: bool = ProfileCommands.unlock_and_equip_ability(level.profile, AbilityEligibility.SHOOTING)
	var cooldown_set: bool = level.profile.set_ability_cooldown(AbilityEligibility.SHOOTING, GameConfig.MIN_ABILITY_COOLDOWN)
	level.profile.weapons.unlock(&"arrow")
	var weapon_equipped: bool = level.profile.weapons.equip(&"arrow")
	level.director.simulation_time = 0.0
	var routed_first: bool = level.request_ability_slot(0) == AbilityEligibility.SHOOTING
	var first_active: bool = level.weapon_controller.timing.is_active
	level.weapon_controller.deactivate_shooting()
	level.director.simulation_time = GameConfig.MIN_ABILITY_COOLDOWN - 0.01
	var routed_early: bool = level.request_ability_slot(0) == AbilityEligibility.SHOOTING
	var early_blocked: bool = not level.weapon_controller.timing.is_active
	level.director.simulation_time = GameConfig.MIN_ABILITY_COOLDOWN
	var routed_exact: bool = level.request_ability_slot(0) == AbilityEligibility.SHOOTING
	var exact_active: bool = level.weapon_controller.timing.is_active
	level.weapon_controller.deactivate_shooting()
	level.director.begin_countdown(level.director.now())
	var paused_blocked: bool = level.request_ability_slot(0).is_empty() and not level.weapon_controller.timing.is_active
	_m6_reset_abilities(level.profile)
	await _dispose(level)
	return "" if shooting_unlocked and cooldown_set and weapon_equipped and routed_first and first_active and routed_early and early_blocked and routed_exact and exact_active and paused_blocked else "M6c shooting unlock=%s cooldown=%s weapon=%s route=%s/%s/%s active=%s early=%s exact=%s paused=%s." % [shooting_unlocked, cooldown_set, weapon_equipped, routed_first, routed_early, routed_exact, first_active, early_blocked, exact_active, paused_blocked]

func test_m8_main_menu_shop_and_screen_entry_points() -> String:
	var session = root.get_node("RunSession")
	session.profile.gold = 1000
	change_scene_to_file("res://scenes/main_menu.tscn")
	var menu := await _wait_for_scene("res://scripts/main_menu.gd") as MainMenu
	if menu == null:
		return "M8 main menu did not load."
	var grid := menu.get_node_or_null("Center/Panel/Content/MenuGrid") as GridContainer
	var entry_points_ok: bool = grid != null
	for button_name in ["Characters", "Stats", "Abilities", "Weapons", "Settings", "BuyPotion"]:
		entry_points_ok = entry_points_ok and grid.get_node_or_null(button_name) is Button
	var before_gold: int = session.profile.gold
	var before_potions: int = session.profile.revival_potions
	(grid.get_node("BuyPotion") as Button).emit_signal("pressed")
	await process_frame
	var transaction_ok: bool = session.profile.gold == before_gold - GameConfig.REVIVAL_POTION_GOLDS and session.profile.revival_potions == before_potions + 1
	var summary := menu.get_node("Center/Panel/Content/ProfileRow/ProfileSummary") as Label
	var summary_ok: bool = str(session.profile.gold) in summary.text and str(session.profile.revival_potions) in summary.text
	(grid.get_node("Characters") as Button).emit_signal("pressed")
	var characters := await _wait_for_scene("res://scripts/ui/progression_screen.gd", 30, menu) as Control
	var navigation_ok: bool = characters != null and characters.get("mode") == "characters" and characters.find_child("Back", true, false) is Button
	if characters != null:
		(characters.find_child("Back", true, false) as Button).emit_signal("pressed")
	var returned := await _wait_for_scene("res://scripts/main_menu.gd", 30, characters) as MainMenu
	navigation_ok = navigation_ok and returned != null
	return "" if entry_points_ok and transaction_ok and summary_ok and navigation_ok else "M8 main menu entry=%s transaction=%s summary=%s navigation=%s." % [entry_points_ok, transaction_ok, summary_ok, navigation_ok]

func test_m8_progression_screens_transactions_and_descriptions() -> String:
	var session = root.get_node("RunSession")
	var profile: ProfileState = session.profile
	profile.gold = 20000
	var scenes := {
		&"characters": "res://scenes/character_screen.tscn",
		&"stats": "res://scenes/stats_screen.tscn",
		&"abilities": "res://scenes/abilities_screen.tscn",
		&"weapons": "res://scenes/weapons_screen.tscn",
		&"settings": "res://scenes/settings_screen.tscn",
	}
	var all_load := true
	for path_variant in scenes.values():
		var screen := (load(String(path_variant)) as PackedScene).instantiate() as Control
		root.add_child(screen)
		await process_frame
		all_load = all_load and screen.find_child("Content", true, false) is VBoxContainer and screen.find_child("Back", true, false) is Button
		await _dispose(screen)

	var characters := (load(String(scenes[&"characters"])) as PackedScene).instantiate() as Control
	root.add_child(characters)
	await process_frame
	var character_row := characters.find_child("Character2", true, false) as HBoxContainer
	var char_button := character_row.get_child(character_row.get_child_count() - 1) as Button
	char_button.emit_signal("pressed")
	await process_frame
	var character_ok: bool = profile.unlocked_characters.get(&"2", false)
	await _dispose(characters)

	var stats := (load(String(scenes[&"stats"])) as PackedScene).instantiate() as Control
	root.add_child(stats)
	await process_frame
	var health_before: int = profile.maximum_health
	var stat_row := stats.find_child("MaximumHealth", true, false) as HBoxContainer
	(stat_row.get_child(stat_row.get_child_count() - 1) as Button).emit_signal("pressed")
	await process_frame
	var stat_ok: bool = profile.maximum_health == health_before + GameConfig.MAXIMUM_HEALTH_UPGRADE
	await _dispose(stats)

	var abilities := (load(String(scenes[&"abilities"])) as PackedScene).instantiate() as Control
	root.add_child(abilities)
	await process_frame
	var dash_row := abilities.find_child("Dash", true, false) as HBoxContainer
	(dash_row.get_child(dash_row.get_child_count() - 1) as Button).emit_signal("pressed")
	await process_frame
	dash_row = abilities.find_child("Dash", true, false) as HBoxContainer
	var dash_equip := dash_row.get_child(1) as Button
	dash_equip.emit_signal("pressed")
	await process_frame
	var ability_ok: bool = profile.abilities.unlocked.get(&"dash", false) and &"dash" in profile.abilities.equipped
	await _dispose(abilities)

	if not profile.abilities.unlocked.get(AbilityEligibility.SHOOTING, false):
		ProfileShopRuntime.purchase_ability(profile, AbilityEligibility.SHOOTING)
	var weapons := (load(String(scenes[&"weapons"])) as PackedScene).instantiate() as Control
	root.add_child(weapons)
	await process_frame
	var arrow_row := weapons.find_child("Arrow", true, false) as HBoxContainer
	var description := (arrow_row.get_child(0) as Label).text
	var description_ok: bool = "Damage" in description and "Trajectory" in description and "Aim" in description and "Targets" in description
	(arrow_row.get_child(arrow_row.get_child_count() - 1) as Button).emit_signal("pressed")
	await process_frame
	arrow_row = weapons.find_child("Arrow", true, false) as HBoxContainer
	(arrow_row.get_child(1) as Button).emit_signal("pressed")
	await process_frame
	var weapon_ok: bool = profile.weapons.unlocked.get(&"arrow", false) and &"arrow" in profile.weapons.equipped
	await _dispose(weapons)

	var settings := (load(String(scenes[&"settings"])) as PackedScene).instantiate() as Control
	root.add_child(settings)
	await process_frame
	var settings_row := settings.find_child("Mobileabilitybuttons", true, false) as HBoxContainer
	var right_button := settings_row.get_child(settings_row.get_child_count() - 1) as Button
	if profile.mobile_auxiliary_button_corner == &"bottom_right":
		var left_button := settings_row.get_child(settings_row.get_child_count() - 2) as Button
		left_button.emit_signal("pressed")
	else:
		right_button.emit_signal("pressed")
	await process_frame
	var settings_ok: bool = profile.mobile_auxiliary_button_corner in [&"bottom_left", &"bottom_right"] and profile.mobile_auxiliary_button_corner != GameConfig.MOBILE_AUXILIARY_BUTTON_CORNER_DEFAULT
	await _dispose(settings)
	return "" if all_load and character_ok and stat_ok and ability_ok and description_ok and weapon_ok and settings_ok else "M8 screens load=%s character=%s stat=%s ability=%s description=%s weapon=%s settings=%s." % [all_load, character_ok, stat_ok, ability_ok, description_ok, weapon_ok, settings_ok]

func test_m9_touch_gestures_buttons_and_parity() -> String:
	var session = root.get_node("RunSession")
	var profile: ProfileState = session.profile
	profile.gold = 5000
	ProfileShopRuntime.purchase_ability(profile, &"dash")
	ProfileShopRuntime.set_ability_equipped(profile, &"dash", true)
	ProfileShopRuntime.purchase_ability(profile, AbilityEligibility.SHOOTING)
	ProfileShopRuntime.set_ability_equipped(profile, AbilityEligibility.SHOOTING, true)
	var level := _make_level()
	await _frames(5)
	var router = level.get_node("CanvasLayer/TouchGestureRouter") as TouchGestureRouterRuntime
	var jump_before := level.player.jump_consumptions
	var tap_down := InputEventScreenTouch.new()
	tap_down.index = 0
	tap_down.position = Vector2(700, 300)
	tap_down.pressed = true
	router.handle_touch(tap_down)
	var tap_up := InputEventScreenTouch.new()
	tap_up.index = 0
	tap_up.position = Vector2(704, 306)
	tap_up.pressed = false
	router.handle_touch(tap_up)
	await physics_frame
	var tap_ok: bool = level.player.jump_consumptions == jump_before + 1

	var roll_before := level.player.roll_consumptions
	var swipe_down := InputEventScreenTouch.new()
	swipe_down.index = 0
	swipe_down.position = Vector2(650, 260)
	swipe_down.pressed = true
	router.handle_touch(swipe_down)
	var swipe_drag := InputEventScreenDrag.new()
	swipe_drag.index = 0
	swipe_drag.position = Vector2(660, 360)
	router.handle_drag(swipe_drag)
	var swipe_up := InputEventScreenTouch.new()
	swipe_up.index = 0
	swipe_up.position = Vector2(660, 360)
	swipe_up.pressed = false
	router.handle_touch(swipe_up)
	await physics_frame
	var swipe_ok: bool = level.player.roll_consumptions == roll_before + 1

	var blocked_before := level.player.jump_consumptions
	var restart := level.get_node("CanvasLayer/Restart") as Button
	var ui_point := restart.get_global_rect().get_center()
	var ui_down := InputEventScreenTouch.new()
	ui_down.index = 0
	ui_down.position = ui_point
	ui_down.pressed = true
	router.handle_touch(ui_down)
	var ui_up := InputEventScreenTouch.new()
	ui_up.index = 0
	ui_up.position = ui_point
	ui_up.pressed = false
	router.handle_touch(ui_up)
	await physics_frame
	var ui_blocked: bool = level.player.jump_consumptions == blocked_before

	var multi_before := level.player.jump_consumptions
	var first := InputEventScreenTouch.new()
	first.index = 0
	first.position = Vector2(700, 260)
	first.pressed = true
	router.handle_touch(first)
	var second := InputEventScreenTouch.new()
	second.index = 1
	second.position = Vector2(730, 260)
	second.pressed = true
	router.handle_touch(second)
	var first_up := InputEventScreenTouch.new()
	first_up.index = 0
	first_up.position = Vector2(700, 260)
	first_up.pressed = false
	router.handle_touch(first_up)
	var second_up := InputEventScreenTouch.new()
	second_up.index = 1
	second_up.position = Vector2(730, 260)
	second_up.pressed = false
	router.handle_touch(second_up)
	await physics_frame
	var multitouch_ok: bool = level.player.jump_consumptions == multi_before

	var cancel_before := level.player.jump_consumptions
	var cancel_down := InputEventScreenTouch.new()
	cancel_down.index = 0
	cancel_down.position = Vector2(700, 260)
	cancel_down.pressed = true
	router.handle_touch(cancel_down)
	router.cancel_active()
	var cancel_up := InputEventScreenTouch.new()
	cancel_up.index = 0
	cancel_up.position = Vector2(700, 260)
	cancel_up.pressed = false
	router.handle_touch(cancel_up)
	await physics_frame
	var cancel_ok: bool = level.player.jump_consumptions == cancel_before

	var right_ok: bool = is_equal_approx(level.mobile_buttons.anchor_left, 1.0)
	ProfileShopRuntime.set_mobile_auxiliary_button_corner(profile, &"bottom_left")
	await process_frame
	var left_ok: bool = is_zero_approx(level.mobile_buttons.anchor_left)
	var mobile_dash := level.mobile_buttons.find_child("MobileAbility1", true, false) as Button
	var routed := [0]
	level.ability_activation_requested.connect(func(_slot: int, _ability: StringName) -> void: routed[0] += 1)
	mobile_dash.emit_signal("pressed")
	await physics_frame
	await process_frame
	var parity_ok: bool = routed[0] == 1 and level.player.dashing and mobile_dash.disabled
	var result := "" if tap_ok and swipe_ok and ui_blocked and multitouch_ok and cancel_ok and right_ok and left_ok and parity_ok else "M9 tap=%s swipe=%s ui=%s multi=%s cancel=%s right=%s left=%s parity=%s routed=%s dashing=%s disabled=%s text=%s." % [tap_ok, swipe_ok, ui_blocked, multitouch_ok, cancel_ok, right_ok, left_ok, parity_ok, routed[0], level.player.dashing, mobile_dash.disabled, mobile_dash.text]
	await _dispose(level)
	return result

func test_m8_level_ability_map_and_revival_ui() -> String:
	var session = root.get_node("RunSession")
	var profile: ProfileState = session.profile
	profile.gold = 5000
	ProfileShopRuntime.purchase_ability(profile, &"dash")
	ProfileShopRuntime.set_ability_equipped(profile, &"dash", true)
	ProfileShopRuntime.purchase_ability(profile, AbilityEligibility.SHOOTING)
	ProfileShopRuntime.set_ability_equipped(profile, AbilityEligibility.SHOOTING, true)
	profile.set_revival_potions(1)
	var level := _make_level()
	await _frames(3)
	var slot1 := level.ability_map.find_child("AbilitySlot1", true, false) as Label
	var slot2 := level.ability_map.find_child("AbilitySlot2", true, false) as Label
	var mapping_ok: bool = slot1 != null and slot2 != null and "Dash" in slot1.text and "Shooting" in slot2.text
	# Keep the Level's validated flat-fixture checkpoint; the player is still
	# settling toward the floor during this short HUD setup window.
	level.director.fail_fall(level.director.now())
	await physics_frame
	var countdown_ui: bool = level.revive_button.visible and not level.revive_button.disabled and "REVIVE" in level.state_overlay.text and "x1" in level.revive_button.text
	level.revive_button.emit_signal("pressed")
	await physics_frame
	var revived_ui: bool = level.director.state == Director.State.RUNNING and profile.revival_potions == 0 and not level.revive_button.visible
	var result := "" if mapping_ok and countdown_ui and revived_ui else "M8 ability map=%s countdown=%s revived=%s state=%s potions=%s visible=%s." % [mapping_ok, countdown_ui, revived_ui, level.director.state, profile.revival_potions, level.revive_button.visible]
	await _dispose(level)
	return result

func test_m7_run_session_autosave_reload() -> String:
	var session = root.get_node("RunSession")
	var previous_path: String = session.save_path
	var previous_autosave: bool = session.autosave_enabled
	var previous_profile: ProfileState = session.profile
	var path := "user://m7_session_autosave_test.json"
	var absolute := ProjectSettings.globalize_path(path)
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(absolute + suffix):
			DirAccess.remove_absolute(absolute + suffix)
	session.save_path = path
	session.autosave_enabled = true
	var profile := ProfileState.new()
	if not session.replace_profile(profile):
		session.save_path = previous_path
		session.autosave_enabled = previous_autosave
		return "M7 autosave fixture profile replacement failed."
	profile.add_gold(345)
	profile.set_revival_potions(2)
	var wrote: bool = FileAccess.file_exists(absolute)
	profile.gold = 0
	profile.revival_potions = 0
	var reloaded: bool = session.reload_profile() and session.profile.gold == 345 and session.profile.revival_potions == 2
	var transient_absent: bool = not ("health" in session.profile) and not ("distance_tiles" in session.profile)
	session.autosave_enabled = false
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(absolute + suffix):
			DirAccess.remove_absolute(absolute + suffix)
	session.save_path = previous_path
	session.replace_profile(previous_profile)
	session.autosave_enabled = previous_autosave
	return "" if wrote and reloaded and transient_absent else "M7 autosave wrote=%s reload=%s transient_absent=%s." % [wrote, reloaded, transient_absent]

func test_m7_profile_character_and_stats_apply_to_level() -> String:
	var session = root.get_node("RunSession")
	var previous_profile: ProfileState = session.profile
	var previous_autosave: bool = session.autosave_enabled
	session.autosave_enabled = false
	var profile := ProfileState.new()
	profile.maximum_health = 180
	profile.defense_multiplier = 0.65
	profile.unlocked_characters[&"2"] = true
	profile.selected_character = &"2"
	if not session.replace_profile(profile):
		session.autosave_enabled = previous_autosave
		return "M7 fixture profile replacement failed."
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate() as Level
	level.use_flat_fixture = true
	level.enemies_enabled = false
	level.collectibles_enabled = false
	level.weapons_enabled = false
	level.director = Director.new(GameClock.ManualClock.new())
	root.add_child(level)
	await physics_frame
	var owner: DamageStatus.HealthOwner = level.director.run.health_owner
	var stats_ok: bool = is_equal_approx(owner.maximum_health, 180.0) and is_equal_approx(owner.current_health, 180.0) and is_equal_approx(owner.defense_multiplier, 0.65)
	var character = CharacterCatalogRuntime.by_id(&"2")
	var sprite := level.player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var loaded_frames_path: String = sprite.sprite_frames.resource_path if sprite.sprite_frames != null else ""
	var frames_ok: bool = character != null and loaded_frames_path == character.sprite_frames_path
	var transient_fresh: bool = is_zero_approx(level.director.run.distance_tiles) and level.director.run.earned_gold == 0
	await _dispose(level)
	session.replace_profile(previous_profile)
	session.autosave_enabled = previous_autosave
	return "" if stats_ok and frames_ok and transient_fresh else "M7 run-start stats=%s frames=%s transient=%s path=%s." % [stats_ok, frames_ok, transient_fresh, loaded_frames_path]
