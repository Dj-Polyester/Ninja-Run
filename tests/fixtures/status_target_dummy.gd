extends Node

var maximum_health := 200.0
var current_health := 200.0
var applied_ids: Array[StringName] = []
var ticked_ids: Array[StringName] = []
var removed_ids: Array[StringName] = []
var tick_damage_events := 0
var total_tick_damage := 0.0

func apply_status_tick_damage(amount: float, _effect: Resource) -> void:
	var applied := maxf(0.0, amount)
	current_health = maxf(0.0, current_health - applied)
	tick_damage_events += 1
	total_tick_damage += applied

func status_effect_applied(effect: Resource, _stacks: int) -> void:
	applied_ids.append(effect.id)

func status_effect_ticked(effect: Resource, _stacks: int) -> void:
	ticked_ids.append(effect.id)

func status_effect_removed(effect: Resource) -> void:
	removed_ids.append(effect.id)
