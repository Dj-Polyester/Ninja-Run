class_name EnemyDefinition
extends RefCounted
const Effect = preload("res://scripts/enemies/enemy_effect_spec.gd")
## Catalog entry contract; controllers/spawners are deliberately out of scope.

const MOVEMENT_STATIONARY: StringName = &"stationary"
const MOVEMENT_PATROL: StringName = &"patrol"
const MOVEMENT_CHASE: StringName = &"chase"
const MOVEMENT_TYPES: Array[StringName] = [MOVEMENT_STATIONARY, MOVEMENT_PATROL, MOVEMENT_CHASE]
const RANGED_PARTICLE: StringName = &"particle"
const RANGED_BEAM: StringName = &"beam"
const RANGED_KINDS: Array[StringName] = [RANGED_PARTICLE, RANGED_BEAM]

var id: StringName
var biome: StringName
var tier: int
var maximum_health: float
var contact_damage: float
var movement_type: StringName
var movement_speed: float
var melee_enabled: bool
var ranged_enabled: bool
var melee_interval: float
var ranged_interval: float
var ranged_kind: StringName
var melee_range_tiles: float
var vicinity_tiles: float
var requires_line_of_sight: bool
var sprite_path: String
var variant_idle_frames: Dictionary = {} # StringName -> PackedStringArray, explicit ordered frames.
var scene_path: String
var effect_spec: Effect

func _init(new_id: StringName = &"", new_biome: StringName = &"", new_tier: int = 1) -> void:
	id = new_id
	biome = new_biome
	tier = new_tier
	maximum_health = 1.0
	contact_damage = 0.0
	movement_type = MOVEMENT_STATIONARY
	movement_speed = 0.0
	melee_enabled = false
	ranged_enabled = false
	melee_interval = 1.0
	ranged_interval = 1.0
	ranged_kind = RANGED_PARTICLE
	melee_range_tiles = GameConfig.ENEMY_MELEE_RANGE_TILES
	vicinity_tiles = 1.0
	requires_line_of_sight = false
	sprite_path = ""
	variant_idle_frames = {}
	scene_path = ""

func is_valid() -> bool:
	if id.is_empty() or not biome in [&"grass", &"tundra", &"snow", &"desert", &"astro", &"fort"] or tier < GameConfig.MIN_ENEMY_TIER or tier > GameConfig.MAX_ENEMY_TIER:
		return false
	if not is_finite(maximum_health) or maximum_health < GameConfig.MIN_ENEMY_HEALTH or maximum_health > GameConfig.MAX_ENEMY_HEALTH or not is_finite(contact_damage) or contact_damage < 0.0 or contact_damage > GameConfig.MAX_ENEMY_DAMAGE:
		return false
	if not movement_type in MOVEMENT_TYPES or not is_finite(movement_speed) or movement_speed < 0.0:
		return false
	if sprite_path.is_empty() or scene_path.is_empty() or not sprite_path.begins_with("res://") or not scene_path.begins_with("res://"):
		return false
	for variant in variant_idle_frames.keys():
		if StringName(variant).is_empty():
			return false
		var frames: PackedStringArray = variant_idle_frames[variant]
		if frames.is_empty() or frames.size() > 48:
			return false
		for frame in frames:
			if not frame.begins_with("res://"):
				return false
	if not is_finite(vicinity_tiles) or vicinity_tiles <= 0.0:
		return false
	if melee_enabled and (not is_finite(melee_interval) or melee_interval <= 0.0 or not is_finite(melee_range_tiles) or melee_range_tiles <= 0.0): return false
	if ranged_enabled and (not is_finite(ranged_interval) or ranged_interval <= 0.0 or not ranged_kind in RANGED_KINDS): return false
	return (melee_enabled or ranged_enabled) and (effect_spec == null or effect_spec.is_valid())

func variant_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	if variant_idle_frames.is_empty():
		result.append(&"default")
		return result
	for variant in variant_idle_frames.keys():
		result.append(StringName(variant))
	result.sort()
	return result

func idle_frames_for_variant(variant_id: StringName) -> PackedStringArray:
	if variant_idle_frames.has(variant_id):
		var frames: PackedStringArray = variant_idle_frames[variant_id]
		return frames.duplicate()
	if variant_idle_frames.is_empty() and variant_id == &"default":
		return PackedStringArray([sprite_path])
	return PackedStringArray()
