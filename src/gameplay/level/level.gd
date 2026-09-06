extends Node2D

const SAFE_CHECKPOINT_SCRIPT := preload("res://src/gameplay/level/safe_checkpoint.gd")

@onready var world_streamer = $WorldStreamer
@onready var player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var health_bar: ProgressBar = $HUD/MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $HUD/MarginContainer/VBoxContainer/HealthLabel
@onready var distance_label: Label = $HUD/MarginContainer/VBoxContainer/DistanceLabel
@onready var biome_label: Label = $HUD/MarginContainer/VBoxContainer/BiomeLabel
@onready var game_over_panel: PanelContainer = $HUD/GameOverPanel
@onready var game_over_title: Label = $HUD/GameOverPanel/VBoxContainer/Title
@onready var game_over_reason: Label = $HUD/GameOverPanel/VBoxContainer/Reason
@onready var countdown_label: Label = $HUD/GameOverPanel/VBoxContainer/CountdownLabel
@onready var revive_button: Button = $HUD/GameOverPanel/VBoxContainer/ReviveButton
@onready var restart_button: Button = $HUD/GameOverPanel/VBoxContainer/RestartButton
@onready var menu_button: Button = $HUD/GameOverPanel/VBoxContainer/MenuButton
@onready var background: ColorRect = $BackgroundLayer/Background

var start_x := 0.0
var game_over_active := false
var revival_active := false
var final_game_over := false
var revival_countdown_remaining := 0.0
var revival_reason := ""
var current_biome_id := -1
var last_progress_x := 0.0
var stuck_elapsed := 0.0
var safe_checkpoint = SAFE_CHECKPOINT_SCRIPT.new()

func _ready() -> void:
	WorldSpeed.reset()
	GameState.reset_run()
	world_streamer.reset(int(GameState.run.seed))
	start_x = player.global_position.x
	last_progress_x = start_x
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)
	game_over_panel.visible = false
	_configure_revival_icon()
	apply_biome_for_tile(floori(GameConfig.pixels_to_tiles(player.global_position.x)))
	_capture_checkpoint(player.global_position, floori(GameConfig.pixels_to_tiles(player.global_position.x)))
	_update_hud()

func _process(delta: float) -> void:
	if not revival_active:
		return
	revival_countdown_remaining = maxf(0.0, revival_countdown_remaining - delta)
	GameState.set_revival_countdown(revival_countdown_remaining)
	_update_revival_panel()
	if revival_countdown_remaining <= 0.0:
		_finish_game_over()

func _physics_process(delta: float) -> void:
	if game_over_active:
		return
	world_streamer.update_for_player(player.global_position.x)
	apply_biome_for_tile(floori(GameConfig.pixels_to_tiles(player.global_position.x)))
	var distance := maxi(0, floori(GameConfig.pixels_to_tiles(player.global_position.x - start_x)))
	GameState.set_distance_tiles(distance)
	camera.global_position.x = player.global_position.x + GameConfig.tiles_to_pixels(GameConfig.CAMERA_LOOK_AHEAD)
	_update_safe_checkpoint()
	_update_stuck_detection(delta)
	_update_hud()

func apply_biome_for_tile(tile_x: int) -> void:
	var biome: BiomeData = world_streamer.biome_for_tile(tile_x)
	var jump_modifier: float = float(world_streamer.snow_jump_modifier_for_tile(tile_x))
	player.set_biome_context(biome, jump_modifier)
	if current_biome_id == biome.id:
		return
	current_biome_id = biome.id
	GameState.set_current_biome(biome.id)
	GameState.set_temporary_effect(&"snow_jump_modifier", jump_modifier if biome.id == BiomeData.Id.SNOW else null)
	background.color = biome.background_color
	biome_label.text = "Biome: %s" % biome.display_name

func _on_player_died(_reason: String) -> void:
	if game_over_active:
		return
	_begin_revival(_reason)

func _begin_revival(reason: String) -> void:
	game_over_active = true
	revival_active = true
	final_game_over = false
	revival_reason = reason
	revival_countdown_remaining = GameConfig.COUNTDOWN_SECS
	player.enter_revival_wait()
	_set_world_halted(true)
	GameState.begin_revival(reason, revival_countdown_remaining)
	game_over_panel.visible = true
	_update_revival_panel()

func _finish_game_over() -> void:
	if final_game_over:
		return
	revival_active = false
	final_game_over = true
	game_over_active = true
	GameState.end_run()
	game_over_title.text = "GAME OVER"
	game_over_reason.text = _reason_text(revival_reason)
	countdown_label.visible = false
	revive_button.visible = false
	restart_button.visible = true
	menu_button.visible = true
	game_over_panel.visible = true

func _on_revive_pressed() -> void:
	if not revival_active:
		return
	if not GameState.consume_revival_potion():
		_update_revival_panel()
		return
	var checkpoint_position: Vector2 = safe_checkpoint.position if safe_checkpoint.valid else Vector2(start_x, player.global_position.y)
	var checkpoint_tile: int = int(safe_checkpoint.tile_index) if safe_checkpoint.valid else floori(GameConfig.pixels_to_tiles(start_x))
	player.revive_at(checkpoint_position)
	apply_biome_for_tile(checkpoint_tile)
	GameState.finish_revival(player.current_health)
	revival_active = false
	final_game_over = false
	game_over_active = false
	revival_countdown_remaining = 0.0
	revival_reason = ""
	last_progress_x = player.global_position.x
	stuck_elapsed = 0.0
	_set_world_halted(false)
	game_over_panel.visible = false
	_update_hud()

func _update_stuck_detection(delta: float) -> void:
	var threshold := GameConfig.tiles_to_pixels(GameConfig.STUCK_PROGRESS_THRESHOLD)
	if player.global_position.x >= last_progress_x + threshold:
		last_progress_x = player.global_position.x
		stuck_elapsed = 0.0
		return
	stuck_elapsed += delta
	if stuck_elapsed >= GameConfig.GAME_OVER_NUMBER_OF_SECS:
		player.die("stuck")

func _update_safe_checkpoint() -> void:
	if not player.is_on_floor() or player.current_health <= 0.0:
		return
	if player.invulnerability_remaining > 0.0 or not player.active_statuses.is_empty():
		return
	var tile_x := floori(GameConfig.pixels_to_tiles(player.global_position.x))
	if safe_checkpoint.valid and tile_x < safe_checkpoint.tile_index + int(ceil(GameConfig.SAFE_CHECKPOINT_INTERVAL_TILES)):
		return
	_capture_checkpoint(player.global_position, tile_x)

func _capture_checkpoint(position: Vector2, tile_x: int) -> void:
	var biome := world_streamer.biome_for_tile(tile_x) as BiomeData
	var biome_id := biome.id if biome != null else BiomeData.Id.GRASS
	safe_checkpoint.capture(position, biome_id, tile_x)
	GameState.set_safe_checkpoint(safe_checkpoint.to_dictionary())

func _set_world_halted(halted: bool) -> void:
	var mode := Node.PROCESS_MODE_DISABLED if halted else Node.PROCESS_MODE_INHERIT
	for node in [world_streamer, $EnemyContainer, $ProjectileContainer, $PickupContainer, $Effects]:
		node.process_mode = mode

func _update_revival_panel() -> void:
	game_over_title.text = "REVIVAL"
	game_over_reason.text = "%s\nUse a potion to return to the last safe checkpoint." % _reason_text(revival_reason)
	countdown_label.text = "Run ends in %d" % maxi(0, ceili(revival_countdown_remaining))
	countdown_label.visible = true
	var potion_count := GameState.revival_potion_count()
	revive_button.text = "REVIVE  ×%d" % potion_count
	revive_button.visible = potion_count > 0
	revive_button.disabled = potion_count <= 0
	restart_button.visible = false
	menu_button.visible = false

func _reason_text(reason: String) -> String:
	match reason:
		"fall":
			return "You fell below the world."
		"stuck":
			return "No forward progress for %.1f seconds." % GameConfig.GAME_OVER_NUMBER_OF_SECS
		"damage":
			return "Your health reached zero."
		_:
			return "The run ended."

func _configure_revival_icon() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var texture := load("res://assets/Consumables/revival_potion.png") as Texture2D
	if texture != null:
		revive_button.icon = texture

func _update_hud() -> void:
	health_bar.max_value = player.maximum_health
	health_bar.value = player.current_health
	health_label.text = "Health: %d / %d" % [roundi(player.current_health), roundi(player.maximum_health)]
	distance_label.text = "Distance: %d tiles" % int(GameState.run.get("distance_tiles", 0))

func _on_health_changed(_current: float, _maximum: float) -> void:
	_update_hud()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
