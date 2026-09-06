extends Node

const SAVE_PATH := "user://save.json"
const PLAYER_PROFILE_SCRIPT := preload("res://src/core/player_profile.gd")

func _ready() -> void:
	load_profile()

func save_profile(path: String = SAVE_PATH) -> bool:
	var sanitized: Dictionary = PLAYER_PROFILE_SCRIPT.sanitize(GameState.profile_snapshot())
	if sanitized.is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(sanitized, "  "))
	file.close()
	return true

func load_profile(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		GameState.reset_profile()
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		GameState.reset_profile()
		return false
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		GameState.reset_profile()
		return false
	var parsed = json.data
	if not parsed is Dictionary:
		GameState.reset_profile()
		return false
	var sanitized: Dictionary = PLAYER_PROFILE_SCRIPT.sanitize(parsed)
	if sanitized.is_empty():
		GameState.reset_profile()
		return false
	GameState.set_profile(sanitized)
	return true
