@tool
extends EditorScript

const ROOT := "res://assets/Characters"
const FIRST_CHARACTER := 1
const LAST_CHARACTER := 45
const ANIMATION_SPEED_FAST := 60.0
const ANIMATION_SPEED := 20.0

func _run():
	for character_id in range(FIRST_CHARACTER, LAST_CHARACTER + 1):
		var character_path := "%s/%d/Png/Character Sprite" % [ROOT, character_id]

		if not DirAccess.dir_exists_absolute(character_path):
			push_warning("Skipping missing folder: %s" % character_path)
			continue

		print("Generating SpriteFrames for character ", character_id)

		var frames := SpriteFrames.new()

		var anim_root := DirAccess.open(character_path)
		anim_root.list_dir_begin()

		while true:
			var anim_name := anim_root.get_next()
			var anim_name_lowered = anim_name.to_lower()

			if anim_name == "":
				break

			if anim_name.begins_with("."):
				continue

			if not anim_root.current_is_dir():
				continue

			frames.add_animation(anim_name_lowered)
			if anim_name_lowered in ["jump before", "jump after"]:
				frames.set_animation_speed(anim_name_lowered, ANIMATION_SPEED_FAST)
			else:
				frames.set_animation_speed(anim_name_lowered, ANIMATION_SPEED)


			# Make common animations loop
			if anim_name_lowered in ["fall", "walk", "run", "fast run", "idle"]:
				frames.set_animation_loop(anim_name_lowered, true)
			else:
				frames.set_animation_loop(anim_name_lowered, false)

			var anim_path := character_path + "/" + anim_name
			var anim_dir := DirAccess.open(anim_path)

			var png_files: Array[String] = []

			anim_dir.list_dir_begin()
			while true:
				var file := anim_dir.get_next()

				if file == "":
					break

				if file.ends_with(".png"):
					png_files.append(file)

			png_files.sort()

			for file in png_files:
				var tex := load(anim_path + "/" + file)
				if tex:
					frames.add_frame(anim_name_lowered, tex)

		var output := character_path + "/sprite_frames.tres"
		var err := ResourceSaver.save(frames, output)

		if err == OK:
			print("Saved ", output)
		else:
			push_error("Failed to save %s (error %d)" % [output, err])

	print("Finished!")