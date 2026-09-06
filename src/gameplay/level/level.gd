extends Node2D

@onready var world_streamer = $WorldStreamer
@onready var player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var health_bar: ProgressBar = $HUD/MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $HUD/MarginContainer/VBoxContainer/HealthLabel
@onready var distance_label: Label = $HUD/MarginContainer/VBoxContainer/DistanceLabel
@onready var biome_label: Label = $HUD/MarginContainer/VBoxContainer/BiomeLabel
@onready var game_over_panel: PanelContainer = $HUD/GameOverPanel
@onready var background: ColorRect = $BackgroundLayer/Background

var start_x := 0.0
var game_over_active := false
var current_biome_id := -1

func _ready() -> void:
	GameState.reset_run()
	world_streamer.reset(int(GameState.run.seed))
	start_x = player.global_position.x
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)
	game_over_panel.visible = false
	apply_biome_for_tile(floori(GameConfig.pixels_to_tiles(player.global_position.x)))
	_update_hud()

func _physics_process(_delta: float) -> void:
	if game_over_active:
		return
	world_streamer.update_for_player(player.global_position.x)
	apply_biome_for_tile(floori(GameConfig.pixels_to_tiles(player.global_position.x)))
	var distance := maxi(0, floori(GameConfig.pixels_to_tiles(player.global_position.x - start_x)))
	GameState.set_distance_tiles(distance)
	camera.global_position.x = player.global_position.x + GameConfig.tiles_to_pixels(GameConfig.CAMERA_LOOK_AHEAD)
	_update_hud()

func apply_biome_for_tile(tile_x: int) -> void:
	var biome: BiomeData = world_streamer.biome_for_tile(tile_x)
	var jump_modifier: float = float(world_streamer.snow_jump_modifier_for_tile(tile_x))
	player.set_biome_context(biome, jump_modifier)
	if current_biome_id == biome.id:
		return
	current_biome_id = biome.id
	background.color = biome.background_color
	biome_label.text = "Biome: %s" % biome.display_name

func _on_player_died(_reason: String) -> void:
	if game_over_active:
		return
	game_over_active = true
	GameState.end_run()
	game_over_panel.visible = true

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
