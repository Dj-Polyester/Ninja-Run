class_name EnemyAttackPolicy
extends RefCounted
const Definition = preload("res://scripts/enemies/enemy_definition.gd")
## Pure cadence policy. Callers own target acquisition/projectile realization.

var last_melee_at := -INF
var last_ranged_at := -INF

func reset() -> void:
	last_melee_at = -INF
	last_ranged_at = -INF

func decide(definition: Definition, simulation_time: float, enemy_position: Vector2, target_position: Vector2, target_visible: bool, camera_contains_enemy: bool, line_of_sight: bool, interval_multiplier: float = GameConfig.DEFAULT_ENEMY_FIRE_RATE, camera_contains_target: bool = true) -> Dictionary:
	# First eligible shot is immediate. Ineligible/pause frames never enqueue
	# debt; returning visibility can yield only one current shot per channel.
	if definition == null or not definition.is_valid() or not is_finite(simulation_time) or not target_visible or not camera_contains_enemy or not camera_contains_target:
		return {&"melee": false, &"ranged": false}
	if definition.requires_line_of_sight and not line_of_sight:
		return {&"melee": false, &"ranged": false}
	var multiplier := clampf(interval_multiplier, GameConfig.MIN_ENEMY_FIRE_RATE, GameConfig.MAX_RUNTIME_ENEMY_INTERVAL_MULTIPLIER)
	var target_distance := enemy_position.distance_to(target_position)
	var melee_within := target_distance <= definition.melee_range_tiles * GameConfig.TILE_SIZE
	var ranged_within := target_distance <= definition.vicinity_tiles * GameConfig.TILE_SIZE
	var melee_due := definition.melee_enabled and melee_within and simulation_time >= last_melee_at + definition.melee_interval * multiplier
	var ranged_due := definition.ranged_enabled and ranged_within and simulation_time >= last_ranged_at + definition.ranged_interval * multiplier
	if melee_due: last_melee_at = simulation_time
	if ranged_due: last_ranged_at = simulation_time
	return {&"melee": melee_due, &"ranged": ranged_due}
