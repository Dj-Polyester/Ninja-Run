extends SceneTree
## Zero-dependency test harness. Each test returns an empty String on success.

const Harness = preload("res://scripts/core/foundation_test_harness.gd")
const Director = preload("res://scripts/models/run_director.gd")
const Palette = preload("res://scripts/terrain/terrain_palette.gd")
const HazardTiming = preload("res://scripts/models/hazard_timing.gd")
const HazardRuntime = preload("res://scripts/terrain/hazard_runtime.gd")
const HazardDescriptorModel = preload("res://scripts/terrain/hazard_descriptor.gd")
const AstroCoordinator = preload("res://scripts/terrain/astro_fall_coordinator.gd")
const EnemyEffect = preload("res://scripts/enemies/enemy_effect_spec.gd")
const EnemyDefinitionContract = preload("res://scripts/enemies/enemy_definition.gd")
const EnemySpawnContract = preload("res://scripts/enemies/enemy_spawn_descriptor.gd")
const EnemyAttackPolicyContract = preload("res://scripts/enemies/enemy_attack_policy.gd")
const EnemySpawnerRuntime = preload("res://scripts/enemies/enemy_spawner.gd")
const EnemyProjectileRuntime = preload("res://scripts/enemies/enemy_projectile.gd")
const EnemyAnimationLoaderRuntime = preload("res://scripts/enemies/enemy_animation_loader.gd")
const EnemyCatalogRuntime = preload("res://scripts/enemies/enemy_catalog.gd")
const CollectibleCatalogRuntime = preload("res://scripts/collectibles/collectible_catalog.gd")
const LootRollsRuntime = preload("res://scripts/models/loot_rolls.gd")
const WeaponCatalogRuntime = preload("res://scripts/weapons/weapon_catalog.gd")
const WeaponDefinitionRuntime = preload("res://scripts/weapons/weapon_definition.gd")
const WeaponTargetingPolicyRuntime = preload("res://scripts/weapons/weapon_targeting_policy.gd")
const WeaponControllerRuntime = preload("res://scripts/weapons/weapon_controller.gd")
const AbilityCatalogRuntime = preload("res://scripts/abilities/ability_catalog.gd")
const AbilityDefinitionRuntime = preload("res://scripts/abilities/ability_definition.gd")
const AbilityCooldownStateRuntime = preload("res://scripts/abilities/ability_cooldown_state.gd")
const AbilityActionRouterRuntime = preload("res://scripts/abilities/ability_action_router.gd")
const SaveServiceRuntime = preload("res://scripts/models/save_service.gd")
const ProfileShopRuntime = preload("res://scripts/models/profile_shop.gd")
const CharacterCatalogRuntime = preload("res://scripts/characters/character_catalog.gd")
const TouchGestureRouterRuntime = preload("res://scripts/ui/touch_gesture_router.gd")

const REQUIRED_ACTIONS: Array[StringName] = [
	&"jump", &"roll", &"touch_tap_jump", &"touch_swipe_roll",
]

var _passed := 0
var _harness = Harness.new()
const EXPECTED_TEST_COUNT := 76

func _init() -> void:
	var session := root.get_node_or_null("RunSession")
	if session != null and session.has_method("reset_profile_for_tests"):
		session.reset_profile_for_tests()
	ActionDispatch.ensure_input_actions(GameConfig.NUM_EQUIPABLE_ABILITIES)
	call_deferred("_run_suite")

func _run_suite() -> void:
	_run_test("test_main_scene_instantiates", test_main_scene_instantiates)
	_run_test("test_required_input_actions_exist", test_required_input_actions_exist)
	_run_test("test_config_defaults_validate", test_config_defaults_validate)
	_run_test("test_config_validation_rejects_bad_edits", test_config_validation_rejects_bad_edits)
	_run_test("test_enemy_config_boundary_validation", test_enemy_config_boundary_validation)
	_run_test("test_action_dispatch_unifies_devices", test_action_dispatch_unifies_devices)
	_run_test("test_project_input_bindings", test_project_input_bindings)
	_run_test("test_ability_eligibility_and_exclusion", test_ability_eligibility_and_exclusion)
	_run_test("test_damage_and_status_owner", test_damage_and_status_owner)
	_run_test("test_manual_clock_is_deterministic", test_manual_clock_is_deterministic)
	_run_test("test_equipment_invariants", test_equipment_invariants)
	_run_test("test_profile_commands_preserve_economy", test_profile_commands_preserve_economy)
	_run_test("test_profile_ability_command_respects_exclusion", test_profile_ability_command_respects_exclusion)
	_run_test("test_run_state_is_transient", test_run_state_is_transient)
	_run_test("test_revival_state_machine_boundaries", test_revival_state_machine_boundaries)
	_run_test("test_support_query_validates_before_potion_commit", test_support_query_validates_before_potion_commit)
	_run_test("test_revival_configuration_is_positive_finite", test_revival_configuration_is_positive_finite)
	_run_test("test_shooting_timing_contract", test_shooting_timing_contract)
	_run_test("test_main_menu_start_intent", test_main_menu_start_intent)
	_run_test("test_harness_self_checks", test_harness_self_checks)
	_run_test("test_terrain_same_seed_equality", test_terrain_same_seed_equality)
	_run_test("test_terrain_different_seed_variation", test_terrain_different_seed_variation)
	_run_test("test_terrain_order_independent_regeneration", test_terrain_order_independent_regeneration)
	_run_test("test_terrain_invalid_config_rejected", test_terrain_invalid_config_rejected)
	_run_test("test_terrain_all_form_kinds_present", test_terrain_all_form_kinds_present)
	_run_test("test_biome_exact_boundary_columns", test_biome_exact_boundary_columns)
	_run_test("test_biome_first_encounter_order", test_biome_first_encounter_order)
	_run_test("test_biome_seeded_random_variation", test_biome_seeded_random_variation)
	_run_test("test_biome_random_encounters_do_not_repeat", test_biome_random_encounters_do_not_repeat)
	_run_test("test_biome_negative_columns_are_grass", test_biome_negative_columns_are_grass)
	_run_test("test_biome_cross_boundary_chunk_metadata", test_biome_cross_boundary_chunk_metadata)
	_run_test("test_biome_regeneration_is_order_independent", test_biome_regeneration_is_order_independent)
	_run_test("test_movement_envelope_body_clearance_min_max", test_movement_envelope_body_clearance_min_max)
	_run_test("test_terrain_reachable_transitions_and_seams", test_terrain_reachable_transitions_and_seams)
	_run_test("test_terrain_stable_anchors", test_terrain_stable_anchors)
	_run_test("test_grass_atlas_rect_bounds_and_source", test_grass_atlas_rect_bounds_and_source)
	_run_test("test_six_biome_palette_rects_and_boundary_selection", test_six_biome_palette_rects_and_boundary_selection)
	_run_test("test_hazard_descriptors_are_deterministic_and_owned", test_hazard_descriptors_are_deterministic_and_owned)
	_run_test("test_snow_multiplier_stream_is_deterministic_and_bounded", test_snow_multiplier_stream_is_deterministic_and_bounded)
	_run_test("test_hazard_timing_phase_and_cadence_contract", test_hazard_timing_phase_and_cadence_contract)
	_run_test("test_hazard_runtime_assets_and_fort_transition_geometry", test_hazard_runtime_assets_and_fort_transition_geometry)
	_run_test("test_astro_fall_config_and_state_contract", test_astro_fall_config_and_state_contract)
	_run_test("test_astro_three_block_cascade_and_pause", test_astro_three_block_cascade_and_pause)
	_run_test("test_astro_order_epoch_and_non_astro_sweep", test_astro_order_epoch_and_non_astro_sweep)
	_run_test("test_astro_arm_direction_and_duplicate_contract", test_astro_arm_direction_and_duplicate_contract)
	_run_test("test_m4_hit_status_simulation_contract", test_m4_hit_status_simulation_contract)
	_run_test("test_m4_player_modifier_and_appearance_precedence", test_m4_player_modifier_and_appearance_precedence)
	_run_test("test_m4_enemy_contract_validation", test_m4_enemy_contract_validation)
	_run_test("test_m4_attack_policy_cadence_contract", test_m4_attack_policy_cadence_contract)
	_run_test("test_m4_status_capacity_and_refresh_contract", test_m4_status_capacity_and_refresh_contract)
	_run_test("test_m4a1_example_runtime_catalog_contract", test_m4a1_example_runtime_catalog_contract)
	_run_test("test_m4a1_projectile_configuration_contract", test_m4a1_projectile_configuration_contract)
	_run_test("test_m4a1_animation_cache_reference_contract", test_m4a1_animation_cache_reference_contract)
	_run_test("test_m4b_catalog_inventory_and_variants", test_m4b_catalog_inventory_and_variants)
	_run_test("test_m4b_biome_roster_tiers_and_effects", test_m4b_biome_roster_tiers_and_effects)
	_run_test("test_m4b_scaling_and_fire_interval_defaults", test_m4b_scaling_and_fire_interval_defaults)
	_run_test("test_m4b_biome_visit_tier_and_variant_selection", test_m4b_biome_visit_tier_and_variant_selection)
	_run_test("test_m5a_collectible_catalog_values_and_assets", test_m5a_collectible_catalog_values_and_assets)
	_run_test("test_m5a_deterministic_loot_probability_contract", test_m5a_deterministic_loot_probability_contract)
	_run_test("test_m5b_weapon_catalog_axes_and_assets", test_m5b_weapon_catalog_axes_and_assets)
	_run_test("test_m5b_targeting_policy_modes_and_multitarget", test_m5b_targeting_policy_modes_and_multitarget)
	_run_test("test_m5b_weapon_equipment_and_shooting_unlock_boundary", test_m5b_weapon_equipment_and_shooting_unlock_boundary)
	_run_test("test_m6a_ability_catalog_levels_and_triggers", test_m6a_ability_catalog_levels_and_triggers)
	_run_test("test_m6a_profile_ability_progress_contract", test_m6a_profile_ability_progress_contract)
	_run_test("test_m6a_cooldown_and_action_router_contract", test_m6a_cooldown_and_action_router_contract)
	_run_test("test_m6c_duration_stats_unlock_and_bounds", test_m6c_duration_stats_unlock_and_bounds)
	_run_test("test_m6c_dynamic_enemy_and_shooting_cooldown_bridge", test_m6c_dynamic_enemy_and_shooting_cooldown_bridge)
	_run_test("test_m7_character_catalog_assets_and_prices", test_m7_character_catalog_assets_and_prices)
	_run_test("test_m7_save_roundtrip_persistent_only", test_m7_save_roundtrip_persistent_only)
	_run_test("test_m7_save_migration_and_corrupt_recovery", test_m7_save_migration_and_corrupt_recovery)
	_run_test("test_m7_shop_purchase_atomicity_and_gates", test_m7_shop_purchase_atomicity_and_gates)
	_run_test("test_m7_stat_and_cooldown_upgrade_boundaries", test_m7_stat_and_cooldown_upgrade_boundaries)
	_run_test("test_m7_profile_stats_apply_to_new_run", test_m7_profile_stats_apply_to_new_run)
	_run_test("test_m8_profile_ui_command_boundaries", test_m8_profile_ui_command_boundaries)
	_run_test("test_m9_touch_gesture_classification", test_m9_touch_gesture_classification)
	_run_test("test_m10_enemy_placeholders_and_mobile_release_config", test_m10_enemy_placeholders_and_mobile_release_config)
	if _harness.scheduled != EXPECTED_TEST_COUNT:
		_harness.record_external_failure("Runner scheduled %d tests; expected %d." % [_harness.scheduled, EXPECTED_TEST_COUNT])
	for failure: String in _harness.failures:
		push_error("FAIL %s" % failure)
	print("RESULT: %d passed, %d failed (%d scheduled, %d executed)" % [_passed, _harness.failures.size(), _harness.scheduled, _harness.executed])
	quit(_harness.exit_code())

func _run_test(name: String, test: Callable) -> void:
	_harness.schedule()
	var failure: String = test.call()
	_harness.record(name, failure)
	if failure.is_empty():
		_passed += 1
		print("PASS %s" % name)

func _expect(condition: bool, description: String) -> String:
	return "" if condition else description

func test_main_scene_instantiates() -> String:
	var main_scene_path := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main_scene_path.is_empty():
		return "ProjectSettings has no configured main scene."
	var packed_scene := load(main_scene_path) as PackedScene
	if packed_scene == null:
		return "Main menu scene did not load."
	var menu := packed_scene.instantiate()
	if not menu is MainMenu:
		return "Configured main scene is not MainMenu."
	menu.free()
	return ""

func test_required_input_actions_exist() -> String:
	for action_name: StringName in REQUIRED_ACTIONS:
		var failure := _expect(InputMap.has_action(action_name), "Missing input action %s." % action_name)
		if not failure.is_empty():
			return failure
	for slot in GameConfig.NUM_EQUIPABLE_ABILITIES:
		if not InputMap.has_action(ActionDispatch.desktop_ability_input(slot)) or not InputMap.has_action(ActionDispatch.mobile_ability_input(slot)):
			return "Missing configured ability input action for slot %d." % slot
	return ""

func test_config_defaults_validate() -> String:
	var errors := GameConfig.validate_defaults()
	if not errors.is_empty():
		return "; ".join(errors)
	if GameConfig.NUM_EQUIPPABLE_WEAPONS <= 0 or GameConfig.NUM_EQUIPABLE_ABILITIES <= 0:
		return "Equip limits must be positive."
	return ""

func test_config_validation_rejects_bad_edits() -> String:
	if not GameConfig.validate_stat_definition(1.0, 2.0, 5.0, 1.0, 10, 1).is_empty():
		return "Valid alternate increasing stat was rejected."
	if not GameConfig.validate_cooldown_definition(6.0, 2.0, 12.0, -0.5, 175).is_empty():
		return "A valid edited cooldown was rejected."
	if GameConfig.validate_stat_definition(1.0, 2.0, 5.0, -1.0, 10, 1).is_empty():
		return "Wrong upgrade direction was accepted."
	if GameConfig.validate_stat_definition(1.0, INF, 5.0, 1.0, 10, 1).is_empty() or GameConfig.validate_stat_definition(1.0, 2.0, 5.0, 1.0, 0, 1).is_empty():
		return "Non-finite value or zero cost was accepted."
	if not GameConfig.validate_positive_finite(0.25, "fixture").is_empty() or GameConfig.validate_positive_finite(NAN, "fixture").is_empty() or GameConfig.validate_positive_finite(INF, "fixture").is_empty() or GameConfig.validate_positive_finite(0.0, "fixture").is_empty():
		return "Positive-finite default validator accepted an invalid parameter."
	return _expect(GameConfig.dash_speed_pixels_per_second() == GameConfig.DASH_SPEED * GameConfig.TILE_SIZE, "Dash tile-to-pixel conversion is invalid.")

func test_enemy_config_boundary_validation() -> String:
	if not GameConfig.validate_enemy_timing(5.0, 1.0).is_empty() or not GameConfig.validate_enemy_timing(2.5, 0.25).is_empty():
		return "Valid enemy timing was rejected."
	if GameConfig.validate_enemy_timing(0.0, 1.0).is_empty() or GameConfig.validate_enemy_timing(5.0, 0.0).is_empty() or GameConfig.validate_enemy_timing(INF, 1.0).is_empty():
		return "Invalid enemy timing was accepted."
	if not GameConfig.validate_drop_probability(0.0) or not GameConfig.validate_drop_probability(1.0):
		return "Probability boundaries were rejected."
	return _expect(not GameConfig.validate_drop_probability(-0.01) and not GameConfig.validate_drop_probability(1.01), "Out-of-range drop probability was accepted.")

func test_action_dispatch_unifies_devices() -> String:
	if ActionDispatch.from_input(&"jump") != ActionDispatch.Action.JUMP or ActionDispatch.from_input(&"touch_tap_jump") != ActionDispatch.Action.JUMP:
		return "Jump inputs do not share one semantic action."
	if ActionDispatch.from_input(&"roll") != ActionDispatch.from_input(&"touch_swipe_roll"):
		return "Roll inputs do not share one semantic action."
	ActionDispatch.ensure_input_actions(6)
	for slot in 6:
		if ActionDispatch.from_input(ActionDispatch.desktop_ability_input(slot)) != ActionDispatch.from_input(ActionDispatch.mobile_ability_input(slot)) or ActionDispatch.ability_slot_from_input(ActionDispatch.desktop_ability_input(slot)) != slot:
			return "Desktop/mobile ability parity failed for slot %d." % slot
	return _expect(ActionDispatch.ability_slot(ActionDispatch.Action.JUMP) == -1 and ActionDispatch.from_input(&"ability_invalid") == -1 and ActionDispatch.from_input(&"mobile_auxiliary_action_0") == -1, "Ability slot parsing accepted an unknown action.")

func test_project_input_bindings() -> String:
	if not _has_key_binding(&"jump", KEY_UP) or not _has_key_binding(&"roll", KEY_DOWN):
		return "Jump/Roll are not bound to Up/Down."
	for slot in GameConfig.NUM_EQUIPABLE_ABILITIES:
		var action := ActionDispatch.desktop_ability_input(slot)
		if not _has_key_binding(action, 49 + slot) or not InputMap.has_action(ActionDispatch.mobile_ability_input(slot)):
			return "Configured ability slot %d lacks desktop/mobile bindings." % slot
	return ""

func _has_key_binding(action_name: StringName, expected_keycode: int) -> bool:
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey and (event as InputEventKey).keycode == expected_keycode:
			return true
	return false

func test_ability_eligibility_and_exclusion() -> String:
	var unlocked := {AbilityEligibility.JUMP: true, AbilityEligibility.REVERSE_GRAVITY: true, &"dash": true}
	if AbilityEligibility.can_equip(&"locked", unlocked, [], 2):
		return "Locked ability can equip."
	if not AbilityEligibility.can_equip(AbilityEligibility.JUMP, unlocked, [], 2):
		return "Unlocked Jump cannot equip."
	if AbilityEligibility.can_equip(AbilityEligibility.REVERSE_GRAVITY, unlocked, [AbilityEligibility.JUMP], 2):
		return "Mutually exclusive abilities can equip together."
	if AbilityEligibility.can_equip(&"dash", unlocked, [], 0):
		return "Zero-capacity equipment accepted."
	if not AbilityEligibility.is_cooldown_exempt(&"fly") or AbilityEligibility.is_cooldown_exempt(&"dash"):
		return "Cooldown exemption set is invalid."
	return _expect(AbilityEligibility.cooldown_stat_is_available(&"dash", unlocked) and not AbilityEligibility.cooldown_stat_is_available(&"dash", {}), "Cooldown stat unlock gate is invalid.")

func test_damage_and_status_owner() -> String:
	var owner := DamageStatus.HealthOwner.new(100.0, 0.5)
	var dealt := owner.apply_damage(DamageStatus.DamageEvent.new(20.0, &"enemy"))
	if not is_equal_approx(dealt, 10.0) or not is_equal_approx(owner.current_health, 90.0):
		return "Defense-aware damage is invalid."
	owner.apply_status(DamageStatus.TimedStatus.new(&"freeze", 2.0, 10.0))
	if not owner.has_status(&"freeze", 11.9) or owner.has_status(&"freeze", 12.0):
		return "Timed status lifetime is invalid."
	owner.clear_expired_statuses(12.0)
	return _expect(owner.statuses.is_empty(), "Expired status remains owned by health recipient.")

func test_manual_clock_is_deterministic() -> String:
	var clock := GameClock.ManualClock.new()
	clock.advance(1.25)
	clock.advance(0.75)
	return _expect(is_equal_approx(clock.now_seconds(), 2.0), "Manual clock did not advance deterministically.")

func test_equipment_invariants() -> String:
	var equipment := EquipmentState.new(2)
	if equipment.equip(&"bow"):
		return "Locked item equipped."
	equipment.unlock(&"bow")
	equipment.unlock(&"axe")
	equipment.unlock(&"wand")
	if not equipment.equip(&"bow") or equipment.equip(&"bow") or not equipment.equip(&"axe") or equipment.equip(&"wand"):
		return "Equipment capacity or uniqueness failed."
	if not equipment.unequip(&"bow") or equipment.unequip(&"bow"):
		return "Unequip contract failed."
	return _expect(equipment.is_valid(), "Equipment invariant validator rejected valid state.")

func test_profile_commands_preserve_economy() -> String:
	var profile := ProfileState.new()
	var notifications := [0]
	profile.changed.connect(func() -> void: notifications[0] += 1)
	profile.gold = 100
	if ProfileCommands.buy_revival_potion(profile, 101):
		return "Unaffordable potion purchase succeeded."
	if notifications[0] != 0:
		return "Rejected potion purchase emitted a profile notification."
	if not ProfileCommands.buy_revival_potion(profile, 40):
		return "Affordable potion purchase failed."
	if profile.gold != 60 or profile.revival_potions != 1 or notifications[0] != 1 or not profile.is_valid():
		return "Potion purchase did not make one atomic notified economy update."
	var director = Director.new()
	director.fail_fall(0.0)
	if not director.revive(profile, 0.0):
		return "Revival potion consumption failed."
	return _expect(notifications[0] == 2 and profile.revival_potions == 0, "RunDirector potion consumption did not emit exactly one profile notification.")

func test_profile_ability_command_respects_exclusion() -> String:
	var profile := ProfileState.new()
	if not profile.abilities.unlocked.get(AbilityEligibility.JUMP, false) or profile.abilities.equipped != [AbilityEligibility.JUMP]:
		return "Default Jump unlock/equip state is invalid."
	var snapshot_gold := profile.gold
	var snapshot_unlocks: Dictionary = profile.abilities.unlocked.duplicate()
	if ProfileCommands.unlock_and_equip_ability(profile, AbilityEligibility.REVERSE_GRAVITY):
		return "Profile command bypassed ability exclusion."
	if profile.abilities.equipped != [AbilityEligibility.JUMP] or profile.abilities.unlocked != snapshot_unlocks or profile.gold != snapshot_gold:
		return "Rejected profile command was not atomic."
	var reverse_first := ProfileState.new()
	reverse_first.abilities.unequip(AbilityEligibility.JUMP)
	if not ProfileCommands.unlock_and_equip_ability(reverse_first, AbilityEligibility.REVERSE_GRAVITY) or ProfileCommands.unlock_and_equip_ability(reverse_first, AbilityEligibility.JUMP):
		return "Reverse Gravity/Jump exclusion failed in the inverse order."
	profile.abilities.unlocked[AbilityEligibility.REVERSE_GRAVITY] = true
	profile.abilities.equipped.append(AbilityEligibility.REVERSE_GRAVITY)
	return _expect(not profile.is_valid(), "Reconstructed mutually-exclusive ability state was accepted.")

func test_run_state_is_transient() -> String:
	var run := RunState.new(100.0)
	run.apply_damage(DamageStatus.DamageEvent.new(20.0))
	run.apply_status(DamageStatus.TimedStatus.new(&"burn", 2.0, 0.0))
	run.advance_distance(2.5)
	run.begin_countdown(4.0)
	if not is_equal_approx(run.health_owner.current_health, 80.0) or not run.health_owner.has_status(&"burn", 1.0) or not is_equal_approx(run.distance_tiles, 2.5) or not run.is_countdown_active(8.9) or run.is_countdown_active(9.0):
		return "Transient run timing or distance is invalid."
	var profile := ProfileState.new()
	return _expect(not ("distance_tiles" in profile) and not ("health" in profile), "Run state leaked into persistent profile contract.")

func test_revival_state_machine_boundaries() -> String:
	var before = Director.new()
	before.seed = 73; before.run.advance_distance(7.0); before.run.earned_gold = 9
	before.run.apply_status(DamageStatus.TimedStatus.new(&"burn", 2.0, 0.0)); before.fail_fall(0.0)
	if before.failure_reason != Director.FailureReason.FALL:
		return "Fall did not retain its recovery reason."
	var early := ProfileState.new(); early.set_revival_potions(2)
	if not before.revive(early, GameConfig.COUNTDOWN_SECS - 0.01) or early.revival_potions != 1 or before.seed != 73 or before.run.distance_tiles != 7.0 or before.run.earned_gold != 9 or not before.run.health_owner.statuses.is_empty():
		return "Just-before revival did not preserve run or clear health state."
	if before.revive(early, GameConfig.COUNTDOWN_SECS - 0.01) or early.revival_potions != 1:
		return "Duplicate revival consumed extra stock."
	var exact = Director.new(); exact.fail_fall(10.0)
	var exact_profile := ProfileState.new(); exact_profile.set_revival_potions(1)
	if exact.revive(exact_profile, 10.0 + GameConfig.COUNTDOWN_SECS):
		return "Exact deadline revival succeeded before tick."
	exact.tick(10.0 + GameConfig.COUNTDOWN_SECS)
	if exact.state != Director.State.GAME_OVER or exact.revive(exact_profile, 10.0 + GameConfig.COUNTDOWN_SECS):
		return "Exact deadline revival succeeded after tick."
	var after = Director.new(); after.fail_fall(20.0)
	var after_profile := ProfileState.new(); after_profile.set_revival_potions(1)
	var health = Director.new(); health.initialize_progress(Vector2(37, 568), 0.0)
	health.apply_damage(DamageStatus.DamageEvent.new(999.0), 0.0)
	return _expect(not after.revive(after_profile, 20.0 + GameConfig.COUNTDOWN_SECS + 0.01) and after_profile.revival_potions == 1 and health.failure_reason == Director.FailureReason.HEALTH and health.failure_position == Vector2(37, 568), "After-deadline revival consumed stock or health failure lacked context.")

func test_support_query_validates_before_potion_commit() -> String:
	var director = Director.new()
	var profile := ProfileState.new()
	profile.revival_potions = 1
	director.safe_support = Vector2(100, 568)
	director.fail_fall(0.0)
	director.set_support_query(func(_candidate: Vector2, _context: Dictionary) -> Variant: return null)
	if director.revive(profile, 0.0) or profile.revival_potions != 1 or director.state != Director.State.REVIVAL_COUNTDOWN:
		return "Invalid support consumed a potion or resumed the run."
	director.set_support_query(func(_candidate: Vector2, _context: Dictionary) -> Variant: return Vector2(64, 568))
	if not director.revive(profile, 0.0):
		return "Valid replacement support was rejected."
	var clock := GameClock.ManualClock.new()
	var stationary := Director.new(clock)
	stationary.initialize_progress(Vector2(100, 568), 0.0)
	for _i in 4:
		clock.advance(1.0)
		stationary.record_checkpoint(Vector2(100, 568))
		stationary.record_progress(Vector2(100, 568), clock.now_seconds())
	return _expect(director.safe_support == Vector2(64, 568) and profile.revival_potions == 0 and stationary.state == Director.State.REVIVAL_COUNTDOWN and stationary.failure_reason == Director.FailureReason.STUCK and stationary.failure_position == Vector2(100, 568), "Checkpoint sampling reset stationary stuck timing or resolved support committed incorrectly.")

func test_revival_configuration_is_positive_finite() -> String:
	return _expect(GameConfig.REVIVAL_PROTECTION > 0.0 and is_finite(GameConfig.REVIVAL_PROTECTION) and GameConfig.DAMAGE_FEEDBACK_DURATION > 0.0 and is_finite(GameConfig.DAMAGE_FEEDBACK_DURATION) and GameConfig.STUCK_PROGRESS_EPSILON > 0.0 and is_finite(GameConfig.STUCK_PROGRESS_EPSILON), "Revival protection, tint, or progress tolerance is not positive finite.")

func test_shooting_timing_contract() -> String:
	var timing := ShootingTiming.new(2.0)
	if not timing.register_weapon(&"bow", 1.0) or timing.register_weapon(&"invalid", 0.0):
		return "Weapon timing registration validation failed."
	var equipped: Array[StringName] = [&"bow"]
	if not timing.due_weapons(0.0, equipped, true).is_empty():
		return "Weapon fired before Shooting activation."
	if not timing.activate(0.0) or timing.activate(1.0):
		return "Shooting activation gate rejected/accepted invalid state."
	timing.deactivate()
	if timing.activate(1.9) or not timing.activate(2.0) or timing.activate(4.0):
		return "Deactivation did not preserve activation cooldown or active gate."
	if not timing.due_weapons(2.0, equipped, false).is_empty():
		return "Weapon fires with no visible target."
	if timing.due_weapons(2.0, equipped, true) != equipped:
		return "Ready weapon did not fire with visible target."
	timing.mark_fired(&"bow", 2.0)
	if not timing.due_weapons(2.9, equipped, true).is_empty():
		return "Weapon fired before its own interval."
	if timing.due_weapons(3.0, equipped, true) != equipped:
		return "Weapon did not fire at its independent interval."
	timing.reset()
	if timing.is_active or not timing.can_activate(0.0) or not timing.due_weapons(2.0, equipped, true).is_empty():
		return "Shooting reset did not restore an explicit inactive gate."
	return _expect(timing.activate(0.0), "Shooting did not activate after reset.")

func test_main_menu_start_intent() -> String:
	var packed_scene := load("res://scenes/main_menu.tscn") as PackedScene
	var menu := packed_scene.instantiate() as MainMenu
	var result := _expect((menu.get_node("Center/Panel/Content/StartRun") as Button) != null, "Menu does not expose a start control.")
	menu.free()
	return result

func test_harness_self_checks() -> String:
	var passing = Harness.new()
	passing.schedule()
	passing.record("pass", "")
	if passing.exit_code() != 0:
		return "Harness rejected a complete passing run."
	var failing = Harness.new()
	failing.schedule()
	failing.record("failure", "intentional failure")
	if failing.exit_code() == 0:
		return "Harness accepted a recorded test failure."
	var missing = Harness.new()
	missing.schedule()
	if missing.exit_code() == 0:
		return "Harness accepted an unexecuted scheduled test."
	var parse_failure = Harness.new()
	parse_failure.record_external_failure("simulated parse failure")
	return _expect(parse_failure.exit_code() != 0, "Harness accepted a simulated parse failure.")

func test_terrain_same_seed_equality() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var first := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 48271, 4)
	var second := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 48271, 4)
	return _expect(first.is_valid() and first.stable_signature() == second.stable_signature() and first.x_end - first.x_begin == GameConfig.TERRAIN_CHUNK_WIDTH, "Same seed/chunk did not produce identical valid half-open terrain.")

func test_terrain_different_seed_variation() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var signatures: Dictionary = {}
	for seed in [1, 2, 3, 4, 5, 6, 7, 8]:
		signatures[TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, seed, 3).geometry_signature()] = true
	return _expect(signatures.size() > 1, "Different run seeds produced no terrain variation.")

func test_terrain_order_independent_regeneration() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var expected := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 717, 11).stable_signature()
	for index in [8, -3, 40, 0, 11, 2]:
		TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 717, index)
	return _expect(expected == TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 717, 11).stable_signature(), "Chunk output depended on generation order.")

func test_terrain_invalid_config_rejected() -> String:
	var invalid := GameConfig.terrain_snapshot()
	invalid[&"snow_min_jump_multiplier"] = 1.2
	invalid[&"snow_max_jump_multiplier"] = 0.8
	invalid[&"chunk_width"] = 0
	var description := TerrainGenerator.generate(invalid, GameConfig.TERRAIN_VERSION, 1, 0)
	var weak_jump := GameConfig.terrain_snapshot()
	weak_jump[&"max_jump_tiles"] = 0.1
	var narrow := GameConfig.terrain_snapshot()
	narrow[&"chunk_width"] = 1
	return _expect(not TerrainGenerator.validate_snapshot(invalid).is_empty() and not description.is_valid() and not TerrainGenerator.validate_snapshot(weak_jump).is_empty() and not TerrainGenerator.generate(weak_jump, GameConfig.TERRAIN_VERSION, 1, 0).is_valid() and not TerrainGenerator.validate_snapshot(narrow).is_empty() and not TerrainGenerator.generate(narrow, GameConfig.TERRAIN_VERSION, 1, 0).is_valid(), "Invalid, undersized, or physically unsupported terrain configuration was accepted instead of fail-closed.")

func test_terrain_all_form_kinds_present() -> String:
	var forms: Dictionary = {}
	for chunk_index in range(-12, 24):
		forms[TerrainGenerator.generate(GameConfig.terrain_snapshot(), GameConfig.TERRAIN_VERSION, 919, chunk_index).form] = true
	return _expect(forms.has(&"platform") and forms.has(&"mountain") and forms.has(&"cave"), "Generator did not expose platform, mountain, and cave forms.")

func test_biome_exact_boundary_columns() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var interval := int(snapshot[&"biome_interval"])
	var expected: Array[StringName] = TerrainGenerator.BIOMES
	for encounter in expected.size():
		var begin := encounter * interval
		if TerrainGenerator.biome_for_column(snapshot, 91, begin) != expected[encounter] or TerrainGenerator.biome_for_column(snapshot, 91, begin + interval - 1) != expected[encounter]:
			return "Biome %s does not own its exact [%d, %d] interval." % [expected[encounter], begin, begin + interval - 1]
		if encounter + 1 < expected.size() and TerrainGenerator.biome_for_column(snapshot, 91, begin + interval) != expected[encounter + 1]:
			return "Biome boundary at column %d did not change ownership exactly once." % [begin + interval]
	return ""

func test_biome_first_encounter_order() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var interval := int(snapshot[&"biome_interval"])
	var actual: Array[StringName] = []
	for encounter in TerrainGenerator.BIOMES.size():
		actual.append(TerrainGenerator.biome_for_column(snapshot, 618, encounter * interval + interval / 2))
	return _expect(actual == TerrainGenerator.BIOMES, "First biome pass was %s instead of Grass, Tundra, Snow, Desert, Astro, Fort." % [actual])

func test_biome_seeded_random_variation() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var interval := int(snapshot[&"biome_interval"])
	var sequences: Dictionary = {}
	for seed in [1, 2, 3, 4, 5, 6, 7, 8]:
		var sequence: Array[String] = []
		for encounter in range(TerrainGenerator.BIOMES.size(), TerrainGenerator.BIOMES.size() + 12):
			sequence.append(TerrainGenerator.biome_for_column(snapshot, seed, encounter * interval))
		sequences[",".join(sequence)] = true
	return _expect(sequences.size() > 1, "Different seeds produced no variation after the ordered biome pass.")

func test_biome_random_encounters_do_not_repeat() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var interval := int(snapshot[&"biome_interval"])
	for seed in [3, 47, 9182]:
		var previous := TerrainGenerator.biome_for_column(snapshot, seed, (TerrainGenerator.BIOMES.size() - 1) * interval)
		for encounter in range(TerrainGenerator.BIOMES.size(), TerrainGenerator.BIOMES.size() + 300):
			var current := TerrainGenerator.biome_for_column(snapshot, seed, encounter * interval)
			if current == previous:
				return "Seed %d repeated biome %s between encounters %d and %d." % [seed, current, encounter - 1, encounter]
			previous = current
	return ""

func test_biome_negative_columns_are_grass() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	for column in [-1, -40, -999999]:
		if TerrainGenerator.biome_for_column(snapshot, 17, column) != &"grass":
			return "Negative logical column %d was not safe Grass pre-origin terrain." % column
	return ""

func test_biome_cross_boundary_chunk_metadata() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	# Chunk six spans columns 72..83, which crosses the Tundra -> Snow boundary
	# at 80 and is even, so it also carries a stable spawn anchor.
	var description := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 101, 6)
	if not description.is_valid() or description.biome_at_column.get(79, &"") != &"tundra" or description.biome_at_column.get(80, &"") != &"snow":
		return "Cross-boundary chunk lacks exact Tundra/Snow column ownership."
	for location: Vector2i in description.occupied:
		var expected := TerrainGenerator.biome_for_column(snapshot, description.seed, location.x)
		if StringName((description.occupied[location] as Dictionary).get(&"material", &"")) != expected:
			return "Cell %s material does not match its absolute-column biome." % location
	for surface: TerrainSurface in description.surfaces:
		for column in range(surface.x_begin, surface.x_end):
			if surface.material != TerrainGenerator.biome_for_column(snapshot, description.seed, column):
				return "Surface %s crosses or mislabels biome boundary." % surface.id
	if description.anchors.is_empty():
		return "Cross-boundary even chunk did not retain its anchor."
	var anchor := description.anchors[0] as SpawnAnchor
	return _expect(anchor.biome == TerrainGenerator.biome_for_column(snapshot, description.seed, anchor.column), "Anchor biome does not match its absolute-column ownership.")

func test_biome_regeneration_is_order_independent() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var expected := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 412, 20).stable_signature()
	for index in [7, -4, 38, 6, 91, 20, 0]:
		TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 412, index)
	return _expect(expected == TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 412, 20).stable_signature(), "Biome-bearing chunk regenerated differently after out-of-order generation.")

func test_movement_envelope_body_clearance_min_max() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var envelope := MovementEnvelope.from_snapshot(snapshot, 36.0)
	var low := TerrainSurface.new(&"low", 0, 0, 2, 0)
	var high := TerrainSurface.new(&"high", 0, 2, 8, -1)
	var impossible := TerrainSurface.new(&"impossible", 0, 2, 8, -9)
	var behind := TerrainSurface.new(&"behind", 0, -3, -1, 0)
	var slowdown_applied := is_equal_approx(envelope.minimum_speed, snapshot[&"speed"] * snapshot[&"slowdown_speed_multiplier"]) and envelope.minimum_speed < envelope.speed
	return _expect(envelope.validate().is_empty() and slowdown_applied and envelope.maximum_rise_pixels() > 0.0 and envelope.maximum_rise_ceiling_pixels() >= envelope.minimum_jump_height_pixels() and envelope.maximum_horizontal_travel_pixels(-GameConfig.TILE_SIZE) > envelope.max_horizontal_travel_pixels(-GameConfig.TILE_SIZE) and envelope.has_vertical_clearance(envelope.required_ceiling_clearance_pixels()) and envelope.can_reach_transition(low, high) and not envelope.can_reach_transition(low, impossible) and not envelope.can_reach_transition(low, behind), "Envelope did not account for slowdown/full-speed extremes, body clearance, Snow min/max height, timing, or forward reachability.")

func test_terrain_reachable_transitions_and_seams() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var envelope := MovementEnvelope.from_snapshot(snapshot, 36.0)
	for seed in [1, 33, 919]:
		var previous_exit: TerrainSurface = null
		for chunk_index in range(-2, 7):
			var description := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, seed, chunk_index)
			if not description.is_valid():
				return "Generator rejected supported terrain for seed %d at chunk %d." % [seed, chunk_index]
			var main_entry: TerrainSurface = null
			var main_exit: TerrainSurface = null
			var route := TerrainGenerator.traversal_surfaces(description.surfaces, &"main_route")
			for surface: TerrainSurface in route:
				if main_entry == null:
					main_entry = surface
				main_exit = surface
			for index in range(1, route.size()):
				if not envelope.can_reach_transition(route[index - 1], route[index]):
					return "Internal route transition %d is unreachable for seed %d chunk %d." % [index, seed, chunk_index]
			for platform in TerrainGenerator.traversal_surfaces(description.surfaces, &"floating_platform"):
				var can_enter := false
				var can_exit := false
				for main in route:
					can_enter = can_enter or envelope.can_reach_transition(main, platform)
					can_exit = can_exit or envelope.can_reach_transition(platform, main)
				if not can_enter or not can_exit:
					return "Optional platform lacks a proven entry/exit for seed %d chunk %d." % [seed, chunk_index]
			if main_entry == null or main_exit == null or (previous_exit != null and (previous_exit.x_end != main_entry.x_begin or not envelope.can_reach_transition(previous_exit, main_entry))):
				return "Main route has an unreachable transition or non-half-open seam for seed %d chunk %d." % [seed, chunk_index]
			previous_exit = main_exit
	return ""

func test_terrain_stable_anchors() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var first := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 101, 2)
	var second := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 101, 2)
	if first.anchors.size() != second.anchors.size() or first.anchors.is_empty():
		return "Anchor generation was not stable or did not expose generic anchors."
	var anchor := first.anchors[0]
	var support: TerrainSurface = null
	for surface in first.surfaces:
		if surface.id == anchor.surface_id:
			support = surface
			break
	var clear := support != null and support.contains_column(anchor.column) and anchor.row == support.y - 1
	for offset in anchor.clearance_tiles:
		clear = clear and not first.occupied.has(Vector2i(anchor.column, anchor.row - offset))
	return _expect(anchor.id == second.anchors[0].id and anchor.type == &"generic" and anchor.is_valid() and clear and first.config_identity == GameConfig.terrain_config_identity(snapshot), "Stable anchor support/clearance/config identity contract is invalid.")

func test_grass_atlas_rect_bounds_and_source() -> String:
	var atlas := load(TerrainChunk.ATLAS_PATH) as Texture2D
	var chunk_source := FileAccess.get_file_as_string("res://scripts/terrain/terrain_chunk.gd")
	var palette_source := FileAccess.get_file_as_string("res://scripts/terrain/terrain_palette.gd")
	var valid := TerrainChunk.ATLAS_PATH == "res://assets/Spritesheets/spritesheet-tiles-double.png"
	valid = valid and Palette.ATLAS_PATH == TerrainChunk.ATLAS_PATH
	valid = valid and Palette.FRAME_SIZE == Vector2i(128, 128) and Palette.GRID_STRIDE == 129
	valid = valid and Palette.GRID_COLUMNS == 18 and Palette.GRID_ROWS == 18
	valid = valid and atlas != null and atlas.get_width() == 2321 and atlas.get_height() == 2321
	valid = valid and Palette.source_rect(&"grass", &"block") == Rect2(516, 1161, 128, 128)
	valid = valid and Palette.all_rects_are_valid(atlas)
	valid = valid and not chunk_source.contains("assets/Tiles/terrain_") and not palette_source.contains("load(\"res://assets/Tiles/")
	return _expect(valid, "Terrain atlas layout/source is invalid or runtime terrain still depends on individual tile PNGs.")

func test_six_biome_palette_rects_and_boundary_selection() -> String:
	var expected_blocks := {
		&"grass": Rect2(516, 1161, 128, 128), &"tundra": Rect2(1548, 903, 128, 128),
		&"snow": Rect2(2064, 1677, 128, 128), &"desert": Rect2(774, 1548, 128, 128),
		&"astro": Rect2(1806, 1290, 128, 128), &"fort": Rect2(1032, 1935, 128, 128),
	}
	for material: StringName in expected_blocks:
		if not Palette.has_material(material) or Palette.source_rect(material, &"block") != expected_blocks[material]:
			return "Biome %s did not map to its verified spritesheet family." % material
		for variant: StringName in Palette.VARIANT_OFFSETS:
			if not Palette.has_variant(variant):
				return "Atlas variant %s is missing." % variant

	var description := ChunkDescription.new(GameConfig.TERRAIN_VERSION, 1, 0, 0, 8)
	description.config_identity = &"atlas-topology-test"
	description.form = &"platform"
	for x in range(3):
		for y in range(3):
			description.occupied[Vector2i(x, y)] = {&"material": &"grass", &"kind": &"main_route", &"tile_id": "g:%d:%d" % [x, y]}
	for x in range(4, 7):
		description.occupied[Vector2i(x, -2)] = {&"material": &"grass", &"kind": &"floating_platform", &"tile_id": "p:%d" % x}
	var chunk := TerrainChunk.new()
	chunk.configure(description, GameConfig.terrain_snapshot())
	var topology_ok := chunk.source_variant_for_cell(Vector2i(0, 0)) == &"block_top_left"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(1, 0)) == &"block_top"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(2, 0)) == &"block_top_right"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(0, 1)) == &"block_left"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(1, 1)) == &"block_center"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(2, 1)) == &"block_right"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(0, 2)) == &"block_bottom_left"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(1, 2)) == &"block_bottom"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(2, 2)) == &"block_bottom_right"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(4, -2)) == &"horizontal_left"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(5, -2)) == &"horizontal_middle"
	topology_ok = topology_ok and chunk.source_variant_for_cell(Vector2i(6, -2)) == &"horizontal_right"
	chunk.free()
	return _expect(topology_ok, "Neighboring terrain did not select compatible atlas edge/corner/interior/platform pieces.")

func test_hazard_descriptors_are_deterministic_and_owned() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var first := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 9182, 10)
	var expected := first.stable_signature()
	for index in [-5, 21, 7, 10, 80]:
		TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 9182, index)
	var second := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 9182, 10)
	if first.hazards.is_empty() or expected != second.stable_signature():
		return "Hazard descriptors absent=%s valid=%s first=%s second=%s." % [first.hazards.is_empty(), first.is_valid(), expected, second.stable_signature()]
	var encountered: Dictionary = {}
	for chunk_index in range(10, 20):
		var description := TerrainGenerator.generate(snapshot, GameConfig.TERRAIN_VERSION, 9182, chunk_index)
		for hazard in description.hazards:
			encountered[hazard.type] = true
			if not hazard.is_valid() or hazard.version != GameConfig.HAZARD_DESCRIPTOR_VERSION or hazard.config_identity != description.config_identity or hazard.chunk_index != chunk_index or hazard.biome != TerrainGenerator.biome_for_column(snapshot, description.seed, hazard.absolute_position.x) or description.occupied.has(hazard.absolute_position):
				return "Hazard descriptor lost stable identity, biome ownership, or clear placement."
			var support: TerrainSurface = null
			for surface in description.surfaces:
				if surface.id == hazard.supporting_surface_id:
					support = surface
					break
			if support == null or StringName((description.occupied.get(Vector2i(hazard.absolute_position.x, support.y), {}) as Dictionary).get(&"tile_id", &"")) != hazard.supporting_tile_id:
				return "Hazard descriptor does not own a live matching support tile."
	return _expect(encountered.has(&"desert_flame_candidate") and encountered.has(&"astro_fall_candidate") and encountered.has(&"fort_spike_candidate"), "Biome-gated hazard candidate catalog is incomplete.")

func test_snow_multiplier_stream_is_deterministic_and_bounded() -> String:
	var seed := 88421
	var first: Array[float] = []
	var second: Array[float] = []
	for index in 8:
		first.append(PlayerController.deterministic_snow_jump_multiplier(seed, index))
		second.append(PlayerController.deterministic_snow_jump_multiplier(seed, index))
		if first[index] < GameConfig.SNOW_MIN_JUMP_MULTIPLIER or first[index] > GameConfig.SNOW_MAX_JUMP_MULTIPLIER:
			return "Snow multiplier escaped configured bounds."
	return _expect(first == second and PlayerController.deterministic_snow_jump_multiplier(seed, 0) != PlayerController.deterministic_snow_jump_multiplier(seed + 1, 0), "Snow multiplier stream was not a deterministic run-seed/index function.")

func test_hazard_timing_phase_and_cadence_contract() -> String:
	var period := GameConfig.FORT_SPIKE_PERIOD
	var window := GameConfig.FORT_SPIKE_EXTENDED_SECONDS
	var rising := HazardTiming.fort_extension(0.125, 0.0, period, window)
	var held := HazardTiming.fort_extension(0.35, 0.0, period, window)
	var falling := HazardTiming.fort_extension(window - 0.125, 0.0, period, window)
	var retracted := HazardTiming.fort_extension(window, 0.0, period, window)
	var phased := HazardTiming.fort_extension(0.0, 0.5, period, window)
	var cadence := HazardTiming.ContactCadence.new()
	var emits := cadence.can_emit(2.0, true, true, GameConfig.DESERT_FLAME_DAMAGE_CADENCE)
	emits = emits and not cadence.can_emit(2.2, true, true, GameConfig.DESERT_FLAME_DAMAGE_CADENCE)
	emits = emits and cadence.can_emit(2.0 + GameConfig.DESERT_FLAME_DAMAGE_CADENCE, true, true, GameConfig.DESERT_FLAME_DAMAGE_CADENCE)
	emits = emits and not cadence.can_emit(4.0, true, false, GameConfig.DESERT_FLAME_DAMAGE_CADENCE)
	return _expect(is_equal_approx(rising, 0.5) and is_equal_approx(held, 1.0) and is_equal_approx(falling, 0.5) and is_zero_approx(retracted) and is_zero_approx(phased) and emits, "Hazard phase/cadence invalid rise=%.3f hold=%.3f fall=%.3f rest=%.3f phase=%.3f emits=%s" % [rising, held, falling, retracted, phased, emits])

func test_hazard_runtime_assets_and_fort_transition_geometry() -> String:
	var desert := HazardRuntime.new()
	var desert_descriptor = HazardDescriptorModel.new(&"test:desert", 1, &"test", 0, Vector2i.ZERO, &"surface", &"tile", &"desert", &"desert_flame_candidate", 0.0)
	desert.configure(desert_descriptor, float(GameConfig.TILE_SIZE), GameConfig.RUN_ORIGIN_X, GameConfig.TERRAIN_BASE_SURFACE_Y)
	var flame_ok := desert.particles != null and desert.particles is GPUParticles2D and desert.particles.texture != null and desert.particles.texture.resource_path == HazardRuntime.FLAME_TEXTURE_PATH
	var fort := HazardRuntime.new()
	var fort_descriptor = HazardDescriptorModel.new(&"test:fort", 1, &"test", 0, Vector2i.ZERO, &"surface", &"tile", &"fort", &"fort_spike_candidate", 0.0)
	fort.configure(fort_descriptor, float(GameConfig.TILE_SIZE), GameConfig.RUN_ORIGIN_X, GameConfig.TERRAIN_BASE_SURFACE_Y)
	fort.advance(0.125, true)
	var shape := fort.hitbox.shape as RectangleShape2D
	var transition_ok := fort.spike_visual != null and fort.spike_visual.texture != null and fort.spike_visual.texture.resource_path == HazardRuntime.SPIKE_TEXTURE_PATH and is_equal_approx(fort.extension_ratio, 0.5) and fort.spike_visual.visible and shape != null and is_equal_approx(shape.size.y, GameConfig.FORT_SPIKE_HEIGHT * fort.extension_ratio) and is_equal_approx(fort.spike_visual.scale.y, GameConfig.FORT_SPIKE_HEIGHT / 64.0 * fort.extension_ratio)
	fort.advance(GameConfig.FORT_SPIKE_EXTENDED_SECONDS, true)
	var retracted_ok := not fort.is_damaging() and not fort.spike_visual.visible
	var final_ratio := fort.extension_ratio
	var final_shape := shape.size if shape != null else Vector2.ZERO
	var final_scale := fort.spike_visual.scale if fort.spike_visual != null else Vector2.ZERO
	desert.free()
	fort.free()
	return _expect(flame_ok and transition_ok and retracted_ok, "Hazard runtime invalid flame=%s transition=%s retract=%s ratio=%.3f shape=%s scale=%s" % [flame_ok, transition_ok, retracted_ok, final_ratio, final_shape, final_scale])

func test_astro_fall_config_and_state_contract() -> String:
	var valid := GameConfig.validate_defaults().is_empty() and GameConfig.ASTRO_FALL_DELAY > 0.0 and GameConfig.ASTRO_FALL_SPEED > 0.0 and GameConfig.ASTRO_FALL_FIXED_STEP > 0.0 and GameConfig.ASTRO_FALL_LIMIT > GameConfig.TILE_SIZE
	return _expect(valid, "Astro editable fall constants failed validation.")

func test_astro_three_block_cascade_and_pause() -> String:
	var coordinator := AstroCoordinator.new()
	coordinator.register_cell(&"a", 1, 3, 0, 0, 32.0, null)
	coordinator.register_cell(&"b", 1, 3, 1, 0, 96.0, null)
	coordinator.register_cell(&"c", 1, 3, 2, 0, 160.0, null)
	var armed := coordinator.arm(&"a", 1, &"top")
	coordinator.advance(0.10, false, 64.0, 320.0, 0.05, 0.01, 512.0)
	var frozen := coordinator.state_for(&"a") == AstroCoordinator.State.ARMED
	coordinator.advance(0.20, true, 64.0, 320.0, 0.05, 0.01, 512.0)
	coordinator.advance(0.45, true, 64.0, 320.0, 0.05, 0.01, 512.0)
	var chain := coordinator.state_for(&"b") != AstroCoordinator.State.STABLE
	coordinator.advance(0.75, true, 64.0, 320.0, 0.05, 0.01, 512.0)
	var third := coordinator.state_for(&"c") != AstroCoordinator.State.STABLE
	var staggered := AstroCoordinator.new()
	staggered.register_cell(&"upper", 7, 1, 0, 14, 32.0, null)
	staggered.register_cell(&"lower", 8, 1, 1, 15, 96.0, null)
	staggered.arm(&"lower", 8, &"top")
	staggered.advance(0.06, true, 64.0, 320.0, 0.05, 0.01, 512.0)
	staggered.arm(&"upper", 7, &"top")
	var separation_ok := true
	for now in [0.10, 0.16, 0.22, 0.28, 0.34, 0.40]:
		staggered.advance(now, true, 64.0, 320.0, 0.05, 0.01, 512.0)
		var upper_cell := staggered.cells[&"upper"] as Dictionary
		var lower_cell := staggered.cells[&"lower"] as Dictionary
		var upper_y := float(upper_cell.get(&"fall_y", upper_cell[&"world_y"]))
		var lower_y := float(lower_cell.get(&"fall_y", lower_cell[&"world_y"]))
		separation_ok = separation_ok and lower_y - upper_y >= 63.999
	return _expect(armed and frozen and chain and third and separation_ok, "Astro cascade/pause/separation states were %d/%d/%d separated=%s." % [coordinator.state_for(&"a"), coordinator.state_for(&"b"), coordinator.state_for(&"c"), separation_ok])

func test_astro_order_epoch_and_non_astro_sweep() -> String:
	var coordinator := AstroCoordinator.new()
	coordinator.register_cell(&"z", 4, 1, 0, 0, 32.0, null)
	coordinator.set_solid_below_query(func(_column: int, _old: float, _new: float) -> bool: return true)
	var stale := not coordinator.arm(&"z", 3, &"top")
	var top := coordinator.arm(&"z", 4, &"top")
	coordinator.advance(0.10, true, 64.0, 640.0, 0.01, 0.01, 512.0)
	coordinator.advance(0.30, true, 64.0, 640.0, 0.01, 0.01, 512.0)
	var forward := _astro_registration_signature([&"a", &"b", &"c"])
	var reverse := _astro_registration_signature([&"c", &"b", &"a"])
	return _expect(stale and top and coordinator.state_for(&"z") == AstroCoordinator.State.REMOVED and forward == reverse, "Astro stale epoch, inclusive non-Astro swept removal, or order independence failed (%s/%s)." % [forward, reverse])

func test_astro_arm_direction_and_duplicate_contract() -> String:
	var coordinator := AstroCoordinator.new()
	coordinator.register_cell(&"one", 9, 0, 0, 0, 32.0, null)
	var side := coordinator.arm(&"one", 9, &"side")
	var head := coordinator.arm(&"one", 9, &"head")
	var first := coordinator.arm(&"one", 9, &"top")
	var duplicate := coordinator.arm(&"one", 9, &"top")
	return _expect(not side and not head and first and not duplicate and coordinator.state_for(&"one") == AstroCoordinator.State.ARMED, "Astro top-only/duplicate arm contract failed.")

func test_m4_hit_status_simulation_contract() -> String:
	var clock := GameClock.ManualClock.new()
	var director = Director.new(clock)
	director.run.set_health(100.0, 100.0)
	var burn := EnemyEffect.new(&"burn", 2.0, 0.5, 10.0, 1.0, &"blood", &"burner")
	var accepted := director.apply_hit(DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(10.0, &"enemy"), burn), 0.0)
	var observer_snapshots: Array[Dictionary] = []
	var observer_callback := func() -> void: observer_snapshots.append({&"state": director.state, &"health": director.run.health_owner.current_health, &"has_burn": director.run.health_owner.has_status(&"burn", director.simulation_time), &"has_freeze": director.run.health_owner.has_status(&"freeze", director.simulation_time)})
	director.damage_landed.connect(observer_callback)
	var observed := director.apply_hit(DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(1.0, &"observer"), EnemyEffect.new(&"freeze", 1.0, 0.0, 0.0, 0.8, &"freeze", &"observer")), 0.0)
	var health_before_invalid: float = director.run.health_owner.current_health
	var invalid := director.apply_hit(DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(10.0), EnemyEffect.new(&"bad", 0.0)), 0.0)
	var invalid_atomic := is_equal_approx(director.run.health_owner.current_health, health_before_invalid)
	director.revival_protection_until = 1.0
	var protected := director.apply_hit(DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(1.0), burn), 0.0)
	director.revival_protection_until = -1.0
	director.advance_simulation(0.49)
	var before_tick: float = director.run.health_owner.current_health
	clock.advance(10.0) # wall time does not expire/tick a RUNNING status.
	director.tick(clock.now_seconds())
	director.advance_simulation(0.01)
	var first_tick: float = director.run.health_owner.current_health
	director.advance_simulation(0.5)
	var second_tick: float = director.run.health_owner.current_health
	# Refresh retains the next-tick phase and only extends exclusive expiry.
	director.apply_hit(DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(0.0), EnemyEffect.new(&"burn", 2.0, 0.5, 10.0, 1.0, &"blood", &"new")), clock.now_seconds())
	director.fail_fall(clock.now_seconds())
	var blocked := director.apply_hit(DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(1.0), burn), clock.now_seconds())
	var profile := ProfileState.new(); profile.revival_potions = 1
	var revived := director.revive(profile, clock.now_seconds())
	var lethal_director = Director.new(GameClock.ManualClock.new())
	var lethal_observers: Array[Dictionary] = [{}]
	var lethal_callback := func() -> void: lethal_observers[0] = {&"state": lethal_director.state, &"health": lethal_director.run.health_owner.current_health, &"statuses": lethal_director.run.health_owner.statuses.size()}
	lethal_director.damage_landed.connect(lethal_callback)
	var lethal := lethal_director.apply_hit(DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(999.0), burn), 0.0)
	director.damage_landed.disconnect(observer_callback)
	lethal_director.damage_landed.disconnect(lethal_callback)
	var observer_snapshot: Dictionary = observer_snapshots[0] if not observer_snapshots.is_empty() else {}
	var lethal_observer: Dictionary = lethal_observers[0]
	var valid: bool = accepted.accepted and accepted.effect_installed and observed.accepted and bool(observer_snapshot.get(&"has_burn", false)) and bool(observer_snapshot.get(&"has_freeze", false)) and int(observer_snapshot.get(&"state", -1)) == Director.State.RUNNING and is_equal_approx(float(observer_snapshot.get(&"health", 0.0)), 89.0) and not invalid.accepted and invalid_atomic and not protected.accepted and is_equal_approx(before_tick, 89.0) and is_equal_approx(first_tick, 79.0) and is_equal_approx(second_tick, 69.0) and not blocked.accepted and revived and director.run.health_owner.statuses.is_empty() and lethal.accepted and lethal.lethal and not lethal.effect_installed and int(lethal_observer.get(&"state", -1)) == Director.State.REVIVAL_COUNTDOWN and int(lethal_observer.get(&"statuses", -1)) == 0
	return "" if valid else "atomic accepted=%s/%s observed=%s snap=%s invalid=%s/%s protected=%s ticks=%.2f,%.2f,%.2f blocked=%s revive=%s lethal=%s snap=%s" % [accepted.accepted, accepted.effect_installed, observed.accepted, observer_snapshot, invalid.accepted, invalid_atomic, protected.accepted, before_tick, first_tick, second_tick, blocked.accepted, revived, lethal.lethal, lethal_observer]

func test_m4_player_modifier_and_appearance_precedence() -> String:
	var player := PlayerController.new()
	player.set_movement_modifier_resolver(func() -> float: return 0.2)
	player.set_appearance_state_resolver(func(_time: float) -> Dictionary: return {&"freeze": true})
	player.simulation_time = 1.0
	var bounded := is_equal_approx(player.effective_movement_multiplier(), GameConfig.MIN_SLOWDOWN_SPEED_MULTIPLIER)
	var frozen := player.appearance_state() == &"freeze"
	player.damage_tint_until = 2.0
	var damage_wins := player.appearance_state() == &"damage"
	player.damage_tint_until = -1.0
	player.set_appearance_state_resolver(func(_time: float) -> Dictionary: return {&"blood": true, &"freeze": true})
	player.simulation_time = 1.0
	var blood_wins := player.appearance_state() == &"blood"
	player.simulation_time = 1.125 # blood is in its blink-off phase.
	var freeze_during_blink_off := player.appearance_state() == &"freeze"
	player.set_appearance_state_resolver(func(_time: float) -> Dictionary: return {&"blood": true})
	var neutral_blink_off := player.appearance_state() == &"neutral"
	player.free()
	return _expect(bounded and frozen and damage_wins and blood_wins and freeze_during_blink_off and neutral_blink_off, "Player composed slowdown or appearance precedence is invalid.")

func test_m4_enemy_contract_validation() -> String:
	var effect := EnemyEffect.new(&"freeze", 2.0, 0.0, 0.0, 0.7, &"freeze", &"ice")
	var definition := EnemyDefinitionContract.new(&"ice_archer", &"snow", 2)
	definition.maximum_health = 30.0; definition.contact_damage = 5.0; definition.movement_type = EnemyDefinitionContract.MOVEMENT_PATROL
	definition.movement_speed = 40.0; definition.ranged_enabled = true; definition.ranged_interval = 1.0; definition.vicinity_tiles = 4.0
	definition.sprite_path = "res://assets/Characters/1/Png/Character Sprite/sprite.png"; definition.scene_path = "res://scenes/level.tscn"; definition.effect_spec = effect
	var spawn := EnemySpawnContract.new(&"spawn:1", 1, 44, definition.id, 3, 9, &"anchor:3:1", &"surface:3", &"tile:3:1", 37, -1, &"snow", 2, 2, &"right", 36, 40)
	var invalid := EnemySpawnContract.new()
	var bad_tier := EnemyDefinitionContract.new(&"bad", &"snow", GameConfig.MAX_ENEMY_TIER + 1)
	bad_tier.maximum_health = 10.0; bad_tier.ranged_enabled = true; bad_tier.sprite_path = definition.sprite_path; bad_tier.scene_path = definition.scene_path
	var bad_health := EnemyDefinitionContract.new(&"bad_health", &"snow", 1)
	bad_health.maximum_health = GameConfig.MAX_ENEMY_HEALTH + 1.0; bad_health.ranged_enabled = true; bad_health.sprite_path = definition.sprite_path; bad_health.scene_path = definition.scene_path
	var bad_damage := EnemyDefinitionContract.new(&"bad_damage", &"snow", 1)
	bad_damage.maximum_health = 10.0; bad_damage.contact_damage = GameConfig.MAX_ENEMY_DAMAGE + 1.0; bad_damage.ranged_enabled = true; bad_damage.sprite_path = definition.sprite_path; bad_damage.scene_path = definition.scene_path
	spawn.variant_id = &"" 
	return _expect(effect.is_valid() and definition.is_valid() and not spawn.is_valid() and not invalid.is_valid() and not bad_tier.is_valid() and not bad_health.is_valid() and not bad_damage.is_valid(), "Enemy definition tier/stat bound or descriptor variant validation is invalid.")

func test_m4_attack_policy_cadence_contract() -> String:
	var definition := EnemyDefinitionContract.new(&"dual", &"fort", 1)
	definition.maximum_health = 10.0; definition.melee_enabled = true; definition.ranged_enabled = true; definition.melee_interval = 1.0; definition.ranged_interval = 2.0; definition.vicinity_tiles = 2.0
	definition.sprite_path = "res://assets/Characters/1/Png/Character Sprite/sprite.png"; definition.scene_path = "res://scenes/level.tscn"
	var policy := EnemyAttackPolicyContract.new()
	var first := policy.decide(definition, 0.0, Vector2.ZERO, Vector2(64, 0), true, true, true)
	var early := policy.decide(definition, 0.9, Vector2.ZERO, Vector2(64, 0), true, true, true)
	var melee := policy.decide(definition, 1.0, Vector2.ZERO, Vector2(64, 0), true, true, true)
	var no_enemy_camera := policy.decide(definition, 9.0, Vector2.ZERO, Vector2(64, 0), true, false, true)
	var no_target_camera := policy.decide(definition, 9.0, Vector2.ZERO, Vector2(64, 0), true, true, true, 1.0, false)
	definition.requires_line_of_sight = true
	var no_los := policy.decide(definition, 9.0, Vector2.ZERO, Vector2(64, 0), true, true, false)
	definition.requires_line_of_sight = false
	var melee_boundary := definition.melee_range_tiles * GameConfig.TILE_SIZE
	var exact_boundary := policy.decide(definition, 9.0, Vector2.ZERO, Vector2(melee_boundary, 0), true, true, true)
	var outside := policy.decide(definition, 12.0, Vector2.ZERO, Vector2(melee_boundary + 0.1, 0), true, true, true)
	policy.reset()
	var slow_first := policy.decide(definition, 0.0, Vector2.ZERO, Vector2(64, 0), true, true, true, 2.0)
	var slow_early := policy.decide(definition, 1.0, Vector2.ZERO, Vector2(64, 0), true, true, true, 2.0)
	var slow_due := policy.decide(definition, 2.0, Vector2.ZERO, Vector2(64, 0), true, true, true, 2.0)
	return _expect(bool(first[&"melee"]) and bool(first[&"ranged"]) and not bool(early[&"melee"]) and not bool(early[&"ranged"]) and bool(melee[&"melee"]) and not bool(melee[&"ranged"]) and not bool(no_enemy_camera[&"melee"]) and not bool(no_target_camera[&"ranged"]) and not bool(no_los[&"melee"]) and bool(exact_boundary[&"melee"]) and not bool(outside[&"melee"]) and bool(slow_first[&"melee"]) and not bool(slow_early[&"melee"]) and bool(slow_due[&"melee"]), "Enemy attack camera/LOS/vicinity/multiplier/channel cadence policy failed.")

func test_m4_status_capacity_and_refresh_contract() -> String:
	var owner := DamageStatus.HealthOwner.new(100.0)
	for index in GameConfig.MAX_ACTIVE_STATUS_IDENTITIES:
		if not owner.apply_status(DamageStatus.TimedStatus.new(StringName("status_%d" % index), 10.0, 0.0), 0.0): return "Configured bounded status capacity rejected an available slot."
	var full := not owner.apply_status(DamageStatus.TimedStatus.new(&"overflow", 10.0, 0.0), 0.0)
	var periodic := DamageStatus.TimedStatus.new(&"burn", 4.0, 0.0, 0.5, 2.0, &"weak")
	var refresh_owner := DamageStatus.HealthOwner.new(100.0)
	refresh_owner.apply_status(periodic, 0.0)
	var next_before := periodic.next_tick_at
	refresh_owner.apply_status(DamageStatus.TimedStatus.new(&"burn", 4.0, 0.1, 0.25, 5.0, &"strong"), 0.1)
	var merged: DamageStatus.TimedStatus = refresh_owner.statuses[&"burn"]
	var next_after_refresh: float = merged.next_tick_at
	var due := refresh_owner.due_periodic_events(1.0000001)
	# Transitioning a live nonperiodic identity to periodic gets the incoming
	# first cadence, rather than retaining the old INF sentinel forever.
	var transition_owner := DamageStatus.HealthOwner.new(100.0)
	transition_owner.apply_status(DamageStatus.TimedStatus.new(&"transition", 1.0, 0.0), 0.0)
	transition_owner.apply_status(DamageStatus.TimedStatus.new(&"transition", 1.0, 0.10, 0.25, 4.0, &"transition_source"), 0.10)
	var transition: DamageStatus.TimedStatus = transition_owner.statuses[&"transition"]
	var transition_early := transition_owner.due_periodic_events(0.349)
	var transition_exact := transition_owner.due_periodic_events(0.35)
	# Simulation pauses have no calls here, so no tick can be emitted; expiry is
	# exclusive and removes an overdue periodic status before it can tick.
	var expired := transition_owner.due_periodic_events(1.11)
	var checks := [full, is_equal_approx(next_after_refresh, next_before), is_equal_approx(merged.periodic_damage, 5.0), is_equal_approx(merged.interval_seconds, 0.25), merged.source_id == &"strong", due.size() == 1, due[0].source_id == &"strong", is_equal_approx(transition.next_tick_at, 0.60), transition_early.is_empty(), transition_exact.size() == 1, transition_exact[0].source_id == &"transition_source", expired.is_empty(), not transition_owner.statuses.has(&"transition")]
	var valid: bool = true
	for check in checks: valid = valid and bool(check)
	return "" if valid else "status checks=%s full=%s next=%.4f/%.4f damage=%.2f interval=%.2f source=%s due=%s transition=%.4f early=%s exact=%s expired=%s" % [checks, full, next_after_refresh, next_before, merged.periodic_damage, merged.interval_seconds, merged.source_id, due, transition.next_tick_at, transition_early, transition_exact, expired]

func test_m4_anchor_lifecycle_and_astro_spawn_support() -> String:
	var streamer := TerrainStreamer.new()
	root.add_child(streamer)
	if not streamer.setup(GameConfig.terrain_snapshot(), 618):
		streamer.free(); return "Streamer setup failed."
	var added: Array[StringName] = []; var removed: Array[StringName] = []; var invalidated: Array[StringName] = []
	streamer.anchor_added.connect(func(id: StringName, _surface: StringName, _tile: StringName, _chunk: int, _epoch: int) -> void: added.append(id))
	streamer.anchor_removed.connect(func(id: StringName, _surface: StringName, _tile: StringName, _chunk: int, _epoch: int) -> void: removed.append(id))
	streamer.anchor_invalidated.connect(func(id: StringName, _surface: StringName, _tile: StringName, _chunk: int, _epoch: int) -> void: invalidated.append(id))
	streamer.reconcile(Vector2(GameConfig.RUN_ORIGIN_X + 168.0 * GameConfig.TILE_SIZE, 568.0), 640.0)
	var astro_anchor: SpawnAnchor = null
	for anchor: SpawnAnchor in streamer.anchor_registry.values():
		if anchor.biome == &"astro": astro_anchor = anchor; break
	var live := astro_anchor != null and streamer.is_anchor_eligible(astro_anchor.id, int(streamer.anchor_identity(astro_anchor.id).get(&"epoch", -1)))
	if astro_anchor != null:
		var description := streamer.descriptions.get(astro_anchor.chunk_index) as ChunkDescription
		var tile := StringName(description.occupied.get(Vector2i(astro_anchor.column, astro_anchor.row + 1), {}).get(&"tile_id", &""))
		if not tile.is_empty(): streamer.invalidate_astro_tile(tile)
	var invalidated_exact := astro_anchor != null and invalidated.has(astro_anchor.id) and not streamer.is_anchor_eligible(astro_anchor.id)
	streamer.reconcile(Vector2(GameConfig.RUN_ORIGIN_X - 120.0 * GameConfig.TILE_SIZE, 568.0), 64.0)
	var retired := astro_anchor != null and removed.has(astro_anchor.id) == false # invalidated anchors must not double-remove.
	streamer.free()
	return _expect(not added.is_empty() and live and invalidated_exact and retired, "Anchor add/Astro invalidation/live eligibility or retirement lifecycle failed.")

func _astro_registration_signature(order: Array[StringName]) -> String:
	var coordinator := AstroCoordinator.new()
	var transitions: Array[String] = []
	var now := 0.0
	coordinator.cell_state_changed.connect(func(id: StringName, _epoch: int, previous: int, next: int) -> void:
		transitions.append("%s:%d>%d@%.2f" % [id, previous, next, now]))
	var rows := {&"a": 0, &"b": 1, &"c": 2}
	for id in order:
		coordinator.register_cell(id, 1, 0, int(rows[id]), 0, 32.0 + float(rows[id]) * 64.0, null)
	coordinator.arm(&"a", 1, &"top")
	for sample in [0.05, 0.12, 0.24, 0.38, 0.60]:
		now = sample
		coordinator.advance(now, true, 64.0, 320.0, 0.01, 0.01, 512.0)
	var positions: Array[String] = []
	for id in [&"a", &"b", &"c"]:
		var cell := coordinator.cells[id] as Dictionary
		positions.append("%.2f" % float(cell.get(&"fall_y", cell[&"world_y"])))
	var separation := float((coordinator.cells[&"b"] as Dictionary).get(&"fall_y", 96.0)) - float((coordinator.cells[&"a"] as Dictionary).get(&"fall_y", 32.0))
	return "%d:%d:%d|%s|sep=%.2f|%s" % [coordinator.state_for(&"a"), coordinator.state_for(&"b"), coordinator.state_for(&"c"), ",".join(positions), separation, ",".join(transitions)]

func test_m4a1_example_runtime_catalog_contract() -> String:
	var spawner := EnemySpawnerRuntime.new()
	spawner.definitions = spawner.example_definitions()
	var ids: Dictionary = {}
	var all_valid := spawner.definitions.size() == 4
	var stationary := false
	var patrol := false
	var melee_only := false
	var ranged_only := false
	var combined := false
	var particle_kind := false
	var beam_kind := false
	for definition in spawner.definitions:
		all_valid = all_valid and definition.is_valid() and not ids.has(definition.id)
		ids[definition.id] = true
		stationary = stationary or definition.movement_type == EnemyDefinitionContract.MOVEMENT_STATIONARY
		patrol = patrol or definition.movement_type == EnemyDefinitionContract.MOVEMENT_PATROL
		melee_only = melee_only or definition.melee_enabled and not definition.ranged_enabled
		ranged_only = ranged_only or definition.ranged_enabled and not definition.melee_enabled
		combined = combined or definition.melee_enabled and definition.ranged_enabled
		particle_kind = particle_kind or definition.ranged_enabled and definition.ranged_kind == EnemyDefinitionContract.RANGED_PARTICLE
		beam_kind = beam_kind or definition.ranged_enabled and definition.ranged_kind == EnemyDefinitionContract.RANGED_BEAM
	var first: EnemyDefinitionContract = spawner.select_definition(&"grass", 0, 77, &"anchor:test")
	var second: EnemyDefinitionContract = spawner.select_definition(&"grass", 0, 77, &"anchor:test")
	var deterministic: bool = first != null and second != null and first.id == second.id
	spawner.free()
	return _expect(all_valid and stationary and patrol and melee_only and ranged_only and combined and particle_kind and beam_kind and deterministic, "M4a.1 example runtime catalog coverage, attack-kind data, or deterministic selection failed.")

func test_m4a1_projectile_configuration_contract() -> String:
	var target := CharacterBody2D.new()
	var hit := DamageStatus.HitEnvelope.new(DamageStatus.DamageEvent.new(5.0, &"projectile_test"))
	var projectile := EnemyProjectileRuntime.new()
	var configured := projectile.configure(Vector2(10, 20), Vector2(3, 4), GameConfig.ENEMY_PROJECTILE_SPEED, hit, target)
	var velocity_ok := is_equal_approx(projectile.velocity.length(), GameConfig.ENEMY_PROJECTILE_SPEED)
	var origin_ok := projectile.global_position == Vector2(10, 20)
	var invalid := EnemyProjectileRuntime.new()
	var rejected := not invalid.configure(Vector2.ZERO, Vector2.ZERO, GameConfig.ENEMY_PROJECTILE_SPEED, hit, target)
	projectile.free()
	invalid.free()
	target.free()
	return _expect(configured and velocity_ok and origin_ok and rejected, "Enemy projectile configuration did not validate direction/speed/origin correctly.")

func test_m4a1_animation_cache_reference_contract() -> String:
	var loader := EnemyAnimationLoaderRuntime.new()
	var path := "res://assets/Enemies/archer-barbarian-mage/Archer Guy/PNG/PNG Sequences/Idle/Idle_000.png"
	var key := &"m4a1:shared:idle"
	var first := loader.create_animated_sprite(PackedStringArray([path]), key, &"Idle", 6.0, true)
	var second := loader.create_animated_sprite(PackedStringArray([path]), key, &"Idle", 6.0, true)
	var shared := loader.cache_stats()
	var first_release := loader.release(key)
	var mid := loader.cache_stats()
	var second_release := loader.release(key)
	var final := loader.cache_stats()
	var sprites_ok := first != null and second != null
	var active_capacity_ok := int(shared[&"max_entries"]) >= GameConfig.MAX_ACTIVE_ENEMIES and int(shared[&"max_frames"]) >= GameConfig.MAX_ACTIVE_ENEMIES * EnemyCatalogRuntime.IDLE_FRAMES_PER_VARIANT
	if first != null: first.free()
	if second != null: second.free()
	var ok: bool = sprites_ok and active_capacity_ok and int(shared[&"entries"]) == 1 and int(shared[&"references"]) == 2 and first_release and int(mid[&"references"]) == 1 and second_release and int(final[&"entries"]) == 0 and int(final[&"references"]) == 0
	return "" if ok else "animation cache sprites=%s shared=%s release1=%s mid=%s release2=%s final=%s" % [sprites_ok, shared, first_release, mid, second_release, final]


func test_m4b_catalog_inventory_and_variants() -> String:
	var definitions := EnemyCatalogRuntime.definitions()
	var expected_ids: Array[StringName] = [
		&"archer_guy", &"barbarian_warrior", &"death_knight", &"desert_nomad",
		&"evil_bald_guy", &"frost_knight", &"ghoul_hunter", &"goblin",
		&"golem", &"human_magician", &"medieval_mage", &"minotaur",
		&"monk_guy", &"ogre", &"old_guy", &"orc", &"pumpkin_head_guy",
		&"reaper_man", &"skeleton", &"skeleton_warrior", &"skull_knight",
		&"vampire", &"zombie",
	]
	expected_ids.sort()
	var ids := EnemyCatalogRuntime.identity_ids()
	var filesystem_folders: Array[String] = []
	for family in DirAccess.get_directories_at("res://assets/Enemies"):
		for costume in DirAccess.get_directories_at("res://assets/Enemies/%s" % family):
			filesystem_folders.append("%s/%s" % [family, costume])
	filesystem_folders.sort()
	var catalog_folders: Array[String] = []
	var paths_seen: Dictionary = {}
	var all_valid := definitions.size() == EnemyCatalogRuntime.CANONICAL_IDENTITY_COUNT
	for definition in definitions:
		all_valid = all_valid and definition.is_valid()
		for variant_id in definition.variant_ids():
			var frames := definition.idle_frames_for_variant(variant_id)
			all_valid = all_valid and frames.size() == EnemyCatalogRuntime.IDLE_FRAMES_PER_VARIANT
			if frames.is_empty():
				continue
			var relative := frames[0].trim_prefix("res://assets/Enemies/")
			var parts := relative.split("/")
			if parts.size() >= 2:
				catalog_folders.append("%s/%s" % [parts[0], parts[1]])
			for frame in frames:
				all_valid = all_valid and ResourceLoader.exists(frame, "Texture2D") and not paths_seen.has(frame)
				paths_seen[frame] = true
	catalog_folders.sort()
	var variants_ok := EnemyCatalogRuntime.supplied_variant_count() == EnemyCatalogRuntime.SUPPLIED_VARIANT_COUNT
	var folders_ok := filesystem_folders == catalog_folders and catalog_folders.size() == EnemyCatalogRuntime.SUPPLIED_VARIANT_COUNT
	return _expect(all_valid and ids == expected_ids and variants_ok and folders_ok, "M4b catalog identity/variant filesystem coverage failed.")

func test_m4b_biome_roster_tiers_and_effects() -> String:
	var definitions := EnemyCatalogRuntime.definitions()
	var counts: Dictionary = {}
	var first_tier: Dictionary = {}
	var later_tier: Dictionary = {}
	var status_ids: Dictionary = {}
	var non_grass_effects_ok := true
	var snow_ok := true
	var desert_ok := true
	var vampire_ok := false
	for definition in definitions:
		counts[definition.biome] = int(counts.get(definition.biome, 0)) + 1
		if definition.tier == 1:
			first_tier[definition.biome] = true
		else:
			later_tier[definition.biome] = true
		if definition.biome == &"grass":
			non_grass_effects_ok = non_grass_effects_ok and definition.effect_spec == null
			continue
		var effect: EnemyEffect = definition.effect_spec
		non_grass_effects_ok = non_grass_effects_ok and effect != null and effect.is_valid() and effect.source_id == definition.id and not status_ids.has(effect.status_id)
		if effect != null:
			status_ids[effect.status_id] = true
		if definition.biome == &"snow":
			snow_ok = snow_ok and effect != null and effect.appearance == &"freeze" and effect.movement_multiplier < 1.0
		if definition.biome == &"desert":
			desert_ok = desert_ok and effect != null and effect.periodic_damage > 0.0 and effect.tick_interval_seconds > 0.0
		if definition.id == &"vampire":
			vampire_ok = effect != null and effect.status_id == &"blood_loss" and effect.appearance == &"blood" and effect.periodic_damage > 0.0
	var roster_ok := true
	for biome in TerrainGenerator.BIOMES:
		roster_ok = roster_ok and int(counts.get(biome, 0)) > 1 and bool(first_tier.get(biome, false)) and bool(later_tier.get(biome, false))
	return _expect(roster_ok and non_grass_effects_ok and snow_ok and desert_ok and vampire_ok, "M4b biome roster, tiers, unique effects, freeze/burn, or vampire blood-loss contract failed.")

func test_m4b_scaling_and_fire_interval_defaults() -> String:
	var definitions := EnemyCatalogRuntime.definitions()
	var scaling_ok := true
	var intervals: Dictionary = {}
	var ranged_count := 0
	var stationary := false
	var patrol := false
	var melee_only := false
	var ranged_only := false
	var combined := false
	var particle := false
	var beam := false
	for definition in definitions:
		stationary = stationary or definition.movement_type == EnemyDefinitionContract.MOVEMENT_STATIONARY
		patrol = patrol or definition.movement_type == EnemyDefinitionContract.MOVEMENT_PATROL
		melee_only = melee_only or definition.melee_enabled and not definition.ranged_enabled
		ranged_only = ranged_only or definition.ranged_enabled and not definition.melee_enabled
		combined = combined or definition.melee_enabled and definition.ranged_enabled
		particle = particle or definition.ranged_enabled and definition.ranged_kind == EnemyDefinitionContract.RANGED_PARTICLE
		beam = beam or definition.ranged_enabled and definition.ranged_kind == EnemyDefinitionContract.RANGED_BEAM
		if definition.ranged_enabled:
			var interval_key := "%.3f" % definition.ranged_interval
			scaling_ok = scaling_ok and not intervals.has(interval_key)
			intervals[interval_key] = true
			ranged_count += 1
	for high in definitions:
		for low in definitions:
			if high.biome == low.biome and high.tier > low.tier:
				scaling_ok = scaling_ok and high.maximum_health > low.maximum_health and high.contact_damage > low.contact_damage
	return _expect(scaling_ok and intervals.size() == ranged_count and stationary and patrol and melee_only and ranged_only and combined and particle and beam, "M4b level scaling, distinct shooting intervals, movement, attack-mode, or ranged-kind coverage failed.")

func test_m4b_biome_visit_tier_and_variant_selection() -> String:
	var snapshot := GameConfig.terrain_snapshot()
	var seed := 618
	var counts: Dictionary = {}
	var visit_ok := true
	for encounter in 60:
		var biome := TerrainGenerator.biome_for_encounter(seed, encounter)
		var expected_visit := int(counts.get(biome, 0))
		var column := encounter * GameConfig.BIOME_INTERVAL
		visit_ok = visit_ok and TerrainGenerator.biome_visit_for_column(snapshot, seed, column) == expected_visit
		counts[biome] = expected_visit + 1
	var spawner := EnemySpawnerRuntime.new()
	spawner.definitions = EnemyCatalogRuntime.definitions()
	var first_tier_only := true
	for index in 80:
		var selected = spawner.select_definition(&"grass", 0, seed, StringName("first:%d" % index))
		first_tier_only = first_tier_only and selected != null and selected.tier == 1
	var saw_later_tier := false
	for index in 160:
		var selected = spawner.select_definition(&"grass", 1, seed, StringName("later:%d" % index))
		if selected != null and selected.tier > 1:
			saw_later_tier = true
			break
	var frost = null
	for definition in spawner.definitions:
		if definition.id == &"frost_knight":
			frost = definition
			break
	var variants_seen: Dictionary = {}
	var variant_deterministic := frost != null
	if frost != null:
		for index in 20:
			var anchor := StringName("variant:%d" % index)
			var first_variant := spawner.select_variant(frost, seed, anchor, 3)
			var second_variant := spawner.select_variant(frost, seed, anchor, 3)
			variant_deterministic = variant_deterministic and first_variant == second_variant and frost.variant_ids().has(first_variant)
			variants_seen[first_variant] = true
	spawner.free()
	return _expect(visit_ok and first_tier_only and saw_later_tier and variant_deterministic and variants_seen.size() > 1, "M4b biome-visit counting, tier gating, or deterministic variant selection failed.")

func test_m5a_collectible_catalog_values_and_assets() -> String:
	var definitions := CollectibleCatalogRuntime.definitions()
	var ids: Dictionary = {}
	var max_coin := 0
	var min_gem := 1 << 30
	var spawnable_count := 0
	var droppable_count := 0
	var health_ok := false
	var all_valid := definitions.size() == 7
	for definition in definitions:
		all_valid = all_valid and definition.is_valid() and not ids.has(definition.id) and ResourceLoader.exists(definition.asset_path, "Texture2D")
		ids[definition.id] = true
		if definition.spawnable:
			spawnable_count += 1
		if definition.droppable:
			droppable_count += 1
		if String(definition.id).begins_with("coin_"):
			max_coin = maxi(max_coin, definition.gold_value)
		elif String(definition.id).begins_with("gem_"):
			min_gem = mini(min_gem, definition.gold_value)
		elif definition.id == &"heart":
			health_ok = definition.kind == &"health" and is_equal_approx(definition.heal_amount, GameConfig.HEALTH_PICKUP_AMOUNT)
	var value_order := GameConfig.COIN_BRONZE_GOLD < GameConfig.COIN_SILVER_GOLD and GameConfig.COIN_SILVER_GOLD < GameConfig.COIN_GOLD_GOLD and max_coin < min_gem
	return _expect(all_valid and spawnable_count == 4 and droppable_count == 3 and health_ok and value_order, "M5a collectible catalog/assets or coin/gem value ordering failed.")

func test_m5a_deterministic_loot_probability_contract() -> String:
	var enemy_ids := EnemyCatalogRuntime.identity_ids()
	var configured_ids: Array[StringName] = []
	var table_ok := true
	for enemy_variant in GameConfig.ENEMY_DROP_PROBABILITIES.keys():
		var enemy_id := StringName(enemy_variant)
		configured_ids.append(enemy_id)
		var table: Dictionary = GameConfig.ENEMY_DROP_PROBABILITIES[enemy_id]
		table_ok = table_ok and table.size() == 3
		for gem_id in CollectibleCatalogRuntime.droppable_ids():
			table_ok = table_ok and table.has(gem_id) and GameConfig.validate_drop_probability(float(table[gem_id]))
	configured_ids.sort()
	var boundary_zero := not LootRollsRuntime.rolls(5, &"spawn", &"gem_blue", 0.0)
	var boundary_one := LootRollsRuntime.rolls(5, &"spawn", &"gem_blue", 1.0)
	var invalid_low := not LootRollsRuntime.rolls(5, &"spawn", &"gem_blue", -0.01)
	var invalid_high := not LootRollsRuntime.rolls(5, &"spawn", &"gem_blue", 1.01)
	var first := LootRollsRuntime.drops_for(618, &"enemy:test:1", &"vampire")
	var second := LootRollsRuntime.drops_for(618, &"enemy:test:1", &"vampire")
	var deterministic := first == second
	return _expect(table_ok and configured_ids == enemy_ids and boundary_zero and boundary_one and invalid_low and invalid_high and deterministic, "M5a deterministic loot table coverage or probability boundary failed.")

func test_m5b_weapon_catalog_axes_and_assets() -> String:
	var definitions := WeaponCatalogRuntime.definitions()
	var ids: Dictionary = {}
	var intervals: Dictionary = {}
	var damages: Dictionary = {}
	var trajectories: Dictionary = {}
	var aims: Dictionary = {}
	var target_counts: Dictionary = {}
	var all_valid := definitions.size() >= 6
	for definition: WeaponDefinitionRuntime in definitions:
		all_valid = all_valid and definition.is_valid() and not ids.has(definition.id)
		all_valid = all_valid and ResourceLoader.exists(definition.asset_path, "Texture2D") and definition.asset_path.begins_with("res://assets/Props/Weapons/")
		ids[definition.id] = true
		intervals["%.3f" % definition.fire_interval] = true
		damages["%.3f" % definition.damage] = true
		trajectories[definition.trajectory] = true
		aims[definition.aim_mode] = true
		target_counts[definition.target_count] = true
	var axes_ok := trajectories.has(WeaponDefinitionRuntime.TRAJECTORY_STRAIGHT) and trajectories.has(WeaponDefinitionRuntime.TRAJECTORY_BALLISTIC)
	axes_ok = axes_ok and aims.has(WeaponDefinitionRuntime.AIM_DIRECTED) and aims.has(WeaponDefinitionRuntime.AIM_RANDOM) and aims.has(WeaponDefinitionRuntime.AIM_DETERMINED) and aims.has(WeaponDefinitionRuntime.AIM_FORWARD)
	axes_ok = axes_ok and target_counts.has(1) and target_counts.keys().max() > 1
	return _expect(all_valid and intervals.size() == definitions.size() and damages.size() > 1 and axes_ok, "M5b weapon catalog asset/damage/interval/trajectory/aim/target-count coverage failed.")

func test_m5b_targeting_policy_modes_and_multitarget() -> String:
	var origin := Vector2(100, 100)
	var targets: Array[Vector2] = [Vector2(300, 40), Vector2(340, 100), Vector2(320, 170)]
	var triple := WeaponCatalogRuntime.by_id(&"triple_mage")
	var directed := WeaponTargetingPolicyRuntime.directions_for(triple, origin, targets, 618, 0)
	var distinct: Dictionary = {}
	for direction in directed:
		distinct["%.4f,%.4f" % [direction.x, direction.y]] = true
	var directed_ok := directed.size() == 3 and distinct.size() == 3
	var shuriken := WeaponCatalogRuntime.by_id(&"shuriken_pair")
	var random_a := WeaponTargetingPolicyRuntime.directions_for(shuriken, origin, targets, 777, 3)
	var random_b := WeaponTargetingPolicyRuntime.directions_for(shuriken, origin, targets, 777, 3)
	var random_ok := random_a == random_b and random_a.size() == 2
	var forward := WeaponTargetingPolicyRuntime.directions_for(WeaponCatalogRuntime.by_id(&"forward_blade"), origin, targets, 1, 0)
	var forward_ok := forward == [Vector2.RIGHT]
	var determined_def := WeaponCatalogRuntime.by_id(&"determined_blade")
	var determined := WeaponTargetingPolicyRuntime.directions_for(determined_def, origin, targets, 1, 0)
	var determined_ok := determined.size() == 1 and determined[0].is_equal_approx(determined_def.determined_direction.normalized())
	var ballistic := WeaponTargetingPolicyRuntime.directions_for(WeaponCatalogRuntime.by_id(&"mage_arc"), origin, [Vector2(360, 100)], 1, 0)
	var ballistic_ok := ballistic.size() == 1 and ballistic[0].is_finite() and ballistic[0].x > 0.0 and ballistic[0].y < 0.0
	var none := WeaponTargetingPolicyRuntime.directions_for(triple, origin, [], 1, 0)
	return _expect(directed_ok and random_ok and forward_ok and determined_ok and ballistic_ok and none.is_empty(), "M5b targeting policy determinism, no-target, multi-target, aim-mode, or ballistic contract failed.")

func test_m5b_weapon_equipment_and_shooting_unlock_boundary() -> String:
	var profile := ProfileState.new()
	var controller := WeaponControllerRuntime.new()
	controller.profile = profile
	var locked := not controller.shooting_available()
	profile.abilities.unlock(AbilityEligibility.SHOOTING)
	var unlocked_not_equipped := not controller.shooting_available()
	var ability_equipped := profile.abilities.equip(AbilityEligibility.SHOOTING)
	var available := controller.shooting_available()
	var ids := WeaponCatalogRuntime.ids()
	var equip_ok := ids.size() > GameConfig.NUM_EQUIPPABLE_WEAPONS
	for index in range(GameConfig.NUM_EQUIPPABLE_WEAPONS):
		profile.weapons.unlock(ids[index])
		equip_ok = equip_ok and profile.weapons.equip(ids[index])
	var overflow_id := ids[GameConfig.NUM_EQUIPPABLE_WEAPONS]
	profile.weapons.unlock(overflow_id)
	var overflow_blocked := not profile.weapons.equip(overflow_id)
	var valid := profile.is_valid()
	controller.free()
	return _expect(locked and unlocked_not_equipped and ability_equipped and available and equip_ok and overflow_blocked and valid, "M5b Shooting unlock/equip boundary or weapon equipment capacity failed.")

func test_m6a_ability_catalog_levels_and_triggers() -> String:
	var definitions: Array[AbilityDefinitionRuntime] = AbilityCatalogRuntime.definitions()
	var ids: Dictionary = {}
	var jump_trigger_count: int = 0
	var slot_trigger_count: int = 0
	var cooldown_exempt: Dictionary = {}
	var all_valid: bool = definitions.size() == 10
	for definition: AbilityDefinitionRuntime in definitions:
		all_valid = all_valid and definition.is_valid() and not ids.has(definition.id)
		ids[definition.id] = true
		if definition.trigger == AbilityDefinitionRuntime.TRIGGER_JUMP:
			jump_trigger_count += 1
		else:
			slot_trigger_count += 1
		cooldown_exempt[definition.id] = definition.cooldown_exempt
	var levels_ok: bool = AbilityCatalogRuntime.by_id(&"jump").max_level == 3 and AbilityCatalogRuntime.by_id(&"climb").max_level == 2
	levels_ok = levels_ok and AbilityCatalogRuntime.by_id(&"glide").max_level == 1 and AbilityCatalogRuntime.by_id(&"fly").max_level == 1
	var exemptions_ok: bool = true
	for ability_id in [&"jump", &"climb", &"glide", &"fly"]:
		exemptions_ok = exemptions_ok and bool(cooldown_exempt.get(ability_id, false))
	for ability_id in [&"reverse_gravity", &"dash", &"shooting", &"explode", &"slow_down_time", &"invisibility"]:
		exemptions_ok = exemptions_ok and not bool(cooldown_exempt.get(ability_id, true))
	return _expect(all_valid and ids.size() == 10 and jump_trigger_count == 5 and slot_trigger_count == 5 and levels_ok and exemptions_ok, "M6a ability catalog count/levels/triggers/cooldown taxonomy failed.")

func test_m6a_profile_ability_progress_contract() -> String:
	var profile := ProfileState.new()
	var default_jump: bool = bool(profile.abilities.unlocked.get(&"jump", false)) and profile.ability_level(&"jump") == 1 and is_zero_approx(profile.ability_cooldown(&"jump"))
	var jump_level_ok: bool = profile.set_ability_level(&"jump", 3) and profile.ability_level(&"jump") == 3 and not profile.set_ability_level(&"jump", 4)
	var dash_unlocked: bool = ProfileCommands.unlock_ability(profile, &"dash")
	var dash_default: bool = profile.ability_level(&"dash") == 1 and is_equal_approx(profile.ability_cooldown(&"dash"), GameConfig.COOLDOWN_PERIOD)
	var cooldown_bounds: bool = profile.set_ability_cooldown(&"dash", GameConfig.MIN_ABILITY_COOLDOWN) and is_equal_approx(profile.ability_cooldown(&"dash"), GameConfig.MIN_ABILITY_COOLDOWN)
	cooldown_bounds = cooldown_bounds and not profile.set_ability_cooldown(&"dash", GameConfig.MIN_ABILITY_COOLDOWN - 0.01) and not profile.set_ability_cooldown(&"jump", GameConfig.COOLDOWN_PERIOD)
	var unknown_blocked: bool = not ProfileCommands.unlock_ability(profile, &"not_an_ability")
	return _expect(default_jump and jump_level_ok and dash_unlocked and dash_default and cooldown_bounds and unknown_blocked and profile.is_valid(), "M6a profile default unlock, levels, or per-ability cooldown contract failed.")

func test_m6a_cooldown_and_action_router_contract() -> String:
	var profile := ProfileState.new()
	ProfileCommands.unlock_and_equip_ability(profile, &"jump")
	ProfileCommands.unlock_and_equip_ability(profile, &"dash")
	ProfileCommands.unlock_and_equip_ability(profile, &"shooting")
	var auxiliary: Array[StringName] = AbilityActionRouterRuntime.auxiliary_equipped(profile)
	var jump_family: Array[StringName] = AbilityActionRouterRuntime.jump_family_equipped(profile)
	var routing_ok: bool = auxiliary == [&"dash", &"shooting"] and jump_family == [&"jump"]
	routing_ok = routing_ok and AbilityActionRouterRuntime.ability_for_slot(profile, 0) == &"dash" and AbilityActionRouterRuntime.ability_for_slot(profile, 1) == &"shooting" and AbilityActionRouterRuntime.ability_for_slot(profile, 2).is_empty()
	var state := AbilityCooldownStateRuntime.new()
	var dash_ready: bool = state.can_activate(&"dash", 0.0, profile) and state.commit_activation(&"dash", 0.0, profile)
	var dash_blocked: bool = not state.can_activate(&"dash", GameConfig.COOLDOWN_PERIOD - 0.01, profile)
	var dash_exact: bool = state.can_activate(&"dash", GameConfig.COOLDOWN_PERIOD, profile)
	var remaining_ok: bool = is_equal_approx(state.remaining(&"dash", 1.0, profile), GameConfig.COOLDOWN_PERIOD - 1.0)
	var jump_exempt: bool = state.can_activate(&"jump", 0.0, profile) and state.commit_activation(&"jump", 0.0, profile) and state.can_activate(&"jump", 0.0, profile) and is_zero_approx(state.remaining(&"jump", 0.0, profile))
	return _expect(routing_ok and dash_ready and dash_blocked and dash_exact and remaining_ok and jump_exempt, "M6a transient cooldown boundary or auxiliary/jump-family routing failed.")

func test_m6c_duration_stats_unlock_and_bounds() -> String:
	var profile := ProfileState.new()
	var locked := is_zero_approx(profile.active_invisibility_duration()) and is_zero_approx(profile.active_slow_down_duration())
	locked = locked and not profile.set_invisibility_duration(GameConfig.MIN_INVISIBILITY_DURATION) and not profile.set_slow_down_duration(GameConfig.MIN_SLOW_DOWN_DURATION)
	var invis_unlocked := ProfileCommands.unlock_ability(profile, &"invisibility")
	var slow_unlocked := ProfileCommands.unlock_ability(profile, &"slow_down_time")
	var defaults := is_equal_approx(profile.active_invisibility_duration(), GameConfig.DEFAULT_INVISIBILITY_DURATION) and is_equal_approx(profile.active_slow_down_duration(), GameConfig.DEFAULT_SLOW_DOWN_DURATION)
	var invis_bounds := profile.set_invisibility_duration(GameConfig.MAX_INVISIBILITY_DURATION) and not profile.set_invisibility_duration(GameConfig.MAX_INVISIBILITY_DURATION + 0.01)
	var slow_bounds := profile.set_slow_down_duration(GameConfig.MAX_SLOW_DOWN_DURATION) and not profile.set_slow_down_duration(GameConfig.MAX_SLOW_DOWN_DURATION + 0.01)
	return _expect(locked and invis_unlocked and slow_unlocked and defaults and invis_bounds and slow_bounds and profile.is_valid(), "M6c duration stat unlock gating or configured bounds failed.")

func test_m6c_dynamic_enemy_and_shooting_cooldown_bridge() -> String:
	var spawner := EnemySpawnerRuntime.new()
	var target := PlayerController.new()
	spawner.target = target
	spawner.interval_multiplier = 1.0
	spawner.target_visibility_resolver = func() -> bool: return false
	spawner.interval_multiplier_resolver = func() -> float: return 1.5
	var hidden := not spawner._target_is_visible()
	var dynamic_interval := is_equal_approx(spawner._current_interval_multiplier(), 1.5)
	spawner.target_visibility_resolver = func() -> bool: return true
	var visible := spawner._target_is_visible()
	var profile := ProfileState.new()
	ProfileCommands.unlock_and_equip_ability(profile, AbilityEligibility.SHOOTING)
	profile.set_ability_cooldown(AbilityEligibility.SHOOTING, GameConfig.MIN_ABILITY_COOLDOWN)
	var controller := WeaponControllerRuntime.new()
	controller.profile = profile
	controller.director = Director.new()
	var first := controller.activate_shooting()
	controller.deactivate_shooting()
	controller.director.simulation_time = GameConfig.MIN_ABILITY_COOLDOWN - 0.01
	var early_blocked := not controller.activate_shooting()
	controller.director.simulation_time = GameConfig.MIN_ABILITY_COOLDOWN
	var exact := controller.activate_shooting()
	controller.free()
	spawner.free()
	target.free()
	return _expect(hidden and visible and dynamic_interval and first and early_blocked and exact, "M6c dynamic enemy resolver or Shooting profile cooldown bridge failed.")

func test_m7_character_catalog_assets_and_prices() -> String:
	var definitions := CharacterCatalogRuntime.definitions()
	var ids: Dictionary = {}
	var all_valid := definitions.size() == CharacterCatalogRuntime.COUNT
	var previous_cost := -1
	for definition in definitions:
		all_valid = all_valid and definition.is_valid() and not ids.has(definition.id)
		ids[definition.id] = true
		if definition.id == CharacterCatalogRuntime.DEFAULT_ID:
			all_valid = all_valid and definition.unlock_cost == 0
		else:
			all_valid = all_valid and definition.unlock_cost >= GameConfig.CHARACTER_UNLOCK_BASE_GOLDS and definition.unlock_cost > previous_cost
		previous_cost = definition.unlock_cost
	return _expect(all_valid and ids.size() == 45, "M7 character catalog did not cover all 45 supplied character assets with valid prices.")

func test_m7_save_roundtrip_persistent_only() -> String:
	var profile := ProfileState.new()
	profile.gold = 4321
	profile.revival_potions = 3
	profile.unlocked_characters[&"2"] = true
	profile.selected_character = &"2"
	profile.maximum_health = 170
	profile.defense_multiplier = 0.75
	profile.melee_power = 25
	profile.enemy_fire_interval_multiplier = 1.4
	profile.initialize_ability_progress(&"shooting")
	profile.initialize_ability_progress(&"invisibility")
	profile.abilities.equip(&"shooting")
	profile.ability_cooldowns[&"shooting"] = 5.5
	profile.invisibility_duration = 4.0
	profile.weapons.unlock(&"arrow")
	profile.weapons.equip(&"arrow")
	profile.mobile_auxiliary_button_corner = &"bottom_left"
	var data := SaveServiceRuntime.profile_to_data(profile)
	var transient_absent := not data.has("health") and not data.has("distance_tiles") and not data.has("statuses") and not data.has("simulation_time")
	var path := "user://m7_roundtrip_test.json"
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(absolute)
	var saved := SaveServiceRuntime.save_profile(profile, path)
	var loaded := SaveServiceRuntime.load_profile(path)
	var roundtrip: bool = loaded.is_valid() and loaded.gold == 4321 and loaded.revival_potions == 3 and loaded.selected_character == &"2" and loaded.maximum_health == 170 and is_equal_approx(loaded.defense_multiplier, 0.75) and loaded.melee_power == 25 and is_equal_approx(loaded.enemy_fire_interval_multiplier, 1.4) and loaded.abilities.unlocked.get(&"shooting", false) and &"shooting" in loaded.abilities.equipped and is_equal_approx(loaded.ability_cooldown(&"shooting"), 5.5) and loaded.weapons.unlocked.get(&"arrow", false) and &"arrow" in loaded.weapons.equipped and loaded.mobile_auxiliary_button_corner == &"bottom_left"
	var clean := not FileAccess.file_exists(absolute + ".tmp") and not FileAccess.file_exists(absolute + ".bak")
	DirAccess.remove_absolute(absolute)
	return _expect(saved and roundtrip and transient_absent and clean, "M7 save roundtrip, persistent-only schema, or temp/backup cleanup failed.")

func test_m7_save_migration_and_corrupt_recovery() -> String:
	var legacy := {
		"schema_version": 0,
		"gold": 77,
		"potions": 2,
		"character": "2",
		"unlocked_characters": ["2"],
		"stats": {"maximum_health": 9999, "defense_multiplier": -3.0},
	}
	var migrated := SaveServiceRuntime.data_to_profile(legacy)
	var migration_ok: bool = migrated.is_valid() and migrated.gold == 77 and migrated.revival_potions == 2 and migrated.selected_character == &"2" and migrated.unlocked_characters.get(&"2", false) and migrated.maximum_health == GameConfig.MAX_MAXIMUM_HEALTH and is_equal_approx(migrated.defense_multiplier, GameConfig.MIN_DEFENSE)
	var unsupported := SaveServiceRuntime.data_to_profile({"schema_version": GameConfig.PROFILE_SCHEMA_VERSION + 1, "gold": 999})
	var version_ok := unsupported.is_valid() and unsupported.gold == 0 and unsupported.selected_character == CharacterCatalogRuntime.DEFAULT_ID
	var malformed := SaveServiceRuntime.data_to_profile({"schema_version": GameConfig.PROFILE_SCHEMA_VERSION, "gold": 12, "stats": [], "abilities": "bad", "weapons": 7, "settings": null})
	var malformed_ok := malformed.is_valid() and malformed.gold == 12 and malformed.selected_character == CharacterCatalogRuntime.DEFAULT_ID
	var invalid_weapon := ProfileState.new()
	invalid_weapon.initialize_ability_progress(AbilityEligibility.SHOOTING)
	invalid_weapon.weapons.unlock(&"not_a_weapon")
	var catalog_validation_ok := not invalid_weapon.is_valid() and SaveServiceRuntime.profile_to_data(invalid_weapon).is_empty()
	var path := "user://m7_corrupt_test.json"
	var absolute := ProjectSettings.globalize_path(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{ definitely-not-json")
	file.close()
	var recovered := SaveServiceRuntime.load_profile(path)
	var corrupt_ok := recovered.is_valid() and recovered.gold == 0 and recovered.selected_character == CharacterCatalogRuntime.DEFAULT_ID
	DirAccess.remove_absolute(absolute)
	return _expect(migration_ok and version_ok and malformed_ok and catalog_validation_ok and corrupt_ok, "M7 migration/defaulting, malformed-shape/catalog validation, unsupported schema fallback, or corrupt-save recovery failed.")

func test_m7_shop_purchase_atomicity_and_gates() -> String:
	var profile := ProfileState.new()
	profile.gold = 2000
	var notifications := [0]
	profile.changed.connect(func() -> void: notifications[0] += 1)
	var char_cost := CharacterCatalogRuntime.by_id(&"2").unlock_cost
	var char_bought := ProfileShopRuntime.purchase_character(profile, &"2")
	var char_selected := ProfileShopRuntime.select_character(profile, &"2")
	var potion_bought := ProfileShopRuntime.purchase_revival_potion(profile)
	var weapon_before_shooting := not ProfileShopRuntime.purchase_weapon(profile, &"arrow")
	var shooting_bought := ProfileShopRuntime.purchase_ability(profile, &"shooting")
	var weapon_bought := ProfileShopRuntime.purchase_weapon(profile, &"arrow")
	var expected_gold := 2000 - char_cost - GameConfig.REVIVAL_POTION_GOLDS - GameConfig.ABILITY_UNLOCK_GOLDS - GameConfig.WEAPON_UNLOCK_GOLDS
	var atomic: bool = profile.gold == expected_gold and profile.revival_potions == 1 and profile.selected_character == &"2" and profile.abilities.unlocked.get(&"shooting", false) and profile.weapons.unlocked.get(&"arrow", false)
	var before_reject := profile.gold
	var duplicate_rejected := not ProfileShopRuntime.purchase_character(profile, &"2") and not ProfileShopRuntime.purchase_ability(profile, &"shooting") and not ProfileShopRuntime.purchase_weapon(profile, &"arrow") and profile.gold == before_reject
	var poor := ProfileState.new()
	poor.gold = GameConfig.REVIVAL_POTION_GOLDS - 1
	var poor_before := poor.gold
	var insufficient := not ProfileShopRuntime.purchase_revival_potion(poor) and poor.gold == poor_before and poor.revival_potions == 0
	return _expect(char_bought and char_selected and potion_bought and weapon_before_shooting and shooting_bought and weapon_bought and atomic and duplicate_rejected and insufficient and notifications[0] == 5 and profile.is_valid(), "M7 purchase affordability, gates, duplicate rejection, or atomic notifications failed.")

func test_m7_stat_and_cooldown_upgrade_boundaries() -> String:
	var profile := ProfileState.new()
	profile.gold = 100000
	var stat_specs: Array = [
		[ProfileShopRuntime.STAT_MAXIMUM_HEALTH, "maximum_health", GameConfig.MAX_MAXIMUM_HEALTH],
		[ProfileShopRuntime.STAT_DEFENSE, "defense_multiplier", GameConfig.MIN_DEFENSE],
		[ProfileShopRuntime.STAT_MELEE_POWER, "melee_power", GameConfig.MAX_MELEE_POWER],
		[ProfileShopRuntime.STAT_ENEMY_FIRE_RATE, "enemy_fire_interval_multiplier", GameConfig.MAX_ENEMY_FIRE_RATE],
	]
	var core_stats_ok := true
	for spec in stat_specs:
		var steps := 0
		while ProfileShopRuntime.upgrade_stat(profile, spec[0]):
			steps += 1
		var gold_at_bound := profile.gold
		var value: Variant = profile.get(spec[1])
		var at_bound := is_equal_approx(float(value), float(spec[2]))
		core_stats_ok = core_stats_ok and steps > 0 and at_bound and not ProfileShopRuntime.upgrade_stat(profile, spec[0]) and profile.gold == gold_at_bound

	var locked_durations := not ProfileShopRuntime.upgrade_stat(profile, ProfileShopRuntime.STAT_INVISIBILITY_DURATION) and not ProfileShopRuntime.upgrade_stat(profile, ProfileShopRuntime.STAT_SLOW_DOWN_DURATION)
	var invis_unlocked := ProfileShopRuntime.purchase_ability(profile, &"invisibility")
	var slow_unlocked := ProfileShopRuntime.purchase_ability(profile, &"slow_down_time")
	while ProfileShopRuntime.upgrade_stat(profile, ProfileShopRuntime.STAT_INVISIBILITY_DURATION):
		pass
	while ProfileShopRuntime.upgrade_stat(profile, ProfileShopRuntime.STAT_SLOW_DOWN_DURATION):
		pass
	var duration_gold := profile.gold
	var durations_ok := invis_unlocked and slow_unlocked and is_equal_approx(profile.invisibility_duration, GameConfig.MAX_INVISIBILITY_DURATION) and is_equal_approx(profile.slow_down_duration, GameConfig.MAX_SLOW_DOWN_DURATION) and not ProfileShopRuntime.upgrade_stat(profile, ProfileShopRuntime.STAT_INVISIBILITY_DURATION) and not ProfileShopRuntime.upgrade_stat(profile, ProfileShopRuntime.STAT_SLOW_DOWN_DURATION) and profile.gold == duration_gold

	var cooldowns_ok := true
	for definition in AbilityCatalogRuntime.definitions():
		if definition.cooldown_exempt:
			continue
		if not profile.abilities.unlocked.get(definition.id, false):
			cooldowns_ok = cooldowns_ok and ProfileShopRuntime.purchase_ability(profile, definition.id)
		var steps := 0
		while ProfileShopRuntime.upgrade_ability_cooldown(profile, definition.id):
			steps += 1
		var gold_at_bound := profile.gold
		cooldowns_ok = cooldowns_ok and steps > 0 and is_equal_approx(profile.ability_cooldown(definition.id), GameConfig.MIN_ABILITY_COOLDOWN) and not ProfileShopRuntime.upgrade_ability_cooldown(profile, definition.id) and profile.gold == gold_at_bound

	var jump_before := profile.ability_level(&"jump")
	var level_upgrade := ProfileShopRuntime.upgrade_ability_level(profile, &"jump") and profile.ability_level(&"jump") == jump_before + 1
	while ProfileShopRuntime.upgrade_ability_level(profile, &"jump"):
		pass
	var level_gold := profile.gold
	var level_bound := profile.ability_level(&"jump") == AbilityCatalogRuntime.by_id(&"jump").max_level and not ProfileShopRuntime.upgrade_ability_level(profile, &"jump") and profile.gold == level_gold
	return _expect(core_stats_ok and locked_durations and durations_ok and cooldowns_ok and level_upgrade and level_bound and profile.gold >= 0 and profile.is_valid(), "M7 stat/level/cooldown upgrade direction, unlock gate, bound, or no-charge-at-bound failed.")

func test_m10_enemy_placeholders_and_mobile_release_config() -> String:
	var definitions := EnemyCatalogRuntime.definitions()
	var centralized := definitions.size() == EnemyCatalogRuntime.CANONICAL_IDENTITY_COUNT and GameConfig.ENEMY_SHOOTING_INTERVALS.size() == definitions.size() and GameConfig.ENEMY_VICINITY_TILES.size() == definitions.size()
	for definition in definitions:
		centralized = centralized and GameConfig.ENEMY_SHOOTING_INTERVALS.has(definition.id) and GameConfig.ENEMY_VICINITY_TILES.has(definition.id)
		centralized = centralized and is_equal_approx(definition.ranged_interval, GameConfig.enemy_shooting_interval(definition.id)) and is_equal_approx(definition.vicinity_tiles, GameConfig.enemy_vicinity_tiles(definition.id))
	var mobile_renderer := String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")) == "mobile"
	var caps := GameConfig.MAX_ACTIVE_ENEMIES > 0 and GameConfig.MAX_ACTIVE_DROPS > 0 and GameConfig.MAX_ACTIVE_WEAPON_PROJECTILES > 0 and GameConfig.TERRAIN_ACTIVE_AHEAD_CHUNKS > 0
	return _expect(centralized and mobile_renderer and caps and GameConfig.validate_defaults().is_empty(), "M10 release config lost centralized enemy placeholders, mobile renderer, caps, or default validation.")

func test_m9_touch_gesture_classification() -> String:
	var tap := TouchGestureRouterRuntime.classify_gesture(Vector2(100, 100), Vector2(108, 112), 28.0, 72.0)
	var swipe := TouchGestureRouterRuntime.classify_gesture(Vector2(100, 100), Vector2(118, 190), 28.0, 72.0)
	var horizontal := TouchGestureRouterRuntime.classify_gesture(Vector2(100, 100), Vector2(210, 125), 28.0, 72.0)
	var short_drag := TouchGestureRouterRuntime.classify_gesture(Vector2(100, 100), Vector2(125, 140), 28.0, 72.0)
	return _expect(tap == &"touch_tap_jump" and swipe == &"touch_swipe_roll" and horizontal.is_empty() and short_drag.is_empty(), "M9 touch gesture classifier confused tap/swipe/non-action boundaries.")

func test_m8_profile_ui_command_boundaries() -> String:
	var profile := ProfileState.new()
	profile.gold = 5000
	var notices := [0]
	profile.changed.connect(func() -> void: notices[0] += 1)
	var dash_bought := ProfileShopRuntime.purchase_ability(profile, &"dash")
	var dash_equipped := ProfileShopRuntime.set_ability_equipped(profile, &"dash", true)
	var duplicate_blocked := not ProfileShopRuntime.set_ability_equipped(profile, &"dash", true)
	var reverse_bought := ProfileShopRuntime.purchase_ability(profile, &"reverse_gravity")
	var exclusion_blocked := not ProfileShopRuntime.set_ability_equipped(profile, &"reverse_gravity", true)
	var shooting_bought := ProfileShopRuntime.purchase_ability(profile, &"shooting")
	var arrow_bought := ProfileShopRuntime.purchase_weapon(profile, &"arrow")
	var arrow_equipped := ProfileShopRuntime.set_weapon_equipped(profile, &"arrow", true)
	var invalid_weapon_blocked := not ProfileShopRuntime.set_weapon_equipped(profile, &"not_a_weapon", true)
	var corner_changed := ProfileShopRuntime.set_mobile_auxiliary_button_corner(profile, &"bottom_left")
	var invalid_corner_blocked := not ProfileShopRuntime.set_mobile_auxiliary_button_corner(profile, &"middle")
	var valid: bool = profile.is_valid() and &"dash" in profile.abilities.equipped and &"arrow" in profile.weapons.equipped and profile.mobile_auxiliary_button_corner == &"bottom_left"
	return _expect(dash_bought and dash_equipped and duplicate_blocked and reverse_bought and exclusion_blocked and shooting_bought and arrow_bought and arrow_equipped and invalid_weapon_blocked and corner_changed and invalid_corner_blocked and valid and notices[0] == 7, "M8 UI command boundary allowed invalid state or emitted the wrong transaction notifications.")

func test_m7_profile_stats_apply_to_new_run() -> String:
	var profile := ProfileState.new()
	profile.maximum_health = 180
	profile.defense_multiplier = 0.65
	var director := Director.new()
	director.run.advance_distance(7.0)
	director.run.add_earned_gold(99)
	var applied := director.apply_profile_stats(profile)
	var stats_ok := applied and is_equal_approx(director.run.health_owner.maximum_health, 180.0) and is_equal_approx(director.run.health_owner.current_health, 180.0) and is_equal_approx(director.run.health_owner.defense_multiplier, 0.65)
	var transient_preserved := is_equal_approx(director.run.distance_tiles, 7.0) and director.run.earned_gold == 99
	var data := SaveServiceRuntime.profile_to_data(profile)
	var separation := not data.has("distance_tiles") and not data.has("earned_gold") and not data.has("health_owner")
	return _expect(stats_ok and transient_preserved and separation, "M7 profile stat application or run/profile separation failed.")
