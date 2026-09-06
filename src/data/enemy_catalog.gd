class_name EnemyCatalog
extends RefCounted

const ENEMY_DATA_SCRIPT := preload("res://src/data/enemy_data.gd")

const RESOURCE_PATHS := {
	&"archer_guy": "res://data/enemies/archer_guy.tres",
	&"barbarian_warrior": "res://data/enemies/barbarian_warrior.tres",
	&"monk_guy": "res://data/enemies/monk_guy.tres",
	&"old_guy": "res://data/enemies/old_guy.tres",
	&"goblin": "res://data/enemies/goblin.tres",
	&"ogre": "res://data/enemies/ogre.tres",
	&"skeleton": "res://data/enemies/skeleton.tres",
	&"zombie": "res://data/enemies/zombie.tres",
	&"ghoul_hunter_1": "res://data/enemies/ghoul_hunter_1.tres",
	&"ghoul_hunter_2": "res://data/enemies/ghoul_hunter_2.tres",
	&"ghoul_hunter_3": "res://data/enemies/ghoul_hunter_3.tres",
	&"golem_1": "res://data/enemies/golem_1.tres",
	&"frost_knight_1": "res://data/enemies/frost_knight_1.tres",
	&"frost_knight_2": "res://data/enemies/frost_knight_2.tres",
	&"frost_knight_3": "res://data/enemies/frost_knight_3.tres",
	&"golem_2": "res://data/enemies/golem_2.tres",
	&"skull_knight": "res://data/enemies/skull_knight.tres",
	&"desert_nomad_1": "res://data/enemies/desert_nomad_1.tres",
	&"desert_nomad_2": "res://data/enemies/desert_nomad_2.tres",
	&"desert_nomad_3": "res://data/enemies/desert_nomad_3.tres",
	&"minotaur_1": "res://data/enemies/minotaur_1.tres",
	&"minotaur_2": "res://data/enemies/minotaur_2.tres",
	&"minotaur_3": "res://data/enemies/minotaur_3.tres",
	&"medieval_mage": "res://data/enemies/medieval_mage.tres",
	&"human_magician_1": "res://data/enemies/human_magician_1.tres",
	&"human_magician_2": "res://data/enemies/human_magician_2.tres",
	&"human_magician_3": "res://data/enemies/human_magician_3.tres",
	&"reaper_man_1": "res://data/enemies/reaper_man_1.tres",
	&"reaper_man_2": "res://data/enemies/reaper_man_2.tres",
	&"reaper_man_3": "res://data/enemies/reaper_man_3.tres",
	&"golem_3": "res://data/enemies/golem_3.tres",
	&"death_knight": "res://data/enemies/death_knight.tres",
	&"skeleton_warrior_1": "res://data/enemies/skeleton_warrior_1.tres",
	&"skeleton_warrior_2": "res://data/enemies/skeleton_warrior_2.tres",
	&"skeleton_warrior_3": "res://data/enemies/skeleton_warrior_3.tres",
	&"evil_bald_guy": "res://data/enemies/evil_bald_guy.tres",
	&"orc": "res://data/enemies/orc.tres",
	&"pumpkin_head_guy": "res://data/enemies/pumpkin_head_guy.tres",
	&"vampire": "res://data/enemies/vampire.tres",
}

static var _cache: Dictionary = {}

static func get_by_id(enemy_id: StringName):
	if _cache.has(enemy_id):
		return _cache[enemy_id]
	var path := String(RESOURCE_PATHS.get(enemy_id, ""))
	if path.is_empty():
		return null
	var resource = load(path)
	if resource != null:
		_cache[enemy_id] = resource
	return resource

static func all() -> Array:
	var result: Array = []
	for enemy_id in RESOURCE_PATHS.keys():
		var enemy = get_by_id(enemy_id)
		if enemy != null:
			result.append(enemy)
	result.sort_custom(func(a, b) -> bool: return String(a.id) < String(b.id))
	return result
static func available_for_biome(biome: BiomeData, encounter_number: int) -> Array:
	var result: Array = []
	if biome == null:
		return result
	for enemy_id in biome.enemy_pool:
		var enemy = get_by_id(enemy_id)
		if enemy == null or enemy.biome_id != biome.id:
			continue
		if enemy.appears_in_encounter(encounter_number):
			result.append(enemy)
	return result
