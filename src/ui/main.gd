extends Control

func _ready() -> void:
	$CenterContainer/VBoxContainer/StartButton.grab_focus()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level/level.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
