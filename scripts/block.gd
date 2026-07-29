extends RigidBody2D
class_name Block

@onready var sprite = $Sprite2D
@onready var visible_on_screen_notifier = $VisibleOnScreenNotifier2D
const STOP_THRESHOLD = 5.0

func _ready():
    visible_on_screen_notifier.screen_exited.connect(_on_screen_exited)

func _on_screen_exited():
    if linear_velocity.length() < STOP_THRESHOLD:
        queue_free()