extends Node2D
# class_name Level

# @onready var tile_map_layer: TileMapLayer = $Platforms
# @onready var player: Player = $Player
# @onready var viewport_size_in_tiles = (
# 	get_viewport().get_visible_rect().size / get_tile_size()
# ).ceil() as Vector2i
# @onready var map_width = viewport_size_in_tiles.x
# @onready var map_height = viewport_size_in_tiles.y

# var platforms = []
# var prev_curr_gen_frame = 0
# var curr_gen_frame = 0
# var prev_player_frame = 0
# var curr_player_frame = 0
# var prev_tile_coo_player_x = 0
# var prev_platform_set_idx = 0
# var was_on_air = false
# var tile_coo_player = Vector2i.ZERO
# var num_platforms = 1
# var num_platforms_ref = 0
# var num_platforms_probs = [1, 0, 0]
# var curr_lwl = 0
# var lwl_probs = [1, 0, 0, 0, 0]

# const PLAYER_HEIGHT = 5
# const PLATFORM_GEN_THRESHOLD = .5
# const COO_DIFF_INIT = 4
# const COO_DIFF_UPDATE_L = 2
# const COO_DIFF_UPDATE_R = 6
# const MIN_LEN = 1
# const MAX_LEN = 6
# const MIN_AVAILABLE_STARTCOO = 4
# const MAX_AVAILABLE_STARTCOO = 7
# const MAX_NUM_FRAMES = 10
# const MV_THRESHOLD = 1
# const LWL_THRESHOLD = 1
# const NUM_PLATFORMS_INCREASE_THRESHOLD = 1

# class LwlCoo:
# 	var coo: Vector2i
# 	var level: int
# 	func _init(_coo, _level) -> void:
# 		coo = _coo
# 		level = _level

# func switch_prob(probs, curr_sample):
# 	if curr_sample % 2: # 1
# 		for i in range(curr_sample):
# 			probs[i] = 1
# 		curr_sample += 1
# 	else:
# 		curr_sample += 1
# 		for i in range(curr_sample):
# 			probs[i] = 0
# 		probs[curr_sample] = 1
# 	return [probs, curr_sample]
	
# func get_tile_coo(platform_set_idx, platform_idx, tile_idx):
# 	var tile_coordinates = platforms[platform_set_idx][platform_idx][tile_idx].coo
# 	var tile_world_center = tile2global(tile_coordinates)
# 	var tile_world_top = tile_world_center.y - (
# 		tile_map_layer.tile_set.tile_size.y * tile_map_layer.scale.y / 2.0
# 	)
# 	return [tile_world_center, tile_world_top]
	
# func get_tile_size():
# 	return (tile_map_layer.tile_set.tile_size as Vector2) * tile_map_layer.scale

# func sample_weighted(weights: Array, population = null):
# 	if population == null:
# 		population = range(len(weights))
# 	var cum_weights = []
# 	var _sum = 0
# 	for w in weights:
# 		_sum += w
# 		cum_weights.append(_sum)
# 	var rndi = randf_range(0, cum_weights[-1] - 0.0001)
# 	var rnd_idx = 0
# 	for w in cum_weights:
# 		if rndi < w:
# 			break
# 		rnd_idx += 1
# 	return population[rnd_idx]

# func rnd_coo1(coo, radius_l, radius_r, min_val, max_val):
# 	return clamp(randi_range(coo - radius_l, coo + radius_r), min_val, max_val)

# func rnd_coo2(coo, radius, min_val, max_val):
# 	return rnd_coo1(coo, radius, radius, min_val, max_val)


# func construct_platform(coox, cooy):
# 	var length = randi_range(MIN_LEN, MAX_LEN)
# 	return range(length).map(func(x): return LwlCoo.new(Vector2i(coox + x, cooy), sample_weighted(lwl_probs)))

# func sample_unique_sorted(source_array: Array, amount: int) -> Array:
# 	# 1. Edge check: You can't sample more elements than exist in the array
# 	if amount > source_array.size():
# 		push_warning("Sample amount is larger than array size! Clamping to max.")
# 		amount = source_array.size()
	
# 	# 2. Duplicate the array so we don't mess up the original list
# 	var shuffled_copy = source_array.duplicate()
	
# 	# 3. Randomly shuffle the entire copy using Godot's built-in function
# 	shuffled_copy.shuffle()
	
# 	# 4. Slice out a chunk from index 0 up to our requested amount, then sort
# 	var items = shuffled_copy.slice(0, amount)
# 	items.sort()
# 	return items

# func global2tile(global_coo: Vector2):
# 	return tile_map_layer.local_to_map(
# 		tile_map_layer.to_local(global_coo)
# 	)

# func tile2global(tile_coo: Vector2i):
# 	return tile_map_layer.to_global(
# 		tile_map_layer.map_to_local(tile_coo)
# 	)

# func paint(platform_set):
# 	var coos2paint = []
# 	for i in lwl_probs:
# 		coos2paint.append([])
# 	for platform in platform_set:
# 		for coo_rnd_idx in platform:
# 			var coo = coo_rnd_idx.coo
# 			var rnd_idx = coo_rnd_idx.level
# 			coos2paint[rnd_idx].append(coo)
# 	var lwl_idx = 0
# 	for coo2paint in coos2paint:
# 		if coo2paint != []:
# 			tile_map_layer.set_cells_terrain_connect(coo2paint, 0, lwl_idx)
# 		lwl_idx += 1

# func clear(platform_set):
# 	for platform in platform_set:
# 		for coo_rnd_idx in platform:
# 			var coo = coo_rnd_idx.coo
# 			tile_map_layer.erase_cell(coo)

# func construct_platform_constrained_from(coox, cooy, new_platform_set):
# 	var there_is_platform_closer = false
# 	for new_platform in new_platform_set:
# 		var startcoo = new_platform[0].coo
# 		if abs(cooy - startcoo.y) < PLAYER_HEIGHT:
# 			there_is_platform_closer = true
# 			break
# 	if there_is_platform_closer:
# 		return null
# 	return construct_platform(coox, cooy)

# func add_platform(idx, new_platform_set):
# 	var lastcoo = platforms[-1][idx][-1].coo
# 	var starty = rnd_coo2(lastcoo.y, PLAYER_HEIGHT, 0, map_height - 1)
# 	var minx = 0 if starty == lastcoo.y else COO_DIFF_UPDATE_L
# 	var startx = rnd_coo1(lastcoo.x + 1, minx, COO_DIFF_UPDATE_R, 0, MAX_NUM_FRAMES * map_width - 1)
	
# 	var new_platform = construct_platform_constrained_from(startx, starty, new_platform_set)
# 	if new_platform != null:
# 		new_platform_set.append(construct_platform(startx, starty))
# 	return new_platform_set

# func gen_platforms():
# 	"""Add num_platforms platforms"""
# 	if platforms.is_empty():
# 		var possible_ys = []
# 		var starty_first_val = randi_range(MIN_AVAILABLE_STARTCOO, MAX_AVAILABLE_STARTCOO)
# 		possible_ys = range(starty_first_val, map_height, PLAYER_HEIGHT)
# 		var rnd_indices = sample_unique_sorted(range(len(possible_ys)), num_platforms)

# 		for idx in rnd_indices:
# 			var starty = possible_ys[idx]
# 			var startx = rnd_coo2(0, COO_DIFF_INIT, 0, MAX_NUM_FRAMES * map_width - 1)
# 			if platforms.is_empty():
# 				platforms.append([])
# 			platforms[-1].append(construct_platform(startx, starty))
# 		paint(platforms[-1])
# 	else:
# 		var num_platforms_matching = min(len(platforms[-1]), num_platforms)
# 		var surplus = abs(num_platforms - len(platforms[-1]))

# 		var rnd_indices = sample_unique_sorted(range(len(platforms[-1])), num_platforms_matching)
# 		var new_platform_set = []
# 		for idx in rnd_indices:
# 			new_platform_set = add_platform(idx, new_platform_set)

# 		for i in range(surplus):
# 			var idx = randi_range(0, len(platforms[-1]) - 1)
# 			new_platform_set = add_platform(idx, new_platform_set)
# 		platforms.append(new_platform_set)
# 		paint(platforms[-1])

# func find_platform_set(_tile_coordinates_x: int):
# 	var set_index = 0
# 	var found = false
# 	for platform_set in platforms:
# 		for platform in platform_set:
# 			for coo_rnd_idx in platform:
# 				var coo = coo_rnd_idx.coo
# 				if coo.x == _tile_coordinates_x:
# 					found = true
# 					break
# 			if found:
# 				break
# 		if found:
# 			break
# 		set_index += 1
# 	return set_index if found else -1

# func clear_platforms():
# 	while true:
# 		var platform_set = platforms[0]
# 		var lastcoo_x = find_rightmost_coo_x(platform_set)
# 		var lastcoo_x_global = tile2global(Vector2i(lastcoo_x, 0)).x + get_tile_size().x / 2
# 		if lastcoo_x_global < player.global_position.x:
# 			clear(platforms.pop_at(0))
# 		else:
# 			break
		
# func find_leftmost_coo_x(platform_set):
# 	var firstcoo_x = MAX_NUM_FRAMES * map_width
# 	for platform in platform_set:
# 		if platform[0].coo.x < firstcoo_x:
# 			firstcoo_x = platform[0].coo.x
# 	return firstcoo_x

# func find_rightmost_coo_x(platform_set):
# 	var lastcoo_x = 0
# 	for platform in platform_set:
# 		if platform[-1].coo.x > lastcoo_x:
# 			lastcoo_x = platform[-1].coo.x
# 	return lastcoo_x

# func mv_everything_left():
# 	# mv tiles left
# 	var tile_mv_amount = curr_gen_frame * map_width
# 	print("leftmost coo is ", tile_mv_amount)
# 	for platform_set in platforms:
# 		for platform in platform_set:
# 			for coo_level in platform:
# 				var coo = coo_level.coo
# 				tile_map_layer.erase_cell(coo)
# 				coo_level.coo.x -= tile_mv_amount
# 		paint(platform_set)
# 	# mv player left
# 	player.global_position.x -= get_tile_size().x * tile_mv_amount
# 	# 

# func fill_frame():
# 	while true:
# 		gen_platforms()
# 		var lastcoo_x = find_rightmost_coo_x(platforms[-1])
# 		if lastcoo_x > map_width:
# 			break

# func _ready():
# 	randomize()
# 	fill_frame()
# 	player.spawn(self , 0, len(platforms[-1]) / 2, 0)

# # func _physics_process(delta: float) -> void:
# # 	if not player.is_on_floor():
# # 		was_on_air = true
# # 	elif was_on_air and platforms != []:
# # 		gen_platforms()
# # 		clear_platforms()
# # 		was_on_air = false

# func _process(delta: float) -> void:
# 	tile_coo_player = player.get_tile_coo_obj(self )
# 	curr_player_frame = tile_coo_player.x / map_width
# 	var tile_coo_gen_x = find_rightmost_coo_x(platforms[-1])
# 	curr_gen_frame = tile_coo_gen_x / map_width

# 	print(curr_player_frame, " ", curr_gen_frame)
	
# 	var platform_set_idx = find_platform_set(tile_coo_player.x)
# 	if platform_set_idx != prev_platform_set_idx and tile_coo_player.x > prev_tile_coo_player_x:
# 		gen_platforms()
# 		clear_platforms()
# 		mv_everything_left()
# 		prev_platform_set_idx = platform_set_idx

# 	#if curr_gen_frame >= MV_THRESHOLD:
# 	#	print("mv_everything_left")
# 	#	mv_everything_left()

# 	if (
# 		curr_player_frame != 0 and
# 		curr_player_frame != prev_player_frame
# 	):
# 		if (
# 			curr_gen_frame % LWL_THRESHOLD == 0 and
# 			curr_lwl < len(lwl_probs) - (len(lwl_probs) % 2)
# 		):
# 			print("switching lwl")
# 			var lwl_probs_curr_lwl = switch_prob(lwl_probs, curr_lwl)
# 			lwl_probs = lwl_probs_curr_lwl[0]
# 			curr_lwl = lwl_probs_curr_lwl[1]
# 		if (
# 			curr_gen_frame % NUM_PLATFORMS_INCREASE_THRESHOLD == 0 and
# 			num_platforms < len(num_platforms_probs) - (len(num_platforms_probs) % 2)
# 		):
# 			print("switching num_platforms")
# 			var num_platforms_probs_num_platforms_ref = switch_prob(num_platforms_probs, num_platforms_ref)
# 			num_platforms_probs = num_platforms_probs_num_platforms_ref[0]
# 			num_platforms_ref = num_platforms_probs_num_platforms_ref[1]
# 			num_platforms = sample_weighted(num_platforms_probs, range(1, len(num_platforms_probs) + 1))
		
# 		prev_player_frame = curr_player_frame
# 	prev_tile_coo_player_x = tile_coo_player.x
# 	prev_platform_set_idx = platform_set_idx