class_name MainMenu
extends Control

signal start_requested

const ProfileShopRuntime = preload("res://scripts/models/profile_shop.gd")

@onready var _status_label: Label = %StatusLabel
@onready var _profile_summary: Label = %ProfileSummary
var profile: ProfileState

func _ready() -> void:
	ActionDispatch.ensure_input_actions(GameConfig.NUM_EQUIPABLE_ABILITIES)
	profile = get_node("/root/RunSession").profile as ProfileState
	if profile != null and not profile.changed.is_connected(_refresh_profile):
		profile.changed.connect(_refresh_profile)
	_refresh_profile()
	_status_label.text = "Ready."

func _exit_tree() -> void:
	if profile != null and profile.changed.is_connected(_refresh_profile):
		profile.changed.disconnect(_refresh_profile)

func _refresh_profile() -> void:
	if profile == null or _profile_summary == null:
		return
	_profile_summary.text = "Gold: %d   Revival potions: %d   Character: %s" % [profile.gold, profile.revival_potions, String(profile.selected_character)]

func _on_start_run_pressed() -> void:
	start_requested.emit()
	_status_label.text = "Start requested."
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)

func _on_characters_pressed() -> void:
	_go("res://scenes/character_screen.tscn")

func _on_stats_pressed() -> void:
	_go("res://scenes/stats_screen.tscn")

func _on_abilities_pressed() -> void:
	_go("res://scenes/abilities_screen.tscn")

func _on_weapons_pressed() -> void:
	_go("res://scenes/weapons_screen.tscn")

func _on_settings_pressed() -> void:
	_go("res://scenes/settings_screen.tscn")

func _on_buy_potion_pressed() -> void:
	if profile == null:
		return
	if ProfileShopRuntime.purchase_revival_potion(profile):
		_status_label.text = "Revival potion purchased for %d gold." % GameConfig.REVIVAL_POTION_GOLDS
	else:
		_status_label.text = "Not enough gold for a revival potion."
