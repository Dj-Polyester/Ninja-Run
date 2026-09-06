extends Node

signal profile_changed
signal run_changed

const DEFAULT_PROFILE := {
	"save_version": 1,
	"selected_character": 1,
	"maximum_health": 100.0,
	"defense_multiplier": 1.0,
}

var profile: Dictionary = DEFAULT_PROFILE.duplicate(true)
var run: Dictionary = {}

func _ready() -> void:
	reset_run()

func reset_profile() -> void:
	profile = DEFAULT_PROFILE.duplicate(true)
	profile_changed.emit()

func set_profile(loaded_profile: Dictionary) -> void:
	var merged := DEFAULT_PROFILE.duplicate(true)
	for key in loaded_profile:
		if merged.has(key):
			merged[key] = loaded_profile[key]
	profile = merged
	profile_changed.emit()

func reset_run(seed_value: int = -1) -> void:
	if seed_value < 0:
		seed_value = int(Time.get_unix_time_from_system())
	run = {
		"seed": seed_value,
		"health": float(profile.get("maximum_health", 100.0)),
		"distance_tiles": 0,
		"game_over": false,
	}
	run_changed.emit()

func set_run_health(value: float) -> void:
	run["health"] = value
	run_changed.emit()

func set_distance_tiles(value: int) -> void:
	if value == int(run.get("distance_tiles", 0)):
		return
	run["distance_tiles"] = value
	run_changed.emit()

func end_run() -> void:
	run["game_over"] = true
	run_changed.emit()
