extends CharacterBody2D
class_name Entity

@onready var sprite = $AnimatedSprite2D

func rising():
	return velocity.y < 0

func falling():
	return velocity.y > 0

func outside_above():
	var collision_shape = get_node("CollisionShape2D") as CollisionShape2D
	return (collision_shape.global_position.y - get_collision_size(collision_shape).y / 2) < 0

func outside_below():
	var collision_shape = get_node("CollisionShape2D") as CollisionShape2D
	var viewport_size = get_viewport().get_visible_rect().size
	return (collision_shape.global_position.y + get_collision_size(collision_shape).y / 2) > viewport_size.y

func get_collision_size(collision_shape: CollisionShape2D) -> Vector2:
	# 1. Safety check to make sure a shape resource is actually assigned
	if not collision_shape or not collision_shape.shape:
		push_warning("No shape resource assigned!")
		return Vector2.ZERO
		
	var shape_res = collision_shape.shape
	var calculated_size = Vector2.ZERO

	# 2. Extract dimensions based on the shape resource type
	if shape_res is RectangleShape2D:
		# Rectangles are easy; they have a direct 'size' property (Width, Height)
		calculated_size = shape_res.size
		
	elif shape_res is CapsuleShape2D:
		# Capsules track a radius and a total height
		var width = shape_res.radius * 2.0
		var height = shape_res.height
		calculated_size = Vector2(width, height)
		
	elif shape_res is CircleShape2D:
		# Circles just track radius; Width and Height are the diameter
		var diameter = shape_res.radius * 2.0
		calculated_size = Vector2(diameter, diameter)
		
	elif shape_res is SeparationRayShape2D or shape_res is SegmentShape2D:
		push_warning("Ray/Segment shapes are lines and don't have a volume 'size'.")
		return Vector2.ZERO

	# 3. CRITICAL STEP: Multiply by the node's global scale!
	# If you scaled your character up to (2.0, 2.0) in the editor, 
	# this ensures the pixel math scales up accurately too.
	return calculated_size * collision_shape.global_scale


