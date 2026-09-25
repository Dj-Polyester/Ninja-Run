class_name AstroFallBlock
extends Node2D
## One Astro cell owns exactly one visual and one collider for its whole life.

var tile_id: StringName
var epoch := 0
var column := 0
var row := 0
var tile_size := 64.0
var atlas: Texture2D
var source_rect := Rect2(0, 0, 128, 128)
var coordinator: AstroFallCoordinator
var support_body: StaticBody2D
var top_area: Area2D
var target: CollisionObject2D
var _base_world_y := 0.0

func configure(new_tile_id: StringName, new_epoch: int, new_column: int, new_row: int, new_tile_size: float, new_atlas: Texture2D, new_source_rect: Rect2, new_coordinator: AstroFallCoordinator, new_world_position: Vector2, surface_id: StringName) -> void:
	tile_id = new_tile_id
	epoch = new_epoch
	column = new_column
	row = new_row
	tile_size = new_tile_size
	atlas = new_atlas
	source_rect = new_source_rect
	coordinator = new_coordinator
	_base_world_y = new_world_position.y
	position = new_world_position
	name = "Astro_%s" % tile_id.replace(":", "_")
	_build_static_collision(surface_id)
	_build_top_sensor()
	queue_redraw()

func on_armed() -> void:
	# Durability is invalid immediately in the coordinator, but collision remains
	# until falling starts so the configured delay is physically meaningful.
	if top_area != null:
		top_area.set_deferred("monitoring", false)

func on_falling() -> void:
	if top_area != null:
		top_area.set_deferred("monitoring", false)

func set_fall_world_y(world_y: float) -> void:
	position.y = world_y

func set_target(new_target: CollisionObject2D) -> void:
	target = new_target

func check_current_top_contact() -> void:
	if target != null and is_instance_valid(target) and top_area != null and top_area.get_overlapping_bodies().has(target):
		_on_body_entered(target)

func on_removed() -> void:
	visible = false
	if support_body != null:
		support_body.set_deferred("collision_layer", 0)
		for child in support_body.get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", true)
	if top_area != null:
		top_area.set_deferred("monitoring", false)

func _draw() -> void:
	if atlas != null and visible:
		draw_texture_rect_region(atlas, Rect2(-tile_size * 0.5, -tile_size * 0.5, tile_size, tile_size), source_rect, Color.WHITE)

func _build_static_collision(surface_id: StringName) -> void:
	support_body = StaticBody2D.new()
	support_body.name = &"AstroSupport"
	support_body.add_to_group(&"terrain_support")
	support_body.set_meta(&"terrain_surface_id", surface_id)
	support_body.set_meta(&"terrain_material", &"astro")
	support_body.set_meta(&"terrain_column", column)
	support_body.set_meta(&"astro_tile_id", tile_id)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tile_size, tile_size)
	collision.shape = shape
	support_body.add_child(collision)
	add_child(support_body)

func _build_top_sensor() -> void:
	top_area = Area2D.new()
	top_area.name = &"AstroTopContact"
	top_area.collision_layer = 0
	top_area.collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tile_size * 0.82, 6.0)
	collision.shape = shape
	collision.position = Vector2(0.0, -tile_size * 0.5 - 3.0)
	top_area.add_child(collision)
	top_area.body_entered.connect(_on_body_entered)
	add_child(top_area)

func _on_body_entered(body: Node2D) -> void:
	# Only a body physically above the tile can arm it. Side/head/proximity
	# overlap cannot satisfy this pose test; future gravity modes can pass an
	# explicit alternate direction through the coordinator API.
	if coordinator == null or body == null or body != target or body.global_position.y > global_position.y - tile_size * 0.35:
		return
	coordinator.arm_from_contact(tile_id, epoch, &"top")

func _exit_tree() -> void:
	if coordinator != null:
		coordinator.retire(tile_id, epoch)
