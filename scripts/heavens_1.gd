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
	var tile_world_top = tile_world_center.y - (
		tile_map_layer.tile_set.tile_size.y * tile_map_layer.scale.y / 2.0
	)
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
		
func construct_platform(coox, cooy, length):
	return range(length).map(func(x): return level.LwlCoo.new(Vector2i(coox + x, cooy), level.sample_weighted(lwl_probs)))

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
		platforms[-1].append(construct_platform(startx, i, len(platforms[-1][-1])))

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

func fill_frame():
	while true:
		gen_platforms()
		var lastcoo_x = find_rightmost_coo_x(platforms[-1])
		if lastcoo_x > map_width:
			break

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

func set_params(_args: Dictionary):
	fill = _args.get("fill", false)

func spawn_player():
	spawn(player, 0, 0, 0)

func process(_delta: float) -> void:
	super(_delta)

	if should_switch:
		# First Heavens generation: anchor platforms directly to the Cave
		# hollows so platforms are visible right after the cave,
		# regardless of the camera-to-hollow distance. gen_platforms()
		# resets should_switch, so this branch fires only once.
		gen_platforms()
	else:
		var rightmost_x = find_rightmost_coo_x(platforms[-1])
		if cam_x_right + map_width > rightmost_x:# generate one full viewport ahead
			gen_platforms()

	var num_platforms_threshold_tiles = map_width * NUM_PLATFORMS_THRESHOLD
	if cam_x_right % num_platforms_threshold_tiles == 0 and cam_x_right != cam_x_right_prev:
		print("switch_num_platforms ", curr_lwl)
		num_platforms = level.sample_weighted([.75, .25], range(1,3))

	process_end()