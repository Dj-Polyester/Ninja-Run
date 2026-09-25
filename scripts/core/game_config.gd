class_name GameConfig
extends Node
## Central, user-editable defaults. Gameplay must receive values through this boundary.

const TILE_SIZE: int = 64
const GRAVITY: float = 1400.0
const SPEED: float = 240.0
const MAX_JUMP: float = 3.0
const SNOW_MIN_JUMP_MULTIPLIER: float = 0.82
const SNOW_MAX_JUMP_MULTIPLIER: float = 1.18
const MIN_SLOWDOWN_SPEED_MULTIPLIER: float = 0.55
const ROLL_DURATION: float = 0.65
const GAME_OVER_NUMBER_OF_SECS: float = 4.0
const COUNTDOWN_SECS: float = 5.0
const BIOME_INTERVAL: int = 40
# Increment this when the deterministic biome-selection contract changes.  It
# is snapshot data so a saved/generated run can identify its exact sequence.
const BIOME_SELECTOR_VERSION: int = 1
const NUM_EQUIPPABLE_WEAPONS: int = 2
# Specification spelling is retained as a public configuration name.
const NUM_EQUIPABLE_ABILITIES: int = 4
const COOLDOWN_PERIOD: float = 8.0
const MAX_GLIDE_DURATION: float = 2.0
const GLIDE_HOLD_THRESHOLD: float = 0.18
const WALL_JUMP_PROBE_DISTANCE: float = 6.0
const DASH_SPEED: float = 11.25 # Tiles per second; convert only at movement boundaries.
const DASH_TILES: float = 4.0
const EXPLODE_RADIUS: float = 3.0
const EXPLODE_DAMAGE: float = 40.0
const SLOW_DOWN_ENEMY_INTERVAL_MULTIPLIER: float = 1.50
const REVIVAL_PROTECTION: float = 1.0
const DAMAGE_FEEDBACK_DURATION: float = 0.16
const STUCK_PROGRESS_EPSILON: float = 1.0

# M3a terrain contracts.  The run origin is deliberately expressed in world
# pixels; terrain descriptions themselves use absolute logical tile columns.
const TERRAIN_VERSION: int = 1
const RUN_ORIGIN_X: float = 160.0
const TERRAIN_BASE_SURFACE_Y: float = 600.0
const TERRAIN_CHUNK_WIDTH: int = 12
const TERRAIN_ACTIVE_BEHIND_CHUNKS: int = 2
const TERRAIN_ACTIVE_AHEAD_CHUNKS: int = 6
const TERRAIN_RECOVERY_MARGIN_CHUNKS: int = 2
const TERRAIN_SAFE_SEAM_COLUMNS: int = 2
# M3c.1 metadata only. Incrementing this invalidates deterministic hazard
# descriptors without changing terrain geometry or biome selection streams.
const HAZARD_DESCRIPTOR_VERSION: int = 1

# M3c.2 streamed-hazard runtime. Values are in world pixels/seconds, and are
# deliberately centralized so designers can edit them without hidden tuning.
const DESERT_FLAME_DAMAGE: float = 12.0
const DESERT_FLAME_DAMAGE_CADENCE: float = 0.80
const DESERT_FLAME_WIDTH: float = 42.0
const DESERT_FLAME_HEIGHT: float = 56.0
const FORT_SPIKE_DAMAGE: float = 18.0
const FORT_SPIKE_DAMAGE_CADENCE: float = 0.90
const FORT_SPIKE_PERIOD: float = 2.40
const FORT_SPIKE_EXTENDED_SECONDS: float = 1.05
const FORT_SPIKE_TRANSITION_SECONDS: float = 0.25
const FORT_SPIKE_WIDTH: float = 54.0
const FORT_SPIKE_HEIGHT: float = 48.0

# M3c.3 Astro tile fall state. These are intentionally public user-editable
# values; the coordinator uses only the RUNNING simulation clock.
const ASTRO_FALL_DELAY: float = 0.35
const ASTRO_FALL_SPEED: float = 260.0
const ASTRO_FALL_FIXED_STEP: float = 1.0 / 60.0
const ASTRO_FALL_LIMIT: float = 640.0

const MIN_MAXIMUM_HEALTH: int = 50
const DEFAULT_MAXIMUM_HEALTH: int = 100
const MAX_MAXIMUM_HEALTH: int = 250
const MAXIMUM_HEALTH_UPGRADE: int = 10
const MAXIMUM_HEALTH_UPGRADE_GOLDS: int = 100

const MIN_DEFENSE: float = 0.40
const DEFAULT_DEFENSE: float = 1.00
const MAX_DEFENSE: float = 1.00
const DEFENSE_UPGRADE: float = -0.05
const DEFENSE_UPGRADE_GOLDS: int = 125

const MIN_MELEE_POWER: int = 5
const DEFAULT_MELEE_POWER: int = 10
const MAX_MELEE_POWER: int = 50
const MELEE_POWER_UPGRADE: int = 5
const MELEE_POWER_UPGRADE_GOLDS: int = 100

# This is an interval multiplier: increasing it intentionally slows enemy fire.
const MIN_ENEMY_FIRE_RATE: float = 1.00
const DEFAULT_ENEMY_FIRE_RATE: float = 1.00
const MAX_ENEMY_FIRE_RATE: float = 1.80
const MAX_RUNTIME_ENEMY_INTERVAL_MULTIPLIER: float = MAX_ENEMY_FIRE_RATE * SLOW_DOWN_ENEMY_INTERVAL_MULTIPLIER
const ENEMY_FIRE_RATE_UPGRADE: float = 0.10
const ENEMY_FIRE_RATE_UPGRADE_GOLDS: int = 150

# M4 enemy contract defaults. Individual catalog definitions supply concrete
# values, but all user-editable shared bounds live here.
const ENEMY_CATALOG_VERSION: int = 1
const MIN_ENEMY_TIER: int = 1
const MAX_ENEMY_TIER: int = 10
const MIN_ENEMY_HEALTH: float = 1.0
const MAX_ENEMY_HEALTH: float = 10000.0
const MAX_ENEMY_DAMAGE: float = 10000.0
const MAX_ACTIVE_ENEMIES: int = 18
const ENEMY_REQUIRED_CLEARANCE_TILES: int = 2
const ENEMY_BODY_WIDTH: float = 34.0
const ENEMY_BODY_HEIGHT: float = 56.0
const ENEMY_MELEE_RANGE_TILES: float = 1.15
const ENEMY_PATROL_RADIUS: float = 96.0
const ENEMY_PROJECTILE_SPEED: float = 420.0
const ENEMY_PROJECTILE_RADIUS: float = 7.0
const ENEMY_COLLISION_LAYER: int = 2

# TASK placeholders `[Enemy name]_SHOOTING_INTERVAL` and `[Enemy name]_VICINITY`.
# Keep these per-identity defaults centralized so source users can tune enemy
# ranged behavior without editing catalog construction code.
const ENEMY_SHOOTING_INTERVALS: Dictionary = {
	&"archer_guy": 1.45, &"barbarian_warrior": 1.0, &"monk_guy": 1.0, &"goblin": 1.75,
	&"old_guy": 1.0, &"ogre": 1.0, &"golem": 1.95, &"orc": 1.60,
	&"frost_knight": 1.0, &"human_magician": 1.85, &"skeleton_warrior": 1.70,
	&"desert_nomad": 1.35, &"minotaur": 1.0, &"evil_bald_guy": 1.55,
	&"medieval_mage": 1.65, &"ghoul_hunter": 1.50, &"reaper_man": 1.90, &"pumpkin_head_guy": 1.25,
	&"death_knight": 1.80, &"skeleton": 1.0, &"zombie": 1.0, &"skull_knight": 1.40, &"vampire": 1.20,
}
const ENEMY_VICINITY_TILES: Dictionary = {
	&"archer_guy": 5.5, &"barbarian_warrior": 1.2, &"monk_guy": 1.2, &"goblin": 4.0,
	&"old_guy": 1.2, &"ogre": 1.2, &"golem": 4.5, &"orc": 4.0,
	&"frost_knight": 1.2, &"human_magician": 5.0, &"skeleton_warrior": 4.0,
	&"desert_nomad": 5.0, &"minotaur": 1.2, &"evil_bald_guy": 4.25,
	&"medieval_mage": 5.5, &"ghoul_hunter": 4.5, &"reaper_man": 5.0, &"pumpkin_head_guy": 4.75,
	&"death_knight": 4.5, &"skeleton": 1.2, &"zombie": 1.2, &"skull_knight": 4.0, &"vampire": 5.0,
}

# M5 melee, collectible, loot, and player-weapon defaults.
const PLAYER_MELEE_INTERVAL: float = 0.55
const COIN_BRONZE_GOLD: int = 5
const COIN_SILVER_GOLD: int = 10
const COIN_GOLD_GOLD: int = 20
const GEM_BLUE_GOLD: int = 50
const GEM_GREEN_GOLD: int = 75
const GEM_YELLOW_GOLD: int = 100
const HEALTH_PICKUP_AMOUNT: float = 25.0
const COLLECTIBLE_PICKUP_RADIUS: float = 18.0
const COLLECTIBLE_SPAWN_HEIGHT_TILES: float = 1.25
const MAX_ACTIVE_DROPS: int = 24
const WEAPON_PROJECTILE_RADIUS: float = 6.0
const WEAPON_PROJECTILE_LIFETIME: float = 3.0
const MAX_ACTIVE_WEAPON_PROJECTILES: int = 48

# User-editable per-enemy drop defaults. Every probability is validated in [0, 1].
const ENEMY_DROP_PROBABILITIES: Dictionary = {
	&"archer_guy": {&"gem_blue": 0.06, &"gem_green": 0.02, &"gem_yellow": 0.01},
	&"barbarian_warrior": {&"gem_blue": 0.08, &"gem_green": 0.03, &"gem_yellow": 0.01},
	&"monk_guy": {&"gem_blue": 0.10, &"gem_green": 0.04, &"gem_yellow": 0.02},
	&"goblin": {&"gem_blue": 0.11, &"gem_green": 0.05, &"gem_yellow": 0.02},
	&"old_guy": {&"gem_blue": 0.07, &"gem_green": 0.03, &"gem_yellow": 0.01},
	&"ogre": {&"gem_blue": 0.09, &"gem_green": 0.04, &"gem_yellow": 0.02},
	&"golem": {&"gem_blue": 0.13, &"gem_green": 0.06, &"gem_yellow": 0.03},
	&"orc": {&"gem_blue": 0.12, &"gem_green": 0.05, &"gem_yellow": 0.03},
	&"frost_knight": {&"gem_blue": 0.08, &"gem_green": 0.04, &"gem_yellow": 0.02},
	&"human_magician": {&"gem_blue": 0.09, &"gem_green": 0.05, &"gem_yellow": 0.02},
	&"skeleton_warrior": {&"gem_blue": 0.14, &"gem_green": 0.07, &"gem_yellow": 0.03},
	&"desert_nomad": {&"gem_blue": 0.08, &"gem_green": 0.04, &"gem_yellow": 0.02},
	&"minotaur": {&"gem_blue": 0.10, &"gem_green": 0.05, &"gem_yellow": 0.02},
	&"evil_bald_guy": {&"gem_blue": 0.15, &"gem_green": 0.07, &"gem_yellow": 0.04},
	&"medieval_mage": {&"gem_blue": 0.09, &"gem_green": 0.05, &"gem_yellow": 0.02},
	&"ghoul_hunter": {&"gem_blue": 0.10, &"gem_green": 0.05, &"gem_yellow": 0.03},
	&"reaper_man": {&"gem_blue": 0.16, &"gem_green": 0.08, &"gem_yellow": 0.04},
	&"pumpkin_head_guy": {&"gem_blue": 0.13, &"gem_green": 0.06, &"gem_yellow": 0.03},
	&"death_knight": {&"gem_blue": 0.10, &"gem_green": 0.05, &"gem_yellow": 0.03},
	&"skeleton": {&"gem_blue": 0.08, &"gem_green": 0.04, &"gem_yellow": 0.02},
	&"zombie": {&"gem_blue": 0.13, &"gem_green": 0.06, &"gem_yellow": 0.03},
	&"skull_knight": {&"gem_blue": 0.14, &"gem_green": 0.07, &"gem_yellow": 0.04},
	&"vampire": {&"gem_blue": 0.20, &"gem_green": 0.10, &"gem_yellow": 0.06},
}
# One active entry exists per status identity; a refresh selects one winning
# source rather than stacking unbounded source records.
const MAX_ACTIVE_STATUS_IDENTITIES: int = 8
const MAX_STATUS_SOURCES: int = MAX_ACTIVE_STATUS_IDENTITIES # Compatibility alias.
const MIN_STATUS_DURATION: float = 0.01
const MAX_STATUS_DURATION: float = 120.0
const MIN_STATUS_TICK_INTERVAL: float = 0.01
const MAX_STATUS_PERIODIC_DAMAGE: float = 10000.0

const MIN_INVISIBILITY_DURATION: float = 1.0
const DEFAULT_INVISIBILITY_DURATION: float = 2.0
const MAX_INVISIBILITY_DURATION: float = 6.0
const INVISIBILITY_DURATION_UPGRADE: float = 0.5
const INVISIBILITY_DURATION_UPGRADE_GOLDS: int = 200

const MIN_SLOW_DOWN_DURATION: float = 1.0
const DEFAULT_SLOW_DOWN_DURATION: float = 2.5
const MAX_SLOW_DOWN_DURATION: float = 7.0
const SLOW_DOWN_DURATION_UPGRADE: float = 0.5
const SLOW_DOWN_DURATION_UPGRADE_GOLDS: int = 200

const MIN_ABILITY_COOLDOWN: float = 2.0
const MAX_ABILITY_COOLDOWN: float = 12.0
const ABILITY_COOLDOWN_UPGRADE: float = -0.5
const ABILITY_COOLDOWN_UPGRADE_GOLDS: int = 175

# M7 persistent economy defaults. Character 1 is free/default; later characters
# use an increasing catalog price derived from these two values.
const REVIVAL_POTION_GOLDS: int = 100
const ABILITY_UNLOCK_GOLDS: int = 300
const ABILITY_LEVEL_UPGRADE_GOLDS: int = 250
const WEAPON_UNLOCK_GOLDS: int = 250
const CHARACTER_UNLOCK_BASE_GOLDS: int = 300
const CHARACTER_UNLOCK_GOLD_STEP: int = 25

const PROFILE_SCHEMA_VERSION: int = 1

const MOBILE_AUXILIARY_BUTTON_CORNER_DEFAULT: StringName = &"bottom_right"

static func validate_defaults() -> PackedStringArray:
	var errors := PackedStringArray()
	errors.append_array(validate_positive_finite(float(TILE_SIZE), "tile size"))
	errors.append_array(validate_positive_finite(GRAVITY, "gravity"))
	errors.append_array(validate_positive_finite(SPEED, "speed"))
	errors.append_array(validate_positive_finite(MAX_JUMP, "maximum jump"))
	errors.append_array(validate_positive_finite(ROLL_DURATION, "roll duration"))
	errors.append_array(validate_positive_finite(GAME_OVER_NUMBER_OF_SECS, "game-over duration"))
	errors.append_array(validate_positive_finite(COUNTDOWN_SECS, "countdown duration"))
	errors.append_array(validate_positive_finite(COOLDOWN_PERIOD, "cooldown period"))
	errors.append_array(validate_positive_finite(MAX_GLIDE_DURATION, "maximum glide duration"))
	errors.append_array(validate_positive_finite(GLIDE_HOLD_THRESHOLD, "glide hold threshold"))
	errors.append_array(validate_positive_finite(WALL_JUMP_PROBE_DISTANCE, "wall jump probe distance"))
	errors.append_array(validate_positive_finite(DASH_SPEED, "dash speed"))
	errors.append_array(validate_positive_finite(DASH_TILES, "dash tiles"))
	errors.append_array(validate_positive_finite(EXPLODE_RADIUS, "explode radius"))
	errors.append_array(validate_positive_finite(EXPLODE_DAMAGE, "explode damage"))
	errors.append_array(validate_positive_finite(SLOW_DOWN_ENEMY_INTERVAL_MULTIPLIER, "slow-down enemy interval multiplier"))
	errors.append_array(validate_positive_finite(REVIVAL_PROTECTION, "revival protection"))
	errors.append_array(validate_positive_finite(DAMAGE_FEEDBACK_DURATION, "damage feedback duration"))
	errors.append_array(validate_positive_finite(STUCK_PROGRESS_EPSILON, "stuck progress epsilon"))
	errors.append_array(validate_positive_finite(SNOW_MIN_JUMP_MULTIPLIER, "minimum snow jump multiplier"))
	errors.append_array(validate_positive_finite(SNOW_MAX_JUMP_MULTIPLIER, "maximum snow jump multiplier"))
	errors.append_array(validate_positive_finite(MIN_SLOWDOWN_SPEED_MULTIPLIER, "minimum slowdown speed multiplier"))
	for hazard_value in [DESERT_FLAME_DAMAGE, DESERT_FLAME_DAMAGE_CADENCE, DESERT_FLAME_WIDTH, DESERT_FLAME_HEIGHT, FORT_SPIKE_DAMAGE, FORT_SPIKE_DAMAGE_CADENCE, FORT_SPIKE_PERIOD, FORT_SPIKE_EXTENDED_SECONDS, FORT_SPIKE_TRANSITION_SECONDS, FORT_SPIKE_WIDTH, FORT_SPIKE_HEIGHT, ASTRO_FALL_DELAY, ASTRO_FALL_SPEED, ASTRO_FALL_FIXED_STEP, ASTRO_FALL_LIMIT]:
		errors.append_array(validate_positive_finite(float(hazard_value), "hazard runtime value"))
	if FORT_SPIKE_EXTENDED_SECONDS > FORT_SPIKE_PERIOD:
		errors.append("Fort spike active window cannot exceed its period.")
	if FORT_SPIKE_TRANSITION_SECONDS * 2.0 > FORT_SPIKE_EXTENDED_SECONDS:
		errors.append("Fort spike rise/fall cannot exceed its active window.")
	if SNOW_MIN_JUMP_MULTIPLIER > SNOW_MAX_JUMP_MULTIPLIER:
		errors.append("Snow jump multipliers are inverted.")
	if MIN_SLOWDOWN_SPEED_MULTIPLIER > 1.0:
		errors.append("Minimum slowdown multiplier must not exceed one.")
	if TERRAIN_VERSION <= 0 or HAZARD_DESCRIPTOR_VERSION <= 0 or TERRAIN_CHUNK_WIDTH <= 0 or TERRAIN_ACTIVE_BEHIND_CHUNKS < 0 or TERRAIN_ACTIVE_AHEAD_CHUNKS <= 0 or TERRAIN_RECOVERY_MARGIN_CHUNKS < 0 or TERRAIN_SAFE_SEAM_COLUMNS < 0:
		errors.append("Terrain streaming configuration is invalid.")
	if BIOME_INTERVAL <= 0 or BIOME_SELECTOR_VERSION <= 0 or NUM_EQUIPPABLE_WEAPONS <= 0 or NUM_EQUIPABLE_ABILITIES <= 0:
		errors.append("Biome selector, interval, and equip limits must be positive.")
	_validate_stat(errors, MIN_MAXIMUM_HEALTH, DEFAULT_MAXIMUM_HEALTH, MAX_MAXIMUM_HEALTH, MAXIMUM_HEALTH_UPGRADE, MAXIMUM_HEALTH_UPGRADE_GOLDS, 1, "maximum health")
	_validate_stat(errors, MIN_DEFENSE, DEFAULT_DEFENSE, MAX_DEFENSE, DEFENSE_UPGRADE, DEFENSE_UPGRADE_GOLDS, -1, "defense")
	_validate_stat(errors, MIN_MELEE_POWER, DEFAULT_MELEE_POWER, MAX_MELEE_POWER, MELEE_POWER_UPGRADE, MELEE_POWER_UPGRADE_GOLDS, 1, "melee power")
	_validate_stat(errors, MIN_ENEMY_FIRE_RATE, DEFAULT_ENEMY_FIRE_RATE, MAX_ENEMY_FIRE_RATE, ENEMY_FIRE_RATE_UPGRADE, ENEMY_FIRE_RATE_UPGRADE_GOLDS, 1, "enemy fire rate")
	if ENEMY_CATALOG_VERSION <= 0 or MIN_ENEMY_TIER <= 0 or MAX_ENEMY_TIER < MIN_ENEMY_TIER or MIN_ENEMY_HEALTH <= 0.0 or MAX_ENEMY_HEALTH < MIN_ENEMY_HEALTH or MAX_ENEMY_DAMAGE <= 0.0 or MAX_ACTIVE_ENEMIES <= 0 or ENEMY_REQUIRED_CLEARANCE_TILES <= 0 or ENEMY_BODY_WIDTH <= 0.0 or ENEMY_BODY_HEIGHT <= 0.0 or ENEMY_MELEE_RANGE_TILES <= 0.0 or ENEMY_PATROL_RADIUS <= 0.0 or ENEMY_PROJECTILE_SPEED <= 0.0 or ENEMY_PROJECTILE_RADIUS <= 0.0 or ENEMY_COLLISION_LAYER <= 0 or MAX_ACTIVE_STATUS_IDENTITIES <= 0 or MIN_STATUS_DURATION <= 0.0 or MAX_STATUS_DURATION < MIN_STATUS_DURATION or MIN_STATUS_TICK_INTERVAL <= 0.0 or MAX_STATUS_PERIODIC_DAMAGE <= 0.0:
		errors.append("Enemy contract defaults are invalid.")
	for enemy_id in ENEMY_SHOOTING_INTERVALS:
		if not ENEMY_VICINITY_TILES.has(enemy_id):
			errors.append("Enemy vicinity default is missing: %s" % enemy_id)
			continue
		errors.append_array(validate_enemy_timing(float(ENEMY_VICINITY_TILES[enemy_id]), float(ENEMY_SHOOTING_INTERVALS[enemy_id])))
	for enemy_id in ENEMY_VICINITY_TILES:
		if not ENEMY_SHOOTING_INTERVALS.has(enemy_id):
			errors.append("Enemy shooting interval default is missing: %s" % enemy_id)
	if PLAYER_MELEE_INTERVAL <= 0.0 or COIN_BRONZE_GOLD <= 0 or COIN_SILVER_GOLD <= COIN_BRONZE_GOLD or COIN_GOLD_GOLD <= COIN_SILVER_GOLD or GEM_BLUE_GOLD <= COIN_GOLD_GOLD or GEM_GREEN_GOLD <= GEM_BLUE_GOLD or GEM_YELLOW_GOLD <= GEM_GREEN_GOLD or HEALTH_PICKUP_AMOUNT <= 0.0 or COLLECTIBLE_PICKUP_RADIUS <= 0.0 or COLLECTIBLE_SPAWN_HEIGHT_TILES <= 0.0 or MAX_ACTIVE_DROPS <= 0 or WEAPON_PROJECTILE_RADIUS <= 0.0 or WEAPON_PROJECTILE_LIFETIME <= 0.0 or MAX_ACTIVE_WEAPON_PROJECTILES <= 0:
		errors.append("M5 melee/collectible/weapon defaults are invalid.")
	for enemy_id in ENEMY_DROP_PROBABILITIES:
		if not ENEMY_SHOOTING_INTERVALS.has(enemy_id) or not ENEMY_VICINITY_TILES.has(enemy_id):
			errors.append("Enemy combat defaults are missing for loot-table identity: %s" % enemy_id)
		var probabilities: Dictionary = ENEMY_DROP_PROBABILITIES[enemy_id]
		for collectible_id in probabilities:
			var probability := float(probabilities[collectible_id])
			if not is_finite(probability) or probability < 0.0 or probability > 1.0:
				errors.append("Enemy drop probability must be in [0, 1]: %s/%s" % [enemy_id, collectible_id])
	_validate_stat(errors, MIN_INVISIBILITY_DURATION, DEFAULT_INVISIBILITY_DURATION, MAX_INVISIBILITY_DURATION, INVISIBILITY_DURATION_UPGRADE, INVISIBILITY_DURATION_UPGRADE_GOLDS, 1, "invisibility duration")
	_validate_stat(errors, MIN_SLOW_DOWN_DURATION, DEFAULT_SLOW_DOWN_DURATION, MAX_SLOW_DOWN_DURATION, SLOW_DOWN_DURATION_UPGRADE, SLOW_DOWN_DURATION_UPGRADE_GOLDS, 1, "slow-down duration")
	errors.append_array(validate_cooldown_definition(COOLDOWN_PERIOD, MIN_ABILITY_COOLDOWN, MAX_ABILITY_COOLDOWN, ABILITY_COOLDOWN_UPGRADE, ABILITY_COOLDOWN_UPGRADE_GOLDS))
	if REVIVAL_POTION_GOLDS <= 0 or ABILITY_UNLOCK_GOLDS <= 0 or ABILITY_LEVEL_UPGRADE_GOLDS <= 0 or WEAPON_UNLOCK_GOLDS <= 0 or CHARACTER_UNLOCK_BASE_GOLDS <= 0 or CHARACTER_UNLOCK_GOLD_STEP < 0:
		errors.append("M7 purchase costs must be positive and character price step cannot be negative.")
	return errors

static func terrain_snapshot() -> Dictionary:
	# Only values in this dictionary may affect TerrainGenerator output.
	return {
		&"tile_size": TILE_SIZE,
		&"gravity": GRAVITY,
		&"speed": SPEED,
		&"max_jump_tiles": MAX_JUMP,
		&"snow_min_jump_multiplier": SNOW_MIN_JUMP_MULTIPLIER,
		&"snow_max_jump_multiplier": SNOW_MAX_JUMP_MULTIPLIER,
		&"slowdown_speed_multiplier": MIN_SLOWDOWN_SPEED_MULTIPLIER,
		&"chunk_width": TERRAIN_CHUNK_WIDTH,
		&"base_surface_y": TERRAIN_BASE_SURFACE_Y,
		&"safe_seam_columns": TERRAIN_SAFE_SEAM_COLUMNS,
		&"run_origin_x": RUN_ORIGIN_X,
		&"biome_interval": BIOME_INTERVAL,
		&"biome_selector_version": BIOME_SELECTOR_VERSION,
		&"hazard_descriptor_version": HAZARD_DESCRIPTOR_VERSION,
	}

static func terrain_config_identity(snapshot: Dictionary = {}) -> StringName:
	var source := terrain_snapshot() if snapshot.is_empty() else snapshot
	var fields: Array[StringName] = [&"tile_size", &"gravity", &"speed", &"max_jump_tiles", &"snow_min_jump_multiplier", &"snow_max_jump_multiplier", &"slowdown_speed_multiplier", &"chunk_width", &"base_surface_y", &"safe_seam_columns", &"run_origin_x", &"biome_interval", &"biome_selector_version", &"hazard_descriptor_version"]
	var values: Array[String] = []
	for field in fields:
		values.append("%s=%s" % [field, source.get(field, "missing")])
	return StringName("terrain-v%d:%s" % [TERRAIN_VERSION, ";".join(values)])

static func dash_speed_pixels_per_second() -> float:
	return DASH_SPEED * TILE_SIZE

static func validate_positive_finite(value: float, label: String = "value") -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_finite(value) or value <= 0.0:
		errors.append("%s must be finite and positive." % label)
	return errors

static func validate_enemy_timing(vicinity_tiles: float, shooting_interval: float) -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_finite(vicinity_tiles) or vicinity_tiles <= 0.0:
		errors.append("Enemy vicinity must be positive.")
	if not is_finite(shooting_interval) or shooting_interval <= 0.0:
		errors.append("Enemy shooting interval must be positive.")
	return errors

static func enemy_shooting_interval(enemy_id: StringName) -> float:
	return float(ENEMY_SHOOTING_INTERVALS.get(enemy_id, 0.0))

static func enemy_vicinity_tiles(enemy_id: StringName) -> float:
	return float(ENEMY_VICINITY_TILES.get(enemy_id, 0.0))

static func validate_drop_probability(probability: float) -> bool:
	return probability >= 0.0 and probability <= 1.0

static func validate_stat_definition(minimum: float, default_value: float, maximum: float, upgrade: float, upgrade_golds: int, expected_direction: int, label: String = "stat") -> PackedStringArray:
	var errors := PackedStringArray()
	_validate_stat(errors, minimum, default_value, maximum, upgrade, upgrade_golds, expected_direction, label)
	return errors

static func validate_cooldown_definition(default_value: float, minimum: float, maximum: float, upgrade: float, upgrade_golds: int) -> PackedStringArray:
	return validate_stat_definition(minimum, default_value, maximum, upgrade, upgrade_golds, -1, "cooldown")

static func _validate_stat(errors: PackedStringArray, minimum: float, default_value: float, maximum: float, upgrade: float, upgrade_golds: int, expected_direction: int, label: String) -> void:
	if not is_finite(minimum) or not is_finite(default_value) or not is_finite(maximum) or not is_finite(upgrade):
		errors.append("%s values must be finite." % label)
		return
	if minimum < 0.0 or minimum > default_value or default_value > maximum or upgrade_golds <= 0:
		errors.append("Invalid %s bounds or cost." % label)
	if expected_direction == 0 or sign(upgrade) != expected_direction:
		errors.append("Invalid %s upgrade direction." % label)
