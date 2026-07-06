extends Generator
class_name Cave

var hollows = []
var walls = []
var num_hollows = 1
var dir_stack = []

const DIR_STACK_MAX = 4
const HOLLOW_MARGIN = 3
const MAX_MARGIN = 0

func paint(wall):
	var coos2paint = []
	for i in lwl_probs:
		coos2paint.append([])
	for coo_rnd_idx in wall:
		var coo = coo_rnd_idx.coo
		var rnd_idx = coo_rnd_idx.level
		coos2paint[rnd_idx].append(coo)
	var lwl_idx = 0
	for coo2paint in coos2paint:
		if coo2paint != []:
			tile_map_layer.set_cells_terrain_connect(coo2paint, 0, lwl_idx)
		lwl_idx += 1

func construct_hollow(coox, cooy, length):
	return range(length).map(func(y): return Vector2i(coox, cooy + y))

func construct_wall_from_hollows(_hollows):
	var coox = _hollows[0].x
	var all_wall = range(map_height).map(
		func(y): return level.LwlCoo.new(Vector2i(coox, y), level.sample_weighted(lwl_probs))
	)
	
	return all_wall.filter(func(lwlcoo): return lwlcoo.coo not in _hollows)

func add_hollow(idx, new_hollow_set):
	var possible_moves = ["n", "uw", "dw"]

	if not dir_stack.is_empty() and dir_stack[0] == "uw" and "ds" not in dir_stack:
		possible_moves.append("ds")
	elif not dir_stack.is_empty() and dir_stack[0] == "dw" and "us" not in dir_stack:
		possible_moves.append("us")
	
	dir_stack.append(possible_moves.pick_random())
	if len(dir_stack) > player_width:
		dir_stack.pop_front()

	var fstcoo = hollows[-1][idx][0]
	var lastcoo = hollows[-1][idx][-1]
	
	var miny = 0
	var maxy = map_height - 2
	var maxy_starty_lc = lastcoo.y - player_height
	var miny_endy_fc = fstcoo.y + player_height

	var starty
	var endy

	print(player_width, player_height)

	if dir_stack[-1] == "n": 
		starty = fstcoo.y
		endy = lastcoo.y
	elif dir_stack[-1] == "uw": 
		var _tmp = fstcoo.y - 1 - MAX_MARGIN
		starty = max(randi_range(_tmp, fstcoo.y - 1), miny)
		endy = min(randi_range(lastcoo.y, lastcoo.y + MAX_MARGIN), maxy)
	elif dir_stack[-1] == "dw": 
		var _tmp = lastcoo.y + 1 + MAX_MARGIN
		starty = max(randi_range(fstcoo.y - MAX_MARGIN, fstcoo.y), miny)
		endy = min(randi_range(lastcoo.y + 1, _tmp), maxy)

	elif dir_stack[-1] == "us": 
		starty = randi_range(min(maxy_starty_lc, fstcoo.y + 1), maxy_starty_lc)
		endy = randi_range(max(fstcoo.y, starty) + player_height, lastcoo.y)
	elif dir_stack[-1] == "ds": 
		endy = randi_range(min(miny_endy_fc, lastcoo.y - 1), lastcoo.y - 1)
		starty = randi_range(fstcoo.y, min(lastcoo.y, endy) - player_height)

	var length = endy - starty + 1
	var startx = lastcoo.x + 1
	var new_hollow = construct_hollow(startx, starty, length)
	new_hollow_set.append(new_hollow)
	return new_hollow_set

func gen_hollows():
	"""Add num_hollows hollows"""
	if walls.is_empty():
		var rnd_indices = level.sample_unique(range(map_height - player_height), num_hollows)

		var _hollowset = []
		for rnd_idx in rnd_indices:
			var starty = rnd_idx
			var endy = min(starty + randi_range(player_height, MAX_LEN), map_height - 2)
			var length = endy - starty + 1
			_hollowset.append(construct_hollow(0, starty, length))

		hollows.append(_hollowset)
		
		var _hollows = _hollowset.reduce(func(x, y): return x + y, [])
		walls.append(construct_wall_from_hollows(_hollows))
		paint(walls[-1])
	else:
		var num_hollows_matching = min(len(hollows[-1]), num_hollows)
		var surplus = abs(num_hollows - len(hollows[-1]))

		var rnd_indices = level.sample_unique(range(len(hollows[-1])), num_hollows_matching)
		var new_hollow_set = []
		for idx in rnd_indices:
			new_hollow_set = add_hollow(idx, new_hollow_set)

		for i in range(surplus):
			var idx = randi_range(0, len(hollows[-1]) - 1)
			new_hollow_set = add_hollow(idx, new_hollow_set)

		hollows.append(new_hollow_set)
		
		var _hollows = new_hollow_set.reduce(func(x, y): return x + y, [])
		walls.append(construct_wall_from_hollows(_hollows))
		paint(walls[-1])

func clear_walls(n = len(hollows)):
	var coos2erase = []
	for i in range(n):
		hollows.pop_at(0)
		var wall = walls.pop_at(0)
		for coo_rnd_idx in wall:
			var coo = coo_rnd_idx.coo
			coos2erase.append(coo)
	for coo2erase in coos2erase:
		tile_map_layer.erase_cell(coo2erase)

func fill_frame():
	while true:
		gen_hollows()
		var lastcoo_x = hollows[-1][0][0].x
		if lastcoo_x > map_width:
			break

func get_tile_coo(hollow_set_idx, hollow_idx, tile_idx):
	var tile_coordinates = hollows[hollow_set_idx][hollow_idx][tile_idx]
	var tile_world_center = level.tile2global(tile_coordinates)
	var tile_world_bottom = tile_world_center.y + (
		tile_map_layer.tile_set.tile_size.y * tile_map_layer.scale.y / 2.0
	)
	return [tile_world_center, tile_world_bottom]
	
func spawn(entity: Entity, hollow_set_idx: int, hollow_idx: int, tile_idx: int = -1):
	var tile_world_center_bottom = get_tile_coo(hollow_set_idx, hollow_idx, tile_idx)

	var tile_world_center = tile_world_center_bottom[0]
	var tile_world_bottom = tile_world_center_bottom[1]

	var collision_shape = entity.get_node("CollisionShape2D") as CollisionShape2D
	var size = entity.get_collision_size(collision_shape)

	entity.global_position = Vector2(
		tile_world_center.x - collision_shape.position.x * global_scale.x,
		tile_world_bottom - collision_shape.position.y * global_scale.y - size.y / 2.0
	)

func spawn_player():
	spawn(player, 0, -1)

func find_rightmost_platform_to_the_left_of_camera(_tile_coordinates_x):
	var set_index = 0
	var found = false
	for hollow_set in hollows:
		if hollow_set[0][0].x == _tile_coordinates_x - 1:
			found = true
			break
		set_index += 1
	return [set_index, _tile_coordinates_x - 1] if found else [INF, INF]

func mv_platforms_left(num_tiles):
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
		if new_wall != []:
			new_walls.append(new_wall)
	walls = new_walls

	for coo2erase in coos2erase:
		tile_map_layer.erase_cell(coo2erase)
	var lwl_idx = 0
	for coo2paint in coos2paint:
		if coo2paint != []:
			tile_map_layer.set_cells_terrain_connect(coo2paint, 0, lwl_idx)
		lwl_idx += 1

func process(_delta: float) -> void:
	super(_delta)
	var rightmost_x = hollows[-1][0][0].x
	var hollow_set_until_destroy_lastcoo_x = find_rightmost_platform_to_the_left_of_camera(cam_x_left)

	var hollow_set_until_destroy = hollow_set_until_destroy_lastcoo_x[0]
	var lastcoo_x = hollow_set_until_destroy_lastcoo_x[1]

	# print(cam_x_left / map_width)

	var shift_amount_tiles = map_width * (MV_THRESHOLD - 1)
	if cam_x_left >= shift_amount_tiles:
		var shift_amount_pixels = level.get_tile_size().x * shift_amount_tiles
		print("mv left")
		mv_platforms_left(shift_amount_tiles)
		camera.global_position.x -= shift_amount_pixels
		player.global_position.x -= shift_amount_pixels
	
	if cam_x_right + map_width > rightmost_x:# generate one full viewport ahead
		print("gen hollows")
		gen_hollows()

	if not cleared and cam_x_left > lastcoo_x:
		print("clear hollows")
		clear_walls(hollow_set_until_destroy)
		cleared = true
	
	process_end()