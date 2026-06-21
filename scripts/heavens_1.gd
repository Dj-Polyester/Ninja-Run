extends Level

var num_platforms = 1
var platforms = []

const MIN_LEN = 3
const MAX_LEN = 10
const COO_DIFF_INIT = 4
const COO_DIFF_UPDATE_L = 2
const COO_DIFF_UPDATE_R = 6
const MIN_AVAILABLE_STARTCOO = 4
const MAX_AVAILABLE_STARTCOO = 7
const MV_THRESHOLD = 2

func find_platform(_tile_coordinates_x):
	var set_index = 0
	var found = false
	for platform_set in platforms:
		for platform in platform_set:
			for coo_rnd_idx in platform:
				var coo = coo_rnd_idx.coo
				if coo.x == _tile_coordinates_x:
					found = true
					break
			if found:
				break
		if found:
			break
		set_index += 1
	return set_index if found else -1

func get_tile_coo(platform_set_idx, platform_idx, tile_idx):
	var tile_coordinates = platforms[platform_set_idx][platform_idx][tile_idx].coo
	var tile_world_center = tile2global(tile_coordinates)
	var tile_world_top = tile_world_center.y - (
		tile_map_layer.tile_set.tile_size.y * tile_map_layer.scale.y / 2.0
	)
	return [tile_world_center, tile_world_top]

func find_leftmost_coo_x(platform_set):
	var firstcoo_x = MAX_NUM_FRAMES * map_width
	for platform in platform_set:
		if platform[0].coo.x < firstcoo_x:
			firstcoo_x = platform[0].coo.x
	return firstcoo_x

func find_rightmost_coo_x(platform_set):
	var lastcoo_x = 0
	for platform in platform_set:
		if platform[-1].coo.x > lastcoo_x:
			lastcoo_x = platform[-1].coo.x
	return lastcoo_x
	
func paint(platforms_):
	var coos2paint = []
	for i in lwl_probs:
		coos2paint.append([])
	for platform in platforms_:
		for coo_rnd_idx in platform:
			var coo = coo_rnd_idx.coo
			var rnd_idx = coo_rnd_idx.level
			coos2paint[rnd_idx].append(coo)
	var lwl_idx = 0
	for coo2paint in coos2paint:
		if coo2paint != []:
			tile_map_layer.set_cells_terrain_connect(coo2paint, 0, lwl_idx)
		lwl_idx += 1
		
func construct_platform(coox, cooy):
	var length = randi_range(MIN_LEN, MAX_LEN)
	return range(length).map(func(x): return LwlCoo.new(Vector2i(coox + x, cooy), sample_weighted(lwl_probs)))

func construct_platform_constrained_from(coox, cooy, new_platform_set):
	var there_is_platform_closer = false
	for new_platform in new_platform_set:
		var startcoo = new_platform[0].coo
		if abs(cooy - startcoo.y) < PLAYER_HEIGHT:
			there_is_platform_closer = true
			break
	if there_is_platform_closer:
		return null
	return construct_platform(coox, cooy)

func add_platform(idx, new_platform_set):
	var lastcoo = platforms[-1][idx][-1].coo
	var starty = rnd_coo2(lastcoo.y, PLAYER_HEIGHT, 0, map_height - 1)
	var minx = 0 if starty == lastcoo.y else COO_DIFF_UPDATE_L
	var startx = rnd_coo1(lastcoo.x + 1, minx, COO_DIFF_UPDATE_R, 0, MAX_NUM_FRAMES * map_width - 1)
	
	var new_platform = construct_platform_constrained_from(startx, starty, new_platform_set)
	if new_platform != null:
		new_platform_set.append(construct_platform(startx, starty))
	return new_platform_set

func gen_platforms():
	"""Add num_platforms platforms"""
	if platforms.is_empty():
		var possible_ys = []
		var starty_first_val = randi_range(MIN_AVAILABLE_STARTCOO, MAX_AVAILABLE_STARTCOO)
		possible_ys = range(starty_first_val, map_height, PLAYER_HEIGHT)
		var rnd_indices = sample_unique_sorted(range(len(possible_ys)), num_platforms)

		for idx in rnd_indices:
			var starty = possible_ys[idx]
			var startx = rnd_coo2(0, COO_DIFF_INIT, 0, MAX_NUM_FRAMES * map_width - 1)
			if platforms.is_empty():
				platforms.append([])
			platforms[-1].append(construct_platform(startx, starty))
		paint(platforms[-1])
	else:
		var num_platforms_matching = min(len(platforms[-1]), num_platforms)
		var surplus = abs(num_platforms - len(platforms[-1]))

		var rnd_indices = sample_unique_sorted(range(len(platforms[-1])), num_platforms_matching)
		var new_platform_set = []
		for idx in rnd_indices:
			new_platform_set = add_platform(idx, new_platform_set)

		for i in range(surplus):
			var idx = randi_range(0, len(platforms[-1]) - 1)
			new_platform_set = add_platform(idx, new_platform_set)
		platforms.append(new_platform_set)
		paint(platforms[-1])

func clear_platforms(n = len(platforms)):
	var coos2erase = []
	for i in range(n):
		var _platforms = platforms.pop_at(0)
		for platform in _platforms:
			for coo_rnd_idx in platform:
				var coo = coo_rnd_idx.coo
				coos2erase.append(coo)
	for coo2erase in coos2erase:
		tile_map_layer.erase_cell(coo2erase)

func fill_frame():
	while true:
		gen_platforms()
		var lastcoo_x = find_rightmost_coo_x(platforms[-1])
		if lastcoo_x > map_width:
			break

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

func spawn(entity: Entity, platform_set_idx: int, platform_idx: int, tile_idx: int):
	var tile_world_center_top = get_tile_coo(platform_set_idx, platform_idx, tile_idx)

	var tile_world_center = tile_world_center_top[0]
	var tile_world_top = tile_world_center_top[1]

	var collision_shape = entity.get_node("CollisionShape2D") as CollisionShape2D
	var size = entity.get_collision_size(collision_shape)

	entity.global_position = Vector2(
		tile_world_center.x - collision_shape.position.x * global_scale.x,
		tile_world_top - collision_shape.position.y * global_scale.y - size.y / 2.0
	)

func _ready():
	super()
	fill_frame()
	spawn(player, 0, 0, 0)

func _process(delta: float) -> void:
	super(delta)
	var rightmost_x = find_rightmost_coo_x(platforms[-1])
	var cam_x_left = global2tile(camera.global_position).x
	var cam_x_right = global2tile(camera.global_position).x + map_width
	var curr_frame = cam_x_right / map_width
	var platform_set_until_destroy = find_platform(cam_x_left)

	print(curr_frame)

	var shift_amount_tiles = map_width * (MV_THRESHOLD - 1)
	if cam_x_left >= shift_amount_tiles:
		var shift_amount_pixels = get_tile_size().x * shift_amount_tiles
		print("mv left")
		mv_platforms_left(shift_amount_tiles)
		camera.global_position.x -= shift_amount_pixels
		player.global_position.x -= shift_amount_pixels

	if cam_x_right > rightmost_x:
		print("gen platforms")
		gen_platforms()
		clear_platforms(platform_set_until_destroy)
