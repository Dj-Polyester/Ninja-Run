class_name TerrainTileSetFactory
extends RefCounted

const SOURCE_ID := 0
const SOURCE_TILE_SIZE := Vector2i(GameConfig.TERRAIN_SOURCE_TILE_SIZE, GameConfig.TERRAIN_SOURCE_TILE_SIZE)
const TERRAIN_TEXTURE_PATH := "res://assets/Spritesheets/spritesheet-tiles-double.png"

static func build() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = SOURCE_TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 2)
	tile_set.set_physics_layer_collision_mask(0, 0)
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)

	var source := TileSetAtlasSource.new()
	source.texture = _load_terrain_texture()
	if source.texture == null:
		push_error("Unable to load required terrain texture: %s" % TERRAIN_TEXTURE_PATH)
		return tile_set
	source.texture_region_size = SOURCE_TILE_SIZE
	source.separation = Vector2i.ONE * GameConfig.TERRAIN_ATLAS_SEPARATION
	tile_set.add_source(source, SOURCE_ID)

	for biome in BiomeCatalog.ORDERED:
		tile_set.add_terrain(0)
		tile_set.set_terrain_name(0, biome.id, biome.display_name)
		for coords in _coords_for_biome(biome):
			if not source.has_tile(coords):
				source.create_tile(coords)
			_configure_tile(source.get_tile_data(coords, 0), biome.id)
		_create_visual_alternative(source, biome.terrain_middle_atlas, biome.id)
	return tile_set

static func _load_terrain_texture() -> Texture2D:
	# Normal editor/export builds use Godot's imported texture. Headless CI may
	# intentionally skip importing the very large bundled asset pack, so keep a
	# raw-PNG fallback for tests and tooling.
	if DisplayServer.get_name() != "headless" and ResourceLoader.exists(TERRAIN_TEXTURE_PATH):
		var imported := load(TERRAIN_TEXTURE_PATH) as Texture2D
		if imported != null:
			return imported
	var image := Image.new()
	var absolute_path := ProjectSettings.globalize_path(TERRAIN_TEXTURE_PATH)
	if image.load(absolute_path) != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

static func _coords_for_biome(biome: BiomeData) -> Array[Vector2i]:
	return [
		biome.terrain_top_atlas,
		biome.terrain_center_atlas,
		biome.terrain_left_atlas,
		biome.terrain_middle_atlas,
		biome.terrain_right_atlas,
	]

static func _configure_tile(tile_data: TileData, terrain_id: int) -> void:
	if tile_data == null:
		return
	tile_data.terrain_set = 0
	tile_data.terrain = terrain_id
	if tile_data.get_collision_polygons_count(0) == 0:
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(
			0,
			0,
			PackedVector2Array([
				Vector2(-64.0, -64.0),
				Vector2(64.0, -64.0),
				Vector2(64.0, 64.0),
				Vector2(-64.0, 64.0),
			])
		)

static func _create_visual_alternative(source: TileSetAtlasSource, coords: Vector2i, terrain_id: int) -> void:
	if not source.has_tile(coords) or source.get_alternative_tiles_count(coords) > 1:
		return
	var alternative_id := source.create_alternative_tile(coords)
	if alternative_id < 0:
		return
	var tile_data := source.get_tile_data(coords, alternative_id)
	_configure_tile(tile_data, terrain_id)
	# A mirrored alternative gives the generator a deterministic visual variant
	# while keeping all static gameplay geometry on the same atlas/collision grid.
	tile_data.flip_h = true
