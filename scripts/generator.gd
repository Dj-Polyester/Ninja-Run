extends Node2D
class_name Generator

var lwl_probs = [MAX_PROB, 0, 0, 0, 0]
var curr_lwl = 0
var cam_x_left
var cam_x_right
var cam_x_right_prev

const MAX_PROB = 2
const MAX_NUM_FRAMES = 10
const MIN_AVAILABLE_STARTCOO = 4
const MAX_AVAILABLE_STARTCOO = 7
const MIN_LEN = 3
const MAX_LEN = 10
const MV_THRESHOLD = 8
const LWL_THRESHOLD = 2

func switch_weight_ptr(curr_ptr, arr):
	var nxt_ptr = (curr_ptr + 1) % len(arr)
	lwl_probs[curr_ptr] -= 1
	lwl_probs[nxt_ptr] += 1
	if lwl_probs[curr_ptr] == 0:
		curr_ptr = nxt_ptr
	return curr_ptr

func fill_frame():
	pass

func spawn_player():
	pass

var level
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
	
func process(_delta: float) -> void:
	cam_x_left = level.global2tile(camera.global_position).x
	cam_x_right = level.global2tile(camera.global_position).x + map_width
	
	var lwl_threshold_tiles = map_width * LWL_THRESHOLD
	if cam_x_right % lwl_threshold_tiles == 0 and cam_x_right != cam_x_right_prev:
		print("switch_lwl ", curr_lwl)
		curr_lwl = switch_weight_ptr(curr_lwl, lwl_probs)

func process_end():
	cam_x_right_prev = cam_x_right


func _init(_level: Level):
	level = _level
	fill_frame()
	spawn_player()