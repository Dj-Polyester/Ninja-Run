class_name TouchGestureRouter
extends Control
## Converts raw touch gestures into the existing semantic mobile input actions.

signal action_requested(action_name: StringName)
## It never handles touches that begin over interactive UI controls.

@export var swipe_down_threshold: float = 72.0
@export var tap_max_distance: float = 28.0

var active_index: int = -1
var start_position := Vector2.ZERO
var current_position := Vector2.ZERO
var blocked_by_ui := false
var cancelled := false
var additional_touches := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag:
		handle_drag(event)

func handle_touch(event: InputEventScreenTouch) -> StringName:
	if event.pressed:
		if active_index >= 0 and event.index != active_index:
			additional_touches += 1
			cancelled = true
			return &""
		active_index = event.index
		start_position = event.position
		current_position = event.position
		blocked_by_ui = _point_hits_interactive_ui(event.position)
		cancelled = false
		additional_touches = 0
		return &""
	if event.index != active_index:
		additional_touches = maxi(0, additional_touches - 1)
		return &""
	current_position = event.position
	var action := &""
	if not cancelled and not blocked_by_ui:
		action = classify_gesture(start_position, current_position, tap_max_distance, swipe_down_threshold)
		if not action.is_empty():
			_emit_action(action)
	_reset_gesture()
	return action

func handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == active_index:
		current_position = event.position

func cancel_active() -> void:
	cancelled = true
	_reset_gesture()

func _reset_gesture() -> void:
	active_index = -1
	start_position = Vector2.ZERO
	current_position = Vector2.ZERO
	blocked_by_ui = false
	cancelled = false
	additional_touches = 0

static func classify_gesture(begin: Vector2, finish: Vector2, max_tap_distance: float, down_threshold: float) -> StringName:
	var delta := finish - begin
	if delta.length() <= maxf(0.0, max_tap_distance):
		return &"touch_tap_jump"
	if delta.y >= maxf(0.0, down_threshold) and absf(delta.y) > absf(delta.x):
		return &"touch_swipe_roll"
	return &""

func _emit_action(action_name: StringName) -> void:
	action_requested.emit(action_name)

func _point_hits_interactive_ui(point: Vector2) -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	for node in viewport.get_tree().get_nodes_in_group(&"touch_ui_blocker"):
		var control := node as Control
		if control != null and control.visible and control.is_inside_tree() and control.get_global_rect().has_point(point):
			return true
	return false
