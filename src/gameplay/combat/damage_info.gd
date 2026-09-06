class_name DamageInfo
extends RefCounted

const STATUS_EFFECT_CATALOG_SCRIPT := preload("res://src/data/status_effect_catalog.gd")

enum DamageType {
	GENERIC,
	FIRE,
	PIERCING,
	IMPACT,
	PROJECTILE,
	MELEE,
	EXPLOSION,
	FALL,
}

var source: Node
var damage_type: int = DamageType.GENERIC
var status_effect
var knockback := Vector2.ZERO

func _init(
	p_source: Node = null,
	p_damage_type: int = DamageType.GENERIC,
	p_status_effect = null,
	p_knockback: Vector2 = Vector2.ZERO
) -> void:
	source = p_source
	damage_type = p_damage_type
	status_effect = STATUS_EFFECT_CATALOG_SCRIPT.resolve(p_status_effect)
	knockback = p_knockback

