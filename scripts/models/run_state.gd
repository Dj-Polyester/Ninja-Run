class_name RunState
extends RefCounted
## Transient state for one run. Persistence is intentionally not implemented in M1.

signal changed

var health_owner: DamageStatus.HealthOwner
var distance_tiles: float = 0.0
var earned_gold: int = 0
var countdown_deadline: float = -1.0

func _init(maximum_health: float = GameConfig.DEFAULT_MAXIMUM_HEALTH) -> void:
	health_owner = DamageStatus.HealthOwner.new(maximum_health)

func apply_damage(event: DamageStatus.DamageEvent) -> float:
	var dealt := health_owner.apply_damage(event)
	changed.emit()
	return dealt

func set_health(maximum_health: float, current_health: float) -> void:
	health_owner.maximum_health = maxf(1.0, maximum_health)
	health_owner.current_health = clampf(current_health, 0.0, health_owner.maximum_health)
	changed.emit()

func apply_status(status: DamageStatus.TimedStatus) -> void:
	health_owner.apply_status(status)
	changed.emit()

func advance_distance(delta_tiles: float) -> void:
	distance_tiles = maxf(0.0, distance_tiles + delta_tiles)
	changed.emit()

func add_earned_gold(amount: int) -> void:
	earned_gold = max(0, earned_gold + amount)
	changed.emit()

func begin_countdown(now_seconds: float) -> void:
	countdown_deadline = now_seconds + GameConfig.COUNTDOWN_SECS
	changed.emit()

func is_countdown_active(now_seconds: float) -> bool:
	return countdown_deadline > now_seconds
