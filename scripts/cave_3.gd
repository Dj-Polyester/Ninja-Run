extends Level
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
	var all_wall = range(map_height).map(func(y): return LwlCoo.new(Vector2i(coox, y), sample_weighted(lwl_probs)))
	
	return all_wall.filter(func(lwlcoo): return lwlcoo.coo not in _hollows)

func all_items_in_stack_same_symbol(symbol):
	for s in dir_stack:
		if s != symbol:
			return false
	return true

func add_hollow(idx, new_hollow_set):

	var possible_moves = ["n", "uw", "dw"]

	if not dir_stack.is_empty() and dir_stack[0] == "uw" and "ds" not in dir_stack:
		possible_moves.append("ds")
	elif not dir_stack.is_empty() and dir_stack[0] == "dw" and "us" not in dir_stack:
		possible_moves.append("us")
	
	dir_stack.append(sample(possible_moves)[0])
	if len(dir_stack) > player_width:
		dir_stack.pop_front()

	var fstcoo = hollows[-1][idx][0]
	var lastcoo = hollows[-1][idx][-1]
	
	var miny = 0
	var maxy = map_height - 1
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

func gen_hollows():
	"""Add num_hollows hollows"""
	if walls.is_empty():
		var rnd_indices = sample_unique(range(map_height - player_height), num_hollows)

		var _hollowset = rnd_indices.map(
			func(idx): return construct_hollow(0, idx, randi_range(player_height, MAX_LEN))
		)
		hollows.append(_hollowset)
		
		var _hollows = _hollowset.reduce(func(x, y): return x + y, [])
		walls.append(construct_wall_from_hollows(_hollows))
		paint(walls[-1])
	else:
		var num_hollows_matching = min(len(hollows[-1]), num_hollows)
		var surplus = abs(num_hollows - len(hollows[-1]))

		var rnd_indices = sample_unique(range(len(hollows[-1])), num_hollows_matching)
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

func fill_frame():
	while true:
		gen_hollows()
		var lastcoo_x = hollows[-1][0][0].x
		if lastcoo_x > map_width:
			break

func _ready():
	super()
	fill_frame()