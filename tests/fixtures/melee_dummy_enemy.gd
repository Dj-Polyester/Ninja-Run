extends CharacterBody2D

var maximum_health := 200.0
var current_health := 200.0
var damage_events := 0
var last_damage_info
var active := true
var dead := false
var statuses: Array[Dictionary] = []

func can_receive_melee_attack() -> bool:
	return active and not dead and current_health > 0.0

func can_receive_projectile_attack() -> bool:
	return active and not dead and current_health > 0.0

func take_damage(amount: float, damage_info = null) -> void:
	if not can_receive_melee_attack() or amount <= 0.0:
		return
	damage_events += 1
	last_damage_info = damage_info
	current_health = maxf(0.0, current_health - amount)
	if current_health <= 0.0:
		die()

func heal(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	current_health = minf(maximum_health, current_health + amount)

func apply_status(effect: Dictionary) -> void:
	statuses.append(effect.duplicate(true))

func die(_reason: String = "damage") -> void:
	dead = true
	current_health = 0.0
