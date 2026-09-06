class_name GlideAbility
extends Ability

var glide_elapsed := 0.0

func gravity_multiplier(delta: float, jump_held: bool) -> float:
	if not jump_held or player.is_supported() or glide_elapsed >= GameConfig.MAX_GLIDE_DURATION:
		active = false
		return 1.0
	if player.velocity.y * player.gravity_direction <= 0.0:
		active = false
		return 1.0
	active = true
	glide_elapsed = minf(GameConfig.MAX_GLIDE_DURATION, glide_elapsed + delta)
	return GameConfig.GLIDE_GRAVITY_FACTOR

func on_support_contact() -> void:
	glide_elapsed = 0.0
	active = false

func reset_runtime() -> void:
	super.reset_runtime()
	glide_elapsed = 0.0
