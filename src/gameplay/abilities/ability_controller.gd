class_name AbilityController
extends Node

const ABILITY_CATALOG_SCRIPT := preload("res://src/data/ability_catalog.gd")
const JUMP_SCRIPT := preload("res://src/gameplay/abilities/jump_ability.gd")
const CLIMB_SCRIPT := preload("res://src/gameplay/abilities/climb_ability.gd")
const GLIDE_SCRIPT := preload("res://src/gameplay/abilities/glide_ability.gd")
const REVERSE_GRAVITY_SCRIPT := preload("res://src/gameplay/abilities/reverse_gravity_ability.gd")
const FLY_SCRIPT := preload("res://src/gameplay/abilities/fly_ability.gd")
const DASH_SCRIPT := preload("res://src/gameplay/abilities/dash_ability.gd")
const EXPLODE_SCRIPT := preload("res://src/gameplay/abilities/explode_ability.gd")
const SLOW_DOWN_TIME_SCRIPT := preload("res://src/gameplay/abilities/slow_down_time_ability.gd")
const INVISIBILITY_SCRIPT := preload("res://src/gameplay/abilities/invisibility_ability.gd")

signal ability_activated(ability_id: StringName)
signal equipment_refreshed

var abilities: Dictionary = {}
var jump_held := false
var was_supported := false

@onready var player = get_parent()

func _ready() -> void:
	refresh_from_profile()
	if not GameState.profile_changed.is_connected(_on_profile_changed):
		GameState.profile_changed.connect(_on_profile_changed)
	set_physics_process(false)

func _exit_tree() -> void:
	cancel_active_effects()
	if GameState.profile_changed.is_connected(_on_profile_changed):
		GameState.profile_changed.disconnect(_on_profile_changed)

func refresh_from_profile() -> void:
	var equipped = GameState.profile.get("equipped_abilities", [])
	var levels = GameState.profile.get("ability_levels", {})
	var desired: Array[String] = []
	if equipped is Array:
		for raw_id in equipped:
			if desired.size() >= GameConfig.NUM_EQUIPABLE_ABILITIES:
				break
			var id := String(raw_id)
			if ABILITY_CATALOG_SCRIPT.get_by_id(StringName(id)) != null and not desired.has(id):
				desired.append(id)

	for existing_id in abilities.keys():
		if desired.has(String(existing_id)):
			continue
		var removed = abilities[existing_id]
		if removed != null:
			removed.deactivate()
		abilities.erase(existing_id)

	for id in desired:
		var data := ABILITY_CATALOG_SCRIPT.get_by_id(StringName(id))
		var level := 1
		if levels is Dictionary:
			level = clampi(int(levels.get(id, 1)), 1, data.max_level)
		if abilities.has(id):
			abilities[id].set_upgrade_level(level)
			continue
		var runtime = _create_runtime(StringName(id))
		if runtime != null:
			abilities[id] = runtime.setup(data, player, self, level)
	equipment_refreshed.emit()

func tick(delta: float) -> void:
	for runtime in abilities.values():
		runtime.tick(delta)

func handle_jump_pressed() -> bool:
	jump_held = true
	var reverse = ability(&"reverse_gravity")
	if reverse != null:
		var reversed: bool = reverse.activate()
		if reversed:
			ability_activated.emit(&"reverse_gravity")
		return reversed

	var climb = ability(&"climb")
	if climb != null and climb.try_wall_jump():
		ability_activated.emit(&"climb")
		return true

	var fly = ability(&"fly")
	if fly != null and fly.try_jump():
		ability_activated.emit(&"fly")
		return true

	var jump = ability(&"jump")
	if jump != null and jump.try_jump():
		ability_activated.emit(&"jump")
		return true
	return false

func handle_jump_released() -> void:
	jump_held = false
	var glide = ability(&"glide")
	if glide != null:
		glide.active = false

func activate_ability(ability_id: StringName) -> bool:
	var runtime = ability(ability_id)
	if runtime == null:
		return false
	var activated: bool = runtime.activate()
	if activated:
		ability_activated.emit(ability_id)
	return activated

func ability(ability_id: StringName):
	return abilities.get(String(ability_id))

func is_equipped(ability_id: StringName) -> bool:
	return abilities.has(String(ability_id))

func cooldown_remaining(ability_id: StringName) -> float:
	var runtime = ability(ability_id)
	return runtime.cooldown_remaining if runtime != null else 0.0

func gravity_multiplier(delta: float) -> float:
	var glide = ability(&"glide")
	if glide == null:
		return 1.0
	return glide.gravity_multiplier(delta, jump_held)

func is_gliding() -> bool:
	var glide = ability(&"glide")
	return glide != null and glide.active

func is_dashing() -> bool:
	var dash = ability(&"dash")
	return dash != null and dash.active

func horizontal_speed(delta: float) -> float:
	var dash = ability(&"dash")
	if dash != null and dash.active:
		return dash.horizontal_speed(delta)
	return 0.0

func after_move(previous_position: Vector2) -> void:
	var dash = ability(&"dash")
	if dash != null and dash.active:
		dash.after_move(previous_position.x)

func update_support_state(supported: bool) -> void:
	if supported and not was_supported:
		for id in [&"jump", &"climb", &"glide"]:
			var runtime = ability(id)
			if runtime != null and runtime.has_method(&"on_support_contact"):
				runtime.call(&"on_support_contact")
	was_supported = supported

func cancel_active_effects(reset_cooldowns: bool = false) -> void:
	jump_held = false
	for runtime in abilities.values():
		if reset_cooldowns:
			runtime.reset_runtime()
		else:
			runtime.deactivate()
	was_supported = false

func _on_profile_changed() -> void:
	refresh_from_profile()

func _create_runtime(ability_id: StringName):
	match ability_id:
		&"jump":
			return JUMP_SCRIPT.new()
		&"climb":
			return CLIMB_SCRIPT.new()
		&"glide":
			return GLIDE_SCRIPT.new()
		&"reverse_gravity":
			return REVERSE_GRAVITY_SCRIPT.new()
		&"fly":
			return FLY_SCRIPT.new()
		&"dash":
			return DASH_SCRIPT.new()
		&"explode":
			return EXPLODE_SCRIPT.new()
		&"slow_down_time":
			return SLOW_DOWN_TIME_SCRIPT.new()
		&"invisibility":
			return INVISIBILITY_SCRIPT.new()
		_:
			# Shooting is a passive unlock consumed by WeaponController rather than
			# an activatable runtime ability.
			return null
