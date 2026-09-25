class_name WeaponController
extends Node2D

const Catalog = preload("res://scripts/weapons/weapon_catalog.gd")
const Definition = preload("res://scripts/weapons/weapon_definition.gd")
const Policy = preload("res://scripts/weapons/weapon_targeting_policy.gd")
const Projectile = preload("res://scripts/weapons/weapon_projectile.gd")
const EnemySpawnerRuntime = preload("res://scripts/enemies/enemy_spawner.gd")
const EnemyControllerRuntime = preload("res://scripts/enemies/enemy_controller.gd")
const Timing = preload("res://scripts/models/shooting_timing.gd")
const AbilityRules = preload("res://scripts/models/ability_eligibility.gd")

signal weapon_fired(weapon_id: StringName, directions: Array[Vector2])

var player: PlayerController
var enemy_spawner: EnemySpawnerRuntime
var director: RunDirector
var profile: ProfileState
var camera: Camera2D
var definitions: Dictionary = {}
var timing := Timing.new(GameConfig.COOLDOWN_PERIOD)
var shot_serial := 0
var active_projectiles: Dictionary = {}

func configure(new_player: PlayerController, new_enemy_spawner: EnemySpawnerRuntime, new_director: RunDirector, new_profile: ProfileState, new_camera: Camera2D) -> void:
	player = new_player
	enemy_spawner = new_enemy_spawner
	director = new_director
	profile = new_profile
	camera = new_camera
	definitions.clear()
	timing = Timing.new(GameConfig.COOLDOWN_PERIOD)
	for definition: Definition in Catalog.definitions():
		definitions[definition.id] = definition
		timing.register_weapon(definition.id, definition.fire_interval)

func shooting_available() -> bool:
	return profile != null and bool(profile.abilities.unlocked.get(AbilityRules.SHOOTING, false)) and AbilityRules.SHOOTING in profile.abilities.equipped

func activate_shooting() -> bool:
	if director == null or director.state != RunDirector.State.RUNNING or not shooting_available():
		return false
	var configured_cooldown := profile.ability_cooldown(AbilityRules.SHOOTING)
	timing.activation_cooldown = configured_cooldown if configured_cooldown > 0.0 else GameConfig.COOLDOWN_PERIOD
	return timing.activate(director.simulation_time)

func deactivate_shooting() -> void:
	timing.deactivate()

func _physics_process(_delta: float) -> void:
	if director == null or profile == null or player == null or enemy_spawner == null:
		return
	if director.state != RunDirector.State.RUNNING or not shooting_available() or not timing.is_active:
		return
	var visible := _visible_enemies()
	var equipped: Array[StringName] = profile.weapons.equipped.duplicate()
	var due := timing.due_weapons(director.simulation_time, equipped, not visible.is_empty())
	for weapon_id in due:
		var definition := definitions.get(weapon_id) as Definition
		if definition == null:
			continue
		var positions: Array[Vector2] = []
		for enemy: EnemyControllerRuntime in visible:
			positions.append(enemy.global_position)
		var directions := Policy.directions_for(definition, player.global_position, positions, director.seed, shot_serial)
		if directions.is_empty():
			continue
		var spawned := 0
		for direction in directions:
			if active_projectiles.size() >= GameConfig.MAX_ACTIVE_WEAPON_PROJECTILES:
				break
			if _spawn_projectile(definition, direction):
				spawned += 1
		if spawned > 0:
			timing.mark_fired(weapon_id, director.simulation_time)
			shot_serial += 1
			weapon_fired.emit(weapon_id, directions)

func _visible_enemies() -> Array[EnemyControllerRuntime]:
	var result: Array[EnemyControllerRuntime] = []
	if enemy_spawner == null:
		return result
	var rect := _camera_rect()
	for enemy_variant in enemy_spawner.active.values():
		var enemy := enemy_variant as EnemyControllerRuntime
		if enemy == null or not is_instance_valid(enemy) or enemy.dead or enemy.retired:
			continue
		if rect.has_point(enemy.global_position):
			result.append(enemy)
	return result

func _camera_rect() -> Rect2:
	if camera == null:
		return Rect2(Vector2(-10000000, -10000000), Vector2(20000000, 20000000))
	var size := camera.get_viewport_rect().size
	return Rect2(camera.global_position - size * 0.5, size)

func _spawn_projectile(definition: Definition, direction: Vector2) -> bool:
	var projectile := Projectile.new()
	if not projectile.configure(definition, player.global_position + Vector2(24.0, -8.0), direction, director):
		projectile.free()
		return false
	projectile.resolved.connect(_on_projectile_resolved)
	add_child(projectile)
	active_projectiles[projectile.get_instance_id()] = projectile
	return true

func _on_projectile_resolved(projectile: Projectile, _enemy: EnemyControllerRuntime, _damaged: bool) -> void:
	if projectile == null:
		return
	active_projectiles.erase(projectile.get_instance_id())
