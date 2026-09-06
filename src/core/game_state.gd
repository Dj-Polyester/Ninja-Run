extends Node

const PLAYER_PROFILE_SCRIPT := preload("res://src/core/player_profile.gd")
const RUN_STATE_SCRIPT := preload("res://src/core/run_state.gd")
const BIOME_DATA_SCRIPT := preload("res://src/data/biome_data.gd")

signal profile_changed
signal run_changed

var profile: Dictionary = PLAYER_PROFILE_SCRIPT.create_default()
var run: Dictionary = {}

func _ready() -> void:
	reset_run()

func reset_profile() -> void:
	profile = PLAYER_PROFILE_SCRIPT.create_default()
	profile_changed.emit()

func set_profile(loaded_profile: Dictionary) -> void:
	var sanitized: Dictionary = PLAYER_PROFILE_SCRIPT.sanitize(loaded_profile)
	profile = sanitized if not sanitized.is_empty() else PLAYER_PROFILE_SCRIPT.create_default()
	profile_changed.emit()

func profile_snapshot() -> Dictionary:
	_sync_legacy_profile_fields()
	return profile.duplicate(true)

func reset_run(seed_value: int = -1) -> void:
	if seed_value < 0:
		seed_value = int(Time.get_unix_time_from_system())
	run = RUN_STATE_SCRIPT.create(float(profile.get("maximum_health", 100.0)), seed_value)
	run_changed.emit()

func set_run_health(value: float) -> void:
	run["health"] = value
	run_changed.emit()

func set_distance_tiles(value: int) -> void:
	if value == int(run.get("distance_tiles", 0)):
		return
	run["distance_tiles"] = value
	run_changed.emit()

func set_current_biome(biome_id: int) -> void:
	if biome_id == int(run.get("current_biome", BIOME_DATA_SCRIPT.Id.GRASS)):
		return
	run["current_biome"] = biome_id
	run_changed.emit()

func set_temporary_effect(effect_id: StringName, payload) -> void:
	var effects: Dictionary = run.get("temporary_effects", {}).duplicate(true)
	if payload == null:
		effects.erase(String(effect_id))
	else:
		effects[String(effect_id)] = payload
	run["temporary_effects"] = effects
	run_changed.emit()

func set_safe_checkpoint(checkpoint: Dictionary) -> void:
	var snapshot := checkpoint.duplicate(true)
	run["checkpoint"] = snapshot
	run["safe_checkpoint"] = snapshot.duplicate(true)
	run_changed.emit()

func gold_count() -> int:
	return maxi(0, int(profile.get("gold", 0)))

func add_gold(amount: int) -> int:
	if amount <= 0:
		return gold_count()
	profile["gold"] = gold_count() + amount
	profile_changed.emit()
	return int(profile.gold)

func consumable_count(consumable_id: StringName) -> int:
	if String(consumable_id) == PLAYER_PROFILE_SCRIPT.REVIVAL_POTION_ID and profile.has("revival_potions"):
		return maxi(0, int(profile.revival_potions))
	var consumables = profile.get("consumables", {})
	if not consumables is Dictionary:
		return 0
	return maxi(0, int(consumables.get(String(consumable_id), 0)))

func set_consumable_count(consumable_id: StringName, count: int) -> void:
	var id := String(consumable_id)
	var consumables: Dictionary = profile.get("consumables", {}).duplicate(true)
	consumables[id] = maxi(0, count)
	profile["consumables"] = consumables
	if id == PLAYER_PROFILE_SCRIPT.REVIVAL_POTION_ID:
		profile["revival_potions"] = consumables[id]
	profile_changed.emit()

func consume_consumable(consumable_id: StringName) -> bool:
	var count := consumable_count(consumable_id)
	if count <= 0:
		return false
	set_consumable_count(consumable_id, count - 1)
	return true

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
	return consumable_count(PLAYER_PROFILE_SCRIPT.REVIVAL_POTION_ID)

func consume_revival_potion() -> bool:
	return consume_consumable(PLAYER_PROFILE_SCRIPT.REVIVAL_POTION_ID)

func end_run() -> void:
	run["revival_active"] = false
	run["revival_countdown"] = 0.0
	run["game_over"] = true
	run_changed.emit()

func _sync_legacy_profile_fields() -> void:
	var potion_count := revival_potion_count()
	var consumables: Dictionary = profile.get("consumables", {}).duplicate(true)
	consumables[PLAYER_PROFILE_SCRIPT.REVIVAL_POTION_ID] = potion_count
	profile["consumables"] = consumables
	profile["revival_potions"] = potion_count
