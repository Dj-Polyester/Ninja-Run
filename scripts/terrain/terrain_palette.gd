class_name TerrainPalette
extends RefCounted
## Atlas-only terrain mapping for the supplied 2321x2321 double-resolution sheet.
## The sheet is an 18x18 grid of 128x128 frames separated by one-pixel gutters.
## Runtime terrain never loads assets/Tiles/terrain_*.png.

const ATLAS_PATH := "res://assets/Spritesheets/spritesheet-tiles-double.png"
const FRAME_SIZE := Vector2i(128, 128)
const GRID_STRIDE := 129
const GRID_COLUMNS := 18
const GRID_ROWS := 18

# Each terrain family occupies 28 consecutive row-major frames in the atlas.
# Starts were verified against the spritesheet itself; the standalone tile PNGs
# were used only as a labeling cross-check, never as runtime sources.
const FAMILY_START_INDEX := {
	&"tundra": 138, # terrain_dirt: orange grass / gray dirt
	&"grass": 166,
	&"astro": 194,  # terrain_purple
	&"desert": 222, # terrain_sand
	&"snow": 250,
	&"fort": 278,   # terrain_stone: black brick / gray-white block
}

# Within every 28-frame family the atlas uses this shared variant order.
const VARIANT_OFFSETS := {
	&"block": 0,
	&"block_bottom": 1,
	&"block_bottom_left": 2,
	&"block_bottom_right": 3,
	&"block_center": 4,
	&"block_left": 5,
	&"block_right": 6,
	&"block_top": 7,
	&"block_top_left": 8,
	&"block_top_right": 9,
	&"cloud": 10,
	&"cloud_background": 11,
	&"cloud_left": 12,
	&"cloud_middle": 13,
	&"cloud_right": 14,
	&"horizontal_left": 15,
	&"horizontal_middle": 16,
	&"horizontal_overhang_left": 17,
	&"horizontal_overhang_right": 18,
	&"horizontal_right": 19,
	&"ramp_long_a": 20,
	&"ramp_long_b": 21,
	&"ramp_long_c": 22,
	&"ramp_short_a": 23,
	&"ramp_short_b": 24,
	&"vertical_bottom": 25,
	&"vertical_middle": 26,
	&"vertical_top": 27,
}

static func has_material(material: StringName) -> bool:
	return FAMILY_START_INDEX.has(material)

static func has_variant(variant: StringName) -> bool:
	return VARIANT_OFFSETS.has(variant)

static func frame_index(material: StringName, variant: StringName = &"block") -> int:
	var safe_material := material if has_material(material) else &"grass"
	var safe_variant := variant if has_variant(variant) else &"block"
	return int(FAMILY_START_INDEX[safe_material]) + int(VARIANT_OFFSETS[safe_variant])

static func frame_coordinates(material: StringName, variant: StringName = &"block") -> Vector2i:
	var index := frame_index(material, variant)
	return Vector2i(index % GRID_COLUMNS, index / GRID_COLUMNS)

static func source_rect(material: StringName, variant: StringName = &"block") -> Rect2:
	var frame := frame_coordinates(material, variant)
	return Rect2(frame.x * GRID_STRIDE, frame.y * GRID_STRIDE, FRAME_SIZE.x, FRAME_SIZE.y)

static func all_rects_are_valid(atlas: Texture2D) -> bool:
	if atlas == null or atlas.get_width() != 2321 or atlas.get_height() != 2321:
		return false
	var seen: Dictionary = {}
	for material: StringName in FAMILY_START_INDEX:
		for variant: StringName in VARIANT_OFFSETS:
			var rect := source_rect(material, variant)
			if rect.position.x < 0.0 or rect.position.y < 0.0 or rect.size != Vector2(FRAME_SIZE) or rect.end.x > atlas.get_width() or rect.end.y > atlas.get_height():
				return false
			seen[rect] = true
	return seen.size() == FAMILY_START_INDEX.size() * VARIANT_OFFSETS.size()

static func family_frame_range(material: StringName) -> Vector2i:
	if not has_material(material):
		return Vector2i(-1, -1)
	var start := int(FAMILY_START_INDEX[material])
	return Vector2i(start, start + VARIANT_OFFSETS.size() - 1)
