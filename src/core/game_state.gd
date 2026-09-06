extends Node

signal profile_changed
signal run_changed

const DEFAULT_PROFILE := {
	"save_version": 1,
	"selected_character": 1,
	"maximum_health": 100.0,
	"defense_multiplier": 1.0,
	"revival_potions": 1,
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
		"revival_active": false,
		"revival_countdown": 0.0,
		"death_reason": "",
		"safe_checkpoint": {},
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

func set_safe_checkpoint(checkpoint: Dictionary) -> void:
	run["safe_checkpoint"] = checkpoint.duplicate(true)
	run_changed.emit()

func begin_revival(reason: String, countdown: float) -> void:
	run["revival_active"] = true
	run["revival_countdown"] = maxf(0.0, countdown)
	run["death_reason"] = reason
	run["game_over"] = false
	run_changed.emit()

func set_revival_countdown(value: float) -> void:
	var clamped := maxf(0.0, value)
	if is_equal_approx(float(run.get("revival_countdown", 0.0)), clamped):
		return
	run["revival_countdown"] = clamped
	run_changed.emit()

func finish_revival(restored_health: float) -> void:
	run["revival_active"] = false
	run["revival_countdown"] = 0.0
	run["death_reason"] = ""
	run["game_over"] = false
	run["health"] = restored_health
	run_changed.emit()

func revival_potion_count() -> int:
	return maxi(0, int(profile.get("revival_potions", 0)))

func consume_revival_potion() -> bool:
	var count := revival_potion_count()
	if count <= 0:
		return false
	profile["revival_potions"] = count - 1
	profile_changed.emit()
	return true

func end_run() -> void:
	run["revival_active"] = false
	run["revival_countdown"] = 0.0
	run["game_over"] = true
	run_changed.emit()
