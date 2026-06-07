extends Node2D

@export var min_platform_length: int = 3
@export var max_platform_length: int = 6

@onready var tile_map_layer: TileMapLayer = $Platforms
@onready var player = $Player

var was_on_air = false
var tile_coordinates: Vector2i
var old_tile_coordinates: Vector2i
var possible_ys = range(MIN_Y, MAX_Y)
var max_num_platforms = len(possible_ys)
var platforms = []
var startcoos = []
var curr_frame = 0

const MAP_WIDTH = 30
const MAP_HEIGHT = 17
const MAX_X = MAP_WIDTH - 1
const PLAYER_HEIGHT = 5
const MIN_Y = PLAYER_HEIGHT - 1
const MAX_Y = MAP_HEIGHT - 1
const MIN_LEN = 3
const MAX_LEN = 10
const COO_DIFF_INIT = 4
const COO_DIFF_UPDATE_L = 2
const COO_DIFF_UPDATE_R = 6


func sample_unique_sorted(source_array: Array, amount: int) -> Array:
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
	items.sort()
	return items

func rnd_coo1(coo, radius_l, radius_r, min_val, max_val):
	return clamp(randi_range(coo - radius_l, coo + radius_r), min_val, max_val)

func rnd_coo2(coo, radius, min_val, max_val):
	return rnd_coo1(coo, radius, radius, min_val, max_val)

func paint(platforms_):
	var coos2paint = []
	for platform in platforms_:
		coos2paint.append_array(platform)
	tile_map_layer.set_cells_terrain_connect(coos2paint, 0, 0)

func construct_platform(coox, cooy):
	startcoos.append(Vector2i(coox, cooy))
	var length = randi_range(MIN_LEN, MAX_LEN)
	return range(length).map(func(x): return Vector2i(coox + x, cooy))
	
func init_platforms(startx: int = 0):
	var num_platforms = randi_range(1, max_num_platforms)
	var rnd_indices = sample_unique_sorted(range(max_num_platforms), num_platforms)
	print("num_platforms: ", num_platforms, " ", "rnd_indices: ", rnd_indices)
	startcoos = []
	
	for i in rnd_indices:
		var starty
		if startcoos.is_empty():
			starty = possible_ys[i]
		else:
			starty = startcoos[-1].y + PLAYER_HEIGHT
		var coox = rnd_coo2(startx, COO_DIFF_INIT, 0, MAX_X)
		var cooy = rnd_coo2(starty, COO_DIFF_INIT, starty, MAX_Y)
		if cooy == MAX_Y and abs(cooy - startcoos[-1].y) < PLAYER_HEIGHT:
			continue
		if platforms.is_empty():
			platforms.append([construct_platform(coox, cooy)])
		else:
			platforms[-1].append(construct_platform(coox, cooy))
	paint(platforms[-1])

func gen_platforms():
	var max_x = 0
	for platform in platforms[-1]:
		if platform[-1].x > max_x:
			max_x = platform[-1].x
	if max_x / MAP_WIDTH > curr_frame:
		curr_frame += 1
		return false

	startcoos = []
	var new_platforms = []

	for platform in platforms[-1]:
		var coox = rnd_coo1(
			platform[-1].x,
			COO_DIFF_UPDATE_L, COO_DIFF_UPDATE_R,
			MAX_X * curr_frame, MAX_X * (curr_frame + 1),
		)
		var cooy = rnd_coo2(platform[-1].y, PLAYER_HEIGHT, MIN_Y, MAX_Y)

		if startcoos != []:
			if abs(cooy - startcoos[-1].y) < PLAYER_HEIGHT:
				cooy = startcoos[-1].y + PLAYER_HEIGHT
		new_platforms.append(construct_platform(coox, cooy))
	platforms.append(new_platforms)
	paint(platforms[-1])
	return true

func clear_platforms(n):
	var coos2erase = []
	for i in n:
		var _platforms = platforms.pop_at(0)
		for platform in _platforms:
			coos2erase.append_array(platform)
	for coo2erase in coos2erase:
		tile_map_layer.erase_cell(coo2erase)
	

func fill_frame():
	while gen_platforms():
		pass

func init_player():
	tile_coordinates = platforms[0][0][0] - Vector2i(0, PLAYER_HEIGHT)
	player.global_position = tile_map_layer.to_global(
		tile_map_layer.map_to_local(tile_coordinates)
	)

func _ready():
	randomize()
	init_platforms()
	fill_frame()
	init_player()

func player_outside(tile_coo, map_length):
	return tile_coo / map_length > 0 and tile_coo % map_length == 0

func find_platform(_tile_coordinates):
	var set_index = 0
	var found = false
	for platform_set in platforms:
		for platform in platform_set:
			for coo in platform:
				if coo.x == _tile_coordinates.x:
					found = true
					break
			if found:
				break
		if found:
			break
		set_index += 1
	return set_index if found else -1

func _physics_process(_delta: float) -> void:
	if player.is_on_floor() and was_on_air:
		var platform_index = find_platform(tile_coordinates)
		clear_platforms(platform_index)
		was_on_air = false
	if not player.is_on_floor() and not was_on_air:
		was_on_air = true

func _process(_delta: float) -> void:
	tile_coordinates = tile_map_layer.local_to_map(
		tile_map_layer.to_local(player.global_position)
	)
	
	# print(tile_coordinates)
	if (
		tile_coordinates.x % MAX_X != 0 and
		old_tile_coordinates.x < tile_coordinates.x
	):
		gen_platforms()
	if player_outside(tile_coordinates.y, MAX_Y):
		print("Death by fall")

	old_tile_coordinates = tile_coordinates
