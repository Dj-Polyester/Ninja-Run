extends Node2D

@export var min_platform_length: int = 3
@export var max_platform_length: int = 6

@onready var tile_map_layer: TileMapLayer = $Platforms
@onready var player = $Player

var was_on_air = false
var prev_player_frame = -1
var tile_coordinates: Vector2i
var last_seen_player_frame = 0
var total_frames_traveled = 0
var last_mv_total_frames = 0
var old_tile_coordinates: Vector2i
var possible_ys = range(MIN_Y, MAX_Y)
var num_platforms = 1
var platforms = []
var startcoos = []
var curr_player_frame = 0
var curr_gen_frame = 0
var curr_lwl = 0
var num_platforms_ref = 0
var lwl_probs = [1, 0, 0, 0, 0]
var num_platforms_probs = [1, 0, 0, 0]

# [1, 0, 0, 0] 0
# [0, 1, 0, 0] 1
# [1, 1, 0, 0]
# [0, 0, 1, 0]
# [1, 1, 1, 0]
const NUM_PLATFORMS_INCREASE_THRESHOLD = 1
const MAX_NUM_PLATFORMS = 4
const MV_THRESHOLD = 8
const LWL_FRAME = 1
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

func switch_prob(probs, curr_sample):
	if curr_sample % 2: # 1
		for i in range(curr_sample):
			probs[i] = 1
		curr_sample += 1
	else:
		curr_sample += 1
		for i in range(curr_sample):
			probs[i] = 0
		probs[curr_sample] = 1
	return [probs, curr_sample]
	

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
	for i in lwl_probs:
		coos2paint.append([])
	for platform in platforms_:
		for coo_rnd_idx in platform:
			var coo = coo_rnd_idx[0]
			var rnd_idx = coo_rnd_idx[1]
			coos2paint[rnd_idx].append(coo)
	var lwl_idx = 0
	for coo2paint in coos2paint:
		if coo2paint != []:
			tile_map_layer.set_cells_terrain_connect(coo2paint, 0, lwl_idx)
		lwl_idx += 1

func construct_platform(coox, cooy):
	startcoos.append(Vector2i(coox, cooy))
	var length = randi_range(MIN_LEN, MAX_LEN)
	return range(length).map(func(x): return [Vector2i(coox + x, cooy), sample_weighted(lwl_probs)])
	
func init_platforms(startx: int = 0):
	var rnd_indices = sample_unique_sorted(range(MAX_NUM_PLATFORMS), num_platforms)
	startcoos = []
	var last_end_x = startx

	for i in rnd_indices:
		var starty
		if startcoos.is_empty():
			starty = possible_ys[i]
		else:
			starty = startcoos[-1].y + PLAYER_HEIGHT
		var coox = rnd_coo2(last_end_x, COO_DIFF_INIT, last_end_x, MAX_X)
		var cooy = rnd_coo2(starty, COO_DIFF_INIT, starty, MAX_Y)
		if cooy == MAX_Y and not startcoos.is_empty() and abs(cooy - startcoos[-1].y) < PLAYER_HEIGHT:
			continue
		var new_platform = construct_platform(coox, cooy)
		if platforms.is_empty():
			platforms.append([new_platform])
		else:
			platforms[-1].append(new_platform)
		last_end_x = new_platform[-1][0].x + 1
	paint(platforms[-1])

func gen_platform_from(platform, last_end_x):
	var coox = rnd_coo1(
		platform[-1][0].x,
		COO_DIFF_UPDATE_L, COO_DIFF_UPDATE_R,
		last_end_x, MAP_WIDTH * (curr_gen_frame + 1) - 1,
	)
	var cooy = rnd_coo2(platform[-1][0].y, PLAYER_HEIGHT, MIN_Y, MAX_Y)

	if startcoos != []:
		var there_is_platform_closer = false
		for startcoo in startcoos:
			if abs(cooy - startcoo.y) < PLAYER_HEIGHT:
				there_is_platform_closer = true
				break
		if there_is_platform_closer:
			return null
	return construct_platform(coox, cooy)

func gen_sample_unique_sorted_platforms(last_end_x, _max, _num):
	_num = min(_num, _max)
	var rnd_indices = sample_unique_sorted(range(_max), _num)
	var _new_platforms = []
	for i in rnd_indices:
		var platform = platforms[-1][i]
		var new_platform = gen_platform_from(platform, last_end_x)
		if new_platform == null:
			continue
		_new_platforms.append(new_platform)
		last_end_x = new_platform[-1][0].x + 1
	return [_new_platforms, last_end_x]

func gen_platforms():
	var max_x = 0
	for platform in platforms[-1]:
		if platform[-1][0].x > max_x:
			max_x = platform[-1][0].x
	if max_x / MAP_WIDTH > curr_gen_frame:
		curr_gen_frame += 1
		return false

	startcoos = []
	var new_platforms = []
	var last_end_x = max_x + 1

	if num_platforms < len(platforms[-1]):
		var new_platforms_last_end_x = gen_sample_unique_sorted_platforms(
			last_end_x,
			len(platforms[-1]),
			num_platforms,
		)
		new_platforms.append_array(new_platforms_last_end_x[0])
		last_end_x = new_platforms_last_end_x[1]
	else:
		for platform in platforms[-1]:
			var new_platform = gen_platform_from(platform, last_end_x)
			if new_platform == null:
				continue
			new_platforms.append(new_platform)
			last_end_x = new_platform[-1][0].x + 1
		
		var surplus = num_platforms - len(platforms[-1])
		if surplus > 0:
			var new_platforms_last_end_x = gen_sample_unique_sorted_platforms(
				last_end_x,
				len(platforms[-1]),
				surplus,
			)
			new_platforms.append_array(new_platforms_last_end_x[0])
			last_end_x = new_platforms_last_end_x[1]
		
	platforms.append(new_platforms)
	paint(platforms[-1])
	return true

func clear_platforms(n = len(platforms)):
	var coos2erase = []
	for i in n:
		var _platforms = platforms.pop_at(0)
		for platform in _platforms:
			for coo_rnd_idx in platform:
				var coo = coo_rnd_idx[0]
				coos2erase.append(coo)
	for coo2erase in coos2erase:
		tile_map_layer.erase_cell(coo2erase)
	

func fill_frame():
	while gen_platforms():
		pass

func get_collision_size(collision_shape: CollisionShape2D) -> Vector2:
	# 1. Safety check to make sure a shape resource is actually assigned
	if not collision_shape or not collision_shape.shape:
		push_warning("No shape resource assigned!")
		return Vector2.ZERO
		
	var shape_res = collision_shape.shape
	var calculated_size = Vector2.ZERO

	# 2. Extract dimensions based on the shape resource type
	if shape_res is RectangleShape2D:
		# Rectangles are easy; they have a direct 'size' property (Width, Height)
		calculated_size = shape_res.size
		
	elif shape_res is CapsuleShape2D:
		# Capsules track a radius and a total height
		var width = shape_res.radius * 2.0
		var height = shape_res.height
		calculated_size = Vector2(width, height)
		
	elif shape_res is CircleShape2D:
		# Circles just track radius; Width and Height are the diameter
		var diameter = shape_res.radius * 2.0
		calculated_size = Vector2(diameter, diameter)
		
	elif shape_res is SeparationRayShape2D or shape_res is SegmentShape2D:
		push_warning("Ray/Segment shapes are lines and don't have a volume 'size'.")
		return Vector2.ZERO

	# 3. CRITICAL STEP: Multiply by the node's global scale!
	# If you scaled your character up to (2.0, 2.0) in the editor, 
	# this ensures the pixel math scales up accurately too.
	return calculated_size * collision_shape.global_scale

func spawn(obj: Node2D, platform_set_idx: int, platform_idx: int, tile_idx: int):
	tile_coordinates = platforms[platform_set_idx][platform_idx][0][tile_idx]
	var tile_world_center = tile_map_layer.to_global(
		tile_map_layer.map_to_local(tile_coordinates)
	)
	var tile_world_top = tile_world_center.y - (
		tile_map_layer.tile_set.tile_size.y * tile_map_layer.scale.y / 2.0
	)

	var collision_shape = obj.get_node("CollisionShape2D") as CollisionShape2D
	var size = get_collision_size(collision_shape)

	obj.global_position = Vector2(
		tile_world_center.x - collision_shape.position.x * obj.global_scale.x,
		tile_world_top - collision_shape.position.y * obj.global_scale.y - size.y / 2.0
	)

func _ready():
	randomize()
	init_platforms()
	fill_frame()

	spawn(player, 0, 0, 0)

func player_outside(tile_coo, map_length):
	return tile_coo / map_length > 0 and tile_coo % map_length == 0

func find_platform(_tile_coordinates):
	var set_index = 0
	var found = false
	for platform_set in platforms:
		for platform in platform_set:
			for coo_rnd_idx in platform:
				var coo = coo_rnd_idx[0]
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
		var platform_set_index = find_platform(tile_coordinates)
		if platform_set_index > 0:
			clear_platforms(platform_set_index)
		was_on_air = false
	if not player.is_on_floor() and not was_on_air:
		was_on_air = true

func find_leftmost_coo_x():
	var leftmost = INF
	for platform_set in platforms:
		for platform in platform_set:
			for coo in platform:
				if coo[0].x < leftmost:
					leftmost = coo[0].x
	return leftmost

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
				var coo = coo_rnd_idx[0]
				var rnd_idx = coo_rnd_idx[1]
				coos2erase.append(coo)
				coo.x -= num_tiles
				if coo.x >= 0:
					coo_rnd_idx[0] = coo
					new_platform.append(coo_rnd_idx)
					coos2paint[rnd_idx].append(coo)
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
	
				
func _process(_delta: float) -> void:
	var collision_shape = player.get_node("CollisionShape2D") as CollisionShape2D
	tile_coordinates = tile_map_layer.local_to_map(
		tile_map_layer.to_local(collision_shape.global_position)
	)
	curr_player_frame = (tile_coordinates.x / MAP_WIDTH)

	if curr_player_frame != last_seen_player_frame:
		if curr_player_frame > last_seen_player_frame:
			total_frames_traveled += curr_player_frame - last_seen_player_frame
		last_seen_player_frame = curr_player_frame
	print(tile_coordinates.x, " ", curr_player_frame, " ", curr_gen_frame)
	if (
		curr_player_frame != 0 and
		curr_player_frame != prev_player_frame
	):
		if (
			curr_gen_frame % LWL_FRAME == 0 and
			curr_lwl < len(lwl_probs) - (len(lwl_probs) % 2)
		):
			#print("switching lwl")
			var lwl_probs_curr_lwl = switch_prob(lwl_probs, curr_lwl)
			lwl_probs = lwl_probs_curr_lwl[0]
			curr_lwl = lwl_probs_curr_lwl[1]
		if (
			curr_gen_frame % NUM_PLATFORMS_INCREASE_THRESHOLD == 0 and
			num_platforms < len(num_platforms_probs) - (len(num_platforms_probs) % 2)
		):
			#print("switching num_platforms")
			var num_platforms_probs_num_platforms_ref = switch_prob(num_platforms_probs, num_platforms_ref)
			num_platforms_probs = num_platforms_probs_num_platforms_ref[0]
			num_platforms_ref = num_platforms_probs_num_platforms_ref[1]
			num_platforms = sample_weighted(num_platforms_probs, range(1, len(num_platforms_probs) + 1))
		
		prev_player_frame = curr_player_frame

	if (
		tile_coordinates.x % MAX_X != 0 and
		old_tile_coordinates.x < tile_coordinates.x
	):
		gen_platforms()

	if (
		total_frames_traveled > 0 and
		total_frames_traveled % MV_THRESHOLD == 0 and
		total_frames_traveled != last_mv_total_frames
	):
		var shift_amount = MAP_WIDTH * MV_THRESHOLD
		mv_platforms_left(shift_amount)
		var tile_size_world = tile_map_layer.tile_set.tile_size.x * tile_map_layer.scale.x
		player.global_position.x -= tile_size_world * shift_amount
		
		# Adjust internal coordinate tracking to match the new shifted world
		tile_coordinates.x -= shift_amount
		old_tile_coordinates.x -= shift_amount
		curr_player_frame = tile_coordinates.x / MAP_WIDTH
		last_seen_player_frame = curr_player_frame
		# Reset curr_gen_frame to match the new shifted coordinates
		curr_gen_frame = max(0, curr_gen_frame - MV_THRESHOLD)
		last_mv_total_frames = total_frames_traveled


	if player_outside(tile_coordinates.y, MAX_Y):
		print("Death by fall")

	old_tile_coordinates = tile_coordinates
