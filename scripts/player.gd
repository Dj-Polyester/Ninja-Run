extends Entity
class_name Player

@export var speed = 300.0
@export var acceleration = 3000.0
@export var ice_acceleration = 200.0
@export var jump_speed = -500.0
@export var back_speed = -100.0
@export var free_movement: bool = true

const MAX_NUM_JUMPS = 2
const MAX_NUM_CLIMBS = 3
const FIRE_DAMAGE = 1
const SPIKE_DAMAGE = 5

var jump_counter = MAX_NUM_JUMPS
var climb_counter = MAX_NUM_CLIMBS
var cleared = false
var climbing = false
var prev_accel = 0
var tile_global_coo_under
var tile_coo_under
var prev_spikey = false
var level: Level
var was_on_floor = true

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
			if level.health_bar.value > 0:
				level.health_bar.set_zero()
			
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
	var direction = Input.get_axis("ui_left", "ui_right") if free_movement else 1.0
	
	var terrain = null
	var curr_tile_config = null
	var on_floor_before = is_on_floor()

	if direction > 0:
		cleared = false
	else:
		cleared = true

	# Add the gravity.
	if on_floor_before:
		jump_counter = MAX_NUM_JUMPS
		climb_counter = MAX_NUM_CLIMBS

		# get tile coo
		tile_global_coo_under = get_tile_global_coo_under(level) 
		tile_coo_under = level.global2tile(tile_global_coo_under)
		var tile = level.get_tile_from_coo(tile_coo_under)
		if tile != null:
			curr_tile_config = level.get_tile_config_from_coo(tile_coo_under)
			terrain = tile.terrain

	else:
		if velocity.y >= 0:
			sprite.play("fall")
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_up"):
		if climb_counter > 0 or jump_counter > 0:
			sprite.play("jump before")
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

	if terrain == 3 and not level.fire_created_once and on_floor_before:
		take_damage(FIRE_DAMAGE, level.health_bar)
		level.fire_created_once = true
		create_fire()

	if terrain == 4:
		drop_blocks()


	if curr_tile_config != null and curr_tile_config.spike != null:
		if on_floor_before and not prev_spikey and curr_tile_config.spike.spikey:
			take_damage(SPIKE_DAMAGE, level.health_bar)
		prev_spikey = curr_tile_config.spike.spikey

	climbing = false
	for hand in hands:
		var overlapping_bodies = hand.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body is TileMapLayer: # climb
				print("climbing")
				climbing = true

	move_and_slide()
	
	# Detect landing and update animation AFTER physics
	var on_floor_after = is_on_floor()
	var just_landed = not on_floor_before and on_floor_after
	
	if just_landed:
		print("jump after")
		sprite.play("jump after")
	elif on_floor_after:
		if sprite.animation == "jump after" and sprite.is_playing():
			print("jump after playing")
			pass # let landing animation finish
		elif direction:
			sprite.play("fast run")
		else:
			print("idle")
			sprite.play("idle")
	
	prev_accel = accel
	was_on_floor = on_floor_after
