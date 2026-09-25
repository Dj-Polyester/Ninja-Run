# Ninja Run Delivery Plan

## Purpose and working rules

This is the live, dependency-ordered implementation plan for `TASK.md`. A milestone is complete only when its acceptance checks pass independently, its automated tests are listed in `README.md`, and the status and requirement matrix below are updated. Later milestones may not begin while an earlier milestone has blocking failures.

The project starts as a Godot 4.7 asset-only repository with no scenes, scripts, input map, main scene, README, or tests. Existing asset files are treated as read-only source material. Gameplay will use typed GDScript, deterministic random-number injection for testability, injectable clocks, data-driven definitions, signals between systems, lazy asset loading, and a strict split between persistent profile data and per-run state.

Every behavioral aspect requires a named unit test in the requirement matrix. Scene/physics integration tests supplement those unit tests. Manual rendered/device checks are evidence only for visual appearance, readability, layout, and touch usability; they never replace behavioral tests.

## Status key

- `pending`: not started
- `in progress`: at least one owning milestone has passed, but other owners remain
- `active`: implementation or validation in progress
- `blocked`: cannot proceed without an external decision or dependency
- `complete`: acceptance criteria and independent validation passed

## Milestones

### M1 — Executable foundation and automated test harness

Status: `complete`

Dependencies: none

Scope:

- Establish project directories, a boot/main-menu scene, project main scene, desktop and mobile input actions, and baseline display settings.
- Add centralized, typed defaults for every uppercase variable in `TASK.md`; enemy-specific intervals/probabilities may be completed with their definitions in M4/M5 but must use the same configuration boundary.
- Establish pure/data-oriented run and profile models without implementing persistence yet.
- Add a zero-dependency headless test harness with deterministic exit status and an initial foundation suite.
- Create `README.md` with launch, controls, architecture, configuration, and test instructions plus a continuously maintained test inventory.

Acceptance and tests:

- Godot parses the project and can instantiate the configured main scene headlessly.
- Input actions required by desktop, touch abstraction, and equipped abilities exist.
- Configuration defaults satisfy documented types/ranges and equip limits are positive.
- The test command exits zero and reports individual tests.
- Lightweight contracts exist for action dispatch/ability eligibility, damage and timed-status ownership, clocks, equipment invariants, profile commands, and Shooting timing before downstream implementation.
- A reviewer approves the core boundaries before M1 closes.

### M2 — Core runner vertical slice

Status: `complete`

Dependencies: M1

Scope:

- Build the level scene, player controller, a temporary safe floor, and horizontal-only following camera.
- Implement nonstop rightward movement at configured speed, jump height in tiles, roll duration/hitbox, and automatic proximity melee trigger boundary.
- Track health and horizontal tile distance per run; implement defense-aware damage and brief red damage feedback.
- Implement fall death, stuck detection, countdown suspension, safe-support checkpoints, and terminal game over. Potion revival preserves seed, distance, and earned run gold while restoring health at the latest safe support near the failure point, clearing unsafe velocity/transient damage effects, and granting brief configurable protection so falling or blockage does not immediately retrigger death.
- Add the required level HUD counters and a functional return/restart path.

Acceptance and tests:

- A headless integration scene advances the player, camera, distance, jump/roll, damage, fall, stuck, countdown, safe recovery, and game-over state transitions deterministically.
- Boundary tests cover countdown expiry versus potion activation, potion consumption exactly once, fall-and-revive continuing play, blocked-and-revive continuing play, and jump/roll collision clearance.
- HUD reflects health, gold, consumable count, and distance signals.

### M3 — Procedural terrain and six-biome run generation

Status: `complete`

Dependencies: M2

Architecture review required: procedural generation and physics lifecycle

Internal gates:

- M3a: deterministic reachable floating-platform/mountain/cave terrain geometry, streaming, cleanup, and safe supports.
- M3b: exact-interval biome selection—ordered first encounter, then seeded random selection excluding the immediately previous biome as an explicit design default.
- M3c.1: six atlas palettes, deterministic hazard descriptors/registry lifecycle, and Snow takeoff variation. (`complete`)
- M3c.2: shared run-clock/contact-damage boundary plus active Desert flames and Fort cycling spikes. (`complete`)
- M3c.3: stepped-on Astro falling blocks, deterministic cascades, and hazard-aware recovery. (`complete`)

Each gate receives independent tester validation before the next begins.

Scope:

- Build deterministic streaming terrain chunks from `spritesheet-tiles-double.png`, with playable/reachable floating platforms, mountain terrain, cave terrain, forward generation, and cleanup behind the camera. Reachability is based on baseline Jump and the worst-case configured snow variation; later abilities add options but are never required to survive generated terrain.
- Implement all six biomes in the required first-encounter order (Grass, Tundra, Snow, Desert, Astro, Fort), switching every configured horizontal tile interval; later encounters choose randomly while avoiding invalid/immediate-repeat behavior.
- Implement snow jump-height randomization, desert flame-particle damage, cascading stepped-on Astro falling blocks, and vertically cycling visible/damaging Fort spikes.
- Astro runtime policy: every occupied Astro cell is a separately owned mutable block (`stable -> armed -> falling -> removed`), not a sparse decorative candidate. A falling Astro block deterministically arms an Astro block beneath it and is removed when it reaches non-Astro terrain or the fall limit; it never mutates neighboring non-Astro tiles. Retired chunks regenerate pristine deterministic terrain if revisited during the same run because offscreen destruction history is intentionally not retained.
- Recovery policy: Astro tiles are never durable revival destinations, even while stable, because a revived player would immediately arm them. Recovery must combine exact physical-pose validation with live Desert/Fort danger regions and Astro state, search only already-streamed non-Astro safe support, and reject without consuming a potion when none exists.
- Expose stable spawn anchors for later enemy and collectible systems.
- Define safe generation behavior for slowdown and Reverse Gravity without requiring either ability.

Acceptance and tests:

- Seeded generation is reproducible, traversable within configured movement limits, streams ahead, and frees old chunks.
- Biome sequence/exact-boundary logic and each biome hazard pass unit/integration tests.
- A headless gameplay smoke test crosses at least one generated biome boundary.

### M4 — Enemy framework, biome roster, and status effects

Status: `complete`

Dependencies: M3

Architecture review required: enemy/attack framework and timed status interactions

Internal gates:

- M4a.0: immutable enemy/spawn/attack/effect contracts, paused simulation-time ownership, player modifier/presentation composition, and exact anchor lifecycle notification. (`complete`)
- M4a.1: shared enemy controller/spawner/projectile framework plus one working example of stationary, patrol, melee-only, ranged-only, and combined behavior. (`complete`)
- M4b: complete catalog inventory, biome roster, encounter tiers, and unique effects. (`complete`)

Each gate receives independent tester validation before the next begins. One implementer owns shared framework files; nonoverlapping biome definition/asset batches may run in parallel only after M4a interfaces pass.

Scope:

- Inventory every distinct supplied enemy identity (documenting costume/animation variants separately), map every identity to exactly one themed biome and encounter tier, and ensure at least two identities per biome. Definitions include scaled health/damage, movement mode, attack modes, vicinity, differing shooting intervals, projectile/effect, and later drop-table hooks.
- Add lazy-loaded enemy animation scenes from selected `assets/Enemies` sequences, biome-filtered spawning, stationary/patrol behavior, overhead health bars, melee, ranged particles/beams, and combined attackers.
- Implement visibility-aware targeting and a unique themed effect for each non-Grass enemy identity, including freeze (ice-blue/slow), burn, blood loss with red blinking, and distinct Astro/Fort/Tundra effects. Shared mechanics require visibly or mechanically distinct parameters and documentation. Grass enemies may be neutral.
- Apply the player's enemy-fire-rate multiplier to enemy attack timing.

Acceptance and tests:

- Catalog coverage tests compare the full identity inventory to definitions, proving every supplied identity maps exactly once; every biome has multiple members and contains first-encounter and later-level definitions.
- Spawn filtering, level scaling, patrol/standing behavior, attack modes, vicinity, fire timing, health bars, death, and timed effects pass deterministic tests.
- Godot particle-system attacks and all non-Grass effects receive rendered visual validation in addition to tests.

### M5 — Collectibles, melee combat, weapons, and loot

Status: `complete`

Dependencies: M4

Architecture review required: weapon targeting/trajectory contracts

Internal gates:

- M5a: automatic melee damage, stream-aware spawnable collectibles, deterministic enemy gem drops, and pickup effects. (`complete`)
- M5b: data-driven weapon catalog, targeting/trajectory policy, Shooting activation boundary, and automatic projectile runtime. (`complete`)

M6 retains action-routing/cooldown-upgrade integration for Shooting as an ability; M7/M8 retain purchase and screen UX.

Scope:

- Complete automatic player melee attacks and enemy damage/death integration.
- Add spawnable bronze/silver/gold coins and health pickups plus droppable gems; define values with every gem worth more than every coin.
- Add enemy-specific probability tables bounded to `[0, 1]` and deterministic drop rolls.
- Implement the Shooting unlock boundary, data-driven weapon catalog using `Props/Weapons`, unlock/equip state, maximum equipped count, and distinct combinations of damage, straight/ballistic trajectory, aimed/random/determined/forward aim, and target count including simultaneous distinct on-screen targets. Shooting owns an ability activation cooldown; once activated, each equipped weapon owns its documented auto-fire interval while enemies remain visible.

Acceptance and tests:

- Melee damage uses melee power; pickups update health/gold; drops obey seeded probabilities including exact probability `0.0` and `1.0` boundaries.
- Weapons cannot be used before Shooting, equip limits hold, and representative weapons prove every required behavior axis.
- Tests cover no on-screen targets and simultaneous targeting of distinct enemies.

### M6 — Ability system and complex interactions

Status: `complete`

Dependencies: M2, M3, M4, M5

Architecture review required: ability composition, gravity, cooldowns, and time scaling

Internal gates:

- M6a: ability catalog, equipment/exclusion rules, cooldown model, and action routing. (`complete`)
- M6b: Jump, Climb, Glide, Reverse Gravity, Fly, and Dash. (`complete`)
- M6c: Shooting integration, Explode, Slow Down Time, Invisibility, and cross-ability interactions. (`complete`)

Each gate receives independent tester validation before the next begins.

Scope:

- Add unlock/equip/upgrade definitions with equip limit, default Jump level 1, cooldown availability after unlock, and decreasing cooldown upgrades. Jump, Climb, Glide, and Fly have no cooldown; Reverse Gravity, Dash, Shooting, Explode, Slow Down Time, and Invisibility have cooldowns.
- Implement Jump levels 1–3, Climb levels 1–2, held-jump Glide, Reverse Gravity, Fly, Dash, Shooting integration, Explode enemy/tile damage, Slow Down Time, and Invisibility.
- Enforce Jump/Reverse Gravity mutual exclusion.
- Make slowdown reduce runner speed and increase enemy firing interval for the upgraded duration; make invisibility suppress enemy perception for its upgraded duration.
- Add desktop numbered ability dispatch and a generic action API for mobile buttons.
- Define input ownership for competing jump consumers and test Fly + Reverse Gravity, Climb + Glide, and repeated jump input combinations.

Acceptance and tests:

- Each ability has focused tests for unlock/equip/limits/cooldown and behavior.
- Cross-ability tests cover mutual exclusion, gravity transitions, slowdown timing, invisibility targeting, explosion tile cleanup, and Shooting/weapon integration.

### M7 — Persistent progression, purchases, characters, and save/load

Status: `complete`

Dependencies: M5, M6

Architecture review required: persistent schema, migration, and economic invariants

Scope:

- Implement versioned profile save/load with atomic writes, safe defaults, validation, and corrupt-save recovery.
- Persist gold, revival potion count, selected/unlocked character, stat levels, ability unlocks/upgrades/equipment, and weapon unlocks/equipment; keep run health/distance transient.
- Implement bounded signed stat upgrades and gold costs for maximum health, defense, melee power, enemy fire rate, unlocked invisibility duration, unlocked slowdown duration, and an individual cooldown stat for every unlocked cooldown-bearing ability.
- Add character catalog/unlock/select flow from `assets/Characters`, shop transactions, a real priced revival-potion purchase, and profile application at run start.

Acceptance and tests:

- Save/load round trips, schema migration/defaulting, corrupt-file handling, affordability, insufficient funds, no-negative-gold rules, inventory increment, bounds, no-charge-at-bound rules, unlock gates, equipment invariants, and run/profile separation pass tests.

### M8 — Complete menus, shops, HUD, and settings

Status: `complete`

Dependencies: M7

Scope:

- Build Main Menu, Character, Stats, Abilities, Weapons, and Settings screens using supplied UI assets and connect navigation/purchases/equipment.
- Expose revival-potion purchasing through the Main Menu shop panel.
- Show weapon damage, trajectory, aim, and target count descriptions.
- Complete level HUD presentation and equipped ability mapping on desktop bottom-left.
- Add settings persistence including mobile auxiliary-action placement on bottom-right by default or bottom-left.
- Add revival countdown/game-over UI with potion action and clear affordances.

Acceptance and tests:

- Every screen loads, navigates, and performs its intended transaction/state change.
- UI binding tests cover catalog details, locked/available states, settings, HUD signal updates, and countdown outcomes.
- Rendered checks cover all screens, supplied UI artwork, readable weapon descriptions, player/status colors, health bars, particles, and both mobile button corners.

### M9 — Touch controls and platform input parity

Status: `complete`

Dependencies: M6, M8

Scope:

- Implement mobile tap-to-jump and swipe-down-to-roll gesture recognition without stealing UI touches.
- Render all other equipped action buttons at the configured bottom corner, with cooldown/disabled feedback.
- Confirm computer Up/Down controls and numbered equipped abilities match the HUD mapping.

Acceptance and tests:

- Synthetic touch tests distinguish tap, swipe down, UI interaction, and cancel/multitouch edge cases.
- Desktop and mobile input paths dispatch the same gameplay action API.

### M10 — Full integration, balancing, performance, and release documentation

Status: `complete`

Dependencies: M1–M9

Architecture review required: final cross-system integration

Scope:

- Run the full automated suite and complete deterministic long-run smoke scenarios across all six biomes, enemy tiers, hazards, abilities, loot, death/revival, and persistence.
- Validate asset lazy loading, node cleanup, projectile/chunk caps, and mobile-renderer performance safeguards.
- Balance/document all configurable defaults and ensure every constant-case placeholder has a user-editable default.
- Complete README setup, controls, gameplay, configuration, architecture, save location, asset attribution notes, and exhaustive test inventory.
- Audit this requirement matrix and close every row with named unit-test evidence plus integration/rendered evidence where applicable.

Acceptance and tests:

- Godot headless import/parse, unit suite, integration suite, and long-run smoke test all exit zero.
- No unresolved requirement or undocumented test remains.

## Requirement traceability matrix

The matrix is the single source of requirement ownership. `pending` changes to `complete` only when every listed owning milestone has passed. Evidence is filled with named automated tests and any supplemental rendered/device check.

| ID | `TASK.md` requirement | Owning milestone(s) | Status | Evidence |
|---|---|---|---|---|
| R01 | 2D platformer with procedurally generated playable floating platforms, mountain terrain, and cave terrain | M1, M3 | complete | M1 boot foundation; M3 deterministic reachable platform/mountain/cave generation, exact collision, six palettes/hazards, bounded streaming, negative/zero seams, and continuous Astro-to-Fort traversal |
| R02 | Player runs left-to-right nonstop at configurable `SPEED` | M1, M2 | complete | M1 config contract; M2 measured scene displacement/distance test |
| R03 | Collectibles and enemies spawn along the generated route | M3, M4, M5 | complete | M4 enemies and M5 coin/heart pickups materialize from live generated anchors and retire with exact chunk/anchor lifecycle |
| R04 | Evade obstacles, falls, and damage | M2, M3, M4 | complete | M2 physical fall/stuck/damage lifecycle; M3 hazard-safe traversal/recovery; M4 complete roster with melee/projectile/beam damage and timed-effect runtime |
| R05 | Camera follows player on horizontal axis | M2 | complete | M2: fixed-Y Camera2D integration tests through run/jump/fall/revive |
| R06 | Falling sets health to zero | M2 | complete | M2: fall failure ignores defense/protection and zeros health |
| R07 | Zero health or stuck for `GAME_OVER_NUMBER_OF_SECS` starts revival countdown | M1, M2 | complete | M1 timing contract; M2 lethal-health, thin/preexisting-wall, exact incremental stuck tests |
| R08 | Countdown lasts `COUNTDOWN_SECS`; potion resumes the same run from a safe nearby support or the run ends | M1, M2 | complete | M2: stocked before/exact/after boundaries, safe resolver, exact-once consumption, expiry/game over |
| R09 | All constant-case variables/placeholders have user-editable defaults | M1, M4, M5, M10 | complete | M10 final audit centralizes all remaining per-enemy `[Enemy]_SHOOTING_INTERVAL` and `[Enemy]_VICINITY` defaults in `GameConfig`; drop probabilities and all other TASK constant-case defaults are already centralized and validated by `test_m10_enemy_placeholders_and_mobile_release_config` |
| R10 | Per-run health and horizontal tile distance | M2 | complete | M2: transient RunState plus signal/HUD and measured-distance scene tests |
| R11 | Brief red feedback on damage | M2 | complete | M2: damage tint duration/protection/revival integration test |
| R12 | Jump input and configurable `MAX_JUMP` tiles | M2 | complete | M2: raw Up input consumed once; measured apex/landing test |
| R13 | Roll input and configurable `ROLL_DURATION` | M2 | complete | M2: exact-shape low/offset-ceiling posture and deferred collider-state tests |
| R14 | Automatic proximity melee | M2, M5 | complete | M2 proximity Area2D intent plus M5 profile melee-power damage, per-enemy cadence, death, and loot integration |
| R15 | Purchasable/upgradable stats use min/max/signed-step/cost rules without charging at bounds | M1, M7 | complete | M7: all six stats and ability-level/cooldown transactions enforce direction, affordability, bounds, and no-charge-at-bound invariants |
| R16 | Max-health integer increasing, defense multiplier decreasing, melee power integer increasing, enemy firing-interval multiplier increasing | M1, M7 | complete | M7: exhaustive signed-step upgrade test reaches each configured bound without overshoot |
| R17 | Invisibility/slowdown duration stats gated by ability unlock | M6, M7 | complete | M6 runtime gating plus M7 purchase/upgrade tests prove locked rejection and bounded post-unlock progression |
| R18 | Gold funds real purchases of characters, revival potions, abilities, weapons, and stats | M5, M7, M8 | complete | M7 atomic transactions plus M8 real Main Menu potion shop and Character/Stats/Abilities/Weapons screen bindings |
| R19 | Six atlas terrain palettes: Grass green/brown, Tundra orange/gray, Snow, Desert, Astro purple/gray, Fort black/gray-white | M3 | complete | Fix 1: all six biomes now map to their verified 28-frame families in `spritesheet-tiles-double.png`; runtime neighbor topology selects block corners/edges/fill plus horizontal/vertical variants instead of repeating one biome swatch, while collision remains separate from drawing. |
| R20 | Biomes switch exactly every `BIOME_INTERVAL` horizontal tiles | M3 | complete | M3b: `test_biome_exact_boundary_columns`, cross-boundary metadata test, and real Grass→Tundra physics crossing |
| R21 | First encounter ordered 1–6; subsequent seeded-random choice excludes immediate repeat as a documented default | M3 | complete | M3b: ordered-pass, seeded-variation, 300-encounter no-repeat, negative-origin, and regeneration tests |
| R22 | Snow randomizes reachable `MAX_JUMP` | M3 | complete | M3c.1: deterministic run-seed/accepted-index sampling from actual physical Snow support, rejected-input non-consumption, revival continuity/new-run reset, and forced min/max physical apex tests |
| R23 | Desert deals damage with flame particles | M3 | complete | M3c.2: supplied flame texture on real `GPUParticles2D`, support-top Area2D contact, deterministic cadence, and defense-aware Director damage integration |
| R24 | Astro blocks fall on step and cascade onto blocks below | M3 | complete | M3c.3: actual occupied-cell ownership, player-only top contact, delayed fall, deterministic non-tunneling three-block/cross-owner cascades, non-Astro preservation, pause/revival/retirement, and full-segment traversal tests |
| R25 | Fort spikes cycle vertically and damage only while visible | M3 | complete | M3c.2: supplied spike asset, one continuous phase for rise/hold/fall, aligned visible/hitbox exposure, retracted no-damage state, and paused-clock integration tests |
| R26 | Shooting unlock exposes weapons; each can unlock/equip; enforce `NUM_EQUIPPABLE_WEAPONS` | M5, M7 | complete | M5 runtime/equipment capacity plus M7 Shooting-gated weapon purchase, persistence, and catalog validation |
| R27 | Weapon damage varies | M5 | complete | M5b `WeaponCatalog` definitions own differing damage values and swept projectile integration applies them to enemy health |
| R28 | Weapon trajectories include projectile arcs and straight motion | M5 | complete | M5b straight and ballistic definitions plus real gravity/sweep scene coverage |
| R29 | Weapon aim includes directed, random, determined, and forward | M5 | complete | M5b pure targeting policy proves directed targets, seeded random directions, configured determined aim, and forward aim |
| R30 | Weapon target count varies and can hit simultaneous distinct on-screen enemies; use `Props/Weapons` assets | M5, M8 | complete | M5 runtime plus M8 Weapons screen exposes damage, trajectory, aim, target count, and fire interval from the live catalog |
| R31 | Every distinct supplied enemy identity maps thematically to exactly one biome | M4 | complete | M4b: `test_m4b_catalog_inventory_and_variants` proves 23 canonical identities cover all 39 supplied costume folders exactly once; roster mapping is documented in README |
| R32 | More than one enemy per biome | M4 | complete | M4b: biome roster test proves every one of the six biomes has multiple identities |
| R33 | First/later encounter enemy levels; higher levels have more health/damage | M4 | complete | M4b: deterministic per-biome visit counts gate tier 1 versus later tiers; catalog scaling test proves higher tiers have greater health/damage |
| R34 | Enemy health bar above head | M4 | complete | M4a.1/M4b: streamed production enemies create overhead ProgressBars, update damage, and reach zero on death |
| R35 | Standing and patrol enemies | M4 | complete | M4b catalog assigns stationary and support-bounded patrol movement across the full roster; controller scene test covers both modes |
| R36 | Melee-only, ranged-only, and combined enemy attacks | M4 | complete | M4b catalog covers all three attack modes; real controller integration verifies each channel |
| R37 | Ranged attacks begin within configurable enemy vicinity | M4 | complete | M4 attack policy uses each definition's tile-based vicinity with distinct melee reach plus camera/LOS/cadence gates |
| R38 | Beam and Godot particle-system ranged attacks | M4 | complete | M4b definitions own particle/projectile versus beam kind; integration verifies textured one-shot `GPUParticles2D`, swept projectile hits, and two-point LOS beam realization |
| R39 | Per-enemy configurable and differing default shooting intervals | M1, M4 | complete | M1 validates timing bounds; M4b catalog gives every ranged identity a distinct interval and runtime applies the run-start profile interval multiplier |
| R40 | Every non-Grass enemy identity has a unique biome-consistent effect | M4 | complete | M4b roster test proves each non-Grass identity owns a unique status ID with themed parameters; Grass is the specified exception |
| R41 | Snow freeze effect and ice-blue player feedback | M4 | complete | M4b Snow definitions install freeze slowdown with `freeze` appearance; runtime test verifies reduced movement and ice-blue presentation |
| R42 | Desert burn effect | M4 | complete | M4b Desert definitions use identity-specific periodic burn; runtime test verifies a burn tick drains health |
| R43 | Vampire blood loss drains health; all drain ticks blink player red | M4 | complete | M4b Vampire `blood_loss` installs red blood presentation and periodic drain; runtime test verifies the drain tick also triggers direct red damage feedback |
| R44 | Spawnable collectibles appear along route | M3, M5 | complete | M5a coin/heart catalog materializes from live generated anchors and retires with streamed support |
| R45 | Enemy collectible drops use configurable probabilities in `[0, 1]` | M4, M5 | complete | M5a all 23 enemy tables validate three gem probabilities, deterministic rolls, and exact 0.0/1.0 boundaries |
| R46 | Coin/gem types grant differing gold values | M5 | complete | M5a bronze/silver/gold and blue/green/yellow values are distinct and real pickup gold updates are covered |
| R47 | Gems are worth more gold than coins (chosen rule: every gem exceeds every coin) | M5 | complete | M5a catalog invariant proves minimum gem value exceeds maximum coin value |
| R48 | Revival potion uses supplied icon, is consumed once, and continues the same run from safe recovery | M2, M8 | complete | M2 safe exact-once revival plus M8 Main Menu purchase and visible countdown revival button using the supplied potion icon/counter |
| R49 | Character assets come from `Characters` folder | M2, M7 | complete | M7 catalog covers all 45 supplied character SpriteFrames with validated pricing; selected character is applied at Level start |
| R50 | Player owns purchasable/unlockable/selectable characters, consumables, abilities, and weapons | M1, M7, M8 | complete | Persistent M7 ownership plus M8 Character/Ability/Weapon/Stats shop and equip/select controls |
| R51 | Abilities unlock/equip with `NUM_EQUIPABLE_ABILITIES` cap | M1, M6 | complete | M6a explicit 10-ability catalog, default Jump, shared capacity/exclusion model, and desktop/mobile slot routing |
| R52 | All non-exempt abilities have cooldown; each decreasing cooldown stat has gated min/max/step/cost upgrades | M1, M6, M7, M8 | complete | M6 runtime cooldowns, M7 bounded purchase logic, and M8 per-ability cooldown upgrade controls |
| R53 | Jump has no cooldown, starts unlocked, permits one/two/three jumps by level, and resets count on landing | M6 | complete | M6a/M6b default Jump level 1/equipped profile plus real 1/2/3-jump and landing-reset scene coverage |
| R54 | Left-side tile contact plus jump gives one/two wall jumps by level, no cooldown, reset on landing | M6 | complete | M6b standing-shape forward wall probe, level-bounded wall-jump counter, and landing reset |
| R55 | Holding jump beyond a documented threshold glides up to `MAX_GLIDE_DURATION`, no cooldown, reset on landing | M6 | complete | M6b `GLIDE_HOLD_THRESHOLD` hold gate, zero-vertical hang, exact maximum duration, and landing reset |
| R56 | Reverse Gravity toggles gravity on jump input | M6 | complete | M6b jump-owned gravity-sign/up-direction toggle with run-simulation cooldown |
| R57 | Jump and Reverse Gravity cannot both be equipped | M6, M7 | complete | M6a default-Jump profile and both equip orders are fail-closed through `AbilityEquipmentState` |
| R58 | Fly provides infinite jumps and no cooldown | M6 | complete | M6b Fly accepts repeated airborne jumps and composes with Reverse Gravity between toggles |
| R59 | Dash uses configurable tile-based `DASH_SPEED` and `DASH_TILES` | M6 | complete | M6b RUNNING-only dash travels exactly `DASH_TILES*TILE_SIZE`, uses configured speed, stops on blockage, and honors cooldown |
| R60 | Explode damages nearby enemies and tiles within `EXPLODE_RADIUS` | M6 | complete | M6c run-local activation damages nearby enemies, breaks non-Astro generated tiles inside the configured radius, preserves Astro tiles, and honors cooldown |
| R61 | Slowdown reduces `SPEED` and firing frequency by increasing enemy interval multiplier for upgraded duration | M6 | complete | M6c movement resolver applies the configured minimum speed multiplier and live enemy cadence uses the temporary runtime interval multiplier for the profile-owned duration |
| R62 | Invisibility prevents enemy perception for upgraded duration | M6 | complete | M6c enemy-spawner visibility resolver suppresses perception/attacks until the run-simulation expiry boundary |
| R63 | Shooting automatically fires equipped weapon assets at regular weapon intervals when enemies are on screen | M5, M6 | complete | M5b automatic visible-enemy firing/projectiles plus M6c numbered/mobile auxiliary action routing and profile-owned Shooting activation cooldown |
| R64 | Smartphone tap jump, swipe-down roll, auxiliary on-screen buttons and configurable side | M1, M8, M9 | complete | M9 touch router distinguishes tap/swipe/UI/multitouch/cancel and dynamic auxiliary buttons honor the persisted bottom-left/right setting with cooldown-disabled feedback |
| R65 | Computer Up jump, Down roll, numbered abilities, bottom-left mapping | M1, M8, M9 | complete | Existing Up/Down/number bindings plus M8 HUD mapping and M9 shared semantic dispatch parity; affected desktop jump/roll and M6 routing integration tests remain green |
| R66 | Main Menu and Level screens | M1, M2, M8 | complete | M8 Main Menu shop/navigation and Level HUD/revival/ability-map scene tests pass |
| R67 | Character, Stats, Abilities, Weapons, and Settings screens | M7, M8 | complete | All five M8 progression/settings scenes load and their real transaction/settings controls are exercised in scene integration tests |
| R68 | Weapons screen describes damage, trajectory, aim, and target count | M8 | complete | `test_m8_progression_screens_transactions_and_descriptions` verifies all required description axes from the live weapon catalog |
| R69 | HUD shows health, gold, consumable count, and horizontal tiles | M2, M8 | complete | M2 HUD signal bindings plus M8 countdown revival affordance and desktop ability mapping |
| R70 | Every game aspect has unit tests and every test is inventoried in README | M1–M10 | complete | Final release: 76 unit + 62 scene integration + 3 long-run cases = 141 unique scheduled tests; automated inventory audit reports 141/141 names present in README; fail-closed declared-failure/runtime/parse/hang self-check passes |
| R71 | Screens and HUD use supplied `UI` folder elements | M8 | complete | Main Menu coin icon, progression screen supplied UI window art, Level life/progress art, and potion art are wired from `assets/UI`/supplied HUD assets; rendered quality remains a supplemental M10 check |

## Planned default configuration

Final values remain user-editable in the central configuration and will be tuned through tests:

| Variable | Initial default |
|---|---:|
| `SPEED` | 240 px/s (3.75 tiles/s at 64 px/tile) |
| `TILE_SIZE` | 64 px |
| `MAX_JUMP` | 3 tiles |
| `ROLL_DURATION` | 0.65 s |
| `GAME_OVER_NUMBER_OF_SECS` | 4.0 s |
| `COUNTDOWN_SECS` | 5.0 s |
| `BIOME_INTERVAL` | 40 tiles |
| `NUM_EQUIPPABLE_WEAPONS` | 2 |
| `NUM_EQUIPABLE_ABILITIES` | 4 (spelling retained from specification) |
| `COOLDOWN_PERIOD` | 8.0 s |
| `MAX_GLIDE_DURATION` | 2.0 s |
| `DASH_SPEED` | 11.25 tiles/s (converted to 720 px/s at 64 px/tile) |
| `DASH_TILES` | 4 tiles |
| `EXPLODE_RADIUS` | 3 tiles |

Stat defaults and bounds:

| Stat | Min | Default | Max | Upgrade | Cost |
|---|---:|---:|---:|---:|---:|
| Maximum health | 50 | 100 | 250 | +10 | 100 gold |
| Defense damage multiplier | 0.40 | 1.00 | 1.00 | -0.05 | 125 gold |
| Melee power | 5 | 10 | 50 | +5 | 100 gold |
| Enemy fire-rate interval multiplier | 1.00 | 1.00 | 1.80 | +0.10 | 150 gold |
| Invisibility duration | 1.0 s | 2.0 s | 6.0 s | +0.5 s | 200 gold |
| Slow-down duration | 1.0 s | 2.5 s | 7.0 s | +0.5 s | 200 gold |

Each cooldown-bearing ability begins at an 8.0 s cooldown with a 2.0 s minimum, 12.0 s maximum validation bound, a signed `-0.5 s` upgrade, and a 175 gold upgrade cost. Jump, Climb, Glide, and Fly are explicitly exempt. Shooting activation owns its ability cooldown; after activation, equipped weapons independently own their regular firing intervals while targets are on screen. “Enemy fire rate” is represented as an interval multiplier, so increasing it intentionally reduces firing frequency, including during Slow Down Time.

Design additions beyond explicit `TASK.md` wording: versioned persistence/migration, health pickups (an available asset used as optional content), excluding immediate biome repeats after the ordered pass, clearing unsafe transient effects on revival, and temporary revival protection.

## Architecture boundaries

- `GameConfig`: immutable/default tuning values and validated data definitions.
- `ProfileState` + `SaveService`: persistent economy, unlocks, upgrades, equipment, settings.
- `RunState`: transient health, distance, biome encounter state, active statuses, death/countdown.
- `RunDirector`: coordinates streaming/spawns without owning profile persistence or entity internals.
- `BiomeGenerator`: deterministic chunk descriptions first, scene realization second.
- `PlayerController`: locomotion/action execution; delegates health/status and equipment rules to components/models.
- `EnemyController` and `WeaponController`: consume definitions instead of branching on asset names.
- UI observes models/signals and requests commands; it does not mutate raw state directly.
- Tests favor pure model tests, with focused headless scene integration tests for physics, input, rendering-independent effects, and navigation.

## Asset decisions

- Terrain visuals must source `assets/Spritesheets/spritesheet-tiles-double.png`; individual `assets/Tiles/terrain_*.png` images are verification-only and must never be runtime terrain sources. Fix 1 maps the 18×18, 128px-frame, 1px-gutter atlas into six 28-frame biome families and selects connected variants from neighbor geometry.
- Character animation uses selected lazy-loaded `sprite_frames.tres` resources under `assets/Characters/<id>/Png/Character Sprite`.
- Enemy definitions centrally map animation frames for every inventoried distinct identity from `assets/Enemies`; folders are never scanned at runtime. Cosmetic/animation variants are documented but need not become separate identities.
- Weapons come from `assets/Props/Weapons`; revival uses `assets/Consumables/revival_potion.png`; collectibles use `assets/Collectibles`; menus/HUD use `assets/UI`.

## Progress log

- Repository and asset inventory: complete (read-only explorer pass).
- Initial plan: independently reviewed. The configured `reviewer` model was unavailable in this session, so an available high-reasoning review subagent performed the same gate.
- Review corrections: applied; full enemy coverage, consumable purchases, cooldowns, safe revival, traceability, sub-gates, and test boundaries clarified.
- M1: complete; 17/17 tests pass via fail-closed wrapper, real failure fixtures pass, configured boot passes, independent tester clean, architecture reviewer approved.
- M2: active; focused repository/character investigation starting.
- M2 first implementation gate: failed; model-only coverage missed core Level physics. Resolved through iterative implementation, runtime probes, and expanded scene integration coverage.
- M2: complete; 20/20 unit and 15/15 integration tests pass, fail-closed self-check and bounded boots pass, independent tester clean, architecture reviewer approved.
- M3a investigation: complete; atlas cells, scene boundaries, movement constraints, and a pure-description/realization/streaming architecture were mapped before implementation.
- M3a first implementation gate: failed architecture review despite 29 unit and 21 integration checks passing. Blocking gaps are mismatched floating-platform collision, unenforced slowdown-aware reachability, incomplete recovery search, unsafe anchors, shifted run origin, repeated production seeds, and tests that overstate their coverage. A focused correction pass is active; M3b has not started.
- M3a correction gate: complete; 29/29 unit and 23/23 integration tests pass, fail-closed self-check passes, the architecture re-review approved, and independent tester inspection found no blocking defect. Centered tile ownership, minimum/maximum movement extremes, exact occupied collision, all-form traversal, recovery/seed/config identity, viewport streaming, and registry replacement are covered. Rendered atlas appearance remains a documented manual validation for the final integration gate.
- M3b: active; exact discrete-column biome sequencing will use columns `0..BIOME_INTERVAL-1` for the first Grass segment, keeping biome tile counts exact while run distance remains measured from the centered player origin.
- M3b: complete; 36/36 unit and 24/24 integration tests pass, self-check and diff checks pass, and the independent tester approved exact boundaries, ordered first pass, seeded no-repeat selection, cross-boundary metadata, and a physical Grass-to-Tundra crossing.
- M3c: active; biome palette/hazard asset and scene integration investigation starting.
- M3c.1 historical gate: the original single-region-per-biome atlas implementation passed its then-current automated checks but was superseded by UPDATE Fix 1. Fix 1 now uses the verified 18×18 connected-tile atlas families and geometry-aware variants; the old single-swatch rendering claim is no longer considered sufficient.
- M3c.2: active; one implementation owner will add the shared run-clock hazard contact boundary and active Desert/Fort hazards before independent validation.
- M3c.2: complete; 41/41 unit and 28/28 integration tests pass, fail-closed self-check and diff checks pass, and an independent tester approved the DamageEvent/Director boundary, supplied particle/spike assets, support-top placement, continuous Fort geometry, deterministic cadence, RUNNING-only clock, and cleanup. Rendered/device synchronization remains assigned to M10.
- M3c.3: active; the architecture reviewer approved a real occupied-cell Astro runtime overlay, stable ordered cascades, immediate eligibility invalidation, and unified hazard-safe recovery after the landing/recovery policies above were made explicit.
- M3c.3 first implementation gate: 45/45 unit and 33/33 integration tests pass and the independent tester found no failing check, but architecture review rejected closure. Reproduced blockers are penetration of independently armed/falling lower Astro cells, unbounded historical chunk epochs, stale same-frame hazard advancement after failure begins countdown, and negative-column collision runs lost to a sentinel bug. A focused correction plus stronger regeneration/non-Astro/continuous-traversal evidence is active.
- M3c.3 correction and M3 final gate: complete; 45/45 unit and 38/38 integration tests pass, fail-closed self-check and diff/shell checks pass, and both the architecture reviewer and an independent tester approved. Corrections cover every present lower-cell cascade sweep, bounded live epoch identity with same-tile regeneration, exact fall/stuck failure-frame clock freezing, negative-column collision, real non-Astro impact preservation, player-only contact, hazard-safe revival, and an uninterrupted full Astro interval traversal into Fort. Rendered atlas/particle/spike presentation remains explicitly deferred to M10.
- M4 investigation: active; explorer census found 23 canonical enemy identities represented by 39 supplied costume folders, documented explicit sequence-path conventions and attack assets, and proposed a complete exact-one-biome roster with multiple identities and first/later tiers per biome. Framework/status architecture is in pre-implementation reviewer review.
- M4 architecture review: approved with M4a.0 contract gate required before runtime controllers. Required seams are one paused run-simulation clock for statuses/combat, accepted-hit transactions through `RunDirector`, composed player movement/appearance modifiers, run-start enemy interval multiplier, exact anchor invalidation signals, stable epoch-owned spawn descriptors, and bounded lazy animation loading.
- M4a.0 first implementation gate: 49/49 unit and 39/39 integration tests pass, but architecture review rejected closure because status capacity/cadence catch-up are not actually bounded, accepted-hit observers can see a partial transaction, enemy definitions do not enforce shared upper bounds, and simultaneous blood/freeze presentation loses freeze during the blood blink's off phase. A focused correction and stronger boundary evidence are active; M4a.1 has not started.
- M4a.0 correction review: 50/50 unit and 39/39 integration checks pass locally and an independent tester approved static contract coverage. Architecture re-review confirmed three former blockers closed, but found one remaining nonperiodic-to-periodic status-refresh transition that retains an infinite pending tick. A targeted fix and regression are required before M4a.1.
- M4a.0 final gate: complete; 50/50 unit and 39/39 integration tests pass with the full wrapper, fail-closed self-check passes, an independent tester approved, and architecture reviewer formally approved after the nonperiodic-to-periodic first-tick regression was fixed. M4a.1 may begin. Rendered/device checks remain assigned to M10.
- M4a.1 final gate: complete; 53/53 unit and 42/42 scene integration tests pass, the fail-closed wrapper and declared-failure/runtime/parse/hang self-check pass, and all 95 tests are inventoried in README. The runtime now has stream-safe capped spawning with physical clearance/retry, exact anchor retirement, shared bounded lazy animation caching, support-bounded stationary/patrol controllers, separate melee/ranged reach, camera/LOS/cadence gates, overhead health bars/death, definition-owned particle/projectile versus beam attack kinds, RUNNING-only projectile lifetime, run-start enemy interval multiplier, and spawner-owned projectile resolution through RunDirector so shots survive source-enemy retirement. A direct architecture pass caught and fixed class-cache load-order dependence, projectile callbacks tied to enemy lifetime, and the last example-ID branch in ranged attack realization. No independent subagent was invoked in this continuation; M4b is the next active gate.
- M4b and M4 final gate: complete; 57/57 unit and 44/44 scene integration tests pass, the fail-closed wrapper and declared-failure/runtime/parse/hang self-check pass, and all 101 tests are inventoried in README. The explicit `EnemyCatalog` covers 23 canonical identities across all 39 supplied costume folders with deterministic variants, exact biome/tier gating, higher-tier health/damage, distinct ranged intervals, stationary/patrol and melee/ranged/combined modes, real particle/projectile and beam realization, and unique non-Grass themed effects. Snow freeze, Desert burn, and Vampire blood loss/red drain-tick feedback are verified through `RunDirector`. A final direct review also aligned animation-cache capacity with the active-enemy cap and fixed particle effects to persist for their one-shot lifetime. No agent instructions or agent-folder content were used; rendered/device presentation remains a supplemental M10 validation. M5 is the next milestone.
- M5 final gate: complete; 62/62 unit and 48/48 scene integration tests pass, the fail-closed wrapper and declared-failure/runtime/parse/hang self-check pass, boot/diff checks are clean, and all 110 tests are inventoried in README. M5a adds profile-powered automatic melee, stream-owned coin/heart pickups, capped healing/run gold, pure seeded per-enemy gem drops with exact probability boundaries, and bounded drop cleanup. M5b adds a supplied-asset weapon catalog with varying damage/interval/target count, real straight and ballistic swept projectiles, directed/seeded-random/determined/forward aim, three-target simultaneous firing, Shooting unlock/equip/activation gating, no-target suppression, and RUNNING simulation-time cadence. Direct architecture review separated random directional aim from random target selection and kept M6 action routing and M7/M8 purchase/screens out of M5. M6a is next.

- M6a final gate: complete; 65/65 unit and 49/49 scene integration tests passed after introducing the exact 10-ability catalog, default equipped Jump level 1, persistent level/cooldown values, transient run-local cooldown timestamps, and common desktop/mobile auxiliary slot routing. Cooldown timestamps are intentionally not profile state.
- M6b final gate: complete; 65/65 unit and 53/53 scene integration tests pass. Jump levels 1–3, two-level right-wall Climb, held-jump Glide, Reverse Gravity, Fly, and exact-distance Dash are realized through real CharacterBody2D physics. Ability cooldowns use RunDirector simulation time so countdowns pause them and revival cannot reset them through PlayerController-local time.
- M6 final gate: complete; 67/67 unit and 56/56 scene integration tests pass. M6c adds profile-owned invisibility/slowdown durations, run-local cooldown execution, slowdown movement and live enemy interval resolvers, invisibility enemy-perception suppression, Explode enemy damage plus non-Astro tile destruction, and Shooting action routing through the profile cooldown. A full-suite physics leak was traced to the navigation test leaving a replacement Level alive and fixed by restoring the scene to Main Menu after that lifecycle assertion. M7 is the next active gate.
- M7 final gate: complete; 73/73 unit and 58/58 scene integration tests pass, and the fail-closed declared-failure/runtime/parse/hang self-check passes. M7 adds versioned JSON profile persistence with temp-file atomic replacement, migration/defaulting and malformed/corrupt-save fallback, strict catalog/equipment validation, application-lifetime autosave/reload through `RunSession`, all 45 supplied characters with pricing/unlock/select flow, real gold-funded potion/ability/weapon/stat transactions, exhaustive signed stat and cooldown/level bounds, and run-start character/max-health/defense application while keeping health/distance/run gold transient. The configured reviewer profile was unavailable; direct architecture review found and fixed stale wrapper counts, cross-test profile leakage, malformed nested save-shape handling, and unknown weapon IDs. M8 is next.
- M8 final gate: complete; 74/74 unit and 61/61 scene integration tests pass with the fail-closed wrapper and declared-failure/runtime/parse/hang self-check. Main Menu now exposes all progression screens and a real revival-potion purchase; Character/Stats/Abilities/Weapons/Settings screens use a shared supplied-UI shell and live profile transactions; weapon descriptions expose all required behavior axes; settings persist mobile auxiliary corner; Level HUD adds bottom-left desktop ability mapping and explicit revival countdown/use-potion affordance. A delegated review attempt failed at the provider protocol layer without code findings; direct full-suite validation is clean. Rendered/device-only readability and artwork checks remain supplemental M10 evidence. M9 is next.
- M9 final gate: complete; 75/75 unit tests pass, the fail-closed self-check passes, and all touch/input-sensitive integration tests pass after the mobile dispatch seam changed to synchronous semantic routing. M9 adds tap-to-jump, vertical swipe-down roll, UI-touch exclusion, cancel/multitouch rejection, dynamic auxiliary buttons in either persisted bottom corner, shared mobile/desktop ability-slot dispatch, and live cooldown-disabled button feedback. A prior full 62-test integration run reached only the new M9 assertion as a failure; after the dispatch fix, the affected desktop jump/roll, M6 ability routing, M8 HUD, and complete M9 scenario were re-run and pass. The expanded integration suite now exceeds the old 50-second wrapper ceiling on this connector, so M10 will update/validate the release timeout and run the final comprehensive gate.
- M10 final gate: complete. Directly observed release validation is 76/76 unit tests, all 62 integration tests across three deterministic release shards (21/21, 21/21, 20/20), 3/3 long-run release cases, fail-closed wrapper self-check, headless project boot, and an automated README inventory audit of 141 scheduled/141 unique/0 missing names. The normal wrapper now uses a 90-second per-stage ceiling and runs unit → full integration → long-run stages with exact markers. M10 centralizes the remaining per-enemy interval/vicinity TASK placeholders, verifies the Mobile renderer/feature and positive runtime caps, exercises 180-chunk/72-encounter deterministic long runs across all biomes/forms/hazard classes/enemy tiers/loot, verifies every ability cooldown boundary plus same-run revival/persistence, and validates lazy enemy-animation cache release. README now documents controls, save behavior/location semantics, release safeguards, supplied-asset attribution guidance, architecture, and exhaustive tests. Required final reviewer and tester delegations were attempted twice through the configured provider but both failed at the provider protocol layer before producing findings; direct review found no remaining matrix row or undocumented test. Rendered/device-only appearance inspection remains a supplemental manual release check, not an unresolved TASK implementation item.
- UPDATE Fix 1 final gate: complete. The actual 2321×2321 terrain sheet was inspected as an 18×18 grid of 128×128 frames with 1px gutters; all six 28-frame biome families are mapped in `TerrainPalette`, `TerrainChunk` selects connected block/horizontal/vertical pieces from live neighbor topology (including chunk seams and broken cells), Astro uses the selected region rather than a fixed swatch, and no runtime terrain code loads individual terrain PNG files. Validation: 76/76 unit, 62/62 full integration, 3/3 long-run, wrapper self-check, and clean headless boot.
