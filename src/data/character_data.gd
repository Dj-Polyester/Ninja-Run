class_name CharacterData
extends Resource

const REQUIRED_ANIMATIONS := {
	&"run": {"folder": "Fast Run", "fps": 12.0, "loop": true},
	&"jump": {"folder": "Jump Before", "fps": 16.0, "loop": false},
	&"fall": {"folder": "Fall", "fps": 12.0, "loop": true},
	&"roll": {"folder": "Roll", "fps": 14.0, "loop": true},
	&"dead": {"folder": "Dead", "fps": 12.0, "loop": false},
	&"melee": {"folder": "Shoot", "fps": 16.0, "loop": false},
}

@export_range(1, 1000, 1) var id := 1
@export var display_name := ""
@export_dir var animation_root := ""
@export_range(0, 1000000, 1) var unlock_cost := 0

var _sprite_frames_cache: SpriteFrames

var sprite_frames: SpriteFrames:
	get:
		return get_sprite_frames()

func is_valid() -> bool:
	if id <= 0 or display_name.strip_edges().is_empty() or unlock_cost < 0:
		return false
	if animation_root.is_empty() or not animation_root.begins_with("res://"):
		return false
	for definition in REQUIRED_ANIMATIONS.values():
		var folder := animation_root.path_join(String(definition.folder))
		var files := list_animation_files(folder)
		var has_png := false
		for file_name in files:
			if file_name.to_lower().ends_with(".png"):
				has_png = true
				break
		if not has_png:
			return false
	return true

func get_sprite_frames() -> SpriteFrames:
	if _sprite_frames_cache == null:
		_sprite_frames_cache = build_sprite_frames(DisplayServer.get_name() == "headless")
	return _sprite_frames_cache

func build_sprite_frames(headless := false) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation_name in REQUIRED_ANIMATIONS:
		var definition: Dictionary = REQUIRED_ANIMATIONS[animation_name]
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, float(definition.fps))
		frames.set_animation_loop(animation_name, bool(definition.loop))
		if headless:
			continue
		var folder := animation_root.path_join(String(definition.folder))
		for file_name in list_animation_files(folder):
			if not file_name.to_lower().ends_with(".png"):
				continue
			var texture := load_texture(folder.path_join(file_name))
			if texture != null:
				frames.add_frame(animation_name, texture)
		if frames.get_frame_count(animation_name) == 0:
			push_error("Character %d animation '%s' has no loadable frames in %s" % [id, animation_name, folder])
	return frames

static func list_animation_files(folder: String) -> PackedStringArray:
	var files := ResourceLoader.list_directory(folder)
	if files.is_empty():
		files = DirAccess.get_files_at(folder)
	files.sort()
	return files

static func load_texture(path: String) -> Texture2D:
	var image := Image.new()
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute_path):
		if image.load(absolute_path) == OK and not image.is_empty():
			return ImageTexture.create_from_image(image)
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return null
