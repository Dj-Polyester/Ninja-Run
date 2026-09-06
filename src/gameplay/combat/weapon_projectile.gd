class_name WeaponProjectile
extends Area2D

const DAMAGE_INFO_SCRIPT := preload("res://src/gameplay/combat/damage_info.gd")
const DAMAGEABLE_CONTRACT_SCRIPT := preload("res://src/gameplay/combat/damageable_contract.gd")
const WEAPON_DATA_SCRIPT := preload("res://src/data/weapon_data.gd")

var source: Node
var weapon
var velocity := Vector2.ZERO
var gravity_acceleration := 0.0
var homing_target: Node2D
var homing_turn_rate := 0.0
var lifetime_remaining := GameConfig.WEAPON_PROJECTILE_LIFETIME
var hit_target: Node

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group(&"weapon_projectiles")
	collision_layer = 0
	collision_mask = GameConfig.ENEMY_COLLISION_MASK
	monitoring = true
	monitorable = false
	body_entered.connect(_on_overlap_entered)
	area_entered.connect(_on_overlap_entered)
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		collision_shape.shape = circle
	circle.radius = GameConfig.WEAPON_PROJECTILE_COLLISION_RADIUS

func configure(
	p_source: Node,
	p_weapon,
	p_velocity: Vector2,
	p_gravity_acceleration: float = 0.0,
	p_homing_target: Node2D = null,
	p_homing_turn_rate: float = 0.0
) -> void:
	source = p_source
	weapon = p_weapon
	velocity = p_velocity
	gravity_acceleration = p_gravity_acceleration
	homing_target = p_homing_target
	homing_turn_rate = maxf(0.0, p_homing_turn_rate)
	lifetime_remaining = GameConfig.WEAPON_PROJECTILE_LIFETIME
	if DisplayServer.get_name() != "headless" and weapon != null and not weapon.texture_path.is_empty():
		var texture := load(weapon.texture_path) as Texture2D
		if texture != null:
			sprite.texture = texture
			_fit_sprite(texture)
	_update_rotation()

func _physics_process(delta: float) -> void:
	lifetime_remaining = maxf(0.0, lifetime_remaining - delta)
	if lifetime_remaining <= 0.0:
		queue_free()
		return

	if homing_target != null and is_instance_valid(homing_target):
		var desired := global_position.direction_to(homing_target.global_position)
		if desired != Vector2.ZERO and velocity != Vector2.ZERO:
			var current_angle := velocity.angle()
			var desired_angle := desired.angle()
			var next_angle := rotate_toward(current_angle, desired_angle, homing_turn_rate * delta)
			velocity = Vector2.RIGHT.rotated(next_angle) * velocity.length()

	if not is_zero_approx(gravity_acceleration):
		velocity.y += gravity_acceleration * delta
	global_position += velocity * delta
	_update_rotation()

func _on_overlap_entered(candidate: Node) -> void:
	if is_queued_for_deletion():
		return
	var target := _resolve_damageable(candidate)
	if target == null or target == source:
		return
	if target.has_method(&"can_receive_projectile_attack") and not bool(target.call(&"can_receive_projectile_attack")):
		return
	if weapon == null or weapon.damage <= 0.0:
		return

	hit_target = target
	var damage_info = DAMAGE_INFO_SCRIPT.new(source, DAMAGE_INFO_SCRIPT.DamageType.PROJECTILE)
	target.call(&"take_damage", weapon.damage, damage_info)
	queue_free()

func _resolve_damageable(candidate: Node) -> Node:
	var current: Node = candidate
	for _depth in 4:
		if current == null:
			break
		if current != source and not current.is_queued_for_deletion() and DAMAGEABLE_CONTRACT_SCRIPT.supports(current):
			return current
		current = current.get_parent()
	return null

func _update_rotation() -> void:
	if velocity != Vector2.ZERO:
		rotation = velocity.angle()

func _fit_sprite(texture: Texture2D) -> void:
	var longest := maxf(texture.get_width(), texture.get_height())
	if longest <= 0.0:
		return
	# Weapon prop files vary substantially in source resolution. Normalize their
	# longest visual axis so projectile gameplay size stays consistent.
	var desired_longest := GameConfig.tiles_to_pixels(0.55)
	var scale_factor := minf(1.0, desired_longest / longest)
	sprite.scale = Vector2.ONE * scale_factor
