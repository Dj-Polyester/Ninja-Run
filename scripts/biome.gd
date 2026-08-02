extends Node2D
class_name Biome

@export var char_id = 2

static var platforms = []
static var hollows = []
static var walls = []
static var num_platforms = 1
static var num_hollows = 1

static var collectible_probs_spawnable = null
static var collectible_probs_droppable = null
static var lwl_probs = [0, 0, 0, 0, 0, 0]
static var curr_lwl = 5
static var switch_counter = 0
static var should_switch = false
static var should_switch_cave = false
static var collectibles = []

const MAX_NUM_FRAMES = 10
const MIN_AVAILABLE_STARTCOO = 4
const MAX_AVAILABLE_STARTCOO = 7
const MIN_LEN = 3
const MAX_LEN = 10
const MV_THRESHOLD = 3
const LWL_THRESHOLD = 2
const LWL_MAX_WEIGHT = 5
const LWL_SWITCH_AMOUNTS = [1, 4]
const COO_DIFF_UPDATE_L = 2
const COO_DIFF_UPDATE_R = 6
const SPIKEY_THRESHOLD = 0.5

var cam_x_right_prev
var level: Level
var tile_map_layer: 
	get: return level.tile_map_layer
var player:
	get: return level.player 
var map_width:
	get: return level.map_width 
var map_height:
	get: return level.map_height 
var player_width:
	get: return level.player_width 
var player_height:
	get: return level.player_height 
var camera:
	get: return level.camera 
var cleared:
	get: return level.cleared
	set(val): level.cleared = val
var cam_x_left:
	get: return level.cam_x_left
	set(val): level.cam_x_left = val
var cam_x_left_pixels:
	get: return level.cam_x_left_pixels
	set(val): level.cam_x_left_pixels = val
var cam_x_right:
	get: return level.cam_x_right
	set(val): level.cam_x_right = val

func mv_spikes_platforms_left(num_pixels):
	for platform_set in platforms:
		for platform in platform_set:
			for coo_rnd_idx in platform:
				if coo_rnd_idx.spike != null:
					coo_rnd_idx.spike.global_position.x -= num_pixels

func mv_spikes_walls_left(num_pixels):
	for wall in walls:
		for coo_rnd_idx in wall:
			if coo_rnd_idx.spike != null:
				coo_rnd_idx.spike.global_position.x -= num_pixels

func mv_platforms_left(num_tiles):
	var coos2paint = []
	for i in lwl_probs:
		coos2paint.append([])
	var coos2erase = []
	var new_platforms = []
	for platform_set in platforms:
		var new_set = []
		for platform in platform_set:
			var new_platform = []
			for coo_rnd_idx in platform:
				var coo = coo_rnd_idx.coo
				var rnd_idx = coo_rnd_idx.level
				coos2erase.append(coo)
				coo.x -= num_tiles
				if coo.x >= 0:
					coo_rnd_idx.coo = coo
					new_platform.append(coo_rnd_idx)
					coos2paint[rnd_idx].append(coo)
				elif coo_rnd_idx.spike != null:
					coo_rnd_idx.spike.queue_free()
					coo_rnd_idx.spike = null
			if new_platform != []:
				new_set.append(new_platform)
		if new_set != []:
			new_platforms.append(new_set)
	platforms = new_platforms

	for coo2erase in coos2erase:
		tile_map_layer.erase_cell(coo2erase)
	var lwl_idx = 0
	for coo2paint in coos2paint:
		if coo2paint != []:
			tile_map_layer.set_cells_terrain_connect(coo2paint, 0, lwl_idx)
		lwl_idx += 1

func mv_walls_left(num_tiles):
	var coos2paint = []
	for i in lwl_probs:
		coos2paint.append([])
	var coos2erase = []
	var new_walls = []
	for wall in walls:
		var new_wall = []
		for coo_rnd_idx in wall:
			var coo = coo_rnd_idx.coo
			var rnd_idx = coo_rnd_idx.level
			coos2erase.append(coo)
			coo.x -= num_tiles
			if coo.x >= 0:
				coo_rnd_idx.coo = coo
				new_wall.append(coo_rnd_idx)
				coos2paint[rnd_idx].append(coo)
			else:
				if coo_rnd_idx.spike != null:
					coo_rnd_idx.spike.queue_free()
					coo_rnd_idx.spike = null
		if new_wall != []:
			new_walls.append(new_wall)
	var new_hollows = []
	for hollow_set in hollows:
		var new_hollow_set = []
		for hollow in hollow_set:
			var new_hollow = []
			for coo in hollow:
				coo.x -= num_tiles
				if coo.x >= 0:
					new_hollow.append(coo)
			if new_hollow != []:
				new_hollow_set.append(new_hollow)
		if new_hollow_set != []:
			new_hollows.append(new_hollow_set)
	hollows = new_hollows
	walls = new_walls

	for coo2erase in coos2erase:
		tile_map_layer.erase_cell(coo2erase)
	var lwl_idx = 0
	for coo2paint in coos2paint:
		if coo2paint != []:
			tile_map_layer.set_cells_terrain_connect(coo2paint, 0, lwl_idx)
		lwl_idx += 1

func find_rightmost_coo_x(platform_set):
	var lastcoo_x = 0
	for platform in platform_set:
		if platform[-1].coo.x > lastcoo_x:
			lastcoo_x = platform[-1].coo.x
	return lastcoo_x
	
func find_rightmost_platform_to_the_left_of_camera(_tile_coordinates_x):
	var set_index = 0
	var found = false
	var lastcoo_x = 0
	for platform_set in platforms:
		var set_rightmost_x = 0
		for platform in platform_set:
			var lastcoo = platform[-1].coo
			if lastcoo.x > set_rightmost_x:
				set_rightmost_x = lastcoo.x
		if set_rightmost_x >= _tile_coordinates_x:
			found = true
			break
		lastcoo_x = set_rightmost_x
		set_index += 1
	return [set_index, lastcoo_x] if found else [INF, INF]
	
func find_rightmost_hollow_to_the_left_of_camera(_tile_coordinates_x):
	# Mirror find_rightmost_platform_to_the_left_of_camera: use a range
	# comparison (>=) to find the first hollow set that still reaches the
	# camera, and return the count of sets strictly to its left to clear.
	# The previous exact-equality check (hollow_set[0][0].x == x - 1) almost
	# never matched, so clear_walls never ran and walls/hollows grew without
	# bound, making mv_walls_left O(total history) each cycle -> slowdown.
	var set_index = 0
	var found = false
	var lastcoo_x = 0
	for hollow_set in hollows:
		var set_rightmost_x = 0
		for hollow in hollow_set:
			# each hollow is a vertical column (constant x); use its last tile
			if hollow[-1].x > set_rightmost_x:
				set_rightmost_x = hollow[-1].x
		if set_rightmost_x >= _tile_coordinates_x:
			found = true
			break
		lastcoo_x = set_rightmost_x
		set_index += 1
	return [set_index, lastcoo_x] if found else [INF, INF]

func switch_weight_ptr(curr_ptr: int, weight_arr: Array, switch_amounts: Array, max_weight: int):
	var nxt_ptr = (curr_ptr + 1) % len(weight_arr)

	var switch_amount = switch_amounts[switch_counter]
	weight_arr[curr_ptr] = max(weight_arr[curr_ptr]-switch_amount, 0)
	weight_arr[nxt_ptr] = min(weight_arr[nxt_ptr]+switch_amount, max_weight)

	if weight_arr[curr_ptr] == 0:
		curr_ptr = nxt_ptr
	switch_counter = ((switch_counter + 1) % len(switch_amounts))
	print(weight_arr)
	return curr_ptr

func fill_frame():
	pass

func mv_collectibles_left(shift_amount_pixels):
	for collectible in collectibles:
		if is_instance_valid(collectible):
			collectible.global_position.x -= shift_amount_pixels

func process(_delta: float) -> void:

	var shift_amount_tiles = map_width * (MV_THRESHOLD - 1)
	if cam_x_left >= shift_amount_tiles:
		var shift_amount_pixels = level.get_tile_size().x * shift_amount_tiles
		print("mv left")
		mv_platforms_left(shift_amount_tiles)
		mv_spikes_platforms_left(shift_amount_pixels)
		mv_walls_left(shift_amount_tiles)
		mv_spikes_walls_left(shift_amount_pixels)
		mv_collectibles_left(shift_amount_pixels)

		camera.global_position.x -= shift_amount_pixels
		player.global_position.x -= shift_amount_pixels
		level.calc_cam_coos()
		# Keep the level's accumulator in sync so biome-zone thresholds can be
		# computed from a monotonic world coordinate.
		level.total_shift_tiles += shift_amount_tiles

	var lwl_threshold_tiles = map_width * LWL_THRESHOLD
	if cam_x_right % lwl_threshold_tiles == 0 and cam_x_right != cam_x_right_prev:
		print("switch_lwl ", curr_lwl)
		curr_lwl = switch_weight_ptr(curr_lwl, lwl_probs, LWL_SWITCH_AMOUNTS, LWL_MAX_WEIGHT)

func get_tile_config_from_coo(_tile_coo: Vector2i):
	pass

func process_end():
	if not cleared:
		var remove_collectibles_until = -1
		for collectible in collectibles:
			if not is_instance_valid(collectible) or collectible.global_position.x < cam_x_left_pixels:
				remove_collectibles_until += 1
		for i in range(remove_collectibles_until + 1):
			var collectible = collectibles.pop_front() 
			if is_instance_valid(collectible):
				collectible.queue_free()
		
	cam_x_right_prev = cam_x_right

func set_params(_args: Dictionary):
	pass

func set_player_anims():
	level.player.sprite.sprite_frames = load("assets/Characters/%d/Png/Character Sprite/sprite_frames.tres" % char_id)

func spawn_player():
	pass

func get_png_files(path: String) -> Array[String]:
	var files: Array[String] = []

	var dir := DirAccess.open(path)
	if dir == null:
		return files

	dir.list_dir_begin()

	while true:
		var file := dir.get_next()
		if file == "":
			break

		if dir.current_is_dir():
			continue

		if file.begins_with("."):
			continue

		if file.get_extension().to_lower() == "png":
			files.append(file.get_basename())

	dir.list_dir_end()

	files.sort()

	return files

func create_collectible(spawnable = true):
	var collectible_str = null
	var collectible_probs = null
	if spawnable:
		collectible_str = "spawnable" 
		if collectible_probs_spawnable == null:
			collectible_probs_spawnable = [5, 1, 3, 5]
		collectible_probs = collectible_probs_spawnable
	else:
		collectible_str = "droppable"
		if collectible_probs_droppable == null:
			collectible_probs_droppable = [1, 3, 5]
		collectible_probs = collectible_probs_droppable
	var collectible_url = "res://assets/Collectibles/%s" % collectible_str
	var collectible_names = get_png_files(collectible_url)
	print(collectible_names)
	var rnd_collectible_name = level.sample_weighted(collectible_probs, collectible_names)
	print(rnd_collectible_name)
	var collectible_sprite = load("%s/%s.png" % [collectible_url, rnd_collectible_name])
	var collectible_scene = preload("res://scenes/collectible.tscn")
	var collectible = collectible_scene.instantiate()
	level.add_child(collectible)
	collectible.init(rnd_collectible_name)
	collectible.sprite.texture = collectible_sprite
	collectibles.append(collectible)
	return collectible

func _init(_level: Level, _args: Dictionary = {}):
	lwl_probs[curr_lwl] = LWL_MAX_WEIGHT
	set_params(_args)
	level = _level
	if not should_switch:
		fill_frame()
		spawn_player()
		set_player_anims()
