extends Node

# Task-level tuning values. Keep source-code knobs in one place and express
# movement/world distances in tiles; gameplay code converts them to pixels.
const TILE_SIZE := 64.0
const SPEED := 6.0
const BIOME_INTERVAL := 48
const MAX_JUMP := 3.0
const ROLL_DURATION := 0.65
const GAME_OVER_NUMBER_OF_SECS := 3.0
const COUNTDOWN_SECS := 5.0
const NUM_EQUIPPABLE_WEAPONS := 3
const NUM_EQUIPABLE_ABILITIES := 4
const MAX_GLIDE_DURATION := 2.0
const DASH_SPEED := 14.0
const DASH_TILES := 4.0
const EXPLODE_RADIUS := 3.0
const COOLDOWN_PERIOD := 8.0

# Phase 6 persistent stat progression. Values are expressed as source-level
# tuning constants because task.md explicitly exposes each stat's bounds,
# upgrade step, and fixed gold cost to project maintainers.
const MIN_MAXIMUM_HEALTH := 100.0
const MAX_MAXIMUM_HEALTH := 250.0
const MAXIMUM_HEALTH_UPGRADE := 25.0
const MAXIMUM_HEALTH_UPGRADE_GOLDS := 50

const MIN_DEFENSE_MULTIPLIER := 0.50
const MAX_DEFENSE_MULTIPLIER := 1.00
const DEFENSE_MULTIPLIER_UPGRADE := 0.05
const DEFENSE_MULTIPLIER_UPGRADE_GOLDS := 75

const MIN_MELEE_POWER := 10.0
const MAX_MELEE_POWER := 50.0
const MELEE_POWER_UPGRADE := 5.0
const MELEE_POWER_UPGRADE_GOLDS := 60

const MIN_ENEMY_FIRE_INTERVAL_MULTIPLIER := 1.0
const MAX_ENEMY_FIRE_INTERVAL_MULTIPLIER := 2.0
const ENEMY_FIRE_INTERVAL_MULTIPLIER_UPGRADE := 0.1
const ENEMY_FIRE_INTERVAL_MULTIPLIER_UPGRADE_GOLDS := 80

const MIN_INVISIBILITY_DURATION := 2.0
const MAX_INVISIBILITY_DURATION := 6.0
const INVISIBILITY_DURATION_UPGRADE := 0.5
const INVISIBILITY_DURATION_UPGRADE_GOLDS := 100

const MIN_SLOW_DOWN_DURATION := 2.0
const MAX_SLOW_DOWN_DURATION := 6.0
const SLOW_DOWN_DURATION_UPGRADE := 0.5
const SLOW_DOWN_DURATION_UPGRADE_GOLDS := 100

# Runner/world configuration.
const GENERATION_DISTANCE_AHEAD := 36
const CLEANUP_DISTANCE_BEHIND := 18
const CAMERA_LOOK_AHEAD := 4.0
const GRAVITY := 1800.0
const KILL_PLANE_Y := 1050.0
const DAMAGE_INVULNERABILITY := 0.45
const DAMAGE_FLASH_DURATION := 0.12
const REVIVE_INVULNERABILITY := 1.0
const STUCK_PROGRESS_THRESHOLD := 0.125
const SAFE_CHECKPOINT_INTERVAL_TILES := 2.0
const PLAYER_COLLISION_WIDTH := 34.0
const PLAYER_COLLISION_HEIGHT := 58.0
const ROLL_HEIGHT_RATIO := 0.52

# Phase 7 automatic melee combat. ENEMY_COLLISION_MASK reserves physics layer
# 3 (bit value 4) for enemy bodies/hurtboxes so the proximity query does not
# spend time considering terrain, pickups, or the player body.
const ENEMY_COLLISION_MASK := 1 << 2
const MELEE_RANGE_TILES := 1.25
const MELEE_ATTACK_INTERVAL := 0.55

# Phase 8 automatic weapon combat. Weapon-specific damage, cadence, aim,
# target count, speed, and unlock cost live in WeaponData resources; these are
# shared simulation/runtime limits that apply to every weapon projectile.
const SHOOTING_ABILITY_ID := &"shooting"
const WEAPON_PROJECTILE_COLLISION_RADIUS := 10.0
const WEAPON_PROJECTILE_LIFETIME := 5.0
const WEAPON_PROJECTILE_GRAVITY := 1050.0
const WEAPON_HOMING_TURN_RATE := 7.5
const WEAPON_RANDOM_AIM_MAX_DEGREES := 70.0
const WEAPON_SCREEN_MARGIN_PIXELS := 48.0

const START_PLATFORM_START_TILE := -4
const START_PLATFORM_WIDTH := 20
const BASE_PLATFORM_HEIGHT := 8
const PLATFORM_MIN_WIDTH := 8
const PLATFORM_MAX_WIDTH := 14
const PLATFORM_MIN_GAP := 1
const PLATFORM_MAX_GAP := 3
const PLATFORM_MAX_HEIGHT_STEP := 1
const WORLD_MIN_HEIGHT_TILE := 6
const WORLD_MAX_HEIGHT_TILE := 9
const CHUNK_MIN_SPAN := 8
const CHUNK_MAX_SPAN := 16
const OPTIONAL_ROUTE_CHANCE := 0.35
const CAVE_CLEARANCE_TILES := 4
const TERRAIN_SOURCE_TILE_SIZE := 128
const TERRAIN_ATLAS_SEPARATION := 1

# Phase 3 biome mechanics.
const SNOW_JUMP_MODIFIER_MIN := -0.5
const SNOW_JUMP_MODIFIER_MAX := 0.5
const DESERT_CONTACT_DAMAGE := 8.0
const DESERT_BURN_TICK_DAMAGE := 4.0
const DESERT_BURN_TICK_INTERVAL := 0.75
const DESERT_BURN_DURATION := 1.5
const ASTRO_FALL_WARNING_DURATION := 0.45
const ASTRO_FALL_GRAVITY := 1400.0
const ASTRO_FALL_CLEANUP_Y := 1400.0
const FORT_SPIKE_DAMAGE := 18.0
const FORT_SPIKE_RETRACTED_DURATION := 1.1
const FORT_SPIKE_RISE_DURATION := 0.18
const FORT_SPIKE_EXPOSED_DURATION := 0.85
const FORT_SPIKE_LOWER_DURATION := 0.18
const FORT_SPIKE_RETRACT_DISTANCE := 24.0

func tiles_to_pixels(value: float) -> float:
	return value * TILE_SIZE

func pixels_to_tiles(value: float) -> float:
	return value / TILE_SIZE
