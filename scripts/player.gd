extends CharacterBody2D

@export var speed = 300.0
@export var jump_speed = -500.0

const MAX_NUM_JUMPS = 2
var jump_counter = MAX_NUM_JUMPS

@onready var sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")

	# Add the gravity.
	if is_on_floor():
		jump_counter = MAX_NUM_JUMPS
		if direction:
			sprite.play("run")
		else:
			sprite.play("idle")
		
	else:
		velocity += get_gravity() * delta
		if velocity.y > 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
	

	# Handle jump.
	if Input.is_action_just_pressed("ui_up") and jump_counter > 0:
		velocity.y = jump_speed
		jump_counter -= 1

	if direction:
		sprite.flip_h = (direction < 0)
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
