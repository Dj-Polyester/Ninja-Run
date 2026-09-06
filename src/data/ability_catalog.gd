class_name AbilityCatalog
extends RefCounted

const JUMP = preload("res://data/abilities/jump.tres")
const CLIMB = preload("res://data/abilities/climb.tres")
const GLIDE = preload("res://data/abilities/glide.tres")
const REVERSE_GRAVITY = preload("res://data/abilities/reverse_gravity.tres")
const FLY = preload("res://data/abilities/fly.tres")
const DASH = preload("res://data/abilities/dash.tres")
const SHOOTING = preload("res://data/abilities/shooting.tres")
const EXPLODE = preload("res://data/abilities/explode.tres")
const SLOW_DOWN_TIME = preload("res://data/abilities/slow_down_time.tres")
const INVISIBILITY = preload("res://data/abilities/invisibility.tres")

const ORDERED := [
	JUMP,
	CLIMB,
	GLIDE,
	REVERSE_GRAVITY,
	FLY,
	DASH,
	SHOOTING,
	EXPLODE,
	SLOW_DOWN_TIME,
	INVISIBILITY,
]

static func get_by_id(ability_id: StringName) -> AbilityData:
	for ability in ORDERED:
		if ability.id == ability_id:
			return ability
	return null

static func is_known(ability_id: StringName) -> bool:
	return get_by_id(ability_id) != null

static func are_compatible(first_id: StringName, second_id: StringName) -> bool:
	if first_id == second_id:
		return true
	return not (
		(first_id == &"jump" and second_id == &"reverse_gravity")
		or (first_id == &"reverse_gravity" and second_id == &"jump")
	)

static func sanitize_levels(raw, fallback: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	for ability in ORDERED:
		var id := String(ability.id)
		var default_level := clampi(int(fallback.get(id, 1)), 1, ability.max_level)
		var requested := default_level
		if raw is Dictionary and raw.has(id):
			var value = raw[id]
			if value is int or value is float:
				requested = int(value)
		result[id] = clampi(requested, 1, ability.max_level)
	return result
