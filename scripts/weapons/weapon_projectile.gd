class_name WeaponProjectile
extends Area2D

const Definition = preload("res://scripts/weapons/weapon_definition.gd")
const EnemyControllerRuntime = preload("res://scripts/enemies/enemy_controller.gd")

signal resolved(projectile: WeaponProjectile, enemy: EnemyControllerRuntime, damaged: bool)

var definition: Definition
var velocity := Vector2.ZERO
var remaining_seconds := GameConfig.WEAPON_PROJECTILE_LIFETIME
var director: RunDirector
var _finished := false

func configure(new_definition: Definition, origin: Vector2, direction: Vector2, new_director: RunDirector) -> bool:
	if new_definition == null or not new_definition.is_valid() or direction.is_zero_approx() or new_director == null:
		return false
	definition = new_definition
	global_position = origin
	velocity = direction.normalized() * definition.projectile_speed
	director = new_director
	remaining_seconds = GameConfig.WEAPON_PROJECTILE_LIFETIME
	return true

func _ready() -> void:
	collision_layer = 0
	collision_mask = GameConfig.ENEMY_COLLISION_LAYER
	monitoring = false
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = GameConfig.WEAPON_PROJECTILE_RADIUS
	collision.shape = shape
	add_child(collision)
	if definition != null:
		var sprite := Sprite2D.new()
		sprite.texture = load(definition.asset_path) as Texture2D
		if sprite.texture != null:
			var size := sprite.texture.get_size()
			var max_axis := maxf(size.x, size.y)
			if max_axis > 0.0:
				sprite.scale = Vector2.ONE * minf(1.0, 34.0 / max_axis)
		sprite.rotation = velocity.angle()
		add_child(sprite)

func _physics_process(delta: float) -> void:
	if _finished or director == null or director.state != RunDirector.State.RUNNING:
		return
	remaining_seconds -= delta
	if remaining_seconds <= 0.0:
		_finish(null, false)
		return
	if definition.trajectory == Definition.TRAJECTORY_BALLISTIC:
		velocity.y += definition.gravity * delta
	var motion := velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + motion, GameConfig.ENEMY_COLLISION_LAYER)
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var enemy := hit.get(&"collider") as EnemyControllerRuntime
		if enemy != null:
			var damaged := enemy.apply_damage(definition.damage)
			_finish(enemy, damaged)
		else:
			_finish(null, false)
		return
	global_position += motion
	rotation = velocity.angle()

func _finish(enemy: EnemyControllerRuntime, damaged: bool) -> void:
	if _finished:
		return
	_finished = true
	resolved.emit(self, enemy, damaged)
	queue_free()
