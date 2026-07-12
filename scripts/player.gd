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
var fire
var fire_created_once = false
var tile_global_coo
var fire_particles = []

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


func _on_fire_animation_finished(_fire):
	fire_particles.erase(_fire)
	_fire.queue_free()
	if fire_particles.is_empty():
		fire_created_once = false


func create_fire():
	var fire_scene = preload("res://scenes/fire.tscn")
	
	
	var num_fire_particles = randi_range(1,3)
	for i in range(num_fire_particles):
		fire = fire_scene.instantiate()
		level.add_child(fire)
		fire.sprite.animation_finished.connect(_on_fire_animation_finished.bind(fire))
		fire_particles.append(fire)

		var margin = level.get_tile_size().x / 2

		var randx = randf_range(-margin, margin)
		var randy = randf_range(0, level.get_tile_size().y / 2)

		fire.global_position = Vector2(
			tile_global_coo.x,	
			tile_global_coo.y - fire.scale.y * fire.get_size().y / 2,
		) + Vector2(randx, randy)

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
		tile_global_coo = get_tile_global_coo_under(level) 
		var tile = level.get_tile_from_coo(tile_global_coo)
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
	
	if terrain == 3 and not fire_created_once and is_on_floor():
		fire_created_once = true
		create_fire()

	if terrain == 2 and abs(velocity.x) > target_speed: # deccelerating
		accel = ice_acceleration
	elif terrain == null:
		accel = prev_accel
	else: # accelerating
		accel = acceleration
	if direction:
		sprite.flip_h = (direction < 0)
	velocity.x = move_toward(velocity.x, target_speed, accel*delta)

	move_and_slide()

	climbing = false
	for hand in hands:
		var overlapping_bodies = hand.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body is TileMapLayer: # climb
				print("climbing")
				climbing = true

	prev_accel = accel