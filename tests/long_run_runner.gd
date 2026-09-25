extends SceneTree
## M10 deterministic release smoke. This stays separate from the physics-heavy
## integration suite so long-run generation/persistence checks remain fast and
## fail-closed.

const TerrainGeneratorRuntime = preload("res://scripts/terrain/terrain_generator.gd")
const EnemySpawnerRuntime = preload("res://scripts/enemies/enemy_spawner.gd")
const EnemyCatalogRuntime = preload("res://scripts/enemies/enemy_catalog.gd")
const LootRollsRuntime = preload("res://scripts/models/loot_rolls.gd")
const ProfileRuntime = preload("res://scripts/models/profile_state.gd")
const SaveServiceRuntime = preload("res://scripts/models/save_service.gd")
const AbilityCatalogRuntime = preload("res://scripts/abilities/ability_catalog.gd")
const AbilityCooldownRuntime = preload("res://scripts/abilities/ability_cooldown_state.gd")
const DirectorRuntime = preload("res://scripts/models/run_director.gd")
const GameClockRuntime = preload("res://scripts/core/game_clock.gd")
const DamageStatusRuntime = preload("res://scripts/models/damage_status.gd")
const EnemyAnimationLoaderRuntime = preload("res://scripts/enemies/enemy_animation_loader.gd")

const EXPECTED_CASES := 3
const LONG_CHUNKS := 180
const LONG_ENCOUNTERS := 72
const SEED := 24681357

var scheduled := 0
var executed := 0
var passed := 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_run_case("terrain_enemy_loot_determinism", _test_terrain_enemy_loot_determinism)
	_run_case("ability_revival_persistence", _test_ability_revival_persistence)
	_run_case("release_configuration_and_lazy_assets", _test_release_configuration_and_lazy_assets)
	if scheduled != EXPECTED_CASES or executed != EXPECTED_CASES:
		failures.append("scheduled %d / executed %d / expected %d" % [scheduled, executed, EXPECTED_CASES])
	for failure in failures:
		push_error("LONG-RUN FAIL %s" % failure)
	print("LONG-RUN RESULT: %d passed, %d failed (%d scheduled, %d executed)" % [passed, failures.size(), scheduled, executed])
	quit(0 if failures.is_empty() else 1)

func _run_case(name: String, test: Callable) -> void:
	scheduled += 1
	var failure: String = test.call()
	executed += 1
	if failure.is_empty():
		passed += 1
		print("PASS long_run_%s" % name)
	else:
		failures.append("%s: %s" % [name, failure])

func _test_terrain_enemy_loot_determinism() -> String:
	var first := _long_signature(SEED)
	if first.has("error"):
		return String(first["error"])
	var second := _long_signature(SEED)
	if second.has("error"):
		return String(second["error"])
	if first != second:
		return "Same-seed long-run terrain/enemy/loot fingerprint changed between passes."
	var biomes: Array = first["biomes"]
	var hazards: Array = first["hazards"]
	var tiers: Array = first["tiers"]
	var forms: Array = first["forms"]
	if biomes.size() != 6:
		return "Long run did not cover all six biomes: %s" % [biomes]
	for required in [&"desert_flame_candidate", &"astro_fall_candidate", &"fort_spike_candidate"]:
		if not required in hazards:
			return "Long run did not cover hazard type %s." % required
	for tier in [1, 2, 3]:
		if not tier in tiers:
			return "Long run did not cover enemy tier %d." % tier
	for form in [&"platform", &"mountain", &"cave"]:
		if not form in forms:
			return "Long run did not cover terrain form %s." % form
	return ""

func _long_signature(seed: int) -> Dictionary:
	var snapshot := GameConfig.terrain_snapshot()
	var biomes := {}
	var hazards := {}
	var forms := {}
	var terrain_parts := PackedStringArray()
	for chunk_index in LONG_CHUNKS:
		var description = TerrainGeneratorRuntime.generate(snapshot, GameConfig.TERRAIN_VERSION, seed, chunk_index)
		if description == null or not description.is_valid():
			return {"error": "Invalid generated chunk %d during long run." % chunk_index}
		terrain_parts.append(str(description.stable_signature().hash()))
		forms[description.form] = true
		for column in range(description.x_begin, description.x_end):
			var biome := StringName(description.biome_at_column.get(column, &""))
			if biome.is_empty():
				return {"error": "Generated chunk %d lost biome ownership." % chunk_index}
			biomes[biome] = true
		for hazard in description.hazards:
			hazards[hazard.type] = true

	var spawner := EnemySpawnerRuntime.new()
	spawner.definitions = EnemyCatalogRuntime.definitions()
	var tiers := {}
	var enemy_parts := PackedStringArray()
	for definition in spawner.definitions:
		if definition == null or not definition.is_valid():
			spawner.free()
			return {"error": "Long run encountered invalid enemy definition."}
		tiers[definition.tier] = true
		var spawn_id := StringName("long:%s" % definition.id)
		var first_drops := LootRollsRuntime.drops_for(seed, spawn_id, definition.id)
		var second_drops := LootRollsRuntime.drops_for(seed, spawn_id, definition.id)
		if first_drops != second_drops:
			spawner.free()
			return {"error": "Loot roll changed for %s at fixed seed/spawn." % definition.id}
		var drop_names := PackedStringArray()
		for drop_id: StringName in first_drops:
			drop_names.append(String(drop_id))
		enemy_parts.append("%s:%d:%s" % [definition.id, definition.tier, ",".join(drop_names)])

	var selection_parts := PackedStringArray()
	for encounter in LONG_ENCOUNTERS:
		var biome := TerrainGeneratorRuntime.biome_for_encounter(seed, encounter)
		var visit := TerrainGeneratorRuntime.biome_visit_for_encounter(seed, encounter)
		var anchor_id := StringName("long_anchor_%d" % encounter)
		var selected = spawner.select_definition(biome, visit, seed, anchor_id)
		if selected == null or selected.biome != biome or selected.tier > visit + 1:
			spawner.free()
			return {"error": "Enemy selection violated biome/tier gating at encounter %d." % encounter}
		selection_parts.append("%d:%s:%d:%s" % [encounter, biome, visit, selected.id])
	spawner.free()

	return {
		"terrain": "|".join(terrain_parts),
		"enemies": "|".join(enemy_parts),
		"selections": "|".join(selection_parts),
		"biomes": _sorted_keys(biomes),
		"hazards": _sorted_keys(hazards),
		"forms": _sorted_keys(forms),
		"tiers": _sorted_int_keys(tiers),
	}

func _test_ability_revival_persistence() -> String:
	for definition in AbilityCatalogRuntime.definitions():
		var ability_profile := ProfileRuntime.new()
		if definition.id != &"jump" and not ability_profile.initialize_ability_progress(definition.id):
			return "Could not initialize ability %s." % definition.id
		if definition.id == &"reverse_gravity":
			ability_profile.abilities.unequip(&"jump")
		if not definition.id in ability_profile.abilities.equipped and not ability_profile.abilities.equip(definition.id):
			return "Could not equip ability %s for release smoke." % definition.id
		var cooldown := AbilityCooldownRuntime.new()
		if definition.cooldown_exempt:
			if not cooldown.commit_activation(definition.id, 0.0, ability_profile) or not cooldown.commit_activation(definition.id, 0.0, ability_profile):
				return "Cooldown-exempt ability %s was not reusable immediately." % definition.id
		else:
			var period := ability_profile.ability_cooldown(definition.id)
			if not cooldown.commit_activation(definition.id, 0.0, ability_profile):
				return "Ability %s did not activate initially." % definition.id
			if cooldown.can_activate(definition.id, period - 0.001, ability_profile):
				return "Ability %s ignored its cooldown boundary." % definition.id
			if not cooldown.commit_activation(definition.id, period, ability_profile):
				return "Ability %s failed at exact cooldown boundary." % definition.id

	var profile := ProfileRuntime.new()
	profile.gold = 12345
	profile.revival_potions = 2
	profile.maximum_health = 180
	profile.defense_multiplier = 0.65
	profile.unlocked_characters[&"2"] = true
	profile.selected_character = &"2"
	profile.initialize_ability_progress(&"shooting")
	profile.abilities.equip(&"shooting")
	profile.weapons.unlock(&"arrow")
	profile.weapons.equip(&"arrow")
	profile.mobile_auxiliary_button_corner = &"bottom_left"
	if not profile.is_valid():
		return "Rich long-run profile is invalid before persistence."

	var data := SaveServiceRuntime.profile_to_data(profile)
	var restored := SaveServiceRuntime.data_to_profile(data)
	if not restored.is_valid() or restored.gold != profile.gold or restored.selected_character != &"2" or not restored.weapons.unlocked.get(&"arrow", false):
		return "In-memory long-run profile round-trip lost persistent state."
	for transient_key in ["distance_tiles", "earned_gold", "simulation_time", "health_owner", "statuses"]:
		if data.has(transient_key):
			return "Transient key %s leaked into long-run save data." % transient_key

	var path := "user://m10_long_run_profile.json"
	var absolute := ProjectSettings.globalize_path(path)
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(absolute + suffix):
			DirAccess.remove_absolute(absolute + suffix)
	if not SaveServiceRuntime.save_profile(profile, path):
		return "Long-run disk save failed."
	var disk := SaveServiceRuntime.load_profile(path)
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(absolute + suffix):
			DirAccess.remove_absolute(absolute + suffix)
	if not disk.is_valid() or disk.gold != profile.gold or disk.selected_character != profile.selected_character:
		return "Long-run disk reload lost persistent state."

	var clock := GameClockRuntime.ManualClock.new()
	var director := DirectorRuntime.new(clock)
	if not director.apply_profile_stats(profile):
		return "Could not apply persistent stats to long-run director."
	director.initialize_progress(Vector2(160, 500), 0.0)
	director.run.advance_distance(42.0)
	director.run.add_earned_gold(17)
	var same_run = director.run
	var potions_before := profile.revival_potions
	if not director.apply_damage(DamageStatusRuntime.DamageEvent.new(9999.0), 0.0):
		return "Lethal long-run hit was rejected."
	if director.state != DirectorRuntime.State.REVIVAL_COUNTDOWN:
		return "Lethal long-run hit did not enter revival countdown."
	if not director.revive(profile, 0.0):
		return "Long-run revival failed before deadline."
	if director.run != same_run or not is_equal_approx(director.run.distance_tiles, 42.0) or director.run.earned_gold != 17 or profile.revival_potions != potions_before - 1:
		return "Revival did not continue the same transient run exactly once."
	return ""

func _test_release_configuration_and_lazy_assets() -> String:
	var errors := GameConfig.validate_defaults()
	if not errors.is_empty():
		return "Release GameConfig validation failed: %s" % [errors]
	if String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")) != "mobile":
		return "Project is not using Godot's mobile rendering method."
	var features: PackedStringArray = ProjectSettings.get_setting("application/config/features", PackedStringArray())
	if not "Mobile" in features:
		return "Project feature list does not declare Mobile."
	if GameConfig.MAX_ACTIVE_ENEMIES <= 0 or GameConfig.MAX_ACTIVE_DROPS <= 0 or GameConfig.MAX_ACTIVE_WEAPON_PROJECTILES <= 0:
		return "Release active-object caps must all be positive."
	if GameConfig.TERRAIN_ACTIVE_AHEAD_CHUNKS <= 0 or GameConfig.TERRAIN_ACTIVE_BEHIND_CHUNKS < 0:
		return "Release terrain streaming window is invalid."

	var definitions := EnemyCatalogRuntime.definitions()
	if definitions.size() != EnemyCatalogRuntime.CANONICAL_IDENTITY_COUNT:
		return "Enemy release catalog count changed unexpectedly."
	for definition in definitions:
		if not GameConfig.ENEMY_SHOOTING_INTERVALS.has(definition.id) or not GameConfig.ENEMY_VICINITY_TILES.has(definition.id):
			return "Central combat defaults are missing for %s." % definition.id
		if not is_equal_approx(definition.ranged_interval, GameConfig.enemy_shooting_interval(definition.id)) or not is_equal_approx(definition.vicinity_tiles, GameConfig.enemy_vicinity_tiles(definition.id)):
			return "Enemy %s is not sourcing combat placeholders from GameConfig." % definition.id

	var loader := EnemyAnimationLoaderRuntime.new()
	var before := loader.cache_stats()
	if int(before[&"entries"]) != 0 or int(before[&"references"]) != 0:
		return "Enemy animation cache was not lazy at construction."
	var sample = definitions[0]
	var variant := sample.variant_ids()[0]
	var key := StringName("m10:%s:%s" % [sample.id, variant])
	var sprite_frames = loader.sprite_frames_for(sample.idle_frames_for_variant(variant), key)
	var loaded := loader.cache_stats()
	if sprite_frames == null or int(loaded[&"entries"]) != 1 or int(loaded[&"references"]) != 1:
		return "Lazy enemy animation load did not create exactly one referenced cache entry."
	if not loader.release(key):
		return "Lazy enemy animation release failed."
	var after := loader.cache_stats()
	if int(after[&"entries"]) != 0 or int(after[&"references"]) != 0:
		return "Released enemy animation remained cached without owners."
	return ""

func _sorted_keys(source: Dictionary) -> Array:
	var result: Array = source.keys()
	result.sort()
	return result

func _sorted_int_keys(source: Dictionary) -> Array:
	var result: Array = source.keys()
	result.sort()
	return result
