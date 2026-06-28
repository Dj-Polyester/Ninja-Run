extends Node2D
class_name Level

@onready var tile_map_layer: TileMapLayer = $Platforms
@onready var player = $Player
@onready var player_camera = $Player/PlayerCamera
@onready var debug_camera = $DebugCamera

@onready var viewport_size_in_tiles = (
	get_viewport().get_visible_rect().size / get_tile_size()
).ceil() as Vector2i
@onready var map_width = viewport_size_in_tiles.x
@onready var map_height = viewport_size_in_tiles.y

@onready var player_collision_shape = player.get_node("CollisionShape2D") as CollisionShape2D
@onready var player_size_in_tiles = get_obj_collision_size_tiles(player, player_collision_shape)
@onready var player_width = player_size_in_tiles.x
@onready var player_height = player_size_in_tiles.y

@onready var debug_mode_label: TextEdit = $CanvasLayer/DebugModeLabel
var camera: Camera2D:
	get:
		return get_viewport().get_camera_2d()

var debug_mode_enabled = false

var lwl_probs = [1, 0, 0, 0, 0]
const MAX_NUM_FRAMES = 10
const CAM_SPEED = 5
const MIN_AVAILABLE_STARTCOO = 4
const MAX_AVAILABLE_STARTCOO = 7
const MIN_LEN = 3
const MAX_LEN = 10

class LwlCoo:
	var coo: Vector2i
	var level: int
	func _init(_coo, _level) -> void:
		coo = _coo
		level = _level

func sample_weighted(weights: Array, population = null):
	if population == null:
		population = range(len(weights))
	var cum_weights = []
	var _sum = 0
	for w in weights:
		_sum += w
		cum_weights.append(_sum)
	var rndi = randf_range(0, cum_weights[-1] - 0.0001)
	var rnd_idx = 0
	for w in cum_weights:
		if rndi < w:
			break
		rnd_idx += 1
	return population[rnd_idx]

func get_tile_size():
	return (tile_map_layer.tile_set.tile_size as Vector2) * tile_map_layer.scale

func get_obj_collision_size_tiles(entity: Entity, collision_shape: CollisionShape2D) -> Vector2i:
	var obj_size = entity.get_collision_size(collision_shape)
	return (obj_size / get_tile_size()).ceil() as Vector2i

func sample(array: Array, amount: int = 1):
	return range(amount).map(func(_idx): return array[randi_range(0, len(array) - 1)])

func sample_unique(source_array: Array, amount: int = 1, sorted = true) -> Array:
	# 1. Edge check: You can't sample more elements than exist in the array
	if amount > source_array.size():
		push_warning("Sample amount is larger than array size! Clamping to max.")
		amount = source_array.size()
	
	# 2. Duplicate the array so we don't mess up the original list
	var shuffled_copy = source_array.duplicate()
	
	# 3. Randomly shuffle the entire copy using Godot's built-in function
	shuffled_copy.shuffle()
	
	# 4. Slice out a chunk from index 0 up to our requested amount, then sort
	var items = shuffled_copy.slice(0, amount)
	if sorted:
		items.sort()
	return items

func global2tile(global_coo: Vector2):
	return tile_map_layer.local_to_map(
		tile_map_layer.to_local(global_coo)
	)

func tile2global(tile_coo: Vector2i):
	return tile_map_layer.to_global(
		tile_map_layer.map_to_local(tile_coo)
	)

func rnd_coo1(coo, radius_l, radius_r, min_val, max_val):
	return clamp(randi_range(coo - radius_l, coo + radius_r), min_val, max_val)

func rnd_coo2(coo, radius, min_val, max_val):
	return rnd_coo1(coo, radius, radius, min_val, max_val)

func _ready() -> void:
	randomize()
	debug_camera.enabled = false
	player_camera.enabled = true
	print(player_size_in_tiles)

func _process(delta: float) -> void:
	debug_mode_label.visible = debug_camera.enabled

	if Input.is_action_just_pressed("debug"):
		print("debug mode")
		debug_camera.enabled = not debug_camera.enabled
		player_camera.enabled = not player_camera.enabled
	if debug_camera.enabled:
		var direction = Input.get_axis("ui_left", "ui_right")
		camera.global_position.x += CAM_SPEED * direction
	else:
		player.process_camera(delta)

func _physics_process(delta: float) -> void:
	if not debug_camera.enabled:
		player.process_movement(delta)
