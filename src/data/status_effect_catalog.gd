class_name StatusEffectCatalog
extends RefCounted

const STATUS_EFFECT_SCRIPT := preload("res://src/data/status_effect.gd")

const RESOURCE_PATHS := {
	&"arcane_burn": "res://data/status_effects/arcane_burn.tres",
	&"arcane_slow": "res://data/status_effects/arcane_slow.tres",
	&"armor_break": "res://data/status_effects/armor_break.tres",
	&"astral_lock": "res://data/status_effects/astral_lock.tres",
	&"bleed": "res://data/status_effects/bleed.tres",
	&"blood_loss": "res://data/status_effects/blood_loss.tres",
	&"brittle": "res://data/status_effects/brittle.tres",
	&"burn": "res://data/status_effects/burn.tres",
	&"chill": "res://data/status_effects/chill.tres",
	&"cold_wound": "res://data/status_effects/cold_wound.tres",
	&"curse": "res://data/status_effects/curse.tres",
	&"deep_freeze": "res://data/status_effects/deep_freeze.tres",
	&"fatigue": "res://data/status_effects/fatigue.tres",
	&"freeze": "res://data/status_effects/freeze.tres",
	&"frost_slow": "res://data/status_effects/frost_slow.tres",
	&"frozen_bleed": "res://data/status_effects/frozen_bleed.tres",
	&"gravity_drag": "res://data/status_effects/gravity_drag.tres",
	&"heat_exhaustion": "res://data/status_effects/heat_exhaustion.tres",
	&"ice_lock": "res://data/status_effects/ice_lock.tres",
	&"ignite": "res://data/status_effects/ignite.tres",
	&"mana_burn": "res://data/status_effects/mana_burn.tres",
	&"numb": "res://data/status_effects/numb.tres",
	&"poison": "res://data/status_effects/poison.tres",
	&"puncture": "res://data/status_effects/puncture.tres",
	&"sand_slow": "res://data/status_effects/sand_slow.tres",
	&"scorch": "res://data/status_effects/scorch.tres",
	&"sear": "res://data/status_effects/sear.tres",
	&"shock": "res://data/status_effects/shock.tres",
	&"slow": "res://data/status_effects/slow.tres",
	&"stagger": "res://data/status_effects/stagger.tres",
	&"starburn": "res://data/status_effects/starburn.tres",
	&"stone_chill": "res://data/status_effects/stone_chill.tres",
	&"terror": "res://data/status_effects/terror.tres",
	&"void_mark": "res://data/status_effects/void_mark.tres",
	&"wound": "res://data/status_effects/wound.tres",
}

static var _cache: Dictionary = {}

static func get_by_id(status_id: StringName):
	if _cache.has(status_id):
		return _cache[status_id]
	var path := String(RESOURCE_PATHS.get(status_id, ""))
	if path.is_empty():
		return null
	var effect = load(path)
	if effect != null:
		_cache[status_id] = effect
	return effect

static func all() -> Array:
	var result: Array = []
	for status_id in RESOURCE_PATHS.keys():
		var effect = get_by_id(status_id)
		if effect != null:
			result.append(effect)
	result.sort_custom(func(a, b) -> bool: return String(a.id) < String(b.id))
	return result

static func resolve(value):
	if value == null:
		return null
	if value is Resource and value.has_method(&"on_apply") and value.has_method(&"on_tick") and value.has_method(&"on_remove"):
		return value
	if value is String or value is StringName:
		return get_by_id(StringName(value))
	if value is Dictionary:
		var status_id := StringName(value.get("id", &""))
		if status_id == &"":
			return null
		var base = get_by_id(status_id)
		if base == null:
			base = STATUS_EFFECT_SCRIPT.new()
			base.id = status_id
			base.display_name = String(status_id).replace("_", " ").capitalize()
		else:
			base = base.duplicate(true)
		if value.has("duration"):
			base.duration = maxf(0.01, float(value.get("duration", base.duration)))
		if value.has("tick_interval"):
			base.tick_interval = maxf(0.0, float(value.get("tick_interval", base.tick_interval)))
		if value.has("tick_damage"):
			base.tick_damage = maxf(0.0, float(value.get("tick_damage", base.tick_damage)))
		return base
	return null
