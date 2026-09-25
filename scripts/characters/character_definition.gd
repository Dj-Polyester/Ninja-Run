class_name CharacterDefinition
extends RefCounted

var id: StringName
var display_name: String
var sprite_frames_path: String
var unlock_cost: int

func _init(new_id: StringName = &"", new_display_name: String = "", new_sprite_frames_path: String = "", new_unlock_cost: int = 0) -> void:
	id = new_id
	display_name = new_display_name
	sprite_frames_path = new_sprite_frames_path
	unlock_cost = new_unlock_cost

func is_valid() -> bool:
	return not id.is_empty() and not display_name.is_empty() and sprite_frames_path.begins_with("res://assets/Characters/") and ResourceLoader.exists(sprite_frames_path, "SpriteFrames") and unlock_cost >= 0
