extends Node2D
class_name Level

@onready var tile_map_layer: TileMapLayer = $Platforms
@onready var debug_camera = $DebugCamera

@onready var viewport_size_in_tiles = (
	get_viewport().get_visible_rect().size / get_tile_size()
).ceil() as Vector2i
@onready var map_width = viewport_size_in_tiles.x
@onready var map_height = viewport_size_in_tiles.y

@onready var player = $Player
@onready var player_camera = $Player/PlayerCamera
@onready var player_size_in_tiles = get_obj_collision_size_tiles(player)
@onready var player_width = player_size_in_tiles.x + 1
@onready var player_height = player_size_in_tiles.y + 1

@onready var debug_mode_label: TextEdit = $UI/DebugModeLabel
@onready var health_bar: ProgressBar = $UI/HealthBar

@onready var block_scene = preload("res://scenes/block.tscn")
@onready var spike_scene = preload("res://scenes/spikes.tscn")
@onready var fire_scene = preload("res://scenes/fire.tscn")

var fire_particles = []
var fire_created_once = false

var camera: Camera2D:
	get:
		return get_viewport().get_camera_2d()

var curr_biome
var debug_mode_enabled = false
var cleared = false
var cam_x_left
var cam_x_right
var prev_id
# Accumulated left-shifts applied to re-base the tilemap as the player
# progresses. cam_x_right alone oscillates (it drops by shift_amount_tiles on
# every mv cycle), so biome-zone thresholds are computed from the monotonic
# world coordinate cam_x_right + total_shift_tiles instead.
var total_shift_tiles = 0
# Last biome zone (in threshold units) we already sampled for. The random
# biome pick must fire ONCE per threshold crossing, not every frame, so we
# compare the current zone against this.
var last_zone = 0

var biomes = [
	BiomeConfig.new(1, Heavens),
	BiomeConfig.new(2, Heavens, {"fill": true}),
	BiomeConfig.new(3, Cave),
]

const CAM_SPEED = 5
const BIOME_THRESHOLD = 2

class TileConfig:
	var coo: Vector2i
	var level: int
	var is_ground: bool
	var spike = null
	func _init(_coo, _level, _is_ground = true) -> void:
		coo = _coo
		level = _level
		is_ground = _is_ground

class BiomeConfig:
	var id
	var type: GDScript
	var args: Dictionary
	func  _init(_id, _type, _args = {}) -> void:
		id = _id
		type = _type
		args = _args


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

func create_spike(tile_coo: TileConfig):
	tile_coo.spike = spike_scene.instantiate()
	add_child(tile_coo.spike)
	var global_coo = tile2global(tile_coo.coo)
	tile_coo.spike.global_position = global_coo
	tile_coo.spike.z_index = -1


func _on_fire_animation_finished(_fire):
	fire_particles.erase(_fire)
	_fire.queue_free()
	if fire_particles.is_empty():
		fire_created_once = false

func create_fire(global_coo: Vector2):
	var fire = fire_scene.instantiate()
	add_child(fire)
	fire.sprite.animation_finished.connect(_on_fire_animation_finished.bind(fire))
	fire_particles.append(fire)

	var margin = get_tile_size().x / 2

	var randx = randf_range(-margin, margin)
	var randy = randf_range(0, get_tile_size().y / 2)

	fire.global_position = Vector2(
		global_coo.x,	
		global_coo.y - fire.scale.y * fire.get_size().y / 2,
	) + Vector2(randx, randy)

func drop_block(tile_coo: Vector2i):
	var global_coo = tile2global(tile_coo)

	var srcid = tile_map_layer.get_cell_source_id(tile_coo)
	var atlas_coo = tile_map_layer.get_cell_atlas_coords(tile_coo)
	if srcid != -1:
		print("srcid != -1")
		var block = block_scene.instantiate()
		add_child(block)
		var src = tile_map_layer.tile_set.get_source(srcid)
		if src is TileSetAtlasSource:
			print("src is TileSetAtlasSource")
			var texture = src.texture
			var region = src.get_tile_texture_region(atlas_coo)
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = texture
			atlas_tex.region = region
			block.sprite.texture = atlas_tex
		block.global_position = global_coo
	tile_map_layer.erase_cell(tile_coo)

func get_tile_config_from_coo(tile_coo: Vector2i):
	return curr_biome.get_tile_config_from_coo(tile_coo)

func get_tile_from_coo(tile_coo: Vector2i):
	return tile_map_layer.get_cell_tile_data(tile_coo)

func get_tile_top_from_center(tile_world_center: Vector2):
	return tile_world_center.y - (get_tile_size().y / 2.0)

func get_tile_bottom_from_center(tile_world_center: Vector2):
	return tile_world_center.y + (get_tile_size().y / 2.0)

func get_tile_size():
	return (tile_map_layer.tile_set.tile_size as Vector2) * tile_map_layer.scale

func get_obj_collision_size_tiles(entity: Entity) -> Vector2i:
	var obj_size = entity.get_collision_size()
	return (obj_size / get_tile_size()).ceil() as Vector2i

func sample(array: Array, amount: int = 1):
	return range(amount).map(func(_idx): return array[randi_range(0, len(array) - 1)])

func sample_unique(source_array: Array, amount: int = 1, sorted = true) -> Array:
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
	if sorted:
		items.sort()
	return items

func global2tile(global_coo: Vector2):
	return tile_map_layer.local_to_map(
		tile_map_layer.to_local(global_coo)
	)

func tile2global(tile_coo: Vector2i):
	return tile_map_layer.to_global(
		tile_map_layer.map_to_local(tile_coo)
	)

func rnd_coo1(coo, radius_l, radius_r, min_val, max_val):
	return clamp(randi_range(coo - radius_l, coo + radius_r), min_val, max_val)

func rnd_coo2(coo, radius, min_val, max_val):
	return rnd_coo1(coo, radius, radius, min_val, max_val)

func game_over():
	print("game over")

func _ready() -> void:
	randomize()
	# print
	print(player_size_in_tiles)
	# debug
	debug_camera.enabled = false
	player_camera.enabled = true
	# signals
	health_bar.no_hp_left.connect(game_over)
	var new_val = 100 + 5 * player.health.level
	health_bar.set_max_val(new_val)
	health_bar.set_val(new_val)
	# biome
	var curr_config = biomes[0]
	curr_biome = curr_config.type.new(self, curr_config.args)
	prev_id = curr_config.id

	player.level = self

func _process(delta: float) -> void:
	cam_x_left = global2tile(camera.global_position).x
	cam_x_right = cam_x_left + map_width
	debug_mode_label.visible = debug_camera.enabled

	if Input.is_action_just_pressed("debug"):
		print("debug mode")
		debug_camera.enabled = not debug_camera.enabled
		player_camera.enabled = not player_camera.enabled
	if debug_camera.enabled:
		var direction = Input.get_axis("ui_left", "ui_right")
		camera.global_position.x += CAM_SPEED * direction
	else:
		player.process_camera(delta)

	var biome_threshold_tiles = map_width * BIOME_THRESHOLD
	# At each threshold crossing, sample a random biome. If it differs from the
	# current one, switch: set the shared should_switch flag BEFORE constructing
	# the new biome so Biome._init skips fill_frame/spawn_player and the new
	# biome anchors to the previous biome's last set.
	# Use the monotonic world right-edge (cam_x_right + total_shift_tiles) so
	# mv re-basing (which drops cam_x_right by shift_amount_tiles each cycle)
	# doesn't make the zone oscillate. last_zone ensures the random pick fires
	# ONCE per crossing instead of every frame.

	var world_cam_x_right = cam_x_right + total_shift_tiles
	var zone = floori(world_cam_x_right / biome_threshold_tiles)
	if zone != last_zone:
		print("enter switch")
		last_zone = zone
		var curr_config = biomes.pick_random()
		var curr_id = curr_config.id
		if curr_id != prev_id:
			print("switch")
			if curr_id == 3 or prev_id == 3:
				curr_biome.should_switch_cave = true
			curr_biome.should_switch = true
			curr_biome = curr_config.type.new(self, curr_config.args)
			prev_id = curr_id
	curr_biome.process(delta)

func _physics_process(delta: float) -> void:
	if not debug_camera.enabled:
		player.process_movement(delta)
		cleared = player.cleared
