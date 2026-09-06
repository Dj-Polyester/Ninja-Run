class_name AutomaticMeleeController
extends Area2D

const DAMAGE_INFO_SCRIPT := preload("res://src/gameplay/combat/damage_info.gd")
const DAMAGEABLE_CONTRACT_SCRIPT := preload("res://src/gameplay/combat/damageable_contract.gd")

signal attack_performed(target: Node, damage: float)

var cooldown_remaining := 0.0
var last_target: Node
var last_damage := 0.0

@onready var detection_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = GameConfig.ENEMY_COLLISION_MASK
	monitoring = true
	monitorable = false
	_configure_range()

func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

func is_ready_to_attack() -> bool:
	return cooldown_remaining <= 0.0

func try_attack(attacker: Node, damage: float) -> Node:
	if attacker == null or not is_instance_valid(attacker) or not is_ready_to_attack():
		return null
	var target := nearest_target(attacker.global_position if attacker is Node2D else global_position, attacker)
	if target == null:
		return null
	var applied_damage := maxf(0.0, damage)
	if applied_damage <= 0.0:
		return null

	last_target = target
	last_damage = applied_damage
	cooldown_remaining = GameConfig.MELEE_ATTACK_INTERVAL
	var damage_info = DAMAGE_INFO_SCRIPT.new(attacker, DAMAGE_INFO_SCRIPT.DamageType.MELEE)
	target.call(&"take_damage", applied_damage, damage_info)
	attack_performed.emit(target, applied_damage)
	return target

func nearest_target(origin: Vector2 = global_position, exclude: Node = null) -> Node:
	var nearest: Node
	var nearest_distance_squared := INF
	var seen: Dictionary = {}
	var overlaps: Array = []
	overlaps.append_array(get_overlapping_bodies())
	overlaps.append_array(get_overlapping_areas())

	for overlap in overlaps:
		if not overlap is Node:
			continue
		var target := _resolve_damageable(overlap as Node)
		if target == null or target == exclude or not is_instance_valid(target):
			continue
		var instance_id := target.get_instance_id()
		if seen.has(instance_id):
			continue
		seen[instance_id] = true
		if target.has_method(&"can_receive_melee_attack") and not bool(target.call(&"can_receive_melee_attack")):
			continue
		if not target is Node2D:
			continue
		var distance_squared := origin.distance_squared_to((target as Node2D).global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest = target

	return nearest

func _resolve_damageable(candidate: Node) -> Node:
	var current: Node = candidate
	# Hurtboxes are commonly one or two nodes beneath their damageable enemy
	# root. Bound the walk so unrelated ancestors are never selected by accident.
	for _depth in 4:
		if current == null:
			break
		if not current.is_queued_for_deletion() and DAMAGEABLE_CONTRACT_SCRIPT.supports(current):
			return current
		current = current.get_parent()
	return null

func _configure_range() -> void:
	var circle := detection_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		detection_shape.shape = circle
	circle.radius = GameConfig.tiles_to_pixels(GameConfig.MELEE_RANGE_TILES)
