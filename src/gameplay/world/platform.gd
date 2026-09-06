class_name RunnerPlatform
extends StaticBody2D

const TERRAIN_TEXTURE_PATH := "res://assets/Spritesheets/spritesheet-tiles-double.png"

var start_tile := 0
var width_tiles := 1
var height_tile := 8

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visuals: Node2D = $Visuals

func configure(new_start_tile: int, new_width_tiles: int, new_height_tile: int) -> void:
	start_tile = new_start_tile
	width_tiles = maxi(1, new_width_tiles)
	height_tile = new_height_tile
	position = Vector2(
		(start_tile + width_tiles * 0.5) * GameConfig.TILE_SIZE,
		height_tile * GameConfig.TILE_SIZE
	)
	var rectangle := collision.shape as RectangleShape2D
	rectangle.size = Vector2(width_tiles * GameConfig.TILE_SIZE, GameConfig.TILE_SIZE)
	_rebuild_visuals()

func end_tile() -> int:
	return start_tile + width_tiles

func _rebuild_visuals() -> void:
	for child in visuals.get_children():
		child.queue_free()
	if DisplayServer.get_name() == "headless":
		return
	var terrain_texture := load(TERRAIN_TEXTURE_PATH) as Texture2D
	if terrain_texture == null:
		return
	for index in width_tiles:
		var atlas := AtlasTexture.new()
		atlas.atlas = terrain_texture
		atlas.region = Rect2(0, 0, 128, 128)
		var tile := Sprite2D.new()
		tile.texture = atlas
		tile.position = Vector2((index - width_tiles * 0.5 + 0.5) * GameConfig.TILE_SIZE, 0.0)
		tile.scale = Vector2.ONE * (GameConfig.TILE_SIZE / 128.0)
		visuals.add_child(tile)
