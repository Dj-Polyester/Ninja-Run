class_name MobileActionControls
extends Control

@onready var touch_input_adapter: TouchInputAdapter = $TouchInputAdapter
@onready var action_cluster: VBoxContainer = $ActionCluster

var input_router

func _ready() -> void:
	visible = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	if not GameState.profile_changed.is_connected(_on_profile_changed):
		GameState.profile_changed.connect(_on_profile_changed)
	_apply_action_button_side()

func _exit_tree() -> void:
	if input_router != null and input_router.ability_slots_changed.is_connected(_refresh_buttons):
		input_router.ability_slots_changed.disconnect(_refresh_buttons)
	if GameState.profile_changed.is_connected(_on_profile_changed):
		GameState.profile_changed.disconnect(_on_profile_changed)

func configure(router) -> void:
	if input_router != null and input_router.ability_slots_changed.is_connected(_refresh_buttons):
		input_router.ability_slots_changed.disconnect(_refresh_buttons)
	input_router = router
	touch_input_adapter.configure(router)
	if input_router != null and not input_router.ability_slots_changed.is_connected(_refresh_buttons):
		input_router.ability_slots_changed.connect(_refresh_buttons)
	_refresh_buttons()
	_apply_action_button_side()

func _refresh_buttons() -> void:
	for child in action_cluster.get_children():
		action_cluster.remove_child(child)
		child.queue_free()
	if input_router == null:
		return
	for slot in input_router.mobile_button_slots():
		var button := Button.new()
		button.name = "Ability%dButton" % (slot + 1)
		button.text = "%d  %s" % [slot + 1, input_router.ability_display_name_for_slot(slot)]
		button.custom_minimum_size = Vector2(GameConfig.MOBILE_ACTION_BUTTON_WIDTH, GameConfig.MOBILE_ACTION_BUTTON_HEIGHT)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_ability_button_pressed.bind(slot))
		action_cluster.add_child(button)

func _apply_action_button_side() -> void:
	if action_cluster == null:
		return
	var side := GameState.action_button_side()
	action_cluster.anchor_top = 1.0
	action_cluster.anchor_bottom = 1.0
	action_cluster.offset_top = -GameConfig.MOBILE_ACTION_BUTTON_CLUSTER_HEIGHT
	action_cluster.offset_bottom = -GameConfig.MOBILE_ACTION_BUTTON_MARGIN
	if side == PlayerProfile.ACTION_BUTTON_SIDE_LEFT:
		action_cluster.anchor_left = 0.0
		action_cluster.anchor_right = 0.0
		action_cluster.offset_left = GameConfig.MOBILE_ACTION_BUTTON_MARGIN
		action_cluster.offset_right = GameConfig.MOBILE_ACTION_BUTTON_MARGIN + GameConfig.MOBILE_ACTION_BUTTON_WIDTH
	else:
		action_cluster.anchor_left = 1.0
		action_cluster.anchor_right = 1.0
		action_cluster.offset_left = -GameConfig.MOBILE_ACTION_BUTTON_MARGIN - GameConfig.MOBILE_ACTION_BUTTON_WIDTH
		action_cluster.offset_right = -GameConfig.MOBILE_ACTION_BUTTON_MARGIN

func _on_profile_changed() -> void:
	_apply_action_button_side()
	_refresh_buttons()

func _on_ability_button_pressed(slot: int) -> void:
	if input_router != null:
		input_router.press_ability_slot(slot)
