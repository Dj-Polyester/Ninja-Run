class_name EnemyAnimationLoader
extends RefCounted
## Lazily realizes one explicit animation sequence at a time.  Catalog data
## owns the exact ordered frame paths; this class deliberately never scans an
## asset directory or preloads an identity's other animations.
##
## A cache key must uniquely identify the identity, costume variant, and
## animation (for example `skeleton_warrior:variant_1:walk`).  Acquiring the
## same key with a different ordered path list is rejected rather than quietly
## displaying the wrong costume.  Every successful frames_for/
## sprite_frames_for call acquires one reference; owners must call release
## when their enemy retires.

const MAX_CACHE_ENTRIES: int = GameConfig.MAX_ACTIVE_ENEMIES
const MAX_CACHED_FRAMES: int = 256
const MAX_FRAMES_PER_SEQUENCE: int = 48

class CacheEntry extends RefCounted:
	var paths: PackedStringArray
	var textures: Array[Texture2D] = []
	var sprite_frames: SpriteFrames
	var references: int = 0
	var last_used: int = 0

	func _init(new_paths: PackedStringArray, new_textures: Array[Texture2D], new_sprite_frames: SpriteFrames, use_serial: int) -> void:
		paths = new_paths.duplicate()
		textures = new_textures
		sprite_frames = new_sprite_frames
		last_used = use_serial


var _entries: Dictionary = {}
var _cached_frame_count: int = 0
var _use_serial: int = 0


func frames_for(frame_paths: PackedStringArray, cache_key: StringName) -> Array[Texture2D]:
	var entry := _acquire(frame_paths, cache_key)
	if entry == null:
		return []
	return entry.textures.duplicate()


func sprite_frames_for(frame_paths: PackedStringArray, cache_key: StringName, animation_name: StringName = &"Idle", frames_per_second: float = 8.0, loop: bool = true) -> SpriteFrames:
	if animation_name.is_empty() or not is_finite(frames_per_second) or frames_per_second <= 0.0:
		push_error("Enemy animation requires a non-empty name and positive FPS.")
		return null
	var entry := _acquire(frame_paths, cache_key)
	if entry == null:
		return null
	# The cache key includes the animation identity, so this resource is never
	# repurposed with a different animation name or cadence.
	if entry.sprite_frames == null:
		entry.sprite_frames = _make_sprite_frames(entry.textures, animation_name, frames_per_second, loop)
	return entry.sprite_frames


func create_animated_sprite(frame_paths: PackedStringArray, cache_key: StringName, animation_name: StringName = &"Idle", frames_per_second: float = 8.0, loop: bool = true) -> AnimatedSprite2D:
	var sprite_frames := sprite_frames_for(frame_paths, cache_key, animation_name, frames_per_second, loop)
	if sprite_frames == null:
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = sprite_frames
	sprite.animation = animation_name
	return sprite


func release(cache_key: StringName) -> bool:
	var entry := _entry_for(cache_key)
	if entry == null or entry.references <= 0:
		return false
	entry.references -= 1
	entry.last_used = _next_use_serial()
	# Retired identities are released eagerly when no instance still owns their
	# texture sequence. This preserves sharing while bounding peak texture use.
	if entry.references == 0:
		_remove_entry(cache_key, entry)
	return true


func clear() -> int:
	var removed := 0
	for key_variant in _entries.keys():
		var key := key_variant as StringName
		var entry := _entry_for(key)
		if entry != null and entry.references == 0:
			_remove_entry(key, entry)
			removed += 1
	return removed


func cache_stats() -> Dictionary:
	var references := 0
	for entry_variant in _entries.values():
		var entry := entry_variant as CacheEntry
		if entry != null:
			references += entry.references
	return {
		&"entries": _entries.size(),
		&"frames": _cached_frame_count,
		&"references": references,
		&"max_entries": MAX_CACHE_ENTRIES,
		&"max_frames": MAX_CACHED_FRAMES,
	}


func _acquire(frame_paths: PackedStringArray, cache_key: StringName) -> CacheEntry:
	if cache_key.is_empty() or frame_paths.is_empty() or frame_paths.size() > MAX_FRAMES_PER_SEQUENCE:
		push_error("Enemy animation cache key and 1-%d explicit frame paths are required." % MAX_FRAMES_PER_SEQUENCE)
		return null
	var existing := _entry_for(cache_key)
	if existing != null:
		if existing.paths != frame_paths:
			push_error("Enemy animation cache key '%s' was reused with different frames." % cache_key)
			return null
		existing.references += 1
		existing.last_used = _next_use_serial()
		return existing
	if not _make_room(frame_paths.size()):
		push_error("Enemy animation cache is full; release retired enemy identities before acquiring another sequence.")
		return null
	var textures := _load_explicit_textures(frame_paths)
	if textures.size() != frame_paths.size():
		return null
	var entry := CacheEntry.new(frame_paths, textures, null, _next_use_serial())
	entry.references = 1
	_entries[cache_key] = entry
	_cached_frame_count += textures.size()
	return entry


func _load_explicit_textures(frame_paths: PackedStringArray) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in frame_paths:
		# `exists` prevents a failed individual load from becoming a noisy engine
		# error during an optional/retired catalog asset lookup.
		if not path.begins_with("res://") or not ResourceLoader.exists(path, "Texture2D"):
			push_error("Enemy animation frame is not a Texture2D resource: %s" % path)
			return []
		var texture := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
		if texture == null:
			push_error("Enemy animation frame could not be loaded: %s" % path)
			return []
		textures.append(texture)
	return textures


func _make_sprite_frames(textures: Array[Texture2D], animation_name: StringName, frames_per_second: float, loop: bool) -> SpriteFrames:
	var result := SpriteFrames.new()
	result.add_animation(animation_name)
	result.set_animation_speed(animation_name, frames_per_second)
	result.set_animation_loop(animation_name, loop)
	for texture in textures:
		result.add_frame(animation_name, texture)
	return result


func _make_room(required_frames: int) -> bool:
	while _entries.size() >= MAX_CACHE_ENTRIES or _cached_frame_count + required_frames > MAX_CACHED_FRAMES:
		var eviction_key := _least_recent_unused_key()
		if eviction_key.is_empty():
			return false
		var entry := _entry_for(eviction_key)
		if entry == null:
			return false
		_remove_entry(eviction_key, entry)
	return true


func _least_recent_unused_key() -> StringName:
	var selected := &""
	var oldest := INF
	for key_variant in _entries.keys():
		var key := key_variant as StringName
		var entry := _entry_for(key)
		if entry != null and entry.references == 0 and entry.last_used < oldest:
			selected = key
			oldest = entry.last_used
	return selected


func _entry_for(cache_key: StringName) -> CacheEntry:
	return _entries.get(cache_key, null) as CacheEntry


func _remove_entry(cache_key: StringName, entry: CacheEntry) -> void:
	_entries.erase(cache_key)
	_cached_frame_count = maxi(0, _cached_frame_count - entry.textures.size())


func _next_use_serial() -> int:
	_use_serial += 1
	return _use_serial
