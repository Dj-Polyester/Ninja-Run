extends Biome
class_name Cave

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
		func(y): return level.TileConfig.new(Vector2i(coox, y), level.sample_weighted(lwl_probs))
	)
	
	var wall_refined = []
	var prev_was_hollow = false
	for coo_rnd_idx in all_wall:
		if coo_rnd_idx.coo in _hollows:
			prev_was_hollow = true
		else:
			if prev_was_hollow:
				prev_was_hollow = false
				coo_rnd_idx.is_ground = true
			wall_refined.append(coo_rnd_idx)

	return wall_refined

func add_hollow(idx, new_hollow_set):
	var possible_moves = ["n", "uw", "dw"]
	var fstcoo = hollows[-1][idx][0]
	var lastcoo = hollows[-1][idx][-1]
	var prev_height = lastcoo.y - fstcoo.y + 1

	if player_height < prev_height:
		if not dir_stack.is_empty() and dir_stack[0] == "uw" and "ds" not in dir_stack:
			possible_moves.append("ds")
		elif not dir_stack.is_empty() and dir_stack[0] == "dw" and "us" not in dir_stack:
			possible_moves.append("us")
	
	dir_stack.append(possible_moves.pick_random())
	if len(dir_stack) > player_width:
		dir_stack.pop_front()

	var miny = 0
	var maxy = map_height - 2
	var maxy_starty_lc = lastcoo.y - player_height 
	var miny_endy_fc = fstcoo.y + player_height

	var starty
	var endy

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

func add_hollow2platform(idx, new_platform_set):
	var lastcoo = platforms[-1][idx][-1].coo
	var endy = level.rnd_coo2(lastcoo.y, player_height, player_height, map_height - 1)
	var starty = randi_range(0, endy - player_height)
	var minx = 0 if endy < lastcoo.y or starty > lastcoo.y else COO_DIFF_UPDATE_L
	var startx = level.rnd_coo1(lastcoo.x + 1, minx, COO_DIFF_UPDATE_R, 0, MAX_NUM_FRAMES * map_width - 1)
	

	var length = endy - starty + 1

	var new_platform = construct_hollow(startx, starty, length)
	new_platform_set.append(new_platform)
	return new_platform_set


func gen_hollows():
	"""Add num_hollows hollows"""
	var _hollowset = []
	if should_switch_cave:
		# add_hollow2platform anchors each new hollow to a Heavens platform
		# in platforms[-1], so indices must be sampled over platforms[-1],
		# NOT hollows[-1] (which is empty on the first Cave generation).
		var num_last_platforms = len(platforms[-1])
		var num_hollows_matching = min(num_last_platforms, num_hollows)
		var surplus = abs(num_hollows - num_last_platforms)

		var rnd_indices = level.sample_unique(range(num_last_platforms), num_hollows_matching)
		for idx in rnd_indices:
			_hollowset = add_hollow2platform(idx, _hollowset)

		if num_last_platforms > 0:
			for i in range(surplus):
				var idx = randi_range(0, num_last_platforms - 1)
				_hollowset = add_hollow2platform(idx, _hollowset)
		should_switch_cave = false
	elif walls.is_empty():
		var rnd_indices = level.sample_unique(range(map_height - player_height), num_hollows)

		for rnd_idx in rnd_indices:
			var starty = rnd_idx
			var endy = min(starty + randi_range(player_height, MAX_LEN), map_height - 2)
			var length = endy - starty + 1
			_hollowset.append(construct_hollow(0, starty, length))
	else:
		var num_hollows_matching = min(len(hollows[-1]), num_hollows)
		var surplus = abs(num_hollows - len(hollows[-1]))

		var rnd_indices = level.sample_unique(range(len(hollows[-1])), num_hollows_matching)
		for idx in rnd_indices:
			_hollowset = add_hollow(idx, _hollowset)

		for i in range(surplus):
			var idx = randi_range(0, len(hollows[-1]) - 1)
			_hollowset = add_hollow(idx, _hollowset)

	hollows.append(_hollowset)
	var _hollows = _hollowset.reduce(func(x, y): return x + y, [])
	walls.append(construct_wall_from_hollows(_hollows))
	paint(walls[-1])
	gen_spikes_walls(walls[-1])
	
func gen_spikes_walls(wall):
	print("gen spikes walls")
	for coo_rnd_idx in wall:
		if coo_rnd_idx.level == 5 and coo_rnd_idx.is_ground and randf() > SPIKEY_THRESHOLD:
			level.create_spike(coo_rnd_idx)

func fill_frame():
	while true:
		gen_hollows()
		var lastcoo_x = hollows[-1][0][0].x
		if lastcoo_x > map_width:
			break

func get_tile_coo(hollow_set_idx, hollow_idx, tile_idx):
	var tile_coordinates = hollows[hollow_set_idx][hollow_idx][tile_idx]
	var tile_world_center = level.tile2global(tile_coordinates)
	var tile_world_bottom = level.get_tile_bottom_from_center(tile_world_center)
	return [tile_world_center, tile_world_bottom]
	
func spawn(entity: Entity, hollow_set_idx: int, hollow_idx: int, tile_idx: int = -1):
	var tile_world_center_bottom = get_tile_coo(hollow_set_idx, hollow_idx, tile_idx)

	var tile_world_center = tile_world_center_bottom[0]
	var tile_world_bottom = tile_world_center_bottom[1]

	entity.set_spawn_position_from_tile_coos(tile_world_center, tile_world_bottom)

func spawn_player():
	spawn(player, 0, -1)

func get_tile_config_from_coo(tile_coo: Vector2i):
	for wall in walls:
		for coo_rnd_idx in wall:
			if coo_rnd_idx.coo == tile_coo:
				return coo_rnd_idx
	return null

func process(_delta: float) -> void:
	super(_delta)

	if should_switch:
		# First Cave generation: anchor hollows directly to the Heavens
		# platforms so the cave is visible right after the platforms,
		# regardless of the camera-to-platform distance.
		gen_hollows()
		# should_switch is the one-shot "immediate gen" gate; it is NOT reset
		# inside gen_hollows (gen_hollows only resets should_switch_cave, the
		# anchor-vs-chain gate). Without resetting it here, process() would
		# call gen_hollows() every frame forever, appending a new hollow/wall
		# set each frame -> unbounded growth -> mv_walls_left freezes the game.
		should_switch = false
	else:
		var rightmost_x = hollows[-1][0][0].x
		if cam_x_right + map_width > rightmost_x: # generate one viewport ahead
			print("gen hollows")
			gen_hollows()

	process_end()