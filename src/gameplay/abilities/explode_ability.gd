class_name ExplodeAbility
extends Ability

const DAMAGE_INFO_SCRIPT := preload("res://src/gameplay/combat/damage_info.gd")
const DAMAGEABLE_CONTRACT_SCRIPT := preload("res://src/gameplay/combat/damageable_contract.gd")

var last_enemy_hits := 0
var last_broken_tiles := 0

func activate() -> bool:
	if not super.activate():
		return false
	last_enemy_hits = _damage_nearby_enemies()
	last_broken_tiles = _break_nearby_terrain()
	_spawn_effect()
	active = false
	return true

func _damage_nearby_enemies() -> int:
	var radius := GameConfig.tiles_to_pixels(GameConfig.EXPLODE_RADIUS)
	var candidates: Array = []
	candidates.append_array(player.get_tree().get_nodes_in_group(&"enemies"))
	var enemy_container := _find_sibling_container("EnemyContainer")
	if enemy_container != null:
		candidates.append_array(enemy_container.find_children("*", "", true, false))
	var seen: Dictionary = {}
	var hits := 0
	for candidate in candidates:
		if not candidate is Node2D or candidate == player or not is_instance_valid(candidate):
			continue
		var id: int = candidate.get_instance_id()
		if seen.has(id) or player.global_position.distance_to(candidate.global_position) > radius:
			continue
		seen[id] = true
		if not DAMAGEABLE_CONTRACT_SCRIPT.supports(candidate):
			continue
		var damage_info = DAMAGE_INFO_SCRIPT.new(player, DAMAGE_INFO_SCRIPT.DamageType.EXPLOSION)
		candidate.call(&"take_damage", GameConfig.EXPLODE_DAMAGE, damage_info)
		hits += 1
	return hits

func _break_nearby_terrain() -> int:
	var world_streamer := _find_sibling_container("WorldStreamer")
	if world_streamer == null or not world_streamer.has_method(&"break_tiles_in_radius"):
		return 0
	return int(world_streamer.call(&"break_tiles_in_radius", player.global_position, GameConfig.EXPLODE_RADIUS))

func _spawn_effect() -> void:
	var parent := _find_sibling_container("Effects")
	if parent == null:
		parent = player.get_parent()
	if parent == null:
		return
	var particles := GPUParticles2D.new()
	particles.name = "ExplosionEffect"
	particles.amount = 24
	particles.lifetime = GameConfig.EXPLODE_EFFECT_DURATION
	particles.one_shot = true
	particles.explosiveness = 0.9
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = GameConfig.tiles_to_pixels(GameConfig.EXPLODE_RADIUS * 0.2)
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 180.0
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 260.0
	material.gravity = Vector3.ZERO
	particles.process_material = material
	parent.add_child(particles)
	particles.global_position = player.global_position
	particles.emitting = true
	var timer: SceneTreeTimer = player.get_tree().create_timer(GameConfig.EXPLODE_EFFECT_DURATION + 0.1)
	timer.timeout.connect(particles.queue_free)

func _find_sibling_container(node_name: String) -> Node:
	var current: Node = player.get_parent()
	while current != null:
		var result := current.get_node_or_null(node_name)
		if result != null:
				return result
		current = current.get_parent()
	return null
