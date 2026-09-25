class_name Level
extends Node2D
## M2 orchestration: one transient run per Level; RunSession owns the in-memory profile.

signal ability_activation_requested(slot: int, ability_id: StringName)

const Director = preload("res://scripts/models/run_director.gd")
const EnemySpawnerRuntime = preload("res://scripts/enemies/enemy_spawner.gd")
const EnemyControllerRuntime = preload("res://scripts/enemies/enemy_controller.gd")
const CollectibleSpawnerRuntime = preload("res://scripts/collectibles/collectible_spawner.gd")
const WeaponControllerRuntime = preload("res://scripts/weapons/weapon_controller.gd")
const AbilityActionRouterRuntime = preload("res://scripts/abilities/ability_action_router.gd")
const AbilityCooldownStateRuntime = preload("res://scripts/abilities/ability_cooldown_state.gd")
const CharacterCatalogRuntime = preload("res://scripts/characters/character_catalog.gd")
var director = Director.new()
var profile: ProfileState
var _last_player_x := 0.0
var hazard_simulation_time := 0.0
var ability_cooldowns := AbilityCooldownStateRuntime.new()
var slow_down_until := -INF
var invisibility_until := -INF
var _ability_map_signature := ""
var _mobile_button_signature := ""
@export var use_flat_fixture := false
@export var enemies_enabled := true
@export var collectibles_enabled := true
@export var weapons_enabled := true
var terrain_seed_override := 0

@onready var player: PlayerController = $Player
@onready var camera: Camera2D = $Camera2D
@onready var health_bar: ProgressBar = %HealthBar
@onready var gold_label: Label = %GoldLabel
@onready var potion_count: Label = %PotionCount
@onready var distance_label: Label = %DistanceLabel
@onready var state_overlay: Label = %StateOverlay
@onready var ability_map: VBoxContainer = %AbilityMap
@onready var revive_button: Button = %ReviveButton
@onready var mobile_buttons: VBoxContainer = %MobileButtons
@onready var touch_gesture_router = $CanvasLayer/TouchGestureRouter
@onready var terrain_streamer: TerrainStreamer = $TerrainStreamer
@onready var enemy_spawner: EnemySpawnerRuntime = $EnemySpawner
@onready var collectible_spawner: CollectibleSpawnerRuntime = $CollectibleSpawner
@onready var weapon_controller: WeaponControllerRuntime = $WeaponController

func _ready() -> void:
	profile = get_node("/root/RunSession").profile as ProfileState
	if not director.apply_profile_stats(profile):
		push_error("Profile stats are invalid; Level cannot start a run.")
		player.set_runner_active(false)
		set_physics_process(false)
		return
	var character = CharacterCatalogRuntime.by_id(profile.selected_character)
	if character == null or not player.apply_character_frames(character.sprite_frames_path):
		push_error("Selected character asset could not be applied.")
		player.set_runner_active(false)
		set_physics_process(false)
		return
	if director.seed == 0:
		var session := get_node("/root/RunSession")
		director.seed = terrain_seed_override if terrain_seed_override != 0 else session.acquire_production_run_seed()
	player.configure_jump_randomness(director.seed, _takeoff_support_material)
	player.configure_abilities(profile, ability_cooldowns, func() -> float: return director.simulation_time)
	player.set_movement_modifier_resolver(_player_movement_multiplier)
	player.set_appearance_state_resolver(_player_appearance_state)
	terrain_streamer.set_hazard_target(player)
	terrain_streamer.set_astro_contact_enabled(director.state == Director.State.RUNNING)
	terrain_streamer.hazard_damage_requested.connect(_on_hazard_damage_requested)
	if use_flat_fixture:
		_create_flat_fixture()
	else:
		if not terrain_streamer.setup(GameConfig.terrain_snapshot(), director.seed):
			push_error("Terrain configuration rejected; production Level cannot enter with invalid terrain.")
			player.set_runner_active(false)
			set_physics_process(false)
			return
		terrain_streamer.reconcile(player.global_position, get_viewport_rect().size.x)
		var start_surfaces := terrain_streamer.surface_candidates(player.global_position, false, 2)
		if not start_surfaces.is_empty():
			var initial := terrain_streamer.world_position_on_surface(start_surfaces[0], terrain_streamer.world_to_column(player.global_position.x))
			# The Level scene declares the run origin; generation is centered so this
			# assignment preserves it exactly while snapping only to valid support Y.
			player.global_position = Vector2(GameConfig.RUN_ORIGIN_X, initial.y)
	if enemies_enabled:
		enemy_spawner.configure(terrain_streamer, player, director, camera, profile.enemy_fire_interval_multiplier, func() -> bool: return not is_invisible(), _current_enemy_interval_multiplier)
	else:
		enemy_spawner.set_physics_process(false)
	if collectibles_enabled:
		collectible_spawner.configure(terrain_streamer, player, director, enemy_spawner)
	else:
		collectible_spawner.set_physics_process(false)
	if weapons_enabled:
		weapon_controller.configure(player, enemy_spawner, director, profile, camera)
	else:
		weapon_controller.set_physics_process(false)
	if not player.melee_proximity.is_connected(_on_player_melee_proximity):
		player.melee_proximity.connect(_on_player_melee_proximity)
	if not ability_activation_requested.is_connected(_on_ability_activation_requested):
		ability_activation_requested.connect(_on_ability_activation_requested)
	if touch_gesture_router != null and not touch_gesture_router.action_requested.is_connected(_on_mobile_action_requested):
		touch_gesture_router.action_requested.connect(_on_mobile_action_requested)
	director.safe_support = Vector2(player.global_position.x, GameConfig.TERRAIN_BASE_SURFACE_Y - 32.0) if use_flat_fixture else player.global_position
	director.initialize_progress(player.global_position, director.now())
	_last_player_x = player.global_position.x
	director.set_support_query(_resolve_safe_support)
	director.state_changed.connect(_on_state_changed)
	director.hud_changed.connect(_update_hud)
	director.revived.connect(_revive_player)
	director.damage_landed.connect(func() -> void: player.apply_damage_feedback(player.simulation_time))
	profile.changed.connect(_update_hud)
	for blocker_path in ["CanvasLayer/ReviveButton", "CanvasLayer/Restart", "CanvasLayer/Return"]:
		var blocker := get_node_or_null(blocker_path) as Control
		if blocker != null:
			blocker.add_to_group(&"touch_ui_blocker")
	_update_hud()

func _physics_process(delta: float) -> void:
	var now := director.now()
	director.tick(now)
	var running: bool = director.state == Director.State.RUNNING
	player.set_runner_active(running)
	if running:
		if not use_flat_fixture:
			terrain_streamer.reconcile(player.global_position, get_viewport_rect().size.x)
		var progress := maxf(0.0, player.global_position.x - _last_player_x)
		if progress > 0.0:
			director.run.advance_distance(progress / GameConfig.TILE_SIZE)
		director.record_progress(player.global_position, now)
		if player.is_on_floor() and _is_valid_support_position(player.global_position):
			director.record_checkpoint(player.global_position)
		if player.global_position.y > 1000.0:
			director.fail_fall_at(player.global_position, now)
	# Progress/fall can have transitioned the Director during this same frame.
	# Re-read it before hazard contact/phase advancement rather than using the
	# entry-state snapshot.
	running = director.state == Director.State.RUNNING
	if running:
		director.advance_simulation(delta)
		hazard_simulation_time = director.simulation_time # M3 public compatibility alias.
	# A periodic status can be lethal. Re-read after advancing before any runtime
	# gets a final same-frame contact/motion opportunity.
	running = director.state == Director.State.RUNNING
	# Terrain hazards advance strictly on this run-local simulation time. A
	# countdown/game-over frame can neither change phase nor consume cadence.
	terrain_streamer.tick_hazards(hazard_simulation_time, running)
	_last_player_x = player.global_position.x
	camera.global_position = Vector2(player.global_position.x, 360.0)
	_update_hud()

func _is_valid_support_position(candidate: Vector2) -> bool:
	if candidate.y >= 1000.0:
		return false
	var space := get_world_2d().direct_space_state
	var clearance := PhysicsShapeQueryParameters2D.new()
	clearance.shape = player.standing_shape.shape
	# Lift the support-validation pose one pixel so a resting floor contact does
	# not count as blocked standing clearance.
	clearance.transform = Transform2D(0.0, candidate + Vector2(0, -1.0))
	clearance.collision_mask = player.collision_mask
	clearance.exclude = [player.get_rid()]
	if not space.intersect_shape(clearance, 1).is_empty():
		return false
	var sweep := PhysicsShapeQueryParameters2D.new()
	sweep.shape = player.standing_shape.shape
	# Sweep the full standing shape over a contiguous forward tile.  Sampling a
	# second pose can miss a thin wall between candidate and destination.
	sweep.transform = Transform2D(0.0, candidate + Vector2(0, -1.0))
	sweep.motion = Vector2(GameConfig.TILE_SIZE, 0)
	sweep.collision_mask = player.collision_mask
	sweep.exclude = [player.get_rid()]
	var motion_result := space.cast_motion(sweep)
	if motion_result.size() != 2 or motion_result[0] < 1.0:
		return false
	var support_ray := PhysicsRayQueryParameters2D.create(candidate + Vector2(0, 28), candidate + Vector2(0, 40), player.collision_mask, [player.get_rid()])
	var result := space.intersect_ray(support_ray)
	var collider := result.get("collider") as Node
	if collider == null or not collider.is_in_group(&"terrain_support"):
		return false
	if use_flat_fixture:
		return true
	# Physical contact alone is insufficient: a stable Astro tile can be walked
	# on but is deliberately never a durable revival destination, and live
	# Desert/Fort regions cannot receive a recovery placement.
	var standing := player.standing_shape.shape as RectangleShape2D
	var half_extents := standing.size * 0.5 if standing != null else Vector2(18.0, 28.0)
	if not terrain_streamer.is_safe_recovery_pose(candidate, half_extents):
		return false
	# A physically lingering body is not a recovery candidate after streaming has
	# marked it stale. This prevents a potion from trusting queue_free-pending
	# collision or a support that is about to be removed.
	var surface_id: StringName = collider.get_meta(&"terrain_surface_id", &"")
	var surface := terrain_streamer.surface_registry.get(surface_id) as TerrainSurface
	return surface != null and terrain_streamer.is_surface_live(surface)

func _takeoff_support_material() -> StringName:
	# This ray reads the physical body currently supporting the player's feet.
	# It never derives material from camera, checkpoint, or recovery state.
	var feet := player.global_position + Vector2(0.0, 24.0)
	var query := PhysicsRayQueryParameters2D.create(feet, feet + Vector2(0.0, 20.0), player.collision_mask, [player.get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	var collider := hit.get("collider") as Node
	if collider != null and collider.is_in_group(&"terrain_support"):
		return StringName(collider.get_meta(&"terrain_material", &"grass"))
	return &"grass"

func is_slow_down_active() -> bool:
	return director != null and director.simulation_time < slow_down_until

func is_invisible() -> bool:
	return director != null and director.simulation_time < invisibility_until

func _player_movement_multiplier() -> float:
	var multiplier: float = float(director.run.health_owner.movement_multiplier(director.simulation_time))
	if is_slow_down_active():
		multiplier *= GameConfig.MIN_SLOWDOWN_SPEED_MULTIPLIER
	return clampf(multiplier, GameConfig.MIN_SLOWDOWN_SPEED_MULTIPLIER, 1.0)

func _current_enemy_interval_multiplier() -> float:
	var multiplier: float = profile.enemy_fire_interval_multiplier if profile != null else GameConfig.DEFAULT_ENEMY_FIRE_RATE
	if is_slow_down_active():
		multiplier *= GameConfig.SLOW_DOWN_ENEMY_INTERVAL_MULTIPLIER
	return clampf(multiplier, GameConfig.MIN_ENEMY_FIRE_RATE, GameConfig.MAX_RUNTIME_ENEMY_INTERVAL_MULTIPLIER)

func _player_appearance_state(_simulation_seconds: float) -> Dictionary:
	# Status storage is generic; appearance is content data. Blood has priority
	# over freeze here, while PlayerController gives direct damage feedback first.
	var has_blood := false
	var has_freeze := false
	for status: DamageStatus.TimedStatus in director.run.health_owner.statuses.values():
		if not status.is_active(director.simulation_time):
			continue
		has_blood = has_blood or status.appearance == &"blood"
		has_freeze = has_freeze or status.appearance == &"freeze"
	return {&"blood": has_blood, &"freeze": has_freeze}

func _resolve_safe_support(candidate: Vector2, context: Dictionary = {}) -> Variant:
	var failure_position: Vector2 = context.get(&"position", candidate)
	var stuck: bool = context.get(&"reason", Director.FailureReason.NONE) == Director.FailureReason.STUCK
	if not stuck and _is_valid_support_position(candidate):
		return candidate
	# A stuck runner must search from the physical failure point, not revive at
	# the last checkpoint behind its blocker.  Only non-stuck recovery may fall
	# back to that checkpoint after forward alternatives are exhausted.
	var forward_origin := failure_position
	if use_flat_fixture:
		var flat_origins: Array[Vector2] = []
		if stuck:
			flat_origins.append(failure_position)
		else:
			flat_origins.append(candidate)
			flat_origins.append(failure_position)
		for origin in flat_origins:
			for offset in range(0 if not stuck else 1, 25):
				var fallback := Vector2(origin.x + offset * GameConfig.TILE_SIZE, candidate.y)
				if (not stuck or fallback.x > failure_position.x + GameConfig.STUCK_PROGRESS_EPSILON) and _is_valid_support_position(fallback):
					return fallback
				if not stuck and offset > 0:
					fallback.x = origin.x - offset * GameConfig.TILE_SIZE
					if _is_valid_support_position(fallback):
						return fallback
		return null
	# Query the registry only: recovery never creates a chunk or trusts collision
	# that was synchronized during this query.
	var max_columns := terrain_streamer.recovery_max_columns()
	var origins: Array[Vector2] = []
	if stuck:
		origins.append(forward_origin)
	else:
		origins.append(candidate)
		origins.append(failure_position)
	var seen_surfaces: Dictionary = {}
	for origin in origins:
		for surface in terrain_streamer.surface_candidates(origin, stuck, max_columns):
			if seen_surfaces.has(surface.id) or not terrain_streamer.is_surface_live(surface):
				continue
			seen_surfaces[surface.id] = true
			var preferred_column := terrain_streamer.world_to_column(origin.x)
			for column in _ordered_surface_columns(surface, preferred_column, stuck):
				var fallback := terrain_streamer.world_position_on_surface(surface, column)
				if (not stuck or fallback.x > failure_position.x + GameConfig.STUCK_PROGRESS_EPSILON) and _is_valid_support_position(fallback):
					return fallback
	return null

func _ordered_surface_columns(surface: TerrainSurface, preferred_column: int, forward_only: bool) -> Array[int]:
	var result: Array[int] = []
	if forward_only:
		for column in range(maxi(surface.x_begin, preferred_column + 1), surface.x_end):
			result.append(column)
		return result
	var center := clampi(preferred_column, surface.x_begin, surface.x_end - 1)
	result.append(center)
	for distance in range(1, surface.x_end - surface.x_begin):
		var forward := center + distance
		var backward := center - distance
		if forward < surface.x_end:
			result.append(forward)
		if backward >= surface.x_begin:
			result.append(backward)
	return result

func _create_flat_fixture() -> void:
	if has_node("Floor"):
		return
	var floor := StaticBody2D.new()
	floor.name = &"Floor"
	floor.position = Vector2(1800, 620)
	floor.add_to_group(&"terrain_support")
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4000, 40)
	collision.shape = shape
	floor.add_child(collision)
	add_child(floor)

func request_revival() -> bool:
	return director.revive(profile, director.now())

func _commit_run_rewards() -> int:
	var session := get_node_or_null("/root/RunSession")
	if session == null:
		return 0
	return int(session.commit_run_rewards(director.run))

func request_restart() -> void:
	_commit_run_rewards()
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func request_return_to_menu() -> void:
	_commit_run_rewards()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _revive_player() -> void:
	player.global_position = director.safe_support
	player.reset_for_revival()
	player.set_runner_active(true)
	_last_player_x = player.global_position.x

func _on_ability_activation_requested(_slot: int, ability_id: StringName) -> void:
	activate_ability(ability_id)

func activate_ability(ability_id: StringName) -> bool:
	if director.state != Director.State.RUNNING or profile == null:
		return false
	match ability_id:
		&"dash":
			return player.request_dash()
		&"shooting":
			return weapon_controller.activate_shooting()
		&"explode":
			if not ability_cooldowns.commit_activation(ability_id, director.simulation_time, profile):
				return false
			_execute_explode()
			return true
		&"slow_down_time":
			if not ability_cooldowns.commit_activation(ability_id, director.simulation_time, profile):
				return false
			slow_down_until = maxf(slow_down_until, director.simulation_time + profile.active_slow_down_duration())
			return slow_down_until > director.simulation_time
		&"invisibility":
			if not ability_cooldowns.commit_activation(ability_id, director.simulation_time, profile):
				return false
			invisibility_until = maxf(invisibility_until, director.simulation_time + profile.active_invisibility_duration())
			return invisibility_until > director.simulation_time
	return false

func _execute_explode() -> void:
	var radius_pixels := GameConfig.EXPLODE_RADIUS * GameConfig.TILE_SIZE
	for enemy_variant in enemy_spawner.active.values().duplicate():
		var enemy := enemy_variant as EnemyControllerRuntime
		if enemy == null or not is_instance_valid(enemy) or enemy.dead or enemy.retired:
			continue
		if enemy.global_position.distance_to(player.global_position) <= radius_pixels:
			enemy.apply_damage(GameConfig.EXPLODE_DAMAGE)
	if is_instance_valid(terrain_streamer):
		terrain_streamer.break_tiles_in_radius(player.global_position, GameConfig.EXPLODE_RADIUS)

func _on_player_melee_proximity(target_node: Node2D) -> void:
	if director.state != Director.State.RUNNING or profile == null:
		return
	var enemy := target_node as EnemyControllerRuntime
	if enemy == null or not is_instance_valid(enemy):
		return
	enemy.receive_player_melee(float(profile.melee_power), director.simulation_time)

func _on_hazard_damage_requested(event: DamageStatus.DamageEvent) -> void:
	# Hazards publish intent only; Director applies defense/protection and owns
	# health state transitions.
	director.apply_damage(event, director.now())

func _on_state_changed(new_state: int) -> void:
	if is_instance_valid(player):
		player.set_runner_active(new_state == Director.State.RUNNING)
	if is_instance_valid(terrain_streamer):
		terrain_streamer.set_astro_contact_enabled(new_state == Director.State.RUNNING)
	_update_hud()

func _update_hud() -> void:
	if profile == null:
		return
	var owner: DamageStatus.HealthOwner = director.run.health_owner
	health_bar.max_value = owner.maximum_health
	health_bar.value = owner.current_health
	gold_label.text = "Gold: %d" % (profile.gold + director.run.earned_gold)
	potion_count.text = "x%d" % profile.revival_potions
	distance_label.text = "Tiles: %d" % floori(director.run.distance_tiles)
	if director.state == Director.State.REVIVAL_COUNTDOWN:
		var remaining := maxi(0, ceili(director.run.countdown_deadline - director.now()))
		state_overlay.text = "REVIVE? %ds remaining" % remaining
		revive_button.visible = true
		revive_button.disabled = profile.revival_potions <= 0
		revive_button.text = "Use Revival Potion (x%d)" % profile.revival_potions
	elif director.state == Director.State.GAME_OVER:
		state_overlay.text = "GAME OVER — Restart or Return"
		revive_button.visible = false
	else:
		state_overlay.text = ""
		revive_button.visible = false
	_update_ability_mapping()
	_update_mobile_buttons()

func _update_ability_mapping() -> void:
	if ability_map == null or profile == null:
		return
	var equipped := AbilityActionRouterRuntime.auxiliary_equipped(profile)
	var names := PackedStringArray()
	for ability_id: StringName in equipped:
		names.append(String(ability_id))
	var signature := ",".join(names)
	if signature == _ability_map_signature:
		return
	_ability_map_signature = signature
	for child in ability_map.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = "Abilities"
	ability_map.add_child(header)
	for slot in GameConfig.NUM_EQUIPABLE_ABILITIES:
		var label := Label.new()
		label.name = "AbilitySlot%d" % (slot + 1)
		label.text = "%d — %s" % [slot + 1, String(equipped[slot]).replace("_", " ").capitalize()] if slot < equipped.size() else "%d — Empty" % (slot + 1)
		ability_map.add_child(label)

func _update_mobile_buttons() -> void:
	if mobile_buttons == null or profile == null:
		return
	var equipped := AbilityActionRouterRuntime.auxiliary_equipped(profile)
	var names := PackedStringArray()
	for ability_id: StringName in equipped:
		names.append(String(ability_id))
	var signature := "%s|%s" % [",".join(names), String(profile.mobile_auxiliary_button_corner)]
	if signature != _mobile_button_signature:
		_mobile_button_signature = signature
		for child in mobile_buttons.get_children():
			mobile_buttons.remove_child(child)
			child.queue_free()
		for slot in mini(equipped.size(), GameConfig.NUM_EQUIPABLE_ABILITIES):
			var button := Button.new()
			button.name = "MobileAbility%d" % (slot + 1)
			button.custom_minimum_size = Vector2(180, 46)
			button.set_meta(&"slot", slot)
			button.set_meta(&"ability_id", equipped[slot])
			button.add_to_group(&"touch_ui_blocker")
			button.pressed.connect(func(index := slot) -> void: _emit_mobile_ability_input(index))
			mobile_buttons.add_child(button)
		_apply_mobile_button_corner()
	for child in mobile_buttons.get_children():
		var button := child as Button
		if button == null:
			continue
		var ability_id := StringName(button.get_meta(&"ability_id", &""))
		var remaining := ability_cooldowns.remaining(ability_id, director.simulation_time, profile)
		button.disabled = director.state != Director.State.RUNNING or remaining > 0.001
		var label := String(ability_id).replace("_", " ").capitalize()
		button.text = "%s  %.1fs" % [label, remaining] if remaining > 0.001 else label

func _apply_mobile_button_corner() -> void:
	if mobile_buttons == null or profile == null:
		return
	mobile_buttons.anchor_top = 1.0
	mobile_buttons.anchor_bottom = 1.0
	if profile.mobile_auxiliary_button_corner == &"bottom_left":
		mobile_buttons.anchor_left = 0.0
		mobile_buttons.anchor_right = 0.0
		mobile_buttons.offset_left = 16.0
		mobile_buttons.offset_right = 196.0
	else:
		mobile_buttons.anchor_left = 1.0
		mobile_buttons.anchor_right = 1.0
		mobile_buttons.offset_left = -196.0
		mobile_buttons.offset_right = -16.0
	mobile_buttons.offset_top = -220.0
	mobile_buttons.offset_bottom = -20.0

func _emit_mobile_ability_input(slot: int) -> void:
	_on_mobile_action_requested(ActionDispatch.mobile_ability_input(slot))

func _on_mobile_action_requested(action_name: StringName) -> void:
	var semantic := ActionDispatch.from_input(action_name)
	if semantic == ActionDispatch.Action.JUMP:
		player.dispatch_input_action(action_name, true)
		player.dispatch_input_action(action_name, false)
		return
	if semantic == ActionDispatch.Action.ROLL:
		player.dispatch_input_action(action_name, true)
		return
	var slot := ActionDispatch.ability_slot(semantic)
	if slot >= 0:
		request_ability_slot(slot)

func request_ability_slot(slot: int) -> StringName:
	if director.state != Director.State.RUNNING or profile == null:
		return &""
	var ability_id := AbilityActionRouterRuntime.ability_for_slot(profile, slot)
	if ability_id.is_empty():
		return &""
	ability_activation_requested.emit(slot, ability_id)
	return ability_id

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") or (event is InputEventKey and event.keycode == KEY_R):
		request_revival()
	if event.is_action_pressed(&"ui_cancel"):
		request_return_to_menu()
	for slot in GameConfig.NUM_EQUIPABLE_ABILITIES:
		if event.is_action_pressed(ActionDispatch.desktop_ability_input(slot)) or event.is_action_pressed(ActionDispatch.mobile_ability_input(slot)):
			request_ability_slot(slot)
			break

func _on_revive_pressed() -> void:
	request_revival()

func _on_restart_pressed() -> void:
	request_restart()

func _on_return_pressed() -> void:
	request_return_to_menu()
