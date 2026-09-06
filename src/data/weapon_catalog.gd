class_name WeaponCatalog
extends RefCounted

const SHURIKEN = preload("res://data/weapons/shuriken.tres")
const SHURIKEN_FAN = preload("res://data/weapons/shuriken_fan.tres")
const ARROW = preload("res://data/weapons/arrow.tres")
const MAGIC_ORB = preload("res://data/weapons/magic_orb.tres")
const THROWING_BLADE = preload("res://data/weapons/throwing_blade.tres")

const ORDERED = [
	SHURIKEN,
	SHURIKEN_FAN,
	ARROW,
	MAGIC_ORB,
	THROWING_BLADE,
]

static func all() -> Array:
	return ORDERED.duplicate()

static func get_by_id(weapon_id: StringName):
	for weapon in ORDERED:
		if weapon.id == weapon_id:
			return weapon
	return null

static func contains(weapon_id: StringName) -> bool:
	return get_by_id(weapon_id) != null
