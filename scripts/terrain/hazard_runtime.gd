class_name TerrainHazardRuntime
extends Node2D
## Chunk-owned realization of one immutable descriptor. It emits damage intent;
## Level/RunDirector remain the sole owners of player health.

const Timing = preload("res://scripts/models/hazard_timing.gd")
const Descriptor = preload("res://scripts/terrain/hazard_descriptor.gd")

signal damage_requested(event: DamageStatus.DamageEvent, hazard)

const FLAME_TEXTURE_PATH := "res://assets/Particles/flame1/images/Sek_00001.png"
const SPIKE_TEXTURE_PATH := "res://assets/Props/Spikes.png"

var descriptor
var tile_size := float(GameConfig.TILE_SIZE)
var target: CollisionObject2D
var area: Area2D
var hitbox: CollisionShape2D
var particles: GPUParticles2D
var spike_visual: Sprite2D
var cadence := Timing.ContactCadence.new()
var extended := false
var extension_ratio := 0.0
var _touching: Dictionary = {}

func configure(new_descriptor, new_tile_size: float, new_run_origin_x: float, new_base_surface_y: float) -> void:
	descriptor = new_descriptor
	tile_size = new_tile_size
	# Descriptor rows identify the empty tile above support. The runtime origin is
	# the support top, so every visual/collider grows upward from real terrain.
	position = Vector2(new_run_origin_x + float(descriptor.absolute_position.x) * tile_size, new_base_surface_y + float(descriptor.absolute_position.y + 1) * tile_size)
	name = "Hazard_%s" % descriptor.id.replace(":", "_")
	_build_contact_area()
	if descriptor.type == &"desert_flame_candidate":
		_build_desert_flame()
	elif descriptor.type == &"fort_spike_candidate":
		_build_fort_spikes()
	else:
		# Astro descriptors remain intentionally inert until M3c.3.
		set_process(false)

func set_target(new_target: CollisionObject2D) -> void:
	target = new_target

func advance(simulation_seconds: float, running: bool) -> void:
	# The supplied time only advances in Level while the director is RUNNING.
	if descriptor == null or not running or descriptor.type == &"astro_fall_candidate":
		return
	if descriptor.type == &"fort_spike_candidate":
		extension_ratio = Timing.fort_extension(simulation_seconds, descriptor.phase, GameConfig.FORT_SPIKE_PERIOD, GameConfig.FORT_SPIKE_EXTENDED_SECONDS, GameConfig.FORT_SPIKE_TRANSITION_SECONDS)
		extended = extension_ratio > 0.0
		_apply_fort_pose()
	else:
		extension_ratio = 1.0
		extended = true
	if cadence.can_emit(simulation_seconds, _target_is_touching(), extended, _cadence_seconds()):
		damage_requested.emit(DamageStatus.DamageEvent.new(_damage_amount(), descriptor.id), self)

func is_damaging() -> bool:
	return extended

func _build_contact_area() -> void:
	area = Area2D.new()
	area.name = &"DamageArea"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 1
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	hitbox = CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(_hitbox_width(), _hitbox_height())
	hitbox.shape = rectangle
	area.add_child(hitbox)
	add_child(area)

func _build_desert_flame() -> void:
	particles = GPUParticles2D.new()
	particles.name = &"FlameParticles"
	particles.texture = load(FLAME_TEXTURE_PATH) as Texture2D
	particles.amount = 12
	particles.lifetime = 0.55
	particles.one_shot = false
	particles.emitting = true
	particles.position = Vector2(0.0, -GameConfig.DESERT_FLAME_HEIGHT * 0.5)
	area.position = Vector2(0.0, -GameConfig.DESERT_FLAME_HEIGHT * 0.5)
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 18.0
	material.initial_velocity_min = 28.0
	material.initial_velocity_max = 52.0
	material.gravity = Vector3.ZERO
	particles.process_material = material
	add_child(particles)

func _build_fort_spikes() -> void:
	spike_visual = Sprite2D.new()
	spike_visual.name = &"SpikesVisual"
	spike_visual.texture = load(SPIKE_TEXTURE_PATH) as Texture2D
	spike_visual.scale = Vector2(tile_size / 128.0, tile_size / 128.0)
	add_child(spike_visual)
	_apply_fort_pose()

func _apply_fort_pose() -> void:
	if descriptor == null or descriptor.type != &"fort_spike_candidate":
		return
	# A single continuous phase-derived extension controls exposed art and the
	# same-sized collision; there is no independent animation clock or hitbox.
	var exposed_height := GameConfig.FORT_SPIKE_HEIGHT * extension_ratio
	var offset := -exposed_height * 0.5
	if spike_visual != null:
		spike_visual.position = Vector2(0.0, offset)
		spike_visual.visible = extension_ratio > 0.0
		spike_visual.scale = Vector2(tile_size / 128.0, GameConfig.FORT_SPIKE_HEIGHT / 64.0 * extension_ratio)
	if area != null:
		area.position = Vector2(0.0, offset)
	if hitbox != null:
		var rectangle := hitbox.shape as RectangleShape2D
		if rectangle != null:
			rectangle.size = Vector2(GameConfig.FORT_SPIKE_WIDTH, maxf(0.1, exposed_height))
		hitbox.set_deferred("disabled", extension_ratio <= 0.0)

func _target_is_touching() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if _touching.has(target.get_instance_id()):
		return true
	return area != null and area.get_overlapping_bodies().has(target)

func _on_body_entered(body: Node2D) -> void:
	_touching[body.get_instance_id()] = body

func _on_body_exited(body: Node2D) -> void:
	_touching.erase(body.get_instance_id())

func _damage_amount() -> float:
	return GameConfig.DESERT_FLAME_DAMAGE if descriptor.type == &"desert_flame_candidate" else GameConfig.FORT_SPIKE_DAMAGE

func _cadence_seconds() -> float:
	return GameConfig.DESERT_FLAME_DAMAGE_CADENCE if descriptor.type == &"desert_flame_candidate" else GameConfig.FORT_SPIKE_DAMAGE_CADENCE

func _hitbox_width() -> float:
	return GameConfig.DESERT_FLAME_WIDTH if descriptor.type == &"desert_flame_candidate" else GameConfig.FORT_SPIKE_WIDTH

func _hitbox_height() -> float:
	return GameConfig.DESERT_FLAME_HEIGHT if descriptor.type == &"desert_flame_candidate" else GameConfig.FORT_SPIKE_HEIGHT
