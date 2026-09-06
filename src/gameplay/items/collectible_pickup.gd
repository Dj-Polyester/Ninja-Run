class_name CollectiblePickup
extends Area2D

signal collected(collectible_id: StringName, gold_value: int)

var data: CollectibleData
var already_collected := false
var base_y := 0.0
var elapsed := 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group(&"collectibles")
	collision_layer = GameConfig.COLLECTIBLE_COLLISION_LAYER
	collision_mask = GameConfig.PLAYER_COLLISION_LAYER
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	base_y = position.y

func configure(collectible_data: CollectibleData) -> void:
	data = collectible_data
	base_y = position.y
	_update_visual()

func collect() -> int:
	if already_collected or data == null:
		return 0
	already_collected = true
	# A physics overlap can call collect() from body_entered. Godot blocks
	# toggling Area2D monitoring synchronously while that signal is being
	# dispatched, so defer the state change and let already_collected guard any
	# duplicate signal before this node is freed.
	set_deferred("monitoring", false)
	var awarded := maxi(0, data.gold_value)
	if awarded > 0:
		GameState.add_gold(awarded)
	collected.emit(data.id, awarded)
	queue_free()
	return awarded

func _process(delta: float) -> void:
	elapsed += delta
	rotation = sin(elapsed * GameConfig.COLLECTIBLE_SPIN_SPEED) * GameConfig.COLLECTIBLE_TILT_RADIANS
	position.y = base_y + sin(elapsed * GameConfig.COLLECTIBLE_BOB_SPEED) * GameConfig.COLLECTIBLE_BOB_PIXELS

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body is CollisionObject2D and (body.collision_layer & GameConfig.PLAYER_COLLISION_LAYER) != 0:
		collect()

func _update_visual() -> void:
	if sprite == null or data == null or DisplayServer.get_name() == "headless":
		return
	var texture := load(data.texture_path) as Texture2D
	if texture != null:
		sprite.texture = texture
