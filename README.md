# Ninja Run

Ninja Run is a Godot 4.7 2D endless-runner project. The repository is being implemented in phases; **Phase 1 (core playable runner)**, **Phase 2 (procedural world generation)**, **Phase 3 (biome mechanics)**, **Phase 4 (health, damage, stuck detection, and revival/game-over loop)**, and **Phase 5 (persistent player progression)** are implemented in this branch.

## Requirements

- Godot 4.7.x
- Mobile renderer (configured in `project.godot`)

## Running the game

Open the project in the Godot editor once so the bundled asset library can be imported, then run the project with **F5**. After that first import, it can also be launched directly from a shell:

```sh
godot --path .
```

The repository contains a large asset pack, so the editor's first import is substantially heavier than normal startup. The headless test suite below can read the required terrain PNG directly and does not require importing the complete asset library.

Desktop controls:

- **Up Arrow** — jump
- **Down Arrow** — roll

The player continuously runs to the right. Procedural terrain streams ahead, old chunks and runtime hazards are removed behind the run, and the camera follows horizontal progress with look-ahead. Falling below the kill plane, losing all health, or failing to make horizontal progress for `GAME_OVER_NUMBER_OF_SECS` starts the Phase 4 revival countdown. A revival potion returns the player to the most recent safe checkpoint with restored health, cleared statuses, and brief invulnerability; otherwise the countdown ends in final game-over. The first traversal is always **Grass → Tundra → Snow → Desert → Astro → Fort**, with each biome lasting `BIOME_INTERVAL` tiles; later biome encounters are seeded-random and never immediately repeat the previous biome. Snow temporarily varies jump height, Desert adds fire/burn zones, Astro substitutes selected terrain cells with falling blocks, and Fort adds cycling spike traps.

## Phase 1–5 architecture

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
  player/
    player.tscn
src/
  core/
    game_config.gd
    game_state.gd
    player_profile.gd
    run_state.gd
    save_manager.gd
  data/
    biome_data.gd
  gameplay/
    combat/
      damage_info.gd
      damageable_contract.gd
    hazards/
      desert_hazard.gd
      falling_tile.gd
      spike_hazard.gd
    level/
      level.gd
      safe_checkpoint.gd
    player/player.gd
    world/biome_catalog.gd
    world/biome_mechanics.gd
    world/biome_sequence.gd
    world/platform.gd
    world/procedural_layout_generator.gd
    world/terrain_tileset_factory.gd
    world/world_streamer.gd
  ui/main.gd
data/
  biomes/
    grass.tres
    tundra.tres
    snow.tres
    desert.tres
    astro.tres
    fort.tres
tests/
  test_runner.gd
```

Responsibilities are deliberately separated: `GameConfig` owns source tuning values, `PlayerProfile` owns the persistent profile schema/defaults/sanitization rules, `RunState` owns transient per-run state, `GameState` coordinates their live dictionaries and emits change signals, and `SaveManager` owns versioned disk persistence. `DamageInfo` carries normalized damage metadata, `DamageableContract` defines the common damage API expected from players and future enemies, `SafeCheckpoint` owns checkpoint data, player code owns movement/health/status feedback, and `level.gd` owns stuck/revival/game-over orchestration. `BiomeSequence` owns encounter selection, `BiomeMechanics` derives deterministic encounter-specific modifiers, `ProceduralLayoutGenerator` owns deterministic geometry specs, `TerrainTileSetFactory` owns the atlas/physics definition, and `WorldStreamer` owns bounded terrain plus runtime-hazard lifetime. Biome presentation, enemy-pool identifiers, generation weights, collectible weights, and hazard selection live in `BiomeData` resources rather than branching through `level.gd`.

## Configuration

The task-defined `CONSTANT_CASE` tuning variables are centralized in `src/core/game_config.gd`. Phase 1–5 actively use the following values:

| Setting | Default | Meaning |
| --- | ---: | --- |
| `TILE_SIZE` | 64 px | Pixel size used for tile-space conversion |
| `SPEED` | 6 tiles/s | Automatic horizontal run speed |
| `MAX_JUMP` | 3 tiles | Maximum jump height target |
| `ROLL_DURATION` | 0.65 s | Time the shortened roll hitbox remains active |
| `BIOME_INTERVAL` | 48 tiles | Horizontal length of each biome encounter |
| `GENERATION_DISTANCE_AHEAD` | 36 tiles | Terrain kept generated ahead |
| `CLEANUP_DISTANCE_BEHIND` | 18 tiles | Terrain retention behind the player |
| `CHUNK_MIN_SPAN` | 8 tiles | Minimum procedural chunk span |
| `CHUNK_MAX_SPAN` | 16 tiles | Maximum procedural chunk span |
| `WORLD_MIN_HEIGHT_TILE` | 6 | Highest generated mandatory platform row |
| `WORLD_MAX_HEIGHT_TILE` | 9 | Lowest generated mandatory platform row |
| `OPTIONAL_ROUTE_CHANCE` | 0.35 | Chance used by eligible archetypes for risky bonus routes |
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

The remaining task-level variables (equipment limits, glide/dash/explode/cooldown values) are centralized now so later phases do not scatter them across gameplay scripts.

## Player states

`NinjaPlayer` defines the planned state vocabulary (`RUNNING`, `JUMPING`, `FALLING`, `ROLLING`, `GLIDING`, `DASHING`, `DEAD`, `REVIVAL_WAIT`). Running, jumping, falling, rolling, dead, and revival-wait states are active through Phase 4; glide and dash remain reserved for their later ability phases.

Damage uses the common `take_damage(amount, damage_info)` entry point and the shared `DamageInfo` payload (`source`, `damage_type`, `status_effect`, `knockback`). The player exposes the full `take_damage`, `heal`, `apply_status`, and `die` contract intended for future enemies as well. Incoming damage applies `raw_damage * defense_multiplier`, gives a short invulnerability window, applies status/knockback metadata, flashes the character red, updates health state, and emits health changes for the HUD.

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

Mandatory platform transitions are constrained by the same `SPEED`, effective jump height, `GRAVITY`, and tile-size movement envelope used by the player. In Snow, both the player and generator derive the same encounter-specific jump modifier from the run seed, so generation remains conservative even when Snow reduces jump height. Layout generation clamps height changes and computes the maximum reachable horizontal gap for the destination elevation. Optional stacked/flying routes are marked separately and expose `bonus_spawn_tiles` metadata for later collectible placement without making those routes mandatory.

Static terrain is painted into a `TileMapLayer`. `TerrainTileSetFactory` builds six terrain definitions and collision polygons from the supplied `assets/Spritesheets/spritesheet-tiles-double.png` atlas, whose 128×128 cells use a one-pixel separation. The biome families currently map to grass, dirt/tundra, snow, sand/desert, purple/astro, and stone/fort atlas regions. Astro terrain cells are deliberately omitted from the static layer and instantiated as independent `FallingTile` scenes instead; their explicit coordinate/support registry is also cleaned with streamed chunks.

## Biome mechanics

- **Grass** is the baseline biome and adds no mandatory status or hazard mechanic.
- **Tundra** changes presentation/data pools but intentionally keeps baseline movement so it remains mechanically distinct from Snow.
- **Snow** derives a temporary `MAX_JUMP` modifier in the configured `-0.5 .. +0.5` tile range. The value is deterministic for a run seed and Snow encounter, never mutates persistent player progression, and is shared with procedural reachability calculations.
- **Desert** procedurally places `DesertHazard` `Area2D` scenes. Contact inflicts fire damage and applies a burn status; an independent timer can apply burn ticks while bundled flame visuals are handled through `GPUParticles2D`.
- **Astro** represents its generated terrain cells with reusable `FallingTile` `CharacterBody2D` scenes instead of static TileMap cells, so every Astro block falls when the player steps on it. Contact starts a warning delay, then the block falls. Explicit support links notify registered blocks above when support disappears, making chain reactions deterministic and unit-testable.
- **Fort** procedurally places `SpikeHazard` scenes using the bundled spike art. The trap cycles through `RETRACTED → RISING → EXPOSED → LOWERING`, and the damage hitbox is enabled only during `EXPOSED`.

Each `BiomeData` resource now carries its terrain-set identifier, background color, enemy-pool identifiers, layout weights, hazard type/chance, collectible weights, and optional particle reference. Enemy and collectible systems consume these fields in their later implementation phases; Phase 3 establishes the data contract without prematurely implementing those later systems.

## Tests

Run the headless test suite with:

```sh
godot --headless --path . tests/test_runner.tscn
```

Phase 1–5 test inventory:

- `test_config_values_are_valid`
- `test_game_state_reset_is_seeded`
- `test_input_actions_configured`
- `test_phase1_assets_exist`
- `test_level_scene_has_phase1_architecture`
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
- `test_zero_health_triggers_countdown`
- `test_stuck_player_triggers_countdown`
- `test_safe_checkpoint_tracks_stable_progress`
- `test_revive_consumes_potion`
- `test_revive_restores_checkpoint`
- `test_countdown_without_potion_ends_run`
- `test_stuck_detection_is_suspended_during_revival`
- `test_profile_defaults_cover_phase5_progression`
- `test_profile_and_run_state_are_separate`
- `test_run_state_is_not_persisted`
- `test_save_profile_round_trip`
- `test_missing_save_creates_defaults`
- `test_corrupted_save_creates_defaults`
- `test_unsupported_save_version_creates_defaults`
- `test_legacy_v1_profile_backfills_phase5_defaults`
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

Physics-sensitive tests instantiate the real player and hazard scenes under the headless Godot physics loop rather than testing duplicate movement formulas outside the engine. The generator smoke test also walks many seeded chunks and checks every mandatory transition, biome boundary, and deterministic replay rather than validating only a few hand-picked layouts. Phase 3 tests additionally verify Snow's shared player/generator modifier, Desert damage/burn, Astro warning/fall/support propagation, Fort damage gating, hazard spawning, and streamed hazard cleanup. Phase 4 tests verify the shared damage contract/payload, defense application, zero-health countdown, progress-based stuck detection, checkpoint advancement, potion consumption, checkpoint restoration, health/status restoration, world halt/resume, no-potion final game-over, and stuck-detection suspension during revival. Phase 5 tests verify the full persistent profile schema, profile/run separation, progression round trips, missing/corrupted/unsupported saves, and backward-compatible loading of the earlier additive version-1 profile.

## Save data

`SaveManager` uses `user://save.json` with `save_version = 1`. Phase 5 keeps version 1 because the schema expansion is additive: older Phase 4 version-1 saves are loaded, sanitized, and backfilled with the new defaults instead of being discarded.

Persistent `PlayerProfile` data now includes:

- gold
- unlocked and selected characters
- stat levels
- unlocked/equipped abilities and ability levels
- unlocked/equipped weapons
- consumables, including revival potions
- settings, including the mobile action-button side
- the Phase 4 maximum-health/defense values retained until Phase 6 derives them from stat definitions

Transient `RunState` is intentionally not written to the profile save. It owns current health, horizontal distance, current biome, temporary effects, run seed, checkpoint data, and revival/game-over fields. Loading a profile therefore cannot resurrect or overwrite an in-progress run by accident.

Save loading validates the root type and `save_version`, sanitizes collection/scalar types, clamps non-negative progression values, removes invalid equipped entries, enforces configured equipment limits during deserialization, and restores a safe default profile when the file is missing, malformed, or uses an unsupported version.

## Scope after Phase 5

The following requested systems are intentionally not claimed as implemented yet: stat upgrade transactions, enemies, automatic melee, weapon gameplay, ability gameplay, collectible spawning/drop tables, character shop, full menu set, and mobile gesture controls. They remain later phases from `task.md` and should build on the deterministic biome/chunk/hazard, Phase 4 health/revival foundation, and Phase 5 persistence schema now in place.

## Assets

The project uses the assets already bundled under `assets/`, including the character animation sets, `spritesheet-tiles-double.png`, `assets/Props/Spikes.png`, and the bundled flame particle frames. No additional third-party assets were introduced by the Phase 1–3 implementation. Before redistribution, use the licensing/attribution terms supplied with the original asset pack/repository; this implementation does not invent licensing claims where metadata is absent.
