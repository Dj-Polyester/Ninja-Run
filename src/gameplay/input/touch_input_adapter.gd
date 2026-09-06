class_name TouchInputAdapter
extends Node

signal gesture_recognized(action: StringName)

var input_router
var active_touch_index := -1
var touch_start := Vector2.ZERO
var touch_position := Vector2.ZERO
var gesture_consumed := false
var touch_elapsed := 0.0
var jump_pressed := false

func configure(router) -> void:
	if jump_pressed and input_router != null:
		input_router.release_jump()
	input_router = router
	reset_gesture()

func _process(delta: float) -> void:
	if input_router == null or active_touch_index < 0 or gesture_consumed or jump_pressed:
		return
	touch_elapsed += maxf(0.0, delta)
	if touch_elapsed < GameConfig.MOBILE_JUMP_HOLD_DELAY:
		return
	if (touch_position - touch_start).length() > GameConfig.MOBILE_TAP_MAX_DISTANCE:
		return
	jump_pressed = true
	input_router.press_jump()
	gesture_recognized.emit(&"jump")

func _unhandled_input(event: InputEvent) -> void:
	if handle_touch_event(event):
		get_viewport().set_input_as_handled()

func handle_touch_event(event: InputEvent) -> bool:
	if input_router == null:
		return false
	if event is InputEventScreenTouch:
		return _handle_screen_touch(event)
	if event is InputEventScreenDrag:
		return _handle_screen_drag(event)
	return false

func reset_gesture() -> void:
	active_touch_index = -1
	touch_start = Vector2.ZERO
	touch_position = Vector2.ZERO
	gesture_consumed = false
	touch_elapsed = 0.0
	jump_pressed = false

func _handle_screen_touch(event: InputEventScreenTouch) -> bool:
	if event.pressed:
		if active_touch_index >= 0:
			return false
		active_touch_index = event.index
		touch_start = event.position
		touch_position = event.position
		gesture_consumed = false
		touch_elapsed = 0.0
		jump_pressed = false
		return true

	if event.index != active_touch_index:
		return false
	touch_position = event.position
	if jump_pressed:
		input_router.release_jump()
	elif not gesture_consumed:
		var displacement := touch_position - touch_start
		if displacement.length() <= GameConfig.MOBILE_TAP_MAX_DISTANCE:
			input_router.press_jump()
			input_router.release_jump()
			gesture_recognized.emit(&"jump")
	reset_gesture()
	return true

func _handle_screen_drag(event: InputEventScreenDrag) -> bool:
	if event.index != active_touch_index:
		return false
	touch_position = event.position
	if gesture_consumed or jump_pressed:
		return true
	var displacement := touch_position - touch_start
	var vertical := displacement.y
	var horizontal := absf(displacement.x)
	if vertical >= GameConfig.MOBILE_SWIPE_MIN_DISTANCE and vertical >= horizontal * GameConfig.MOBILE_SWIPE_DIRECTION_RATIO:
		gesture_consumed = true
		input_router.press_roll()
		gesture_recognized.emit(&"roll")
	return true
