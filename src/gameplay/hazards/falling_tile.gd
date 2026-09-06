class_name FallingTile
extends CharacterBody2D

enum State { STABLE, WARNING, FALLING }

var state := State.STABLE
var grid_coordinate := Vector2i.ZERO
var support_below: FallingTile
var supported_tiles: Array[FallingTile] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var warning_timer: Timer = $WarningTimer
@onready var trigger_area: Area2D = $TriggerArea

func _ready() -> void:
	add_to_group("astro_falling_tile")
	warning_timer.wait_time = GameConfig.ASTRO_FALL_WARNING_DURATION
	set_physics_process(false)

func configure(tile_coordinate: Vector2i, atlas_coords: Vector2i) -> void:
	grid_coordinate = tile_coordinate
	if DisplayServer.get_name() == "headless":
		return
	var texture := load(TerrainTileSetFactory.TERRAIN_TEXTURE_PATH) as Texture2D
	if texture == null:
		return
	sprite.texture = texture
	sprite.region_enabled = true
	var stride := GameConfig.TERRAIN_SOURCE_TILE_SIZE + GameConfig.TERRAIN_ATLAS_SEPARATION
	sprite.region_rect = Rect2(
		Vector2(atlas_coords.x * stride, atlas_coords.y * stride),
		Vector2.ONE * GameConfig.TERRAIN_SOURCE_TILE_SIZE
	)
	sprite.scale = Vector2.ONE * (GameConfig.TILE_SIZE / float(GameConfig.TERRAIN_SOURCE_TILE_SIZE))

func set_support_below(tile: FallingTile) -> void:
	if support_below == tile:
		return
	if is_instance_valid(support_below):
		support_below.supported_tiles.erase(self)
	support_below = tile
	if is_instance_valid(tile) and not tile.supported_tiles.has(self):
		tile.supported_tiles.append(self)

func trigger_fall() -> bool:
	if state != State.STABLE:
		return false
	state = State.WARNING
	sprite.modulate = Color(1.0, 0.8, 0.35, 1.0)
	warning_timer.start()
	return true

func lose_support() -> void:
	trigger_fall()

func begin_falling_immediately() -> void:
	if state == State.FALLING:
		return
	warning_timer.stop()
	_begin_falling()

func _on_trigger_area_body_entered(body: Node) -> void:
	if body is NinjaPlayer:
		trigger_fall()

func _on_warning_timer_timeout() -> void:
	_begin_falling()

func _begin_falling() -> void:
	if state == State.FALLING:
		return
	state = State.FALLING
	sprite.modulate = Color.WHITE
	trigger_area.set_deferred("monitoring", false)
	set_physics_process(true)
	var dependents := supported_tiles.duplicate()
	supported_tiles.clear()
	for tile in dependents:
		if not is_instance_valid(tile):
			continue
		if tile.support_below == self:
			tile.support_below = null
			tile.lose_support()

func _physics_process(delta: float) -> void:
	velocity.y += GameConfig.ASTRO_FALL_GRAVITY * delta
	move_and_slide()
	if global_position.y > GameConfig.ASTRO_FALL_CLEANUP_Y:
		queue_free()

