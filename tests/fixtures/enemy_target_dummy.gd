extends CharacterBody2D

var maximum_health := 500.0
var current_health := 500.0
var detectable := true
var last_damage := 0.0
var last_damage_info
var status_effects: Array[Resource] = []
var damage_events := 0

func take_damage(amount: float, damage_info = null) -> void:
	last_damage = maxf(0.0, amount)
	last_damage_info = damage_info
	current_health = maxf(0.0, current_health - last_damage)
	damage_events += 1
	if damage_info != null and damage_info.status_effect != null:
		apply_status(damage_info.status_effect)

func heal(amount: float) -> void:
	current_health = minf(maximum_health, current_health + maxf(0.0, amount))

func apply_status(effect) -> void:
	if effect is Resource:
		status_effects.append(effect)

func die() -> void:
	current_health = 0.0

func is_detectable() -> bool:
	return detectable

func set_detectable(value: bool) -> void:
	detectable = value
