class_name AbilityCooldownState
extends RefCounted

const Catalog = preload("res://scripts/abilities/ability_catalog.gd")

var last_activation_at: Dictionary = {}

func can_activate(ability_id: StringName, now_seconds: float, profile: ProfileState) -> bool:
	if profile == null or not is_finite(now_seconds):
		return false
	var definition := Catalog.by_id(ability_id)
	if definition == null or not profile.abilities.unlocked.get(ability_id, false) or not ability_id in profile.abilities.equipped:
		return false
	if definition.cooldown_exempt:
		return true
	var cooldown := profile.ability_cooldown(ability_id)
	var last_at: float = float(last_activation_at.get(ability_id, -INF))
	return now_seconds >= last_at + cooldown

func commit_activation(ability_id: StringName, now_seconds: float, profile: ProfileState) -> bool:
	if not can_activate(ability_id, now_seconds, profile):
		return false
	var definition := Catalog.by_id(ability_id)
	if definition != null and not definition.cooldown_exempt:
		last_activation_at[ability_id] = now_seconds
	return true

func remaining(ability_id: StringName, now_seconds: float, profile: ProfileState) -> float:
	var definition := Catalog.by_id(ability_id)
	if definition == null or definition.cooldown_exempt or profile == null:
		return 0.0
	var last_at: float = float(last_activation_at.get(ability_id, -INF))
	if not is_finite(last_at):
		return 0.0
	return maxf(0.0, last_at + profile.ability_cooldown(ability_id) - now_seconds)

func reset() -> void:
	last_activation_at.clear()
