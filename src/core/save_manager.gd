extends Node

const SAVE_PATH := "user://save.json"

func _ready() -> void:
	load_profile()

func save_profile(path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(GameState.profile, "  "))
	return true

func load_profile(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		GameState.reset_profile()
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		GameState.reset_profile()
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("save_version", -1)) != 1:
		GameState.reset_profile()
		return false
	GameState.set_profile(parsed)
	return true
