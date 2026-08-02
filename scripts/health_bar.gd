extends ProgressBar

@onready var damage_bar: ProgressBar = get_parent().get_node("DamageBar")
@onready var health_timer: Timer = $HealthTimer

const HEALTH_DELAY = 0.5
signal no_hp_left

func increase(val):
	value = min(max_value, value + val)

func decrease(val):
	value = max(0, value - val)
	health_timer.start(HEALTH_DELAY)
	if value == 0:
		no_hp_left.emit()

func set_zero():
	value = 0
	health_timer.start(HEALTH_DELAY)
	no_hp_left.emit()

func decrease_damage_bar():
	damage_bar.value = value

func set_val(val):
	value = val
	damage_bar.value = val

func set_max_val(val):
	max_value = val
	damage_bar.max_value = val
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_timer.timeout.connect(decrease_damage_bar)

