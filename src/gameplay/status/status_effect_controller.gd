class_name StatusEffectController
extends Node

const STATUS_EFFECT_SCRIPT := preload("res://src/data/status_effect.gd")
const STATUS_EFFECT_CATALOG_SCRIPT := preload("res://src/data/status_effect_catalog.gd")

signal effect_applied(effect: Resource, stacks: int)
signal effect_refreshed(effect: Resource, stacks: int)
signal effect_ticked(effect: Resource, stacks: int)
signal effect_removed(effect: Resource)

class ActiveStatus:
	extends RefCounted
	var effect: Resource
	var remaining := 0.0
	var tick_elapsed := 0.0
	var stacks := 1

	func _init(p_effect: Resource) -> void:
		effect = p_effect
		remaining = maxf(0.0, float(effect.duration))

var target: Node
var _active: Dictionary = {}

func _ready() -> void:
	if target == null:
		target = get_parent()

func configure(p_target: Node) -> void:
	target = p_target

func apply(effect_value) -> bool:
	var effect = STATUS_EFFECT_CATALOG_SCRIPT.resolve(effect_value)
	if effect == null or not effect.is_valid():
		return false
	var status_id: StringName = effect.id
	if _active.has(status_id):
		var active: ActiveStatus = _active[status_id]
		match int(effect.stack_policy):
			STATUS_EFFECT_SCRIPT.StackPolicy.REFRESH:
				active.effect = effect
				active.remaining = effect.duration
			STATUS_EFFECT_SCRIPT.StackPolicy.EXTEND:
				active.effect = effect
				active.remaining += effect.duration
			STATUS_EFFECT_SCRIPT.StackPolicy.STACK:
				active.effect = effect
				active.stacks = mini(effect.max_stacks, active.stacks + 1)
				active.remaining = effect.duration
			STATUS_EFFECT_SCRIPT.StackPolicy.IGNORE:
				return false
		effect.on_apply(target, active.stacks)
		effect_refreshed.emit(effect, active.stacks)
		return true

	var new_active := ActiveStatus.new(effect)
	_active[status_id] = new_active
	effect.on_apply(target, new_active.stacks)
	effect_applied.emit(effect, new_active.stacks)
	return true

func tick(delta: float) -> void:
	if delta <= 0.0 or _active.is_empty():
		return
	for status_id in _active.keys():
		if not _active.has(status_id):
			continue
		var active: ActiveStatus = _active[status_id]
		var effect = active.effect
		var active_delta := minf(delta, active.remaining)
		active.remaining = maxf(0.0, active.remaining - delta)
		if effect.tick_interval > 0.0 and active_delta > 0.0:
			active.tick_elapsed += active_delta
			while active.tick_elapsed + 0.000001 >= effect.tick_interval:
				active.tick_elapsed -= effect.tick_interval
				effect.on_tick(target, active.stacks)
				effect_ticked.emit(effect, active.stacks)
				if target == null or not is_instance_valid(target):
					break
		if active.remaining <= 0.0 and _active.has(status_id):
			_remove(status_id)

func clear_all() -> void:
	for status_id in _active.keys():
		_remove(status_id)

func remove(status_id: StringName) -> bool:
	if not _active.has(status_id):
		return false
	_remove(status_id)
	return true

func has_effect(status_id: StringName) -> bool:
	return _active.has(status_id)

func remaining(status_id: StringName) -> float:
	if not _active.has(status_id):
		return 0.0
	return float((_active[status_id] as ActiveStatus).remaining)

func stacks(status_id: StringName) -> int:
	if not _active.has(status_id):
		return 0
	return int((_active[status_id] as ActiveStatus).stacks)

func is_empty() -> bool:
	return _active.is_empty()

func remaining_snapshot() -> Dictionary:
	var result := {}
	for status_id in _active.keys():
		result[status_id] = remaining(status_id)
	return result

func movement_speed_multiplier() -> float:
	var multiplier := 1.0
	for active_value in _active.values():
		var active := active_value as ActiveStatus
		multiplier *= pow(float(active.effect.movement_speed_multiplier), active.stacks)
	return maxf(GameConfig.STATUS_MIN_MOVEMENT_MULTIPLIER, multiplier)

func damage_taken_multiplier() -> float:
	var multiplier := 1.0
	for active_value in _active.values():
		var active := active_value as ActiveStatus
		multiplier *= pow(float(active.effect.damage_taken_multiplier), active.stacks)
	return maxf(0.05, multiplier)

func visual_tint() -> Color:
	var chosen := Color.WHITE
	var priority := -1000000
	for active_value in _active.values():
		var active := active_value as ActiveStatus
		if int(active.effect.visual_priority) >= priority and active.effect.tint != Color.WHITE:
			priority = int(active.effect.visual_priority)
			chosen = active.effect.tint
	return chosen

func emits_flames() -> bool:
	for active_value in _active.values():
		var active := active_value as ActiveStatus
		if bool(active.effect.emits_flames):
			return true
	return false

func _remove(status_id: StringName) -> void:
	if not _active.has(status_id):
		return
	var active := _active[status_id] as ActiveStatus
	_active.erase(status_id)
	active.effect.on_remove(target)
	effect_removed.emit(active.effect)
