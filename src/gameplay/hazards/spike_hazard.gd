class_name SpikeHazard
extends Area2D

enum State { RETRACTED, RISING, EXPOSED, LOWERING }

var state := State.RETRACTED
var state_time := 0.0
var exposed_visual_y := -16.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("fort_spike_hazard")
	_configure_sprite()
	set_state(State.RETRACTED)

func set_state(next_state: State) -> void:
	state = next_state
	state_time = 0.0
	hitbox.disabled = state != State.EXPOSED
	_update_visual_position()

func is_damage_enabled() -> bool:
	return state == State.EXPOSED and not hitbox.disabled

func try_damage(target: Node) -> bool:
	if not is_damage_enabled() or target == null or not target.has_method("take_damage"):
		return false
	target.take_damage(GameConfig.FORT_SPIKE_DAMAGE, {
		"source": self,
		"damage_type": &"piercing",
	})
	return true

func _physics_process(delta: float) -> void:
	state_time += delta
	match state:
		State.RETRACTED:
			if state_time >= GameConfig.FORT_SPIKE_RETRACTED_DURATION:
				set_state(State.RISING)
		State.RISING:
			_update_visual_position()
			if state_time >= GameConfig.FORT_SPIKE_RISE_DURATION:
				set_state(State.EXPOSED)
		State.EXPOSED:
			if state_time >= GameConfig.FORT_SPIKE_EXPOSED_DURATION:
				set_state(State.LOWERING)
		State.LOWERING:
			_update_visual_position()
			if state_time >= GameConfig.FORT_SPIKE_LOWER_DURATION:
				set_state(State.RETRACTED)

func _on_body_entered(body: Node) -> void:
	try_damage(body)

func _update_visual_position() -> void:
	var offset := 0.0
	match state:
		State.RETRACTED:
			offset = GameConfig.FORT_SPIKE_RETRACT_DISTANCE
		State.RISING:
			var progress := clampf(state_time / GameConfig.FORT_SPIKE_RISE_DURATION, 0.0, 1.0)
			offset = lerpf(GameConfig.FORT_SPIKE_RETRACT_DISTANCE, 0.0, progress)
		State.EXPOSED:
			offset = 0.0
		State.LOWERING:
			var progress := clampf(state_time / GameConfig.FORT_SPIKE_LOWER_DURATION, 0.0, 1.0)
			offset = lerpf(0.0, GameConfig.FORT_SPIKE_RETRACT_DISTANCE, progress)
	sprite.position.y = exposed_visual_y + offset

func _configure_sprite() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var texture := load("res://assets/Props/Spikes.png") as Texture2D
	if texture == null:
		return
	sprite.texture = texture
	var size := texture.get_size()
	if size.x > 0.0:
		var scale_factor := minf(1.0, GameConfig.TILE_SIZE / size.x)
		sprite.scale = Vector2.ONE * scale_factor
		exposed_visual_y = -size.y * scale_factor * 0.5

