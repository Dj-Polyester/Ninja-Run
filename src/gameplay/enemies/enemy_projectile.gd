class_name EnemyProjectile
extends Area2D

const DAMAGE_INFO_SCRIPT := preload("res://src/gameplay/combat/damage_info.gd")
const DAMAGEABLE_CONTRACT_SCRIPT := preload("res://src/gameplay/combat/damageable_contract.gd")
const STATUS_EFFECT_CATALOG_SCRIPT := preload("res://src/data/status_effect_catalog.gd")

var source_enemy: Node
var velocity := Vector2.ZERO
var damage := 0.0
var status_effect
var lifetime_remaining := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var particles: GPUParticles2D = $Particles

func _ready() -> void:
	collision_layer = 0
	collision_mask = GameConfig.PLAYER_COLLISION_LAYER | GameConfig.TERRAIN_COLLISION_LAYER
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	_configure_visuals()

func configure(p_source_enemy: Node, target_position: Vector2, p_damage: float, p_status_effect, speed: float) -> void:
	source_enemy = p_source_enemy
	damage = maxf(0.0, p_damage)
	status_effect = STATUS_EFFECT_CATALOG_SCRIPT.resolve(p_status_effect)
	lifetime_remaining = GameConfig.ENEMY_PROJECTILE_LIFETIME
	var direction := global_position.direction_to(target_position)
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT
	velocity = direction * maxf(0.0, speed)
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	lifetime_remaining -= delta
	if lifetime_remaining <= 0.0:
		queue_free()
		return
	global_position += velocity * WorldSpeed.projectile_speed_multiplier * delta

func _on_body_entered(body: Node) -> void:
	if body == source_enemy:
		return
	if DAMAGEABLE_CONTRACT_SCRIPT.supports(body):
		var info = DAMAGE_INFO_SCRIPT.new(source_enemy, DAMAGE_INFO_SCRIPT.DamageType.PROJECTILE, status_effect)
		body.call(&"take_damage", damage, info)
	queue_free()

func _configure_visuals() -> void:
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		collision_shape.shape = circle
	circle.radius = GameConfig.ENEMY_PROJECTILE_COLLISION_RADIUS
	if DisplayServer.get_name() == "headless":
		particles.emitting = false
		return
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(-1.0, 0.0, 0.0)
	material.spread = 18.0
	material.initial_velocity_min = 16.0
	material.initial_velocity_max = 34.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.08
	material.scale_max = 0.18
	particles.process_material = material
	particles.emitting = true
