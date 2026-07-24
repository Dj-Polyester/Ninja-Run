extends Entity
class_name Player

@export var speed = 300.0
@export var acceleration = 3000.0
@export var ice_acceleration = 200.0
@export var jump_speed = -500.0
@export var back_speed = -100.0

const MAX_NUM_JUMPS = 2
const MAX_NUM_CLIMBS = 3

var jump_counter = MAX_NUM_JUMPS
var climb_counter = MAX_NUM_CLIMBS
var cleared = false
var climbing = false
var prev_accel = 0
var tile_global_coo_under
var tile_coo_under

var level: Level

@onready var camera = $Camera2D
@onready var hands = [$Area2DL, $Area2DR]

func process_camera(delta: float):
	var viewport_size = get_viewport().get_visible_rect().size
	
	if outside_above():
		print("fly")
		if rising():
			camera.global_position.y = lerp(camera.global_position.y, global_position.y, 10.0 * delta)
		elif falling():
			camera.global_position.y = lerp(camera.global_position.y, viewport_size.y, 5.0 * delta)

	else:
		if outside_below():
			print("fall")
		camera.global_position.y = viewport_size.y
	camera.global_position.x = global_position.x

func create_fire():
	var num_fire_particles = randi_range(1,3)
	for i in range(num_fire_particles):
		level.create_fire(tile_global_coo_under)

func drop_blocks():
	for y in range(tile_coo_under.y, level.map_height):
		var tile_coo = Vector2i(tile_coo_under.x, y)
		var tile = level.get_tile_from_coo(tile_coo)
		if tile != null:
			var terrain = tile.terrain
			if terrain == 4:
				level.drop_block(tile_coo)
			else:
				break

func process_movement(delta: float):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	var terrain = null
	if direction > 0:
		cleared = false
	else:
		cleared = true

	# Add the gravity.
	if is_on_floor():
		jump_counter = MAX_NUM_JUMPS
		climb_counter = MAX_NUM_CLIMBS

		if direction:
			sprite.play("run")
		else:
			sprite.play("idle")
		# get tile coo
		tile_global_coo_under = get_tile_global_coo_under(level) 
		tile_coo_under = level.global2tile(tile_global_coo_under)
		var tile = level.get_tile_from_coo(tile_coo_under)
		if tile != null:
			terrain = tile.terrain

	else:
		velocity += get_gravity() * delta
		if velocity.y > 0:
			sprite.play("jump")
		else:
			sprite.play("fall")

	# Handle jump.
	if Input.is_action_just_pressed("ui_up"):
		if climbing and climb_counter > 0:
			velocity.y = jump_speed
			velocity.x = back_speed
			climb_counter -= 1
		if not climbing and jump_counter > 0:
			velocity.y = jump_speed
			jump_counter -= 1

	var target_speed = direction * speed
	var accel
	

	if terrain == 2 and abs(velocity.x) > target_speed: # deccelerating
		accel = ice_acceleration
	elif terrain == null:
		accel = prev_accel
	else: # accelerating
		accel = acceleration
	if direction:
		sprite.flip_h = (direction < 0)
	velocity.x = move_toward(velocity.x, target_speed, accel*delta)

	if terrain == 3 and not level.fire_created_once and is_on_floor():
		level.fire_created_once = true
		create_fire()

	if terrain == 4:
		drop_blocks()

	climbing = false
	for hand in hands:
		var overlapping_bodies = hand.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body is TileMapLayer: # climb
				print("climbing")
				climbing = true

	move_and_slide()
	prev_accel = accel