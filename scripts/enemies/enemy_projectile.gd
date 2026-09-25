class_name EnemyProjectile
extends Area2D
## Swept hitbox whose lifetime advances only while the owning run is active.

signal resolved(projectile: EnemyProjectile, hit_player: bool)

var velocity := Vector2.ZERO
var remaining_seconds := 3.0
var hit: DamageStatus.HitEnvelope
var target: CollisionObject2D
var director: RunDirector
var _finished := false

func configure(origin: Vector2, direction: Vector2, speed: float, new_hit: DamageStatus.HitEnvelope, new_target: CollisionObject2D, new_director: RunDirector = null) -> bool:
	if not is_finite(speed) or speed <= 0.0 or direction.is_zero_approx():
		return false
	if new_hit == null or new_target == null:
		return false
	global_position = origin
	velocity = direction.normalized() * speed
	hit = new_hit
	target = new_target
	director = new_director
	return true

func _ready() -> void:
	monitoring = true
	collision_layer = 0
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = GameConfig.ENEMY_PROJECTILE_RADIUS
	collision.shape = shape
	add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(-6, -4), Vector2(8, 0), Vector2(-6, 4)])
	visual.color = Color(1.0, 0.75, 0.22)
	add_child(visual)

func _physics_process(delta: float) -> void:
	if _finished:
		return
	if director != null and director.state != RunDirector.State.RUNNING:
		return
	remaining_seconds -= delta
	if remaining_seconds <= 0.0:
		_finish(false)
		return
	var motion := velocity * delta
	var state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + motion, 1)
	query.exclude = [get_rid()]
	var result := state.intersect_ray(query)
	if not result.is_empty():
		_finish(result.get(&"collider") == target)
		return
	global_position += motion
	for body in get_overlapping_bodies():
		if body == target:
			_finish(true)
			return

func _finish(hit_player: bool) -> void:
	if _finished:
		return
	_finished = true
	resolved.emit(self, hit_player)
	queue_free()
