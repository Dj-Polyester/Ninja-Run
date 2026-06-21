extends Level
class_name Cave

var hollows = []
var walls = []
var num_hollows = 1

func paint(wall_set):
	var coos2paint = []
	for i in lwl_probs:
		coos2paint.append([])
	for wall in wall_set:
		for coo_rnd_idx in wall:
			var coo = coo_rnd_idx.coo
			var rnd_idx = coo_rnd_idx.level
			coos2paint[rnd_idx].append(coo)
	var lwl_idx = 0
	for coo2paint in coos2paint:
		if coo2paint != []:
			tile_map_layer.set_cells_terrain_connect(coo2paint, 0, lwl_idx)
		lwl_idx += 1

func construct_hollow(coox, cooy):
	var length = randi_range(PLAYER_HEIGHT, MAX_LEN)
	return range(length).map(func(y): return Vector2i(coox, cooy + y))

func construct_wall_from_hollows(_hollows):
	var coox = _hollows[0].x
	var all_wall = range(map_height).map(func(y): return LwlCoo.new(Vector2i(coox, y), sample_weighted(lwl_probs)))
	
	return all_wall.filter(func(lwlcoo): return lwlcoo.coo not in _hollows)

func construct_hollow_constrained_from(coox, cooy, new_platform_set):
	var there_is_platform_closer = false
	for new_platform in new_platform_set:
		var startcoo = new_platform[0].coo
		if abs(cooy - startcoo.y) < PLAYER_HEIGHT:
			there_is_platform_closer = true
			break
	if there_is_platform_closer:
		return null
	return construct_hollow(coox, cooy)

func add_hollow(idx, new_hollow_set):
	var lastcoo = hollows[-1][idx][-1].coo
	var starty = rnd_coo2(lastcoo.y, PLAYER_HEIGHT, 0, map_height - 1)
	var startx = lastcoo.x + 1
	
	var new_hollow = construct_hollow_constrained_from(startx, starty, new_hollow_set)
	if new_hollow != null:
		new_hollow_set.append(construct_hollow(startx, starty))
	return new_hollow_set

func gen_hollows():
	"""Add num_hollows hollows"""
	if walls.is_empty():
		var rnd_indices = sample_unique_sorted(range(map_height), num_hollows)

		var _hollowset = rnd_indices.map(func(idx): return construct_hollow(0, idx))
		hollows.append(_hollowset)
		
		var _hollows = _hollowset.reduce(func(x, y): return x + y, [])
		walls.append(construct_wall_from_hollows(_hollows))
		paint(walls[-1])
	else:
		var num_hollows_matching = min(len(hollows[-1]), num_hollows)
		var surplus = abs(num_hollows - len(hollows[-1]))

		var rnd_indices = sample_unique_sorted(range(len(hollows[-1])), num_hollows_matching)
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