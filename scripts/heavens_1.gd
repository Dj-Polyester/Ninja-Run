extends Biome
class_name Heavens

var fill = false

const COO_DIFF_INIT = 4
const NUM_PLATFORMS_THRESHOLD = 2

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
	var tile_world_center = level.tile2global(tile_coordinates)
	var tile_world_top = level.get_tile_top_from_center(tile_world_center)
	return [tile_world_center, tile_world_top]
	
func paint(platform_set):
	var coos2paint = []
	for i in lwl_probs:
		coos2paint.append([])
	for platform in platform_set:
		for coo_rnd_idx in platform:
			var coo = coo_rnd_idx.coo
			var rnd_idx = coo_rnd_idx.level
			coos2paint[rnd_idx].append(coo)
	var lwl_idx = 0
	for coo2paint in coos2paint:
		if coo2paint != []:
			tile_map_layer.set_cells_terrain_connect(coo2paint, 0, lwl_idx)
		lwl_idx += 1
		
func construct_platform(coox, cooy, length, is_ground=true):
	return range(length).map(
		func(x): return level.TileConfig.new(
			Vector2i(coox + x, cooy), 
			level.sample_weighted(lwl_probs),
			is_ground
		)
	)

func construct_platform_constrained_from(coox, cooy, new_platform_sets):
	var there_is_platform_closer = false
	for new_platform_set in new_platform_sets:
		for new_platform in new_platform_set:
			var startcoo = new_platform[0].coo
			if abs(cooy - startcoo.y) < player_height:
				there_is_platform_closer = true
				break
		if there_is_platform_closer:
			break
	if there_is_platform_closer:
		return null
	return construct_platform(coox, cooy, randi_range(MIN_LEN, MAX_LEN))

func add_platform(idx, new_platform_set):
	var lastcoo = platforms[-1][idx][-1].coo
	var starty = level.rnd_coo2(lastcoo.y, player_height, 0, map_height - 1)
	var minx = 0 if starty == lastcoo.y else COO_DIFF_UPDATE_L
	var startx = level.rnd_coo1(lastcoo.x + 1, minx, COO_DIFF_UPDATE_R, 0, MAX_NUM_FRAMES * map_width - 1)
	
	var last_platform_sets = [new_platform_set]

	var new_platform = construct_platform_constrained_from(startx, starty, last_platform_sets)
	if new_platform != null:
		new_platform_set.append(new_platform)
	return new_platform_set

func add_platform2hollow(idx, new_platform_set):
	
	var fstcoo = hollows[-1][idx][0]
	var lastcoo = hollows[-1][idx][-1]

	var starty = level.rnd_coo2(lastcoo.y, player_height, 0, map_height - 1)
	var minx = 0 if starty < fstcoo.y or starty > lastcoo.y else COO_DIFF_UPDATE_L
	var startx = level.rnd_coo1(lastcoo.x + 1, minx, COO_DIFF_UPDATE_R, 0, MAX_NUM_FRAMES * map_width - 1)

	var new_platform = construct_platform(startx, starty, randi_range(MIN_LEN, MAX_LEN))
	new_platform_set.append(new_platform)
	return new_platform_set


func fill_last_platform():
	var last_starty = platforms[-1][-1][0].coo.y
	for i in range(last_starty+1, map_height):
		var startx = platforms[-1][-1][0].coo.x
		platforms[-1].append(
			construct_platform(startx, i, len(platforms[-1][-1]), false)
		)

func gen_platforms():
	"""Add num_platforms platforms"""
	var _platformset = []
	if should_switch_cave:
		# add_platform2hollow anchors each new platform to a Cave hollow
		# in hollows[-1], so indices must be sampled over hollows[-1],
		# NOT platforms[-1] (which is empty on the first Heavens generation).
		var num_last_hollows = len(hollows[-1])
		var num_platforms_matching = min(num_last_hollows, num_platforms)
		var surplus = abs(num_platforms - num_last_hollows)

		var rnd_indices = level.sample_unique(range(num_last_hollows), num_platforms_matching)
		for idx in rnd_indices:
			_platformset = add_platform2hollow(idx, _platformset)

		if num_last_hollows > 0:
			for i in range(surplus):
				var idx = randi_range(0, num_last_hollows - 1)
				_platformset = add_platform2hollow(idx, _platformset)
		should_switch_cave = false
	elif platforms.is_empty():
		var starty_first_val = randi_range(MIN_AVAILABLE_STARTCOO, MAX_AVAILABLE_STARTCOO)
		var possible_ys = range(starty_first_val, map_height, player_height)
		var rnd_indices = level.sample_unique(range(len(possible_ys)), num_platforms)

		for idx in rnd_indices:
			var starty = possible_ys[idx]
			var startx = level.rnd_coo2(0, COO_DIFF_INIT, 0, MAX_NUM_FRAMES * map_width - 1)
			_platformset.append(construct_platform(startx, starty, randi_range(MIN_LEN, MAX_LEN)))

	else:
		var num_platforms_matching = min(len(platforms[-1]), num_platforms)
		var surplus = abs(num_platforms - len(platforms[-1]))

		var rnd_indices = level.sample_unique(range(len(platforms[-1])), num_platforms_matching)
		for idx in rnd_indices:
			_platformset = add_platform(idx, _platformset)

		for i in range(surplus):
			var idx = randi_range(0, len(platforms[-1]) - 1)
			_platformset = add_platform(idx, _platformset)
	platforms.append(_platformset)
	if fill:
		fill_last_platform()
	paint(platforms[-1])
	gen_spikes_platforms(platforms[-1])
	spawn_collectible()

func fill_frame():
	while true:
		gen_platforms()
		var lastcoo_x = find_rightmost_coo_x(platforms[-1])
		if lastcoo_x > map_width:
			break

func spawn(entity, platform_set_idx: int, platform_idx: int, tile_idx: int):
	var tile_world_center_top = get_tile_coo(platform_set_idx, platform_idx, tile_idx)

	var tile_world_center = tile_world_center_top[0]
	var tile_world_top = tile_world_center_top[1]

	entity.set_spawn_position_from_tile_coos(tile_world_center, tile_world_top)

func set_params(_args: Dictionary):
	fill = _args.get("fill", false)

func spawn_player():
	spawn(player, 0, 0, 0)

func gen_spikes_platforms(platform_set):
	print("gen spikes platforms")
	for platform in platform_set:
		for coo_rnd_idx in platform:
			if coo_rnd_idx.level == 5 and coo_rnd_idx.is_ground and randf() > SPIKEY_THRESHOLD:
				level.create_spike(coo_rnd_idx)

func get_tile_config_from_coo(tile_coo: Vector2i):
	for platform_set in platforms:
		for platform in platform_set:
			for coo_rnd_idx in platform:
				if coo_rnd_idx.coo == tile_coo:
					return coo_rnd_idx
	return null

func spawn_collectible():
	if randf() > 0.7:
		var collectible = create_collectible()
		var platform_idx = range(len(platforms[-1])).pick_random()
		var tile_idx = range(len(platforms[-1][platform_idx])).pick_random()
		spawn(collectible, -1, platform_idx, tile_idx)

func clear_spikes_platforms(platform_set):
	for platform in platform_set:
		for coo_rnd_idx in platform:
			if coo_rnd_idx.spike != null:
				coo_rnd_idx.spike.queue_free()
				coo_rnd_idx.spike = null


func clear_platforms(n = len(platforms)):
	var coos2erase = []
	for i in range(n):
		var platform_set = platforms.pop_at(0)
		for platform in platform_set:
			for coo_rnd_idx in platform:
				var coo = coo_rnd_idx.coo
				coos2erase.append(coo)
		clear_spikes_platforms(platform_set)
	for coo2erase in coos2erase:
		tile_map_layer.erase_cell(coo2erase)
		
func process(_delta: float) -> void:
	super(_delta)

	if should_switch:
		# First Heavens generation: anchor platforms directly to the Cave
		# hollows so platforms are visible right after the cave,
		# regardless of the camera-to-hollow distance.
		gen_platforms()
		# should_switch is the one-shot "immediate gen" gate; it is NOT reset
		# inside gen_platforms (gen_platforms only resets should_switch_cave,
		# the anchor-vs-chain gate). Without resetting it here, process() would
		# call gen_platforms() every frame forever, appending a new platform
		# set each frame -> unbounded growth -> mv_platforms_left freezes the
		# game.
		should_switch = false
	else:
		var rightmost_x = find_rightmost_coo_x(platforms[-1])
		if cam_x_right + map_width > rightmost_x:# generate one full viewport ahead
			gen_platforms()

	var num_platforms_threshold_tiles = map_width * NUM_PLATFORMS_THRESHOLD
	if cam_x_right % num_platforms_threshold_tiles == 0 and cam_x_right != cam_x_right_prev:
		print("switch_num_platforms ", curr_lwl)
		num_platforms = level.sample_weighted([.75, .25], range(1,3))

	var platform_set_until_destroy_lastcoo_x = find_rightmost_platform_to_the_left_of_camera(cam_x_left)
	var platform_set_until_destroy = platform_set_until_destroy_lastcoo_x[0]
	var lastcoo_x_platform = platform_set_until_destroy_lastcoo_x[1]
	if not cleared and cam_x_left > lastcoo_x_platform:
		print("clear platforms")
		clear_platforms(platform_set_until_destroy)
	process_end()