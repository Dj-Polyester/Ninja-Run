class_name EnemyCatalog
extends RefCounted
## Explicit supplied-asset inventory. Runtime code never scans enemy folders.

const Definition = preload("res://scripts/enemies/enemy_definition.gd")
const Effect = preload("res://scripts/enemies/enemy_effect_spec.gd")

const CANONICAL_IDENTITY_COUNT: int = 23
const SUPPLIED_VARIANT_COUNT: int = 39
const IDLE_FRAMES_PER_VARIANT: int = 6

static func definitions() -> Array[Definition]:
	var out: Array[Definition] = []
	# Grass is intentionally neutral: the task explicitly exempts Grass effects.
	out.append(_entry(&"archer_guy", &"grass", 1, Definition.MOVEMENT_STATIONARY, false, true, Definition.RANGED_PARTICLE, null,
		PackedStringArray(["archer-barbarian-mage/Archer Guy"]), PackedStringArray(["Idle_"])))
	out.append(_entry(&"barbarian_warrior", &"grass", 1, Definition.MOVEMENT_PATROL, true, false, Definition.RANGED_PARTICLE, null,
		PackedStringArray(["archer-barbarian-mage/Barbarian Warrior"]), PackedStringArray(["Idle_"])))
	out.append(_entry(&"monk_guy", &"grass", 2, Definition.MOVEMENT_PATROL, true, false, Definition.RANGED_PARTICLE, null,
		PackedStringArray(["monk-evil-bald-warrior-and-old-warrior/Monk Guy"]), PackedStringArray(["Idle_"])))
	out.append(_entry(&"goblin", &"grass", 2, Definition.MOVEMENT_PATROL, true, true, Definition.RANGED_PARTICLE, null,
		PackedStringArray(["orc-ogre-and-goblin/Goblin"]), PackedStringArray(["0_Goblin_Idle_"])))

	# Tundra: rugged creatures; effects are distinct cold/fatigue mechanics.
	out.append(_entry(&"old_guy", &"tundra", 1, Definition.MOVEMENT_STATIONARY, true, false, Definition.RANGED_PARTICLE,
		_effect(&"tundra_fatigue", 1.30, 0.0, 0.0, 0.88, &"", &"old_guy"),
		PackedStringArray(["monk-evil-bald-warrior-and-old-warrior/Old Guy"]), PackedStringArray(["Idle_"])))
	out.append(_entry(&"ogre", &"tundra", 1, Definition.MOVEMENT_PATROL, true, false, Definition.RANGED_PARTICLE,
		_effect(&"tundra_stagger", 0.80, 0.0, 0.0, 0.72, &"", &"ogre"),
		PackedStringArray(["orc-ogre-and-goblin/Ogre"]), PackedStringArray(["0_Ogre_Idle_"])))
	out.append(_entry(&"golem", &"tundra", 2, Definition.MOVEMENT_STATIONARY, true, true, Definition.RANGED_BEAM,
		_effect(&"stone_chill", 1.80, 0.0, 0.0, 0.82, &"", &"golem"),
		PackedStringArray(["golems/Golem_1", "golems/Golem_2", "golems/Golem_3"]), PackedStringArray(["0_Golem_Idle_", "0_Golem_Idle_", "0_Golem_Idle_"])))
	out.append(_entry(&"orc", &"tundra", 2, Definition.MOVEMENT_PATROL, true, true, Definition.RANGED_PARTICLE,
		_effect(&"tundra_wound", 2.20, 0.70, 1.0, 0.90, &"", &"orc"),
		PackedStringArray(["orc-ogre-and-goblin/Orc"]), PackedStringArray(["0_Orc_Idle_"])))

	# Snow: every hit freezes with distinct duration/slow strength.
	out.append(_entry(&"frost_knight", &"snow", 1, Definition.MOVEMENT_PATROL, true, false, Definition.RANGED_PARTICLE,
		_effect(&"frost_knight_freeze", 2.00, 0.0, 0.0, 0.62, &"freeze", &"frost_knight"),
		PackedStringArray(["frost-knight/Frost_Knight_1", "frost-knight/Frost_Knight_2", "frost-knight/Frost_Knight_3"]), PackedStringArray(["0_Knight_Idle_", "0_Frost_Knight_Idle_", "0_Frost_Knight_Idle_"])))
	out.append(_entry(&"human_magician", &"snow", 1, Definition.MOVEMENT_STATIONARY, false, true, Definition.RANGED_BEAM,
		_effect(&"arcane_freeze", 2.40, 0.0, 0.0, 0.58, &"freeze", &"human_magician"),
		PackedStringArray(["human-magician/Human Magician_1", "human-magician/Human Magician_2", "human-magician/Human Magician_3"]), PackedStringArray(["0_Human Magician_Idle_", "0_Human Magician_Idle_", "0_Human Magician_Idle_"])))
	out.append(_entry(&"skeleton_warrior", &"snow", 2, Definition.MOVEMENT_PATROL, true, true, Definition.RANGED_PARTICLE,
		_effect(&"bone_freeze", 1.50, 0.0, 0.0, 0.70, &"freeze", &"skeleton_warrior"),
		PackedStringArray(["skeleton-warrior/Skeleton_Warrior_1", "skeleton-warrior/Skeleton_Warrior_2", "skeleton-warrior/Skeleton_Warrior_3"]), PackedStringArray(["0_Skeleton_Warrior_Idle_", "0_Skeleton_Warrior_Idle_", "0_Skeleton_Warrior_Idle_"])))

	# Desert: all effects burn, but cadence/damage/duration are identity-specific.
	out.append(_entry(&"desert_nomad", &"desert", 1, Definition.MOVEMENT_PATROL, true, true, Definition.RANGED_PARTICLE,
		_effect(&"nomad_burn", 2.20, 0.55, 2.0, 1.00, &"", &"desert_nomad"),
		PackedStringArray(["desert-nomad/Desert_Nomad_1", "desert-nomad/Desert_Nomad_2", "desert-nomad/Desert_Nomad_3"]), PackedStringArray(["0_Desert_Nomad_Idle_", "0_Desert_Nomad_Idle_", "0_Desert_Nomad_Idle_"])))
	out.append(_entry(&"minotaur", &"desert", 1, Definition.MOVEMENT_PATROL, true, false, Definition.RANGED_PARTICLE,
		_effect(&"minotaur_burn", 3.00, 0.75, 3.5, 0.90, &"", &"minotaur"),
		PackedStringArray(["minotaur/Minotaur_1", "minotaur/Minotaur_2", "minotaur/Minotaur_3"]), PackedStringArray(["0_Minotaur_Idle_", "0_Minotaur_Idle_", "0_Minotaur_Idle_"])))
	out.append(_entry(&"evil_bald_guy", &"desert", 2, Definition.MOVEMENT_PATROL, true, true, Definition.RANGED_PARTICLE,
		_effect(&"scorch_burn", 1.80, 0.45, 1.5, 0.95, &"", &"evil_bald_guy"),
		PackedStringArray(["monk-evil-bald-warrior-and-old-warrior/Evil Bald Guy"]), PackedStringArray(["Idle_"])))

	# Astro: magical/otherworldly identities use void/phase effects.
	out.append(_entry(&"medieval_mage", &"astro", 1, Definition.MOVEMENT_STATIONARY, false, true, Definition.RANGED_BEAM,
		_effect(&"void_drag", 2.00, 0.0, 0.0, 0.68, &"", &"medieval_mage"),
		PackedStringArray(["archer-barbarian-mage/Medieval Mage"]), PackedStringArray(["Idle_"])))
	out.append(_entry(&"ghoul_hunter", &"astro", 1, Definition.MOVEMENT_PATROL, true, true, Definition.RANGED_PARTICLE,
		_effect(&"phase_sickness", 1.60, 0.0, 0.0, 0.60, &"", &"ghoul_hunter"),
		PackedStringArray(["ghoul-hunter/Ghoul_Hunter_1", "ghoul-hunter/Ghoul_Hunter_2", "ghoul-hunter/Ghoul_Hunter_3"]), PackedStringArray(["0_Ghoul_Hunter_Idle_", "0_Ghoul_Hunter_Idle_", "0_Ghoul_Hunter_Idle_"])))
	out.append(_entry(&"reaper_man", &"astro", 2, Definition.MOVEMENT_PATROL, true, true, Definition.RANGED_BEAM,
		_effect(&"entropy_drain", 2.80, 0.70, 2.5, 0.85, &"", &"reaper_man"),
		PackedStringArray(["reaper-man/Reaper_Man_1", "reaper-man/Reaper_Man_2", "reaper-man/Reaper_Man_3"]), PackedStringArray(["0_Reaper_Man_Idle_", "0_Reaper_Man_Idle_", "0_Reaper_Man_Idle_"])))
	out.append(_entry(&"pumpkin_head_guy", &"astro", 2, Definition.MOVEMENT_STATIONARY, false, true, Definition.RANGED_PARTICLE,
		_effect(&"star_fright", 1.20, 0.0, 0.0, 0.75, &"", &"pumpkin_head_guy"),
		PackedStringArray(["halloween-characters/Pumpkin Head Guy"]), PackedStringArray(["Idle_"])))

	# Fort: undead/gothic roster. Vampire owns the required blood-loss feedback.
	out.append(_entry(&"death_knight", &"fort", 1, Definition.MOVEMENT_PATROL, true, true, Definition.RANGED_BEAM,
		_effect(&"death_knight_dread", 2.50, 0.0, 0.0, 0.80, &"", &"death_knight"),
		PackedStringArray(["death-knight-skeleton-zombie/Death_Knight"]), PackedStringArray(["0_Death_Knight_Idle_"])))
	out.append(_entry(&"skeleton", &"fort", 1, Definition.MOVEMENT_PATROL, true, false, Definition.RANGED_PARTICLE,
		_effect(&"bone_bleed", 1.80, 0.60, 1.2, 0.95, &"blood", &"skeleton"),
		PackedStringArray(["death-knight-skeleton-zombie/Skeleton"]), PackedStringArray(["0_Skeleton_Idle_"])))
	out.append(_entry(&"zombie", &"fort", 2, Definition.MOVEMENT_PATROL, true, false, Definition.RANGED_PARTICLE,
		_effect(&"grave_rot", 2.60, 0.65, 2.0, 0.90, &"blood", &"zombie"),
		PackedStringArray(["death-knight-skeleton-zombie/Zombie"]), PackedStringArray(["0_Zombie_Idle_"])))
	out.append(_entry(&"skull_knight", &"fort", 2, Definition.MOVEMENT_PATROL, true, true, Definition.RANGED_PARTICLE,
		_effect(&"skull_stagger", 1.10, 0.0, 0.0, 0.65, &"", &"skull_knight"),
		PackedStringArray(["halloween-characters/Skull Knight"]), PackedStringArray(["Idle_"])))
	out.append(_entry(&"vampire", &"fort", 3, Definition.MOVEMENT_STATIONARY, true, true, Definition.RANGED_BEAM,
		_effect(&"blood_loss", 3.00, 0.50, 3.0, 0.92, &"blood", &"vampire"),
		PackedStringArray(["halloween-characters/Vampire"]), PackedStringArray(["Idle_"])))
	return out

static func _effect(status_id: StringName, duration: float, tick: float, periodic_damage: float, movement: float, appearance: StringName, source: StringName) -> Effect:
	return Effect.new(status_id, duration, tick, periodic_damage, movement, appearance, source)

static func _entry(id: StringName, biome: StringName, tier: int, movement: StringName, melee: bool, ranged: bool, ranged_kind: StringName, effect: Effect, variant_folders: PackedStringArray, variant_prefixes: PackedStringArray) -> Definition:
	var result := Definition.new(id, biome, tier)
	result.maximum_health = 20.0 + 15.0 * float(tier)
	result.contact_damage = 4.0 + 3.0 * float(tier)
	result.movement_type = movement
	result.movement_speed = 48.0 + 8.0 * float(tier) if movement == Definition.MOVEMENT_PATROL else 0.0
	result.melee_enabled = melee
	result.ranged_enabled = ranged
	result.melee_interval = maxf(0.55, 1.05 - 0.08 * float(tier))
	result.ranged_interval = GameConfig.enemy_shooting_interval(id)
	result.ranged_kind = ranged_kind
	result.melee_range_tiles = GameConfig.ENEMY_MELEE_RANGE_TILES
	result.vicinity_tiles = GameConfig.enemy_vicinity_tiles(id)
	result.requires_line_of_sight = ranged
	result.scene_path = "res://scenes/level.tscn"
	result.effect_spec = effect
	if variant_folders.size() != variant_prefixes.size() or variant_folders.is_empty():
		return result
	for index in variant_folders.size():
		var variant_id := &"default" if variant_folders.size() == 1 else StringName("v%d" % [index + 1])
		var frames := _idle_frames(variant_folders[index], variant_prefixes[index])
		result.variant_idle_frames[variant_id] = frames
		if index == 0 and not frames.is_empty():
			result.sprite_path = frames[0]
	return result

static func _idle_frames(folder: String, prefix: String) -> PackedStringArray:
	var frames := PackedStringArray()
	for index in IDLE_FRAMES_PER_VARIANT:
		frames.append("res://assets/Enemies/%s/PNG/PNG Sequences/Idle/%s%03d.png" % [folder, prefix, index])
	return frames

static func identity_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition: Definition in definitions():
		ids.append(definition.id)
	ids.sort()
	return ids

static func supplied_variant_count() -> int:
	var total := 0
	for definition: Definition in definitions():
		total += definition.variant_ids().size()
	return total
