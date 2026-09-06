class_name DesertHazard
extends Area2D

var tracked_bodies: Array[Node] = []

@onready var damage_timer: Timer = $DamageTimer
@onready var flame_particles: GPUParticles2D = $FlameParticles

func _ready() -> void:
	add_to_group("desert_hazard")
	damage_timer.wait_time = GameConfig.DESERT_BURN_TICK_INTERVAL
	_configure_particles()

func apply_contact_damage(target: Node) -> bool:
	if not _is_damageable(target):
		return false
	target.take_damage(GameConfig.DESERT_CONTACT_DAMAGE, {
		"source": self,
		"damage_type": &"fire",
		"status_effect": &"burn",
	})
	if target.has_method("apply_status"):
		target.apply_status({
			"id": &"burn",
			"duration": GameConfig.DESERT_BURN_DURATION,
		})
	return true

func apply_burn_tick(target: Node) -> bool:
	if not _is_damageable(target):
		return false
	target.take_damage(GameConfig.DESERT_BURN_TICK_DAMAGE, {
		"source": self,
		"damage_type": &"fire",
		"status_effect": &"burn",
	})
	if target.has_method("apply_status"):
		target.apply_status({
			"id": &"burn",
			"duration": GameConfig.DESERT_BURN_DURATION,
		})
	return true

func _on_body_entered(body: Node) -> void:
	if not _is_damageable(body):
		return
	if not tracked_bodies.has(body):
		tracked_bodies.append(body)
	apply_contact_damage(body)
	if damage_timer.is_stopped():
		damage_timer.start()

func _on_body_exited(body: Node) -> void:
	tracked_bodies.erase(body)
	if tracked_bodies.is_empty():
		damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	for body in tracked_bodies.duplicate():
		if not is_instance_valid(body):
			tracked_bodies.erase(body)
			continue
		apply_burn_tick(body)
	if tracked_bodies.is_empty():
		damage_timer.stop()

func _is_damageable(target: Node) -> bool:
	return target != null and target.has_method("take_damage")

func _configure_particles() -> void:
	if flame_particles.process_material == null:
		var material := ParticleProcessMaterial.new()
		material.direction = Vector3(0.0, -1.0, 0.0)
		material.spread = 28.0
		material.initial_velocity_min = 24.0
		material.initial_velocity_max = 48.0
		material.gravity = Vector3(0.0, -18.0, 0.0)
		material.scale_min = 0.18
		material.scale_max = 0.42
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		material.emission_box_extents = Vector3(GameConfig.TILE_SIZE * 0.4, 3.0, 1.0)
		flame_particles.process_material = material
	if DisplayServer.get_name() != "headless" and flame_particles.texture == null:
		var texture := load("res://assets/Particles/flame3/png/flame_00.png") as Texture2D
		if texture != null:
			flame_particles.texture = texture

