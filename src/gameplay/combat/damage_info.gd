class_name DamageInfo
extends RefCounted

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
var status_effect: Dictionary = {}
var knockback := Vector2.ZERO

func _init(
	p_source: Node = null,
	p_damage_type: int = DamageType.GENERIC,
	p_status_effect: Dictionary = {},
	p_knockback: Vector2 = Vector2.ZERO
) -> void:
	source = p_source
	damage_type = p_damage_type
	status_effect = p_status_effect.duplicate(true)
	knockback = p_knockback

