class_name EnemyHealthComponent
extends Node

signal health_changed(current: float, maximum: float)

var current_health := 1.0
var maximum_health := 1.0

func configure(maximum: float) -> void:
	maximum_health = maxf(1.0, maximum)
	current_health = maximum_health
	health_changed.emit(current_health, maximum_health)

func take_damage(amount: float) -> float:
	var requested := maxf(0.0, amount)
	if requested <= 0.0 or current_health <= 0.0:
		return 0.0
	var before := current_health
	current_health = maxf(0.0, current_health - requested)
	health_changed.emit(current_health, maximum_health)
	return before - current_health

func heal(amount: float) -> float:
	var requested := maxf(0.0, amount)
	if requested <= 0.0 or current_health <= 0.0:
		return 0.0
	var before := current_health
	current_health = minf(maximum_health, current_health + requested)
	health_changed.emit(current_health, maximum_health)
	return current_health - before

func kill() -> void:
	if current_health <= 0.0:
		return
	current_health = 0.0
	health_changed.emit(current_health, maximum_health)

func is_depleted() -> bool:
	return current_health <= 0.0
