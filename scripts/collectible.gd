extends Area2D
class_name Collectible

@onready var sprite: Sprite2D = $Sprite2D
@export var amplitude := 8.0
@export var speed := 2.0

var start_y := 0.0
var t := 0.0
var base_scale := Vector2.ONE
var base_rot := 0.
var target_to_follow = null
var type: String

func get_size():
	return sprite.get_rect().size * sprite.global_scale
	
func get_spawn_position_from_tile_coos(tile_world_center: Vector2, tile_world_edge: float) -> Vector2:
	var size = get_size()

	return Vector2(
		tile_world_center.x - sprite.position.x * sprite.global_scale.x,
		tile_world_edge - sprite.position.y * sprite.global_scale.y - size.y / 2.0
	)

func set_spawn_position_from_tile_coos(tile_world_center: Vector2, tile_world_edge: float) -> void:
	global_position = get_spawn_position_from_tile_coos(tile_world_center, tile_world_edge)
	start_y = global_position.y
	base_scale = scale
	base_rot = rotation

func _process(delta):
	if target_to_follow != null:
		return  # physics_process handles movement, no idle animation
	t += delta
	global_position.y = start_y + sin(t * TAU * speed) * amplitude
	rotation = base_rot + 0.05*sin(t * TAU * speed)
	scale = base_scale * (1.0 + 0.05 * sin(t * TAU * speed))

func start_magnet(target):
	print("starting magnetting")
	target_to_follow = target

func init(_type: String):
	type = _type

func _on_collectible_pick_up(body: Node2D):
	if body.is_in_group("player"):
		body.collect(self)
		queue_free()

func _ready() -> void:	
	body_entered.connect(_on_collectible_pick_up)

func _physics_process(delta: float) -> void:
	if target_to_follow != null:
		global_position = global_position.move_toward(
            target_to_follow.global_position,
            500.0 * delta
        )