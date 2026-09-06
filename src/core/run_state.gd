class_name RunState
extends RefCounted

const BIOME_DATA_SCRIPT := preload("res://src/data/biome_data.gd")

static func create(maximum_health: float, seed_value: int) -> Dictionary:
	return {
		"health": maximum_health,
		"distance_tiles": 0,
		"current_biome": BIOME_DATA_SCRIPT.Id.GRASS,
		"temporary_effects": {},
		"seed": seed_value,
		"checkpoint": {},
		# Phase 4 compatibility name. The checkpoint field above is the Phase 5
		# model name; both are synchronized by GameState.set_safe_checkpoint().
		"safe_checkpoint": {},
		"game_over": false,
		"revival_active": false,
		"revival_countdown": 0.0,
		"death_reason": "",
	}
