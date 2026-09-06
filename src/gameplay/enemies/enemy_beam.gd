class_name EnemyBeam
extends Node2D

const DAMAGE_INFO_SCRIPT := preload("res://src/gameplay/combat/damage_info.gd")
const DAMAGEABLE_CONTRACT_SCRIPT := preload("res://src/gameplay/combat/damageable_contract.gd")
const STATUS_EFFECT_CATALOG_SCRIPT := preload("res://src/data/status_effect_catalog.gd")

var source_enemy: Node
var damage := 0.0
var status_effect
var lifetime_remaining := 0.0
var fired := false

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var line: Line2D = $Line2D
@onready var particles: GPUParticles2D = $ImpactParticles

func _ready() -> void:
	ray_cast.collision_mask = GameConfig.PLAYER_COLLISION_LAYER | GameConfig.TERRAIN_COLLISION_LAYER
	ray_cast.collide_with_areas = false
	ray_cast.collide_with_bodies = true
	_configure_particles()

func configure(p_source_enemy: Node, target_position: Vector2, p_damage: float, p_status_effect) -> void:
	source_enemy = p_source_enemy
	damage = maxf(0.0, p_damage)
	status_effect = STATUS_EFFECT_CATALOG_SCRIPT.resolve(p_status_effect)
	lifetime_remaining = GameConfig.ENEMY_BEAM_DURATION
	var local_target := to_local(target_position)
	if local_target.length() > GameConfig.tiles_to_pixels(GameConfig.ENEMY_BEAM_MAX_RANGE_TILES):
		local_target = local_target.normalized() * GameConfig.tiles_to_pixels(GameConfig.ENEMY_BEAM_MAX_RANGE_TILES)
	ray_cast.target_position = local_target
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(local_target)
	call_deferred(&"_fire_once")

func _process(delta: float) -> void:
	lifetime_remaining -= delta
	if lifetime_remaining <= 0.0:
		queue_free()

func _fire_once() -> void:
	if fired or not is_inside_tree():
		return
	fired = true
	ray_cast.force_raycast_update()
	var endpoint := ray_cast.target_position
	if ray_cast.is_colliding():
		endpoint = to_local(ray_cast.get_collision_point())
		var collider := ray_cast.get_collider() as Node
		if collider != null and DAMAGEABLE_CONTRACT_SCRIPT.supports(collider):
			var info = DAMAGE_INFO_SCRIPT.new(source_enemy, DAMAGE_INFO_SCRIPT.DamageType.PROJECTILE, status_effect)
			collider.call(&"take_damage", damage, info)
	line.set_point_position(1, endpoint)
	particles.position = endpoint
	particles.emitting = true

func _configure_particles() -> void:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 25.0
	material.spread = 180.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.06
	material.scale_max = 0.14
	particles.process_material = material
