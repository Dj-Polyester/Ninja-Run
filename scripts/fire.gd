extends Node2D

var velocity := Vector2.ZERO
@onready var sprite = $AnimatedSprite2D
@onready var frame_count = sprite.sprite_frames.get_frame_count("burn")

func _ready():
    sprite.play("burn")
    sprite.frame = randi() % frame_count

func get_size():
    var tex = sprite.sprite_frames.get_frame_texture(
        sprite.animation,
        sprite.frame
    )
    return tex.get_size()
