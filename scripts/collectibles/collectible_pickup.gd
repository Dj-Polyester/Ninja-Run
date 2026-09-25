class_name CollectiblePickup
extends Area2D

const Definition = preload("res://scripts/collectibles/collectible_definition.gd")

signal collected(pickup: CollectiblePickup)

var definition: Definition
var pickup_id: StringName
var anchor_id: StringName = &""
var is_drop := false
var _resolved := false

func configure(new_definition: Definition, new_pickup_id: StringName, new_anchor_id: StringName = &"", new_is_drop: bool = false) -> bool:
	if new_definition == null or not new_definition.is_valid() or new_pickup_id.is_empty():
		return false
	definition = new_definition
	pickup_id = new_pickup_id
	anchor_id = new_anchor_id
	is_drop = new_is_drop
	return true

func _ready() -> void:
	if definition == null or pickup_id.is_empty():
		push_error("CollectiblePickup must be configured before entering the tree.")
		set_deferred("monitoring", false)
		return
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = GameConfig.COLLECTIBLE_PICKUP_RADIUS
	collision.shape = shape
	add_child(collision)
	var sprite := Sprite2D.new()
	sprite.texture = load(definition.asset_path) as Texture2D
	if sprite.texture != null:
		var size := sprite.texture.get_size()
		var max_axis := maxf(size.x, size.y)
		if max_axis > 0.0:
			sprite.scale = Vector2.ONE * minf(1.0, 42.0 / max_axis)
	add_child(sprite)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _resolved or not body is PlayerController:
		return
	_resolved = true
	set_deferred("monitoring", false)
	collected.emit(self)

func retire() -> void:
	if _resolved:
		return
	_resolved = true
	set_deferred("monitoring", false)
	queue_free()
