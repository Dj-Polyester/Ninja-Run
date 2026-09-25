# Ninja Run

Ninja Run is a Godot 4.7 2D runner with six deterministic streamed biomes and hazards, enemies/status effects, collectibles/melee/weapons, all ten abilities, touch/desktop input parity, shops/settings, and persistent profile progression. Production Level has no hidden flat floor: reachable platform, mountain, and cave chunk forms are realized from the supplied tile atlas. The first biome pass is exactly Grass, Tundra, Snow, Desert, Astro, Fort in `BIOME_INTERVAL`-column segments; later segments are seeded and never immediately repeat. Profile gold, potions, characters, stats, abilities, weapons, equipment, and settings are versioned and autosaved; per-run health, distance, statuses, cooldown timestamps, and earned run gold remain transient.

## Run

Open `project.godot` in Godot 4.7 and run the project, or use:

```bash
godot --path . --editor
godot --path .
```

The current main scene is `scenes/main_menu.tscn`. **Start Run** enters the streamed Grass Level. The runner moves continuously; **Restart** creates a fresh transient run and **Return** goes back to the menu. `RunSession` owns the application-lifetime profile and autosaves it through `SaveService` to `user://profile.json`.

## Controls

- Desktop: **Up** jumps, **Down** rolls, **R/Enter** uses a revival potion during the countdown, **Escape** returns to the menu, and **1–4** select equipped-ability slots.
- Mobile: tap the gameplay area to jump and swipe downward to roll. Other equipped auxiliary abilities appear as on-screen buttons in the bottom-right by default; Settings can move them to the bottom-left. Touches that begin over interactive UI are not interpreted as gameplay gestures.

## Test

Run the headless suite from the repository root:

```bash
./tests/run_tests.sh
```

The wrapper uses a task-local Godot user directory/log, a 90-second per-run timeout, engine-error scanning, and exact completion markers. It runs **76 unit tests**, **62 scene integration tests**, and **3 deterministic long-run release cases**; the process exits `0` only when every stage passes.

The runner fail-closes if its scheduled and executed counts differ or any test/external error is recorded. Verify that bookkeeping separately with:

```bash
./tests/run_tests.sh --self-check
```

The inner runners remain available for debugging only: `godot --headless --path . -s res://tests/test_runner.gd`, `godot --headless --path . -s res://tests/integration_runner.gd`, and `godot --headless --path . -s res://tests/long_run_runner.gd`. They do not provide the wrapper's timeout/error-output protections.

## Configuration and architecture

Edit the typed defaults in `scripts/core/game_config.gd`. It owns the configuration boundary for the constant-case TASK variables: movement/jump/roll/revival timing, biome/terrain streaming, equipment limits, stat bounds/steps/costs, ability cooldown/distance values, per-enemy shooting intervals and vicinity tiles, and per-enemy collectible-drop probabilities. `EnemyCatalog` consumes those centralized combat defaults rather than embedding the TASK placeholders in catalog construction code.

- `GameConfig`: defaults and validation.
- `ActionDispatch` / `AbilityEligibility`: platform-neutral actions, unlock/equip eligibility, cooldown exemption rules.
- `DamageStatus` / `RunDirector`: accepted-hit transactions preserve the legacy `DamageEvent` call site while reporting acceptance, dealt damage, lethal result, and effect installation. Entire envelopes are validated before mutation; health/status/lifecycle commit before observer signals, and rejected or lethal hits cannot install an effect. One explicit RUNNING-only simulation clock owns status duration/ticks; countdown/protection remains on the wall/manual clock. Distinct active status identities are bounded by `MAX_ACTIVE_STATUS_IDENTITIES`; each identity has one winning source (not an unbounded source stack). Refresh extends expiry without moving an existing periodic cadence; a nonperiodic-to-periodic refresh initializes its first incoming cadence. Refresh keeps the strongest periodic damage/shortest interval and its source attribution, and uses constant-time skipped-tick catch-up. Revival clears status state.
- `GameClock`: injectable production/manual clocks.
- `EquipmentState`, `ProfileState`, `ProfileCommands`: persistent-profile contracts and safe command boundary.
- `SaveService`, `ProfileShop`, `CharacterCatalog`, `RunSession`: M7 versioned JSON persistence, temp-file atomic replacement, schema migration/defaulting, malformed/corrupt-save fallback, autosave/reload, strict catalog validation, 45 supplied character definitions, and atomic gold-funded purchases/upgrades. Run-local health/distance/status/cooldown timestamps/earned gold are intentionally excluded from the save schema.
- `RunState`: transient run-only state and change notifications for health, distance, and earned gold.
- `RunDirector`: RUNNING/countdown/game-over lifecycle, exact potion timing, protection, measured-progress stuck timing, and an M3-ready validated support-query seam. Recovery carries the actual failure position/reason, so stuck recovery searches beyond the blocker before a potion is committed.
- `TerrainGenerator`, `ChunkDescription`, `TerrainSurface`, `SpawnAnchor`, `HazardDescriptor`, `MovementEnvelope`: versioned pure terrain contracts in absolute logical tile columns. A generated chunk records its configuration identity, half-open bounds, per-column biome ownership, occupied/material/kind data, stable IDs, biome-labelled support-bound clearance-checked anchors, deterministic hazard descriptors, and entry/exit conditions. Hazard descriptors are immutable metadata, separate from their active chunk-owned runtime nodes. Candidates use their own stateless stream, carry version/config/support-tile identity plus phase/parameters, skip occupied or unclear cells, and are emitted only for Desert flame, Astro, or Fort spike types; Astro gameplay derives from every actual occupied Astro cell rather than its sparse candidate descriptor. Columns before run origin are safely Grass; columns `0..BIOME_INTERVAL-1` start the ordered six-biome pass, and later encounters use a stateless seed/index stream that excludes the immediately preceding biome. Geometry is checked against worst-case Snow jump, minimum slowdown speed, body clearance, fixed-step timing, run-up, and landing room.
- `TerrainPalette` / `TerrainChunk` / `TerrainStreamer`: all visible procedural terrain is rendered directly from `assets/Spritesheets/spritesheet-tiles-double.png`; the runtime does not load individual `assets/Tiles/terrain_*.png` files. The 2321×2321 sheet is an 18×18 atlas of 128×128 frames with 1px gutters (129px stride). Each biome maps to one 28-frame terrain family: Tundra/dirt starts at frame 138, Grass at 166, Astro/purple at 194, Desert/sand at 222, Snow at 250, and Fort/stone at 278. Within every family the same IDs cover block, 3×3 top/bottom/left/right/corner/center, horizontal ledge/overhang, vertical, ramp, and cloud variants. Runtime neighbor topology selects matching corners/edges/fill for solid terrain and left/middle/right horizontal pieces for one-tile platforms and cave roofs; active neighboring chunks participate in the lookup so same-biome seams do not become arbitrary block borders. Collision continues to follow generated terrain surfaces independently of drawing. The streamer keeps bounded descriptor and active-runtime hazard registries alongside support/anchor registries, and retirement/reconfiguration removes both before nodes are freed.
- `HazardTiming` / `TerrainHazardRuntime`: one run-local simulation clock advances only while `RunDirector` is `RUNNING`. Chunk-owned Desert descriptors realize as `GPUParticles2D` flames using the supplied `Sek_00001.png` frame; Fort descriptors use supplied `Spikes.png` art. Both grow from their supporting terrain top and publish `DamageStatus.DamageEvent` intent through the streamer to `Level`/`RunDirector`, which alone applies defense, protection, and health changes. Damage, cadence, geometry, period, active-window, and rise/fall timing are validated `GameConfig` values. Fort’s descriptor phase drives one continuous rise/hold/fall extension value shared by visible spike height and Area2D hitbox; it cannot damage while fully retracted.
- `AstroFallCoordinator` / `AstroFallBlock`: every generated Astro occupied cell is omitted from terrain batch drawing and merged static runs, then owns exactly one aligned atlas visual and collider. Its immutable generated tile ID plus stream-registration epoch addresses a run-local `stable → armed → falling → removed` state overlay. Only the streamer’s current player target may arm a validated top contact; countdown/game-over contacts are rejected and a current valid overlap is checked only after RUNNING resumes. Recovery eligibility and its exact dependent anchor disappear immediately, while collision persists through the editable `ASTRO_FALL_DELAY`. The shared RUNNING-only fixed-step coordinator moves art/collision together, preserves whole-tile separation during swept vertical cascades, retires on a live non-Astro collision or editable fall limit, and removes registry state before streamed nodes are freed. Re-entering a retired chunk reconstructs pristine deterministic terrain. Recovery validates the whole standing body plus its required forward sweep against live Desert/Fort regions and refuses all Astro support.
- `Level` / `PlayerController`: generated-terrain runner in production, exact configured run origin, fixed-Y horizontal camera, collision-safe compact roll posture, Area2D enemy proximity intent, recovery/reset behavior, and signal-bound HUD widgets. Movement speed is a bounded composed resolver and appearance precedence is damage flash → blood blink → freeze → neutral. A Snow jump samples once at accepted takeoff from the physical supporting body’s material; its multiplier is a run-seed/accepted-Snow-index function and stays continuous through revival. Tests may inject that resolver; failed requests and non-Snow takeoffs consume no Snow sample. The Level’s pre-tree `use_flat_fixture` switch exists solely for M2 physics regression tests; only that fixture exposes `Floor`. Recovery searches multiple collision-validated positions near the failure/checkpoint using only live streamer registry entries; it never creates terrain while committing a potion. Each new run/restart rotates its production seed, while revival retains the active director seed.
- `EnemyDefinition`, `EnemySpawnDescriptor`, `EnemyEffectSpec`, and `EnemyAttackPolicy`: validated M4 content contracts. Definitions enforce configured tier/health/damage bounds plus distinct melee reach and ranged vicinity; spawn descriptors bind deterministic run/catalog, explicit `variant_id`, anchor, support tile/surface, epoch, biome visit, and patrol span identity. Attack policy uses only simulation time, requires target/enemy camera inclusion and optional LOS, has immediate first shots, independent melee/ranged cadence, and never accumulates pause/visibility backlog. `ProfileState.enemy_fire_interval_multiplier` is snapshotted at run setup; larger values intentionally slow attack intervals.
- `EnemySpawner`, `EnemyController`, `EnemyProjectile`, and `EnemyAnimationLoader`: the M4 runtime consumes live terrain anchors with physical spawn-clearance checks, an active-enemy cap, exact invalidation/removal retirement, surface-bounded patrols, overhead health bars, stationary/patrol and melee/ranged/combined definitions, data-driven particle/projectile versus LOS-checked beam realization, RUNNING-only projectile lifetime, and spawner-owned projectile hit routing through `RunDirector`. Particle attacks use a real `GPUParticles2D` process material and supplied particle texture for their full one-shot lifetime. Enemy sprites are loaded from explicit paths through one bounded shared cache sized for the active-enemy cap and released when controllers leave the tree.
- `EnemyCatalog`: explicitly inventories all 23 canonical supplied enemy identities and all 39 supplied costume folders without runtime directory scanning. Each definition owns its biome, first/later encounter tier, health/damage scaling, movement/attack modes, unique shooting interval, ranged kind, effect, and explicit ordered idle-frame variants. Grass is the documented no-effect exception; Snow uses freeze/ice-blue slowdown, Desert uses burn damage-over-time, Fort includes Vampire blood loss/red blinking, and Tundra/Astro/Fort identities otherwise have distinct themed status IDs and parameters.
- `CollectibleCatalog`, `CollectibleSpawner`, `CollectiblePickup`, and `LootRolls`: M5 route pickups and enemy loot are explicit-data, stream-aware systems. Bronze/silver/gold coins and hearts materialize from live route anchors and retire with exact anchor epochs; enemy deaths publish immutable spawn identity into pure seeded gem rolls. Pickups update run gold or Director-owned health, every gem is worth more than every coin, drop probability boundaries are exact at `0.0`/`1.0`, and active drops are bounded.
- `WeaponCatalog`, `WeaponTargetingPolicy`, `WeaponController`, `WeaponProjectile`, and `ShootingTiming`: M5 weapons use supplied `Props/Weapons` art and definition-owned damage, fire intervals, straight/ballistic trajectories, directed/random/determined/forward aim, and target count. Random aim is replay-deterministic but directionally random; directed multi-target fire chooses distinct on-screen enemies. Shooting must be unlocked, equipped, and explicitly activated before auto-fire; activation cooldown and each weapon cadence use RUNNING simulation time, no visible enemies produce no shots, and swept projectiles damage the existing enemy controller/death/drop path.

## Save data

Persistent progression is written to `user://profile.json` through `SaveService`. Godot resolves `user://` to the current user's application-data directory for the platform/build; the exact filesystem location is therefore engine/platform managed. Saves are versioned JSON, written through a temporary file before replacement, and recover to validated defaults when missing, malformed, corrupt, or from an unsupported future schema. Health, distance, run-earned gold, status timers, active cooldown timestamps, and other one-run state are intentionally not persisted.

## Release and performance safeguards

The project declares the Godot **Mobile** feature and uses `renderer/rendering_method="mobile"`. Runtime growth is bounded by configurable streaming/active-object limits including terrain ahead/behind chunks, `MAX_ACTIVE_ENEMIES`, `MAX_ACTIVE_DROPS`, `MAX_ACTIVE_WEAPON_PROJECTILES`, and `MAX_ACTIVE_STATUS_IDENTITIES`. Enemy animation frames are loaded from explicit supplied paths into a bounded reference-counted cache and released when the last owning enemy retires; runtime code does not scan asset directories. Stream retirement tests cover stale chunks, anchors, hazards, Astro blocks, enemies, and collectibles.

## Assets and attribution

The game uses the assets supplied with this repository under `assets/`, including `Characters`, `Enemies`, `Props/Weapons`, `UI`, the terrain spritesheet, hazard art, collectibles, and `Consumables/revival_potion.png`. This README does not infer or replace the original authors' license/attribution terms; when redistributing the project or its assets, retain and follow any license/credit files that accompanied the supplied asset pack.

### Enemy roster and supplied variants

| Canonical identity | Biome | Tier | Supplied costume variant(s) | Effect |
|---|---|---:|---|---|
| Archer Guy | Grass | 1 | Archer Guy | none |
| Barbarian Warrior | Grass | 1 | Barbarian Warrior | none |
| Monk Guy | Grass | 2 | Monk Guy | none |
| Goblin | Grass | 2 | Goblin | none |
| Old Guy | Tundra | 1 | Old Guy | tundra fatigue |
| Ogre | Tundra | 1 | Ogre | tundra stagger |
| Golem | Tundra | 2 | Golem 1/2/3 | stone chill |
| Orc | Tundra | 2 | Orc | tundra wound |
| Frost Knight | Snow | 1 | Frost Knight 1/2/3 | freeze |
| Human Magician | Snow | 1 | Human Magician 1/2/3 | arcane freeze |
| Skeleton Warrior | Snow | 2 | Skeleton Warrior 1/2/3 | bone freeze |
| Desert Nomad | Desert | 1 | Desert Nomad 1/2/3 | burn |
| Minotaur | Desert | 1 | Minotaur 1/2/3 | burn |
| Evil Bald Guy | Desert | 2 | Evil Bald Guy | burn |
| Medieval Mage | Astro | 1 | Medieval Mage | void drag |
| Ghoul Hunter | Astro | 1 | Ghoul Hunter 1/2/3 | phase sickness |
| Reaper Man | Astro | 2 | Reaper Man 1/2/3 | entropy drain |
| Pumpkin Head Guy | Astro | 2 | Pumpkin Head Guy | star fright |
| Death Knight | Fort | 1 | Death Knight | dread |
| Skeleton | Fort | 1 | Skeleton | bone bleed |
| Zombie | Fort | 2 | Zombie | grave rot |
| Skull Knight | Fort | 2 | Skull Knight | skull stagger |
| Vampire | Fort | 3 | Vampire | blood loss |

Every listed costume variant has an explicit ordered six-frame Idle sequence in `EnemyCatalog`; runtime code does not scan asset directories.

Rendered tile appearance remains a manual check: launch a production Level, confirm all six atlas palettes are visible and aligned at biome/chunk seams, and confirm platform/mountain/cave art has no atlas bleeding. The source coordinates, in-bounds status, distinct palette choice, and internal biome-boundary selection are covered headlessly, but final visual appearance cannot be fully validated headlessly.

## Automated test inventory

| Test | Covers |
|---|---|
| `test_main_scene_instantiates` | Configured boot/main-menu scene loads headlessly. |
| `test_required_input_actions_exist` | Desktop, touch, and four ability action entries. |
| `test_config_defaults_validate` | Typed defaults, ranges, and positive equip limits. |
| `test_config_validation_rejects_bad_edits` | Stat direction/domain/cost checks, editable cooldowns, and dash conversion. |
| `test_enemy_config_boundary_validation` | Enemy timing and drop-probability configuration boundary. |
| `test_action_dispatch_unifies_devices` | Desktop and mobile actions map to the same semantic action. |
| `test_project_input_bindings` | ProjectSettings main scene plus Up/Down/numeric input bindings. |
| `test_ability_eligibility_and_exclusion` | Unlock gate, capacity, Jump/Reverse Gravity exclusion, cooldown exemptions. |
| `test_damage_and_status_owner` | Defense-aware damage, expiration, and recipient-owned status. |
| `test_manual_clock_is_deterministic` | Injectable monotonic manual clock. |
| `test_equipment_invariants` | Unlock-before-equip, unique entries, capacity, and unequip. |
| `test_profile_commands_preserve_economy` | No overspend, one atomic notification for a successful potion transaction (none for rejection), and exactly one notification for revival consumption. |
| `test_profile_ability_command_respects_exclusion` | Profile command delegates ability equip eligibility. |
| `test_run_state_is_transient` | Run distance/countdown behavior remains separate from profile. |
| `test_revival_state_machine_boundaries` | Independently stocked just-before/exact/after deadline cases, duplicate activation, preserved seed/run values, restored health, and cleared statuses. |
| `test_support_query_validates_before_potion_commit` | Unsafe support rejection, replacement support, and exactly-once potion commit. |
| `test_revival_configuration_is_positive_finite` | Protection, damage-tint, and progress-tolerance defaults are positive finite. |
| `test_shooting_timing_contract` | Activation cooldown and per-weapon visible-target intervals. |
| `test_main_menu_start_intent` | Boot menu exposes a working start intent without requiring Level. |
| `test_harness_self_checks` | Runner failure, incomplete-run, and simulated parse-error bookkeeping. |

## M2 real-scene integration inventory

| Test | Covers |
|---|---|
| `test_measured_nonstop_displacement_and_distance` | Measured real-physics nonstop X displacement and run-distance conversion. |
| `test_input_jump_apex_landing_and_camera` | Input-action jump, measured `MAX_JUMP × TILE_SIZE` apex tolerance, landing, camera X follow, and fixed camera Y. |
| `test_camera_fixed_y_during_fall_and_revival` | Camera Y remains invariant through fall and safe revival. |
| `test_validated_support_recovery_and_revalidation` | Real Level floor support validation, recovery placement, and rejection after support removal. |
| `test_recovery_rejects_blocked_pose_and_finds_replacement` | Blocked standing pose rejection, terrain-support replacement placement, and no-potion rejection after every eligible support is disabled. |
| `test_low_ceiling_roll_posture_and_revival_reset` | Offset low-ceiling standing/rolling shape queries, deferred collision-shape toggles, delayed standing, and revive posture reset. |
| `test_area2d_melee_only_near_running_enemy` | Actual Area2D target proximity, distant exclusion, and countdown suspension gate. |
| `test_hud_widgets_update_from_run_and_profile_signals` | Notified transient health maximum/current values, gold, potion icon/count, distance, and REVIVE/GAME OVER overlays. |
| `test_grounded_countdown_exact_expiry_and_freeze` | Manual-clock deadline, countdown/game-over freeze of movement, distance, and actions. |
| `test_thin_wall_sweep_and_stationary_checkpoint_timeout` | A thin physical wall fails the continuous standing-shape sweep, while repeated stationary checkpoint samples cannot postpone incremental manual-clock stuck timeout. |
| `test_physical_wall_stuck_boundary_and_revival_recovery` | A wall placed well before approach triggers measured stuck failure, then recovery starts beyond the actual blocker and sustains post-protection movement while the wall remains live. |
| `test_damage_fall_protection_tint_and_reset` | Default-defense damage, tint lifetime, fall regardless of protection, exact protection boundary, and revive reset. |
| `test_safe_support_records_latest_grounded_progress` | Latest grounded/progressing checkpoint updates on the real floor. |
| `test_menu_restart_return_profile_lifecycle` | Awaited Start/Restart/Return navigation, profile retention, new director/run state, and distinct production seeds for distinct runs. |
| `test_level_ui_paths_exist` | Concrete restart, return, and potion UI paths. |

`tests/run_tests.sh --self-check` additionally proves the wrapper rejects isolated declared-failure, runtime-null-access, parse-error, and hang fixtures.

## M3a deterministic terrain inventory

| Test | Covers |
|---|---|
| `test_terrain_same_seed_equality` | Identical seed/config/version/chunk output, half-open bounds. |
| `test_terrain_different_seed_variation` | Different seeds vary geometry itself, excluding seed metadata from comparison. |
| `test_terrain_order_independent_regeneration` | Stateless order-independent generation. |
| `test_terrain_invalid_config_rejected` | Invalid fields and a physically insufficient jump envelope fail closed. |
| `test_terrain_all_form_kinds_present` | Platform, mountain, and cave description forms. |
| `test_movement_envelope_body_clearance_min_max` | Minimum slowdown speed, worst/best Snow jump, fixed-step/body clearance, forward direction, and reachability bounds. |
| `test_terrain_reachable_transitions_and_seams` | Every internal route transition, optional-platform entry/exit, and adjacent half-open seam is reachable. |
| `test_terrain_stable_anchors` | Stable anchors reference live support geometry and reserve explicit vertical clearance. |
| `test_grass_atlas_rect_bounds_and_source` | Required spritesheet-only runtime path, 2321×2321 / 18×18 / 128px-frame / 1px-gutter atlas geometry, Grass family anchor, and absence of individual terrain-PNG loading. |

## M3b biome-selection inventory

| Test | Covers |
|---|---|
| `test_biome_exact_boundary_columns` | Exact inclusive start/end ownership at every first-pass `BIOME_INTERVAL` boundary. |
| `test_biome_first_encounter_order` | Grass → Tundra → Snow → Desert → Astro → Fort first-pass order. |
| `test_biome_seeded_random_variation` | Post-Fort biome encounters vary by explicit run seed. |
| `test_biome_random_encounters_do_not_repeat` | Long deterministic encounter sequences, including the Fort transition, contain no immediate repeat. |
| `test_biome_negative_columns_are_grass` | Pre-origin streamed columns use safe Grass ownership. |
| `test_biome_cross_boundary_chunk_metadata` | A chunk spanning a biome boundary labels cells, surfaces, and anchors per absolute column. |
| `test_biome_regeneration_is_order_independent` | Biome-bearing chunk regeneration is stable after out-of-order generation. |

## M3c.1 palette, metadata, and Snow inventory

| Test | Covers |
|---|---|
| `test_six_biome_palette_rects_and_boundary_selection` | All six biome families map to valid atlas frame ranges, and 3×3 solids plus one-tile platforms select compatible corner/edge/interior/left/middle/right sprites from the shared family layout. |
| `test_hazard_descriptors_are_deterministic_and_owned` | Stateless descriptor regeneration, version/config identity, biome/type gate, clear position, and matching support-tile ownership. |
| `test_snow_multiplier_stream_is_deterministic_and_bounded` | Pure run-seed/accepted-index Snow multiplier determinism and configured bounds. |
| `test_hazard_registry_cleanup_and_reconfigure` | Live Desert descriptor registration, chunk-retirement cleanup, bounded registry size, and reconfiguration clearing. |
| `test_snow_jump_sampling_physical_bounds_and_revival` | Failed-request non-consumption, actual Snow/Grass support material, injected min/max physical apex bounds, one sample per accepted Snow jump, and seed/index continuity through revival. |

## M3c.2 Desert and Fort hazard inventory

| Test | Covers |
|---|---|
| `test_hazard_timing_phase_and_cadence_contract` | Pure deterministic phase offsets, continuous Fort rise/hold/fall/retraction, and contact-cadence boundaries. |
| `test_hazard_runtime_assets_and_fort_transition_geometry` | Supplied flame/spike assets, GPUParticles2D realization, and a Fort transition’s shared visual/hitbox geometry. |
| `test_streamed_desert_hazard_contact_defense_and_cadence` | A real streamed Desert Area2D overlap at support-top placement, Director defense multiplier, and repeat-cadence damage without duplicates. |

## M3c.3 Astro fall inventory

| Test | Coverage |
| --- | --- |
| `test_astro_fall_config_and_state_contract` | User-editable fall timing/speed/fixed-step/limit validation. |
| `test_astro_three_block_cascade_and_pause` | Pure pause, delay, and three-cell cascade state transitions. |
| `test_astro_order_epoch_and_non_astro_sweep` | Stale epoch rejection and inclusive swept non-Astro removal. |
| `test_astro_arm_direction_and_duplicate_contract` | Top-only arming and duplicate-contact idempotence. |
| `test_astro_cells_have_single_runtime_ownership_and_cascade` | Streamed Astro cells have one block owner/collider and enter active fall state. |
| `test_astro_recovery_excludes_armed_support_and_anchor_only` | Astro support exclusion and exact-anchor invalidation seam. |
| `test_astro_area_contact_pause_and_duplicate_delay` | Isolated real Area2D/CharacterBody2D top-only contact, paused contact rejection/resume polling, and idempotent delay. |
| `test_astro_real_block_cascade_alignment_and_release` | Real three-block, cross-owner cascade; art/collider alignment, tile separation, and released starting space. |
| `test_astro_revival_pause_and_retirement_cleanup` | Falling-state pause/revival persistence, real Desert-danger recovery rejection with a safe fallback, actual no-safe potion preservation, stale-epoch rejection, bounded far streaming, retirement, and reconfiguration cleanup. |
| `test_negative_chunk_collision_and_zero_crossing` | Physical support in a negative generated chunk and jump-assisted traversal across logical column zero. |
| `test_generated_non_astro_impact_preserves_terrain` | A real streamer non-Astro collision removes a falling Astro fixture without mutating its generated cell or collider. |
| `test_continuous_astro_segment_traversal_with_collapse` | Normal player physics and grounded jumps traverse the entire first Astro segment into Fort while collapse remains active. |
| `test_same_frame_fall_freezes_astro_hazard_tick` | A Level fall transition prevents same-frame Astro contact, state, motion, and simulation-clock advancement. |
| `test_same_frame_stuck_freezes_astro_and_fort` | A real stuck transition freezes Astro motion, Fort extension, and the shared simulation clock in the exact failure frame. |
| `test_streamed_fort_phase_hitbox_pause_and_resume` | A real streamed Fort overlap, retracted no-damage state, partial-rise geometry alignment, defense-aware contact, frozen countdown clock, and resumed simulation time. |

## M3a production integration inventory

| Test | Covers |
|---|---|
| `test_production_has_no_floor_and_generated_grass` | Production Level begins at the exact distance origin, has generated atlas terrain, has no active `Floor`, and resolves the live Grass chunk seam as connected top/interior atlas pieces rather than exposed repeated blocks. |
| `test_floating_platform_collision_matches_tiles` | Real physics collision is exactly one tile deep with empty underside and side space matching the description. |
| `test_generated_route_crosses_chunk_seam_without_teleport` | Real player physics crosses a generated route/chunk seam for platform, mountain, and cave starting forms. |
| `test_streamer_far_teleport_reconciles_directly_and_cleans` | Far teleport creates required chunks directly and frees stale nodes. |
| `test_streamer_bounded_counts_and_stale_anchor_removal` | Chunk/description/node caps and stale anchor registry cleanup. |
| `test_streamer_setup_replaces_generation_identity` | Centered world/column boundaries, wide-viewport behind retention, and clearing old nodes/registries before a different seed identity. |
| `test_generated_recovery_varied_elevation_and_removed_support` | Potion revival lands on generated elevated support; removing all supports rejects revival without consumption. |
| `test_generated_forward_blocker_recovery_and_no_potion_without_support` | A real blocker forces forward live-support recovery; no eligible support preserves the potion. |
| `test_generated_player_crosses_grass_tundra_boundary_without_teleport` | Real player physics crosses the generated Grass → Tundra boundary from centered-column Grass setup with bounded per-frame displacement. |
## M4a enemy framework inventory

| Test | Covers |
|---|---|
| `test_m4_hit_status_simulation_contract` | Atomic accepted-hit transactions, RUNNING-only status time/ticks, lethal behavior, and source attribution. |
| `test_m4_player_modifier_and_appearance_precedence` | Bounded slowdown composition plus damage/blood/freeze appearance precedence, including blood blink-off fallback. |
| `test_m4_enemy_contract_validation` | Enemy definition tier/health/damage bounds, spawn identity/variant requirements, and effect validation. |
| `test_m4_attack_policy_cadence_contract` | Separate melee reach/ranged vicinity, target/enemy camera gates, LOS, independent channels, and interval multiplier cadence. |
| `test_m4_status_capacity_and_refresh_contract` | Bounded status identities, refresh winner rules, cadence preservation, and nonperiodic-to-periodic transition. |
| `test_m4a1_example_runtime_catalog_contract` | Valid deterministic framework fixtures cover stationary, patrol, melee-only, ranged-only, combined behavior, and definition-owned particle/beam attack kinds. |
| `test_m4a1_projectile_configuration_contract` | Projectile origin/direction/speed validation and rejection of zero-direction shots. |
| `test_m4a1_animation_cache_reference_contract` | Shared explicit-frame cache reference accounting, eager release at zero owners, and capacity sufficient for the configured active-enemy/frame bounds. |
| `test_m4_anchor_lifecycle_and_astro_spawn_support` | Exact anchor add/invalidate/remove lifecycle and stable-only Astro spawn eligibility. |
| `test_m4a1_spawner_materializes_healthbar_and_retires` | Production streamed-anchor materialization, physical eligibility, active cap, shared animation cache, overhead health bar updates, and exact chunk retirement. |
| `test_m4a1_controller_behavior_channels_and_pause` | Real controller stationary/patrol movement, melee-only/ranged-only/combined channels, real one-shot textured `GPUParticles2D`, two-point beam realization, death/health-bar zeroing, and countdown pause. |
| `test_m4a1_projectile_sweep_pause_and_hit` | Swept projectile collision, frozen countdown lifetime/position, resumed hit, and spawner-owned damage routing through RunDirector. |

## M4b complete enemy catalog inventory

| Test | Covers |
|---|---|
| `test_m4b_catalog_inventory_and_variants` | Exact 23 canonical identities and 39 supplied costume folders, unique explicit six-frame variant paths, and resource existence with no runtime directory scan. |
| `test_m4b_biome_roster_tiers_and_effects` | Every biome has multiple first/later-tier identities; every non-Grass identity has a unique valid themed effect; Snow freeze, Desert burn, and Vampire blood loss rules. |
| `test_m4b_scaling_and_fire_interval_defaults` | Higher tiers scale health/damage upward, all ranged identities use distinct default intervals, and the catalog covers standing/patrol, melee/ranged/combined, particle/beam modes. |
| `test_m4b_biome_visit_tier_and_variant_selection` | Deterministic per-biome visit counting, first-encounter tier gating, later-tier eligibility, and deterministic supplied-variant selection. |
| `test_m4b_production_catalog_spawn_wiring` | Production spawner uses the complete catalog, preserves biome/tier/visit/variant identity, and realizes explicit catalog sprite sequences. |
| `test_m4b_freeze_burn_and_blood_loss_runtime` | Director-owned real runtime application of Snow freeze/ice-blue slowdown, Desert burn ticks, and Vampire blood-loss ticks/red presentation. |

## M5 collectibles, melee, loot, and weapons inventory

| Test | Covers |
|---|---|
| `test_m5a_collectible_catalog_values_and_assets` | Supplied coin/heart/gem assets, spawnable versus droppable roles, health amount, increasing coin values, and every gem exceeding every coin. |
| `test_m5a_deterministic_loot_probability_contract` | All 23 enemies have three validated gem probabilities, exact 0/1 rejection/acceptance boundaries, and stable seed/spawn drop decisions. |
| `test_m5a_streamed_collectible_pickup_and_cleanup` | Real route-anchor pickup materialization/retirement plus coin run-gold and capped heart healing. |
| `test_m5a_player_melee_cadence_death_and_drops` | Profile melee power, per-enemy melee cadence, enemy death, deterministic drop selection, and real gem pickup materialization. |
| `test_m5b_weapon_catalog_axes_and_assets` | Supplied Props/Weapons resources with varying damage/intervals and complete straight/ballistic, directed/random/determined/forward, and target-count axes. |
| `test_m5b_targeting_policy_modes_and_multitarget` | No-target suppression, three distinct directed targets, seeded random directions, fixed determined/forward aim, and ballistic launch solution. |
| `test_m5b_weapon_equipment_and_shooting_unlock_boundary` | Shooting locked/unlocked/equipped states plus weapon unlock/equip capacity enforcement. |
| `test_m5b_shooting_unlock_visibility_and_cadence` | Real controller activation gate, no-visible-enemy suppression, immediate first shot, per-weapon cadence, and countdown pause. |
| `test_m5b_multitarget_and_projectile_trajectories` | Three simultaneous distinct on-screen target directions, real swept straight-projectile damage, ballistic gravity, and paused projectile lifetime. |

## M6 ability-system inventory

| Test | Covers |
|---|---|
| `test_m6a_ability_catalog_levels_and_triggers` | Exact ten-ability catalog, Jump/Climb level caps, jump-family versus auxiliary triggers, and cooldown exemption taxonomy. |
| `test_m6a_profile_ability_progress_contract` | Default Jump level 1, unlock-owned progress initialization, bounded levels, and per-ability cooldown values. |
| `test_m6a_cooldown_and_action_router_contract` | Run-local exact cooldown boundaries plus equipped auxiliary-slot and jump-family routing. |
| `test_m6a_level_desktop_mobile_ability_slot_routing` | Desktop numbered and mobile auxiliary inputs resolve the same equipped auxiliary abilities and stop outside RUNNING. |
| `test_m6b_jump_levels_and_fly` | Real single/double/triple jump limits, landing reset, and repeated no-cooldown Fly jumps. |
| `test_m6b_climb_wall_jumps_and_glide` | Physics wall contact, level-2 two-use Climb limit, held-jump glide threshold, max duration, and gravity resume. |
| `test_m6b_reverse_gravity_fly_and_cooldown` | Reverse-Gravity toggles, exact run-clock cooldown, Fly composition while the toggle is cooling down, and countdown freeze. |
| `test_m6b_dash_distance_speed_and_cooldown` | Configured high-speed dash, exact four-tile travel, immediate cooldown rejection, exact-boundary reuse, and countdown block. |
| `test_m6c_duration_stats_unlock_and_bounds` | Invisibility/slowdown duration stats remain locked until their abilities unlock, then enforce configured defaults and bounds. |
| `test_m6c_dynamic_enemy_and_shooting_cooldown_bridge` | Dynamic enemy visibility/interval resolvers and Shooting activation use live profile-owned cooldown values. |
| `test_m6c_slowdown_invisibility_enemy_runtime` | Real slowdown reduces runner movement, delays enemy ranged cadence, and invisibility suppresses then restores enemy perception at expiry. |
| `test_m6c_explode_enemy_damage_tile_break_and_cooldown` | Explode damages nearby enemies, breaks generated non-Astro tiles, preserves Astro tiles, and enforces exact cooldown boundaries. |
| `test_m6c_shooting_action_route_and_profile_cooldown` | Numbered/mobile auxiliary routing activates Shooting, observes profile cooldown, and blocks outside RUNNING. |

## M7 persistent-progression inventory

| Test | Covers |
|---|---|
| `test_m7_character_catalog_assets_and_prices` | All 45 supplied character SpriteFrames paths, default character, and deterministic unlock pricing. |
| `test_m7_save_roundtrip_persistent_only` | Versioned profile round-trip for economy, character, stats, abilities/cooldowns, weapons/equipment, and settings while excluding run-only state; temp/backup cleanup is verified. |
| `test_m7_save_migration_and_corrupt_recovery` | Legacy alias migration, clamped defaults, unsupported-version fallback, malformed nested save shapes, unknown weapon rejection, and corrupt JSON recovery. |
| `test_m7_shop_purchase_atomicity_and_gates` | Character/select, revival potion, Shooting-gated weapon, and ability purchases with affordability, duplicate rejection, no negative gold, and one notification per committed transaction. |
| `test_m7_stat_and_cooldown_upgrade_boundaries` | All six signed stats, ability levels, and every cooldown-bearing ability reach configured bounds without overshoot or charging at the bound; duration stats remain unlock-gated. |
| `test_m7_profile_stats_apply_to_new_run` | Persistent max-health/defense application while run distance and earned gold remain transient. |
| `test_m7_profile_character_and_stats_apply_to_level` | Real Level startup applies selected character frames plus persistent max-health/defense to a fresh run. |
| `test_m7_run_session_autosave_reload` | Application-lifetime `RunSession` autosave/reload round-trip on a temporary profile path without persisting run-only fields. |

## M8 menu/UI inventory

| Test | Covers |
|---|---|
| `test_m8_profile_ui_command_boundaries` | Ability/weapon equip commands and persisted mobile-button-corner changes reject duplicates, exclusions, unknown IDs, and invalid corners without corrupting profile state. |
| `test_m8_main_menu_shop_and_screen_entry_points` | Main Menu progression entry points, real revival-potion purchase/profile summary update, Character navigation, and Back navigation. |
| `test_m8_progression_screens_transactions_and_descriptions` | All five progression/settings scenes load; real Character/Stats/Abilities/Weapons/Settings controls mutate the profile; weapon rows expose damage, trajectory, aim, targets, and cadence. |
| `test_m8_level_ability_map_and_revival_ui` | Bottom-left numbered desktop ability mapping, visible revival countdown/action, exact potion consumption, and return to RUNNING. |

## M9 touch-input inventory

| Test | Covers |
|---|---|
| `test_m9_touch_gesture_classification` | Pure tap versus downward-swipe thresholds plus non-action horizontal/short-drag boundaries. |
| `test_m9_touch_gestures_buttons_and_parity` | Real touch tap jump, swipe-down roll, UI-touch exclusion, multitouch/cancel rejection, both configured mobile corners, auxiliary-button routing parity, and cooldown-disabled feedback. |

## M10 release-smoke inventory

| Test | Covers |
|---|---|
| `test_m10_enemy_placeholders_and_mobile_release_config` | All 23 enemy interval/vicinity TASK placeholders come from centralized `GameConfig` dictionaries; mobile renderer and active-object caps remain configured and validated. |
| `long_run_terrain_enemy_loot_determinism` | Two identical 180-chunk / 72-encounter passes match exactly while covering all six biomes, all three terrain forms, Desert/Astro/Fort hazards, enemy tiers 1–3, deterministic enemy selection, and deterministic loot. |
| `long_run_ability_revival_persistence` | Every ability's cooldown/exemption boundary, rich profile memory/disk round-trip, transient-save exclusion, lethal countdown, exact potion consumption, and same-run revival. |
| `long_run_release_configuration_and_lazy_assets` | Valid release defaults, Mobile renderer/feature, positive runtime caps, centralized enemy combat defaults, lazy enemy animation load, and zero-owner cache release. |

The fail-closed wrapper requires exactly **76 unit tests**, **62 scene integration tests**, and **3 long-run release cases**, and rejects declared failure, runtime error, parse error, or hang fixtures.
