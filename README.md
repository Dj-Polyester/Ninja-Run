# Ninja Run

Ninja Run is a Godot 4.7 2D endless-runner project. **Phases 1–17 are implemented on this branch**, including the complete headless regression/stress suite and this final documentation pass.

## Requirements

- Godot 4.7.x
- Mobile renderer (configured in `project.godot`)

## Running the game

Open the project in the Godot editor once so the bundled asset library can be imported, then run the project with **F5**. After that first import, it can also be launched directly from a shell:

```sh
godot --path .
```

The repository contains a large asset pack, so the editor's first import is substantially heavier than normal startup. The headless test suite below can read the required terrain PNG directly and does not require importing the complete asset library.

## Controls

Desktop controls:

- **Up Arrow** — jump
- **Down Arrow** — roll
- **1 / 2 / 3 / 4** — activate mapped direct-action abilities (up to four)

Mobile controls:

- **Tap** — jump; holding the touch briefly keeps the logical Jump action held so Glide/hang retains its desktop semantics
- **Swipe down** — roll
- Active equipped abilities that are not already represented by the jump gesture (and are not passive) appear as touch buttons using the same dense action-slot order as desktop. The cluster defaults to the **right** side and follows the persisted `action_button_side` setting (`right` / `left`).

## Gameplay

The main menu provides Start Run plus Character, Stats, Abilities, Weapons, and Settings screens. Profile screens read directly from the same catalogs and `GameState` transaction APIs used by gameplay: unlocks/upgrades spend persistent gold, loadout limits and incompatibilities are enforced by services rather than widgets, and successful changes are saved immediately. The lower-left level HUD mirrors the four direct-action slots and their live cooldowns so the number-key mapping is always visible. Jump/Climb/Glide/Reverse Gravity/Fly stay on the dedicated Jump action, Shooting stays automatic, and active abilities such as Dash/Explode/Slow Down/Invisibility receive dense 1–4 mappings. Keyboard and touch both terminate at `PlayerInputRouter`; the player and `AbilityController` receive logical jump/roll/ability requests and do not branch on the physical input source.

The player continuously runs to the right. Procedural terrain streams ahead, old chunks and runtime hazards are removed behind the run, and the camera follows horizontal progress with look-ahead. Falling below the kill plane, losing all health, or failing to make horizontal progress for `GAME_OVER_NUMBER_OF_SECS` starts the Phase 4 revival countdown. A revival potion returns the player to the most recent safe checkpoint with restored health, cleared statuses, and brief invulnerability; otherwise the countdown ends in final game-over. The first traversal is always **Grass → Tundra → Snow → Desert → Astro → Fort**, with each biome lasting `BIOME_INTERVAL` tiles; later biome encounters are seeded-random and never immediately repeat the previous biome. Snow temporarily varies jump height, Desert adds fire/burn zones, Astro substitutes selected terrain cells with falling blocks, and Fort adds cycling spike traps.

## Architecture

```text
scenes/
  main.tscn
  level/
    level.tscn
    platform.tscn
  hazards/
    desert_hazard.tscn
    falling_tile.tscn
    spike_hazard.tscn
  combat/
    weapon_projectile.tscn
  enemies/
    enemy.tscn
    enemy_projectile.tscn
    enemy_beam.tscn
  items/
    collectible_pickup.tscn
  player/
    player.tscn
  ui/
    mobile_action_controls.tscn
src/
  core/
    game_config.gd
    game_state.gd
    player_profile.gd
    rng_service.gd
    run_state.gd
    save_manager.gd
  data/
    ability_catalog.gd
    ability_data.gd
    biome_data.gd
    character_catalog.gd
    character_data.gd
    collectible_catalog.gd
    collectible_data.gd
    enemy_catalog.gd
    enemy_data.gd
    status_effect.gd
    status_effect_catalog.gd
    stat_catalog.gd
    stat_data.gd
    weapon_catalog.gd
    weapon_data.gd
  gameplay/
    abilities/
      ability.gd
      ability_controller.gd
      ability_inventory_service.gd
      jump_ability.gd
      climb_ability.gd
      glide_ability.gd
      reverse_gravity_ability.gd
      fly_ability.gd
      dash_ability.gd
      explode_ability.gd
      slow_down_time_ability.gd
      invisibility_ability.gd
      world_speed_controller.gd
    combat/
      automatic_melee_controller.gd
      damage_info.gd
      damageable_contract.gd
      weapon_controller.gd
      weapon_inventory_service.gd
      weapon_projectile.gd
    enemies/
      enemy.gd
      enemy_health_component.gd
      enemy_spawner.gd
      enemy_projectile.gd
      enemy_beam.gd
    hazards/
      desert_hazard.gd
      falling_tile.gd
      spike_hazard.gd
    input/
      player_input_router.gd
      touch_input_adapter.gd
    items/
      collectible_pickup.gd
      collectible_spawner.gd
    status/
      status_effect_controller.gd
    level/
      level.gd
      safe_checkpoint.gd
    player/player.gd
    progression/
      character_inventory_service.gd
      stat_upgrade_service.gd
    world/biome_catalog.gd
    world/biome_mechanics.gd
    world/biome_sequence.gd
    world/platform.gd
    world/procedural_layout_generator.gd
    world/terrain_tileset_factory.gd
    world/world_streamer.gd
  ui/
    main.gd
    hud/mobile_action_controls.gd
data/
  abilities/
    jump.tres
    climb.tres
    glide.tres
    reverse_gravity.tres
    fly.tres
    dash.tres
    shooting.tres
    explode.tres
    slow_down_time.tres
    invisibility.tres
  biomes/
    grass.tres
    tundra.tres
    snow.tres
    desert.tres
    astro.tres
    fort.tres
  collectibles/
    bronze_coin.tres
    silver_coin.tres
    gold_coin.tres
    gem_blue.tres
    gem_green.tres
    gem_yellow.tres
  characters/
    45 CharacterData resources mapped one-to-one to assets/Characters/1..45
  enemies/
    39 EnemyData resources covering every supplied enemy character set
  status_effects/
    reusable StatusEffect resources referenced by themed enemies and hazards
  stats/
    maximum_health.tres
    defense_multiplier.tres
    melee_power.tres
    enemy_fire_interval_multiplier.tres
    invisibility_duration.tres
    slow_down_duration.tres
  weapons/
    shuriken.tres
    shuriken_fan.tres
    arrow.tres
    magic_orb.tres
    throwing_blade.tres
tests/
  fixtures/
    enemy_target_dummy.gd
    melee_dummy_enemy.gd
  test_runner.gd
```

Responsibilities are deliberately separated: `GameConfig` owns source tuning values, `PlayerProfile` owns the persistent profile schema/defaults/sanitization rules, `RunState` owns transient per-run state, `GameState` coordinates their live dictionaries and emits change signals, and `SaveManager` owns versioned disk persistence. `CharacterData` now describes each playable presentation (`id`, display name, animation root/SpriteFrames, unlock cost), `CharacterCatalog` maps all 45 supplied numbered asset sets, and `CharacterInventoryService` owns atomic gold-backed unlock and selection rules; player spawning resolves the selected resource instead of constructing an unchecked asset path from a raw integer. `StatData` resources define upgradeable stat ranges/costs/locks, `StatCatalog` resolves those resources and derives values from persisted levels, and `StatUpgradeService` owns the atomic upgrade transaction. `AbilityData` resources define the ability catalog, unlock prices, and upgrade bounds; `AbilityInventoryService` owns atomic gold-backed unlock/equip/upgrade validation (including the four-slot cap and Jump/Reverse Gravity incompatibility), and the player's `AbilityController` composes independent runtime ability objects rather than embedding every mechanic in `player.gd`. Phase 14 adds `PlayerInputRouter` as the source-agnostic logical input boundary, with `TouchInputAdapter` handling mobile gesture recognition separately and `MobileActionControls` rendering only the touch buttons needed by the current equipped slots. Phase 15 adds a catalog-driven `main.gd` menu shell for Character/Stats/Abilities/Weapons/Settings, immediate persistence after successful transactions, and live cooldown/weapon/consumable HUD feedback. Supplied UI textures are loaded only in graphical runs so headless validation does not require importing the complete art library. `GameState.action_button_side()` / `set_action_button_side()` expose the already-persisted left/right preference without coupling UI layout to save internals. `WorldSpeed` is a project autoload that exposes explicit subsystem multipliers for slow-time effects without touching `Engine.time_scale`. `DamageInfo` carries normalized damage metadata, `DamageableContract` defines the common player/enemy damage API, and `AutomaticMeleeController` owns proximity filtering, nearest-target selection, attack cooldown, and shared melee damage dispatch. Phase 8 keeps ranged player combat similarly data-driven through `WeaponData`, `WeaponCatalog`, `WeaponController`, and `WeaponProjectile`. Phase 10 adds the corresponding enemy layer: `EnemyData` describes stats/AI/ranged style/status/drop metadata, `EnemyCatalog` resolves all supplied enemy definitions, `EnemySpawner` turns deterministic streamed chunks into bounded biome-valid spawns, `EnemyHealthComponent` owns health arithmetic, and one reusable `Enemy` scene implements stationary/patrol movement plus melee/shoot/hybrid behavior. Enemy projectile and beam scenes separate gameplay collision/raycast logic from particle/line presentation. Phase 11 moves temporary combat effects out of player/enemy bespoke timers: `StatusEffect` resources define duration, tick cadence, stack policy, periodic damage, movement/damage multipliers and presentation metadata; `StatusEffectCatalog` resolves canonical resources (and normalizes legacy dictionary payloads at boundaries); reusable `StatusEffectController` nodes own active instances for both the player and enemies and invoke `on_apply`, `on_tick`, and `on_remove` hooks. Phase 12 adds `CollectibleData`/`CollectibleCatalog`, a generic `CollectiblePickup`, deterministic `CollectibleSpawner`, and the injectable `RngService`. The spawner consumes biome collectible weights plus generated platform difficulty, guarantees bonus slots on risky optional routes, listens to enemy death signals for per-enemy drop tables, and cleans every uncollected pickup with its streamed chunk. Pickups award `GameState` profile gold directly, so currency remains persistent without polluting transient run state. `SafeCheckpoint` owns checkpoint data, player code owns movement/health/status/attack-animation feedback, and `level.gd` owns stuck/revival/game-over orchestration. `BiomeSequence` owns encounter selection, `BiomeMechanics` derives deterministic encounter-specific modifiers, `ProceduralLayoutGenerator` owns deterministic geometry specs, `TerrainTileSetFactory` owns the atlas/physics definition, and `WorldStreamer` owns bounded terrain plus runtime-hazard lifetime. Biome presentation, enemy-pool identifiers, generation weights, collectible weights, and hazard selection live in `BiomeData` resources rather than branching through `level.gd`.

## Configuration

The task-defined and shared runtime `CONSTANT_CASE` tuning variables are centralized in `src/core/game_config.gd`. The table below documents every current `GameConfig` constant so project tuning does not require hunting through gameplay scripts or scenes:

| Setting | Default | Meaning |
| --- | ---: | --- |
| `TILE_SIZE` | 64 px | Pixel size used for tile-space conversion |
| `SPEED` | 6 tiles/s | Automatic horizontal run speed |
| `MAX_JUMP` | 3 tiles | Maximum jump height target |
| `ROLL_DURATION` | 0.65 s | Time the shortened roll hitbox remains active |
| `ENEMY_COLLISION_MASK` | 4 (physics layer 3) | Enemy body/hurtbox layer queried by automatic melee |
| `PLAYER_COLLISION_LAYER` | 1 (physics layer 1) | Player body collision layer |
| `TERRAIN_COLLISION_LAYER` | 2 (physics layer 2) | Terrain/platform collision layer |
| `MELEE_RANGE_TILES` | 1.25 tiles | Radius of the player melee proximity detector |
| `MELEE_ATTACK_INTERVAL` | 0.55 s | Minimum time between automatic melee hits |
| `ENEMY_COLLISION_WIDTH` / `ENEMY_COLLISION_HEIGHT` | 36 / 56 px | Generic enemy body collision dimensions |
| `ENEMY_MIN_PLATFORM_WIDTH` | 4 tiles | Minimum mandatory platform width eligible for an enemy spawn |
| `ENEMY_SPAWN_START_TILE` | 12 tiles | Earliest procedural tile where enemies may spawn |
| `ENEMY_MAX_PER_CHUNK` | 2 | Hard bound on generated enemies per streamed chunk |
| `ENEMY_ADDITIONAL_SPAWN_CHANCE` | 0.42 | Probability of adding a second enemy to an eligible chunk |
| `ENEMY_INITIAL_SHOOT_DELAY` | 0.45 s | Maximum initial ranged delay before an enemy can shoot |
| `ENEMY_PROJECTILE_COLLISION_RADIUS` | 8 px | Enemy projectile gameplay hitbox radius |
| `ENEMY_PROJECTILE_LIFETIME` | 5 s | Bounded enemy projectile lifetime |
| `ENEMY_BEAM_DURATION` | 0.18 s | Visual lifetime of a beam attack after its ray resolves damage |
| `ENEMY_BEAM_MAX_RANGE_TILES` | 8 tiles | Maximum gameplay ray length for beam enemies |
| `ENEMY_DAMAGE_FLASH_DURATION` | 0.10 s | Red damage-feedback duration for enemies |
| `ENEMY_DEATH_CLEANUP_DELAY` | 0.55 s | Delay before a defeated enemy scene is released |
| `ENEMY_ANIMATION_MAX_FRAMES` | 16 | Runtime cap on loaded frames per enemy animation |
| `STATUS_MIN_MOVEMENT_MULTIPLIER` | 0.25 | Safety floor after combining active status movement multipliers |
| `STATUS_TICK_FLASH_DURATION` | 0.12 s | Red blink duration for periodic damage statuses such as Blood Loss |
| `COLLECTIBLE_COLLISION_LAYER` | 8 (physics layer 4) | Pickup overlap layer, kept separate from player/enemy combat layers |
| `COLLECTIBLE_MAX_PER_CHUNK` | 5 | Hard bound on procedurally placed collectibles per streamed chunk |
| `COLLECTIBLE_BASE_SPAWN_CHANCE` | 0.42 | Baseline placement chance on low-risk platform slots |
| `COLLECTIBLE_MAX_SPAWN_CHANCE` | 0.80 | Placement chance approached by high-risk mandatory platforms |
| `COLLECTIBLE_DIFFICULTY_VALUE_BONUS` | 1.25 | Strength of high-value collectible weighting on difficult platforms |
| `COLLECTIBLE_VERTICAL_OFFSET` | 34 px | Height above terrain used by procedural pickups |
| `COLLECTIBLE_DROP_SPACING` | 24 px | Horizontal spacing between multiple drops from one enemy |
| `COLLECTIBLE_DROP_LIFT` | 28 px | Vertical lift applied when placing enemy drops |
| `COLLECTIBLE_BOB_PIXELS` | 4 px | Pickup idle bob amplitude |
| `COLLECTIBLE_BOB_SPEED` | 3.4 | Pickup idle bob angular speed |
| `COLLECTIBLE_SPIN_SPEED` | 2.1 | Pickup presentation spin speed |
| `COLLECTIBLE_TILT_RADIANS` | 0.10 rad | Small presentation tilt applied while spinning |
| `NUM_EQUIPPABLE_WEAPONS` | 3 | Maximum number of simultaneously equipped weapons |
| `NUM_EQUIPABLE_ABILITIES` | 4 | Maximum number of simultaneously equipped abilities |
| `MAX_GLIDE_DURATION` | 2.0 s | Maximum continuous Glide/Hang duration per landing cycle |
| `GLIDE_GRAVITY_FACTOR` | 0.22 | Gravity multiplier while Glide is active |
| `DASH_SPEED` | 14 tiles/s | Dash movement speed |
| `DASH_TILES` | 4 tiles | Exact target distance for one Dash |
| `WALL_JUMP_HORIZONTAL_SPEED` | 3 tiles/s | Horizontal push away from a contacted wall |
| `WALL_JUMP_PUSH_DURATION` | 0.18 s | Time the wall-jump push overrides automatic running |
| `EXPLODE_RADIUS` | 3 tiles | Enemy/terrain query radius for Explode |
| `EXPLODE_DAMAGE` | 40 | Damage applied by Explode inside its radius |
| `EXPLODE_EFFECT_DURATION` | 0.45 s | Lifetime of the one-shot explosion visual effect |
| `COOLDOWN_PERIOD` | 8.0 s | Shared cooldown used by action abilities |
| `INVISIBILITY_ALPHA` | 0.35 | Visual alpha while gameplay detectability is disabled |
| `MOBILE_TAP_MAX_DISTANCE` | 28 px | Maximum release displacement still classified as a tap |
| `MOBILE_JUMP_HOLD_DELAY` | 0.12 sec | Stationary-touch delay before the Jump action is held for Glide/hang |
| `MOBILE_SWIPE_MIN_DISTANCE` | 72 px | Minimum downward travel required to trigger roll |
| `MOBILE_SWIPE_DIRECTION_RATIO` | 1.25 | Required vertical dominance over horizontal drag for a downward swipe |
| `MOBILE_ACTION_BUTTON_WIDTH` / `MOBILE_ACTION_BUTTON_HEIGHT` | 168 / 52 px | Touch-button minimum dimensions |
| `MOBILE_ACTION_BUTTON_MARGIN` | 24 px | Edge margin for the left/right mobile action cluster |
| `MOBILE_ACTION_BUTTON_CLUSTER_HEIGHT` | 300 px | Vertical layout budget reserved for the mobile action cluster |
| `SLOW_TIME_PLAYER_SPEED_MULTIPLIER` | 0.60 | Player run-speed multiplier during Slow Down Time |
| `SLOW_TIME_ENEMY_MOVE_MULTIPLIER` | 0.60 | Enemy movement multiplier exposed for the enemy phase |
| `SLOW_TIME_ENEMY_FIRE_INTERVAL_MULTIPLIER` | 1.50 | Enemy firing-interval multiplier exposed for the enemy phase |
| `SLOW_TIME_PROJECTILE_SPEED_MULTIPLIER` | 0.65 | Projectile-speed multiplier exposed for the enemy/projectile phase |
| `SHOOTING_ABILITY_ID` | `shooting` | Ability id required before weapons can be bought, equipped, or fired |
| `WEAPON_PROJECTILE_COLLISION_RADIUS` | 10 px | Shared projectile damage-query radius |
| `WEAPON_PROJECTILE_LIFETIME` | 5 s | Maximum projectile lifetime before cleanup |
| `WEAPON_PROJECTILE_GRAVITY` | 1050 px/s² | Shared ballistic projectile acceleration |
| `WEAPON_HOMING_TURN_RATE` | 7.5 rad/s | Maximum homing steering rate |
| `WEAPON_RANDOM_AIM_MAX_DEGREES` | 70° | Random-aim half-angle around the forward runner direction |
| `WEAPON_SCREEN_MARGIN_PIXELS` | 48 px | Small viewport margin used for on-screen enemy eligibility |
| `BIOME_INTERVAL` | 48 tiles | Horizontal length of each biome encounter |
| `GENERATION_DISTANCE_AHEAD` | 36 tiles | Terrain kept generated ahead |
| `CLEANUP_DISTANCE_BEHIND` | 18 tiles | Terrain retention behind the player |
| `START_PLATFORM_START_TILE` | -4 | Tile X where the authored safe starting platform begins |
| `START_PLATFORM_WIDTH` | 20 tiles | Width of the authored safe starting platform |
| `BASE_PLATFORM_HEIGHT` | 8 | Default generated platform row |
| `PLATFORM_MIN_WIDTH` / `PLATFORM_MAX_WIDTH` | 8 / 14 tiles | Width bounds for mandatory procedural platforms |
| `PLATFORM_MIN_GAP` / `PLATFORM_MAX_GAP` | 1 / 3 tiles | Candidate horizontal gap bounds before reachability clamping |
| `PLATFORM_MAX_HEIGHT_STEP` | 1 tile | Maximum ordinary vertical step between adjacent mandatory platforms |
| `CHUNK_MIN_SPAN` | 8 tiles | Minimum procedural chunk span |
| `CHUNK_MAX_SPAN` | 16 tiles | Maximum procedural chunk span |
| `WORLD_MIN_HEIGHT_TILE` | 6 | Highest generated mandatory platform row |
| `WORLD_MAX_HEIGHT_TILE` | 9 | Lowest generated mandatory platform row |
| `OPTIONAL_ROUTE_CHANCE` | 0.35 | Chance used by eligible archetypes for risky bonus routes |
| `CAVE_CLEARANCE_TILES` | 4 tiles | Vertical clearance reserved by cave archetypes |
| `TERRAIN_SOURCE_TILE_SIZE` | 128 px | Source atlas cell size in `spritesheet-tiles-double.png` |
| `TERRAIN_ATLAS_SEPARATION` | 1 px | Pixel separation between source atlas cells |
| `CAMERA_LOOK_AHEAD` | 4 tiles | Horizontal camera lead |
| `GRAVITY` | 1800 px/s² | Player gravity |
| `KILL_PLANE_Y` | 1050 px | Falling past this Y coordinate kills the player |
| `DAMAGE_INVULNERABILITY` | 0.45 s | Damage re-hit protection |
| `DAMAGE_FLASH_DURATION` | 0.12 s | Red damage-feedback duration |
| `REVIVE_INVULNERABILITY` | 1.0 s | Protection window immediately after revival |
| `GAME_OVER_NUMBER_OF_SECS` | 3.0 s | Maximum time without meaningful forward progress before stuck death |
| `COUNTDOWN_SECS` | 5.0 s | Time available to use a revival potion before final game-over |
| `STUCK_PROGRESS_THRESHOLD` | 0.125 tiles | Minimum horizontal advance that resets the stuck timer |
| `SAFE_CHECKPOINT_INTERVAL_TILES` | 2 tiles | Minimum forward spacing between safe checkpoint captures |
| `PLAYER_COLLISION_WIDTH` / `PLAYER_COLLISION_HEIGHT` | 34 / 58 px | Standing player collision dimensions |
| `ROLL_HEIGHT_RATIO` | 0.52 | Roll hitbox height as a fraction of standing height |
| `SNOW_JUMP_MODIFIER_MIN` | -0.5 tiles | Minimum temporary Snow jump modifier |
| `SNOW_JUMP_MODIFIER_MAX` | +0.5 tiles | Maximum temporary Snow jump modifier |
| `DESERT_CONTACT_DAMAGE` | 8 | Initial Desert heat damage |
| `DESERT_BURN_TICK_DAMAGE` | 4 | Burn damage per hazard tick |
| `DESERT_BURN_TICK_INTERVAL` | 0.75 s | Desert burn hazard tick interval |
| `DESERT_BURN_DURATION` | 1.5 s | Player burn visual/status duration |
| `ASTRO_FALL_WARNING_DURATION` | 0.45 s | Delay between Astro trigger and falling |
| `ASTRO_FALL_GRAVITY` | 1400 px/s² | Downward acceleration of falling Astro cells |
| `ASTRO_FALL_CLEANUP_Y` | 1400 px | World Y at which detached Astro cells release themselves |
| `FORT_SPIKE_DAMAGE` | 18 | Damage while a Fort spike is exposed |
| `FORT_SPIKE_RETRACTED_DURATION` | 1.1 s | Fort spike idle/retracted duration |
| `FORT_SPIKE_RISE_DURATION` | 0.18 s | Fort spike rising animation/state duration |
| `FORT_SPIKE_EXPOSED_DURATION` | 0.85 s | Fort spike damaging duration |
| `FORT_SPIKE_LOWER_DURATION` | 0.18 s | Fort spike lowering animation/state duration |
| `FORT_SPIKE_RETRACT_DISTANCE` | 24 px | Vertical visual offset while a Fort spike is hidden |
| `MIN_MAXIMUM_HEALTH` / `MAX_MAXIMUM_HEALTH` | 100 / 250 | Maximum-health upgrade bounds |
| `MAXIMUM_HEALTH_UPGRADE` / `MAXIMUM_HEALTH_UPGRADE_GOLDS` | +25 / 50 gold | Maximum-health upgrade step and fixed cost |
| `MIN_DEFENSE_MULTIPLIER` / `MAX_DEFENSE_MULTIPLIER` | 0.50 / 1.00 | Incoming-damage multiplier bounds; lower is better |
| `DEFENSE_MULTIPLIER_UPGRADE` / `DEFENSE_MULTIPLIER_UPGRADE_GOLDS` | -0.05 / 75 gold | Defense upgrade step and fixed cost |
| `MIN_MELEE_POWER` / `MAX_MELEE_POWER` | 10 / 50 | Melee-power upgrade bounds |
| `MELEE_POWER_UPGRADE` / `MELEE_POWER_UPGRADE_GOLDS` | +5 / 60 gold | Melee-power upgrade step and fixed cost |
| `MIN_ENEMY_FIRE_INTERVAL_MULTIPLIER` / `MAX_ENEMY_FIRE_INTERVAL_MULTIPLIER` | 1.0 / 2.0 | Enemy firing-interval multiplier bounds; higher means less frequent enemy shots |
| `ENEMY_FIRE_INTERVAL_MULTIPLIER_UPGRADE` / `ENEMY_FIRE_INTERVAL_MULTIPLIER_UPGRADE_GOLDS` | +0.1 / 80 gold | Enemy firing-interval upgrade step and fixed cost |
| `MIN_INVISIBILITY_DURATION` / `MAX_INVISIBILITY_DURATION` | 2.0 / 6.0 s | Invisibility-duration upgrade bounds |
| `INVISIBILITY_DURATION_UPGRADE` / `INVISIBILITY_DURATION_UPGRADE_GOLDS` | +0.5 s / 100 gold | Invisibility-duration step and fixed cost |
| `MIN_SLOW_DOWN_DURATION` / `MAX_SLOW_DOWN_DURATION` | 2.0 / 6.0 s | Slow-down-duration upgrade bounds |
| `SLOW_DOWN_DURATION_UPGRADE` / `SLOW_DOWN_DURATION_UPGRADE_GOLDS` | +0.5 s / 100 gold | Slow-down-duration step and fixed cost |

Ability tuning remains centralized here so runtime ability scripts contain behavior rather than duplicated balance values.

Per-content tuning that varies by resource is intentionally not duplicated as global constants. Enemy vicinity/shooting cadence, level scaling, status effects, and drop probabilities live in `EnemyData`; weapon damage/cadence/trajectory/aim/target count live in `WeaponData`; biome layout/hazard/collectible weights live in `BiomeData`; stat ranges/costs live in `StatData`; and ability unlock/upgrade metadata lives in `AbilityData`. This preserves the task's user-tunable values while keeping content variation data-driven.

## Stats and upgrades

Phase 6 makes the six requested player stats data-driven. Persistent saves store only the integer upgrade level for each stat as the progression source of truth; `StatCatalog` clamps those levels to each `StatData.max_level()` and derives the effective value. Maximum health, melee power, enemy firing interval, invisibility duration, and slow-down duration increase as levels rise. Defense deliberately runs in the opposite direction: it starts at `1.00` and approaches `0.50`, so the existing `raw_damage * defense_multiplier` formula reduces incoming damage as the stat improves.

`GameState.upgrade_stat(stat_id)` delegates to `StatUpgradeService`, which checks every precondition before mutation: the stat must exist, its required ability must be unlocked, the stat must not be at its limit, and the profile must have enough gold. A successful transaction increments exactly one level, deducts exactly the resource's fixed `upgrade_golds` cost, refreshes derived compatibility values, and emits `profile_changed`. Failed transactions leave both gold and levels unchanged. `invisibility_duration` requires the `invisibility` ability; `slow_down_duration` independently requires `slow_down_time`. The other four stats are available without an ability gate.

Maximum health and defense are consumed by runtime player creation, new `RunState` health starts from the current derived maximum-health value, and Phase 7 automatic melee reads the current derived melee-power value for every hit. Phase 9 now consumes the persisted invisibility and slow-down durations directly; the enemy firing-interval stat and `WorldSpeed` enemy multipliers remain ready for the enemy phase without another save-schema change.

## Player states

`NinjaPlayer` uses the full state vocabulary (`RUNNING`, `JUMPING`, `FALLING`, `ROLLING`, `GLIDING`, `DASHING`, `DEAD`, `REVIVAL_WAIT`). Phase 9 activates `GLIDING` and `DASHING` through `AbilityController`; death/revival cancels transient ability effects, restores normal gravity/detectability, and resets movement ability runtime state before the run resumes.

Damage uses the common `take_damage(amount, damage_info)` entry point and the shared `DamageInfo` payload (`source`, `damage_type`, `status_effect`, `knockback`). The player exposes the full `take_damage`, `heal`, `apply_status`, and `die` contract intended for future enemies as well. Incoming damage applies `raw_damage * defense_multiplier`, gives a short invulnerability window, applies status/knockback metadata, flashes the character red, updates health state, and emits health changes for the HUD.

## Automatic melee combat

The player scene contains a circular `MeleeDetector` `Area2D`. It monitors only `ENEMY_COLLISION_MASK`, resolves overlapping bodies or hurtboxes upward to an object implementing `DamageableContract`, ignores invalid/dead targets that opt out through `can_receive_melee_attack()`, and chooses the nearest remaining target by world-space distance. When the controller is ready, it applies the current `melee_power` stat through a `DamageInfo` payload tagged `MELEE`, then starts `MELEE_ATTACK_INTERVAL`. A target that remains nearby is attacked again only after that cooldown expires.

Melee is automatic and needs no input binding. The player plays the bundled character `Shoot` frames as the Phase 7 melee attack animation because every one of the 45 supplied character sets contains that attack-capable sequence; normal run/jump/fall/roll/dead state animation resumes afterward. Dead and revival-wait players do not invoke the melee controller. Future enemy scenes only need to use the reserved enemy collision layer and implement the shared damage contract; the player does not depend on an enemy-specific class.

## Weapons

Weapons remain unavailable until the profile unlocks the `shooting` ability. `GameState.unlock_weapon()`, `equip_weapon()`, and `unequip_weapon()` delegate to `WeaponInventoryService`, which validates the weapon id and Shooting gate before mutating the profile. Purchases are atomic: insufficient gold, duplicate purchases, locked Shooting, and unknown ids leave both currency and inventory unchanged. Equipment is restricted to unlocked weapons and cannot exceed `NUM_EQUIPPABLE_WEAPONS`.

The initial Phase 8 catalog uses all four supplied `Props/Weapons` categories and deliberately varies damage, cadence, trajectory, aim, and target count:

| Weapon | Damage | Interval | Trajectory | Aim | Targets | Unlock cost |
| --- | ---: | ---: | --- | --- | ---: | ---: |
| Shuriken | 18 | 0.55 s | Straight | Targeted | 1 | 120 |
| Shuriken Fan | 11 | 0.80 s | Straight | Fixed pattern | 3 | 220 |
| Arrow | 34 | 0.95 s | Straight | Forward | 1 | 260 |
| Magic Orb | 24 | 1.15 s | Homing | Targeted | 2 | 360 |
| Throwing Blade | 42 | 1.40 s | Ballistic | Random | 1 | 420 |

`WeaponController` runs automatically while the player is alive and Shooting is unlocked. It gathers damageable enemy nodes from the `enemies` group and the level's `EnemyContainer`, converts their world coordinates through the active viewport/camera transform, and only considers nodes within the visible screen plus a small margin. Targeted weapons choose nearest enemies; random selection uses a seeded `RandomNumberGenerator`; fixed-pattern weapons emit deterministic spread angles; forward weapons always fire along the runner direction. The controller supports `STRAIGHT`, `BALLISTIC`, `ARC`, and `HOMING` motion without hard-coding weapon ids, so later weapon resources can reuse the same simulation code.

Projectiles are independent `Area2D` scenes placed into the level's `ProjectileContainer` when available. They use the reserved enemy collision mask, normalize the widely varying source-art dimensions for display, expire after a bounded lifetime, and call the same damage contract used by melee with `DamageInfo.DamageType.PROJECTILE`. Homing shots steer at a bounded turn rate; ballistic and arc shots use gravity; aim mode remains independent from trajectory, so a ballistic random-aim weapon does not silently become targeted.

## Abilities

Phase 9 adds a common runtime ability interface and keeps each mechanic in a dedicated class owned by `AbilityController`. The persistent profile stores unlocked/equipped ids and upgrade levels; `AbilityInventoryService` validates changes before mutation. Phase 15 completes the purchase path: every non-default ability has a positive `unlock_cost`, insufficient-gold unlocks leave the profile unchanged, and successful unlocks deduct exactly that configured cost. At most `NUM_EQUIPABLE_ABILITIES` can be equipped, and Jump plus Reverse Gravity are rejected as an incompatible pair both during equipment transactions and save sanitization.

| Ability | Unlock cost |
| --- | ---: |
| Jump | Default/unlocked |
| Climb | 150 |
| Glide / Hang | 180 |
| Dash | 250 |
| Shooting | 300 |
| Invisibility | 320 |
| Reverse Gravity | 350 |
| Slow Down Time | 350 |
| Explode | 400 |
| Fly | 450 |

- **Jump** is unlocked/equipped by default. Its level is the number of extra air jumps available before landing: levels 1, 2, and 3 allow one, two, and three air jumps respectively. Landing resets the budget.
- **Climb** converts wall contact into wall jumps. Level 1 allows one wall jump before landing and level 2 allows two; the horizontal wall-normal push briefly overrides automatic running so the player actually detaches from the wall.
- **Glide / Hang** reduces gravity to `GLIDE_GRAVITY_FACTOR` while jump remains held during a fall, for at most `MAX_GLIDE_DURATION` per landing cycle.
- **Reverse Gravity** replaces normal jump behavior when equipped. Each jump activation toggles gravity direction and flips `CharacterBody2D.up_direction`, so floor/ceiling support semantics invert consistently with physics.
- **Fly** permits effectively unlimited air jumps while equipped.
- **Dash** travels exactly `DASH_TILES` at `DASH_SPEED`; its implementation tracks actual X distance after each physics move and ends early on a blocking wall instead of approximating distance with a timer.
- **Explode** applies shared `DamageInfo` explosion damage to damageable enemies inside `EXPLODE_RADIUS`, emits a one-shot particle effect, and removes nearby generated terrain explicitly marked breakable. The authored starting platform is protected.
- **Slow Down Time** uses the `WorldSpeed` autoload rather than `Engine.time_scale`. It applies explicit player/enemy/projectile multipliers for the upgraded `slow_down_duration`; later enemy code can consume the already-defined enemy movement/fire multipliers without coupling UI or cooldown clocks to global time scale.
- **Invisibility** sets `player.detectable = false` for the upgraded `invisibility_duration`. Transparency is feedback only; gameplay systems can query `is_detectable()` / `detectable` directly. Detectability is restored on expiry, death, revival, or unequip.
- **Shooting** remains the passive unlock gate introduced in Phase 8; weapon firing depends on it being unlocked rather than creating a separate active runtime effect.

Dash, Explode, Slow Down Time, and Invisibility use the shared `COOLDOWN_PERIOD`. Movement/passive abilities that need immediate continuous input do not consume that action cooldown.

## Characters

The bundled `assets/Characters/1` through `assets/Characters/45` directories are mapped one-to-one to **45 `CharacterData` resources** in `data/characters/`. Each resource defines a stable id, display name, animation root/SpriteFrames source, and unlock price. `CharacterCatalog` is the lookup boundary used by menus, save sanitization, and player spawning, so raw save values cannot select an unknown asset directory.

Character unlocks are persistent, gold-backed transactions. Selection requires the character to be unlocked first, and `selected_character` is sanitized on load. Character choice is intentionally presentation-only: it changes the player animation set but does not add undocumented character-specific stat bonuses or penalties.

## Profile UI and level HUD

Phase 15 replaces the placeholder launcher with one responsive menu shell backed by the existing catalogs and progression services:

- **Main Menu** — Start Run, Character, Stats, Abilities, Weapons, Settings, Quit, selected-character summary, and persistent gold.
- **Character** — renders all 45 `CharacterData` entries with locked/unlocked/selected state, configured unlock price, preview in graphical runs, and unlock/select actions.
- **Stats** — renders all six `StatData` entries with level, current value, next value, gold cost, ability-gated lock state, and upgrade action.
- **Abilities** — renders all ability definitions with level, cooldown metadata, unlock price, lock/equip state, unlock/equip/unequip/upgrade actions, current loadout summary, four-slot enforcement, and Jump/Reverse Gravity conflict feedback.
- **Weapons** — renders every `WeaponData` entry with the task-required **Name, Damage, Trajectory, Aim, Targets, Locked/Unlocked, Equipped, and Price** fields. The screen also exposes the Shooting prerequisite and delegates purchase/equipment rules to `WeaponInventoryService`.
- **Settings** — exposes the persistent **BOTTOM LEFT / BOTTOM RIGHT** mobile action-button cluster preference and an input reference for desktop/mobile controls.

The level HUD now shows health, gold, revival-potion count, horizontal tiles travelled, active biome, equipped weapon state, and the dense direct-action ability mapping. Active ability slots append their live cooldown seconds, and mobile ability buttons use the same cooldown source and disable themselves until the action is ready. Enemy health bars remain attached above generic enemy instances through the Phase 10 enemy scene.

The supplied `assets/UI` window, button/icon, avatar-slot, weapon-slot, coin, and magic art is resolved at runtime for graphical sessions. Headless mode intentionally skips those texture loads, keeping automated tests independent of the repository's very large first-time art import.

## Enemies

Phase 10 uses one reusable enemy scene for the supplied enemy character families. `EnemyData` resources select biome, minimum encounter, level-scaled health/damage, stationary versus patrol movement, melee/shoot/hybrid attack modes, ranged style, cadence/ranges, animation folders, one optional themed `StatusEffect` resource, and the Phase 12 collectible drop table. `EnemyCatalog` and the biome pools restrict definitions to their intended environments, while `EnemySpawner` derives deterministic per-chunk spawn choices from the run seed and removes every enemy when its streamed chunk is retired. Higher `minimum_encounter` values introduce stronger variants only on later biome encounters.

Projectiles use `Area2D` gameplay hitboxes and beams resolve with ray queries; particles/lines are presentation only. Both paths dispatch the shared `DamageInfo` contract, so melee, ranged attacks, biome hazards, and status effects reach player/enemy health through the same damage boundary. Enemy health bars follow the level-scaled health component and are updated independently of sprite animation.

## Status effects

Phase 11 represents temporary effects as data rather than dedicated timers in `player.gd` or `enemy.gd`. A `StatusEffect` resource defines `duration`, `tick_interval`, `stack_policy`, `max_stacks`, optional tick damage, movement and damage-taken multipliers, tint priority, flame presentation, and periodic red-blink presentation. Its `on_apply`, `on_tick`, and `on_remove` hooks call a small target-facing contract. `StatusEffectController` owns active instances, remaining time and stack counts, and is reused unchanged by both the player and generic enemy scene.

The catalog contains the required generic **Freeze**, **Burn**, **Blood Loss**, **Poison**, and **Slow** effects plus the themed statuses referenced by Phase 10 enemies. Freeze-family effects provide ice-blue tinting and movement reduction; Burn-family effects request the player's flame `GPUParticles2D`; Blood Loss, Poison, and other periodic wounds execute deterministic tick damage, with Blood Loss producing the required red blink. Damage-amplifying effects compose with the player's persistent defense multiplier rather than replacing it. Revival clears the controller atomically, so no stale DOT or movement modifier survives checkpoint restoration.

Stack behavior is explicit per resource: `REFRESH` restarts duration, `EXTEND` adds duration, `STACK` increments up to `max_stacks` and refreshes duration, and `IGNORE` rejects reapplication while active. `DamageInfo` normalizes incoming status values through `StatusEffectCatalog`; this preserves compatibility with older dictionary-shaped hazard/test payloads without letting gameplay code continue to depend on dictionary keys. Enemy resources now reference actual `.tres` status resources directly, and Desert heat likewise uses the canonical Burn resource.

## Collectibles

Phase 12 defines six data-driven collectibles using the supplied art: Bronze Coin (1 gold), Silver Coin (3), Gold Coin (8), Blue Gem (20), Green Gem (30), and Yellow Gem (45). The lowest-value gem is therefore worth more than the highest-value coin. `CollectiblePickup` is one reusable `Area2D` scene for every type; it only reacts to the player physics layer, awards gold through `GameState.add_gold()`, emits its collection event once, and immediately retires itself so a pickup cannot be collected twice. The level HUD listens to profile changes and displays the live persistent gold total.

`CollectibleSpawner` listens to the same streamed chunk lifecycle as enemies. It reads each biome's `collectible_weights`, derives placement difficulty from geometry archetype/elevation, and increases the relative weight of premium coins as difficulty rises. Gems are intentionally excluded from every biome pool and their `CollectibleData` resources are marked `spawnable = false`, so procedural generation cannot place them. Mandatory platform slots use a bounded difficulty-scaled spawn chance, while the generator's `bonus_spawn_tiles` on risky optional routes are guaranteed reward slots. Every chunk is capped by `COLLECTIBLE_MAX_PER_CHUNK`, tracked by chunk id, and cleaned with that chunk so uncollected rewards cannot accumulate without bound.

Enemy drops use `EnemyData.drop_table` entries containing `collectible_id`, `probability`, `min_count`, and `max_count`. Default enemy data provides common coin drops plus rarer Blue, Green, and Yellow gem drops; gems remain `droppable = true` and are obtainable only through this enemy-death pipeline. Spawned pickups retain a source tag (`procedural` or `enemy_drop`) for validation/telemetry. Individual enemy resources can override the table without changing enemy behavior code. `RngService` wraps a seeded `RandomNumberGenerator` and is injectable into spawn/drop calculations, making both probability outcomes and replay tests deterministic. Runtime enemy-drop seeds combine the run seed, streamed chunk, enemy id/level, and death position so an identical generated encounter reproduces the same rewards.

## Consumables

Revival potions are persistent profile consumables and use the bundled `revival_potion.png` presentation in graphical runs. When the player enters the revival countdown, a potion can be consumed to restore health, clear lethal temporary statuses, return to the most recent safe checkpoint, grant brief revival invulnerability, and resume the same run. If no potion is used before `COUNTDOWN_SECS` expires, the run ends.

## Health, stuck detection, revival, and game-over

`level.gd` tracks actual X-position progress rather than velocity. Moving forward by at least `STUCK_PROGRESS_THRESHOLD` resets the stuck timer; remaining below that progress threshold for `GAME_OVER_NUMBER_OF_SECS` enters the same death/revival path as zero health or falling below the kill plane. The detector does not advance while the run is halted for revival/game-over, and normal SceneTree pause semantics also suspend it.

The level retains a `SafeCheckpoint` containing position, biome id, and tile index. The initial spawn is a fallback checkpoint; after that, checkpoint updates occur only on grounded, living, status-free, non-invulnerable progress and are spaced by `SAFE_CHECKPOINT_INTERVAL_TILES` so a lethal hazard does not immediately overwrite the previous safe point. The current checkpoint is mirrored into `GameState.run`.

On death or stuck detection, the player enters `REVIVAL_WAIT`, moving world gameplay is disabled without globally pausing the SceneTree, and a `COUNTDOWN_SECS` UI appears. If `revival_potions > 0`, the supplied revival-potion art is used on the revive button in non-headless runs. Using a potion decrements inventory, teleports to the safe checkpoint, restores health, clears active statuses, grants `REVIVE_INVULNERABILITY`, resets stuck tracking, and resumes streamed gameplay. If the countdown reaches zero, the state becomes final game-over and exposes restart/menu controls.

## Procedural world generation

`WorldStreamer` generates only to `GENERATION_DISTANCE_AHEAD` and erases chunks that fall behind `CLEANUP_DISTANCE_BEHIND`. Geometry and biome RNG streams are independently seeded from the run seed, so changing how many random values a layout consumes does not silently change the biome sequence.

`BiomeSequence.get_biome_for_tile(tile_x)` keeps biome selection independent from terrain geometry. The first six encounters are fixed in the required order. Once that traversal completes, later encounters are selected randomly from the six-biome catalog with immediate repetition excluded.

Each biome resource assigns weights to the seven Phase 2 geometry archetypes:

- `FLAT`
- `FLYING_PLATFORMS`
- `MOUNTAIN`
- `CAVE`
- `STAIRS`
- `STACKED_PLATFORMS`
- `GAPS`

Mandatory platform transitions are constrained by the same `SPEED`, effective jump height, `GRAVITY`, and tile-size movement envelope used by the player. In Snow, both the player and generator derive the same encounter-specific jump modifier from the run seed, so generation remains conservative even when Snow reduces jump height. Layout generation clamps height changes and computes the maximum reachable horizontal gap for the destination elevation. Optional stacked/flying routes are marked separately and expose `bonus_spawn_tiles` metadata consumed by the Phase 12 collectible spawner without making those routes mandatory.

Static terrain is painted into a `TileMapLayer`. `TerrainTileSetFactory` builds six terrain definitions and collision polygons from the supplied `assets/Spritesheets/spritesheet-tiles-double.png` atlas, whose 128×128 cells use a one-pixel separation. The biome families currently map to grass, dirt/tundra, snow, sand/desert, purple/astro, and stone/fort atlas regions. Astro terrain cells are deliberately omitted from the static layer and instantiated as independent `FallingTile` scenes instead; their explicit coordinate/support registry is also cleaned with streamed chunks.

## Biomes

- **Grass** is the baseline biome and adds no mandatory status or hazard mechanic.
- **Tundra** changes presentation/data pools but intentionally keeps baseline movement so it remains mechanically distinct from Snow.
- **Snow** derives a temporary `MAX_JUMP` modifier in the configured `-0.5 .. +0.5` tile range. The value is deterministic for a run seed and Snow encounter, never mutates persistent player progression, and is shared with procedural reachability calculations.
- **Desert** procedurally places `DesertHazard` `Area2D` scenes. Contact inflicts fire damage and applies a burn status; an independent timer can apply burn ticks while bundled flame visuals are handled through `GPUParticles2D`.
- **Astro** represents its generated terrain cells with reusable `FallingTile` `CharacterBody2D` scenes instead of static TileMap cells, so every Astro block falls when the player steps on it. Contact starts a warning delay, then the block falls. Explicit support links notify registered blocks above when support disappears, making chain reactions deterministic and unit-testable.
- **Fort** procedurally places `SpikeHazard` scenes using the bundled spike art. The trap cycles through `RETRACTED → RISING → EXPOSED → LOWERING`, and the damage hitbox is enabled only during `EXPOSED`.

Each `BiomeData` resource carries its terrain-set identifier, background color, enemy-pool identifiers, layout weights, hazard type/chance, collectible weights, and optional particle reference. Enemy spawning consumes the biome pools, while Phase 12 now consumes the collectible weights directly for procedural reward selection.

## Running tests

Run the headless test suite with:

```sh
godot --headless --path . tests/test_runner.tscn
```

## Test inventory

The headless runner currently contains **170 tests**. The exact function inventory is grouped by subsystem below.

### Core configuration and Phase 1 scene

- `test_config_values_are_valid`
- `test_game_state_reset_is_seeded`
- `test_input_actions_configured`
- `test_phase1_assets_exist`
- `test_level_scene_has_phase1_architecture`

### Biomes, procedural generation, and streaming

- `test_biome_data_is_valid`
- `test_first_biomes_are_ordered`
- `test_biome_changes_after_interval`
- `test_later_biomes_are_seeded_random_without_immediate_repeat`
- `test_seed_reproduces_biome_sequence`
- `test_world_streamer_is_deterministic`
- `test_generated_platform_specs_are_reachable`
- `test_all_geometry_archetypes_generate_reachable_routes`
- `test_generator_respects_biome_boundaries`
- `test_long_generator_smoke_is_reachable_and_deterministic`
- `test_optional_routes_expose_bonus_spawn_slots`
- `test_tileset_uses_required_atlas_and_collisions`
- `test_world_streamer_generates_ahead`
- `test_world_streamer_cleans_behind`

### Player movement, damage, and camera

- `test_player_auto_run_speed`
- `test_player_jump_limit`
- `test_roll_changes_hitbox`
- `test_roll_duration_restores_hitbox`
- `test_animation_state_selection`
- `test_common_damage_contract`
- `test_damage_applies_defense`
- `test_damage_invulnerability_window`
- `test_damage_flashes_red`
- `test_fall_sets_health_zero`
- `test_camera_tracks_x_only`
- `test_level_advances_distance`

### Game-over, stuck detection, and revival

- `test_zero_health_triggers_countdown`
- `test_stuck_player_triggers_countdown`
- `test_safe_checkpoint_tracks_stable_progress`
- `test_revive_consumes_potion`
- `test_revive_restores_checkpoint`
- `test_countdown_without_potion_ends_run`
- `test_stuck_detection_is_suspended_during_revival`

### Profile persistence and save compatibility

- `test_profile_defaults_cover_phase5_progression`
- `test_profile_and_run_state_are_separate`
- `test_run_state_is_not_persisted`
- `test_save_profile_round_trip`
- `test_missing_save_creates_defaults`
- `test_corrupted_save_creates_defaults`
- `test_unsupported_save_version_creates_defaults`
- `test_legacy_v1_profile_backfills_phase5_defaults`

### Stats and upgrades

- `test_stat_definitions_are_valid`
- `test_stat_values_follow_levels`
- `test_upgrade_costs_gold`
- `test_each_stat_upgrade_uses_definition`
- `test_upgrade_requires_enough_gold_is_atomic`
- `test_unknown_stat_upgrade_is_atomic`
- `test_upgrade_clamped_to_maximum`
- `test_decreasing_stat_clamped_to_minimum`
- `test_locked_stat_cannot_upgrade`
- `test_stat_levels_sanitize_to_limits`
- `test_runtime_player_uses_upgraded_stats`
- `test_run_health_uses_upgraded_maximum_health`

### Automatic melee

- `test_melee_detector_configuration`
- `test_automatic_melee_attacks_nearest_target`
- `test_automatic_melee_uses_upgraded_power_and_damage_info`
- `test_automatic_melee_respects_cooldown`
- `test_automatic_melee_ignores_invalid_targets`
- `test_automatic_melee_stops_when_player_is_dead`

### Weapons

- `test_weapon_definitions_are_valid`
- `test_weapon_requires_shooting`
- `test_weapon_unlock_costs_gold_atomically`
- `test_weapon_equipment_limit`
- `test_weapon_target_count`
- `test_weapon_forward_aim`
- `test_weapon_targeted_aim`
- `test_weapon_random_aim_is_seeded`
- `test_weapon_fixed_pattern_aim`
- `test_weapon_ballistic_trajectory`
- `test_weapon_controller_requires_shooting`
- `test_weapon_automatic_firing_and_interval`
- `test_weapon_automatic_target_count`
- `test_weapon_ignores_offscreen_enemy`
- `test_weapon_projectile_damage`
- `test_homing_projectile_steers_to_target`

### Biome-specific mechanics and hazards

- `test_phase3_biome_metadata`
- `test_snow_modifier_is_seeded_and_bounded`
- `test_snow_generator_uses_effective_jump`
- `test_snow_changes_player_jump_temporarily`
- `test_desert_hazard_damage_and_burn`
- `test_astro_falling_tile_sequence`
- `test_astro_chain_fall_uses_support_links`
- `test_fort_spike_damage_only_when_exposed`
- `test_fort_spike_cycles_states`
- `test_streamer_spawns_phase3_hazards`
- `test_all_astro_terrain_uses_falling_tiles`
- `test_hazard_placement_is_seeded`
- `test_streamer_cleans_runtime_hazards`
- `test_level_applies_biome_context`

### Abilities

- `test_ability_definitions_are_valid`
- `test_ability_equipment_limit_and_conflict`
- `test_jump_air_jump_levels`
- `test_climb_wall_jump_count`
- `test_glide_duration`
- `test_reverse_gravity_semantics`
- `test_fly_allows_unlimited_air_jumps`
- `test_dash_distance_and_cooldown`
- `test_explode_damage_and_destructible_terrain`
- `test_slow_down_uses_world_multipliers`
- `test_invisibility_detectability_and_duration`

### Enemies

- `test_enemy_biome_restriction`
- `test_enemy_animation_resource_loading`
- `test_enemy_level_scaling`
- `test_enemy_patrol`
- `test_stationary_enemy`
- `test_enemy_melee_vicinity`
- `test_enemy_shooting_vicinity`
- `test_enemy_fire_interval`
- `test_enemy_projectile_damage_and_status`
- `test_enemy_death`
- `test_enemy_health_bar_updates`
- `test_enemy_spawner_is_seeded`
- `test_streamed_enemy_cleanup`

### Status effects

- `test_status_effect_resources_are_valid`
- `test_status_effect_dictionary_compatibility`
- `test_freeze`
- `test_burn`
- `test_blood_loss`
- `test_poison`
- `test_slow`
- `test_status_refresh_policy`
- `test_status_stack_policy`
- `test_status_expiration`
- `test_status_damage_multiplier`
- `test_enemy_uses_generic_status_controller`

### Collectibles and drops

- `test_collectible_definitions_are_valid`
- `test_gem_value_exceeds_coin`
- `test_pickup_increases_gold`
- `test_collectible_spawn_is_seeded`
- `test_collectible_difficulty_biases_value`
- `test_enemy_drop_tables_are_valid`
- `test_enemy_drop_probability_and_count`
- `test_enemy_death_spawns_drops`
- `test_streamed_collectible_cleanup`
- `test_level_collectible_architecture`

### Characters

- `test_character_definitions_are_valid`
- `test_character_unlock_costs_gold_atomically`
- `test_character_selection_requires_unlock`
- `test_character_profile_sanitizes_unknown_ids`
- `test_selected_character_drives_player_presentation`

### Desktop and mobile input

- `test_keyboard_ability_slot_routes_equipped_ability`
- `test_touch_tap_maps_to_jump`
- `test_touch_hold_preserves_jump_hold_semantics`
- `test_swipe_down_maps_to_roll_without_jump`
- `test_mobile_action_buttons_follow_equipped_slots`
- `test_action_button_side_setting_updates_mobile_cluster`
- `test_level_has_phase14_input_hud`

### Menus and HUD

- `test_ability_unlock_costs_gold_atomically`
- `test_phase15_main_menu_navigation`
- `test_phase15_character_screen`
- `test_phase15_stats_screen`
- `test_phase15_abilities_screen`
- `test_phase15_weapons_screen`
- `test_phase15_settings_screen`
- `test_level_has_phase15_hud`

### Phase 16 integration and procedural stress

- `test_phase16_player_jumps_onto_generated_platform`
- `test_phase16_roll_clears_low_obstacle`
- `test_phase16_enemy_projectile_damages_player`
- `test_phase16_player_melee_damages_nearby_enemy`
- `test_phase16_collectible_is_collected_during_auto_run`
- `test_phase16_biome_transition_swaps_terrain_and_enemy_pool`
- `test_phase16_revival_resumes_streamed_world`
- `test_phase16_hud_reflects_game_state`
- `test_phase16_procedural_stress`

Physics-sensitive tests instantiate the real player, projectile, hazard, enemy, and pickup scenes under the headless Godot physics loop rather than testing duplicate movement formulas outside the engine. The generator smoke test also walks many seeded chunks and checks every mandatory transition, biome boundary, and deterministic replay rather than validating only a few hand-picked layouts. Phase 3 tests additionally verify Snow's shared player/generator modifier, Desert damage/burn, Astro warning/fall/support propagation, Fort damage gating, hazard spawning, and streamed hazard cleanup. Phase 4 tests verify the shared damage contract/payload, defense application, zero-health countdown, progress-based stuck detection, checkpoint advancement, potion consumption, checkpoint restoration, health/status restoration, world halt/resume, no-potion final game-over, and stuck-detection suspension during revival. Phase 5 tests verify the full persistent profile schema, profile/run separation, progression round trips, missing/corrupted/unsupported saves, and backward-compatible loading of the earlier additive version-1 profile. Phase 6 tests verify every stat definition, increasing/decreasing value derivation, fixed upgrade cost, transactional failure behavior, upper/lower clamps, ability-gated stats, persisted-level sanitization, runtime player health/defense integration, and upgraded starting run health. Phase 7 tests instantiate real `Area2D`/physics overlaps and verify detector configuration, nearest valid-target selection, contract filtering, upgraded melee damage, `MELEE` `DamageInfo`, cooldown repeat timing, attack animation selection, and dead-state suppression. Phase 8 tests verify resource validity and supplied assets, Shooting-gated purchases, atomic gold handling, the equipment cap, target counts, all four aim modes, deterministic random aim, ballistic reachability math, automatic on-screen firing/cooldowns, off-screen suppression, real projectile collision damage, and homing steering. Phase 9 tests verify every ability resource, equipment caps/conflicts, all Jump levels and landing reset, Climb wall-jump budgets, Glide duration, Reverse Gravity support semantics, unlimited Fly jumps, exact travelled Dash distance/cooldown, explosion radius plus protected/destructible terrain, explicit slow-time subsystem multipliers without `Engine.time_scale`, and Invisibility's gameplay detectability/expiry. Phase 10 tests verify biome-constrained enemy catalogs, encounter/level scaling, patrol/stationary behavior, melee/shoot ranges and cadence, projectile status dispatch, death/health bars, deterministic spawning, and streamed cleanup. Phase 11 tests verify canonical resource validity, boundary normalization of legacy payloads, Freeze movement/tint, Burn particles, Blood Loss DOT/blink, Poison ticks, Slow movement, refresh/stack policies, expiration cleanup, and damage-multiplier composition with defense. Phase 12 tests verify collectible resource validity/value ordering, persistent gold pickup behavior, deterministic weighted placement, increased premium weighting on risky platforms, valid `[0, 1]` enemy drop probabilities, deterministic probability/count handling, death-signal drop integration, streamed pickup cleanup, and the level/HUD collectible architecture. Phase 13 tests verify all 45 character definitions and animation mappings, non-negative/purchasable costs, atomic gold handling, unlock-before-selection rules, invalid-save ID sanitation, and that a spawned player resolves presentation from the persisted selected `CharacterData`. Phase 14 tests verify the physical Up/Down/1–4 bindings, source-agnostic dense direct-action routing, exclusion of Jump-family/passive abilities from numbered slots, tap-to-jump, swipe-down-to-roll without duplicate jump, matching touch-button mappings, persisted left/right cluster placement, and the level's input/HUD scene architecture. Phase 15 tests verify atomic ability purchase costs, all required main-menu destinations, every catalog-backed character/stat/ability/weapon card, the required weapon description fields, persisted Settings presentation, and the level HUD's health/gold/consumable/distance/weapon/ability information including a live runtime cooldown. Phase 16 adds scene-level integration coverage for generated-platform jumping, rolling beneath a low obstacle, enemy projectile dispatch into the real player damage/status pipeline, automatic melee, auto-run pickup collection, biome terrain/enemy-pool transitions, revival/world resume, and HUD/GameState synchronization. Its procedural stress pass runs 100 deterministic seeds through at least 10,000 horizontal tiles each and validates mandatory-route reachability, biome/resource validity, supported enemy and collectible placement, forward generator progress, and bounded simulated streamed-chunk retention.

## Save data

`SaveManager` uses `user://save.json` with `save_version = 1`. Phase 13 does not require a schema bump because `unlocked_characters` and `selected_character` were introduced in Phase 5; it now validates those IDs against the 45-entry `CharacterCatalog` instead of accepting arbitrary positive integers. Phase 12 likewise reuses the existing persistent `gold` field for collectible rewards. Phase 9 activates the `unlocked_abilities`, `equipped_abilities`, and `ability_levels` fields added in Phase 5, while Phase 8 continues to use the weapon fields and melee continues to consume the Phase 6 stat model. Older Phase 4 version-1 saves that contain only numeric maximum-health/defense fields are still migrated to the nearest valid stat levels, while current saves derive numeric compatibility fields from the persisted levels.

Persistent `PlayerProfile` data now includes:

- gold
- unlocked and selected characters
- stat levels
- unlocked/equipped abilities and ability levels
- unlocked/equipped weapons
- consumables, including revival potions
- settings, including the mobile action-button side
- derived compatibility values for maximum health, defense, melee power, enemy firing interval, invisibility duration, and slow-down duration; `stat_levels` remains their persisted progression source of truth

Transient `RunState` is intentionally not written to the profile save. It owns current health, horizontal distance, current biome, temporary effects, run seed, checkpoint data, and revival/game-over fields. Loading a profile therefore cannot resurrect or overwrite an in-progress run by accident.

Save loading validates the root type and `save_version`, sanitizes collection/scalar types, clamps non-negative progression values, removes invalid equipped entries, enforces configured equipment limits during deserialization, and restores a safe default profile when the file is missing, malformed, or uses an unsupported version.

## Implementation status

Phases 1–17 are complete. The required Main Menu, Character, Stats, Abilities, Weapons, Settings screens and expanded Level HUD are implemented; persistent transactions route through the progression services; desktop and mobile input share the same logical action boundary; procedural generation is deterministic and bounded; all six biome mechanics are active; and the headless suite includes the dedicated integration scenarios plus the 100-seed/10,000-tile-per-seed procedural stress coverage described above. This README documents the complete current configuration and all 168 test functions.

## Assets

The project uses the assets already bundled under `assets/`, including the 45 character animation sets (with their `Shoot` sequence reused for Phase 7 melee feedback), `spritesheet-tiles-double.png`, `assets/Props/Spikes.png`, the bundled flame particle frames, and weapon props from `Props/Weapons/Mage`, `Ranged`, `Shuriken`, and `Swords`. No additional third-party assets were introduced by the phased implementation.

No `LICENSE`, `COPYING`, credits, attribution, or asset-pack README file is present in the checked-out repository or under `assets/`. Accordingly, this README does **not** infer or invent licensing terms. Before redistribution, obtain and follow the licensing/attribution terms from the original repository or original asset source.
