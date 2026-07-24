extends Node2D

var distance := -20.0
var duration := .5
var wait_time := 1

@onready var spikes = $Sprite2D
var spikey = true
var start_pos: Vector2

func _ready():
	start_pos = spikes.position

	var tween = create_tween()
	tween.set_loops() # Infinite

	tween.tween_callback(func():
		spikey = true
	)

	tween.tween_property(
		spikes,
		"position",
		start_pos + Vector2(0, distance),
		duration
	)

	tween.tween_property(
		spikes,
		"position",
		start_pos,
		duration
	)
	
	tween.tween_callback(func():
		spikey = false
	)

	tween.tween_interval(1.0)