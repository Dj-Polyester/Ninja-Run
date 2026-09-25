class_name RunDirector
extends RefCounted
const EnemyEffect = preload("res://scripts/enemies/enemy_effect_spec.gd")
signal state_changed(state: int)
signal revived
signal damage_landed
enum State { RUNNING, REVIVAL_COUNTDOWN, GAME_OVER }
enum FailureReason { NONE, FALL, STUCK, HEALTH }
var run := RunState.new()
var state := State.RUNNING
var safe_support := Vector2.ZERO
var support_query: Callable
var seed: int = 0
var revival_protection_until := -1.0
var last_progress_x := 0.0
var last_progress_at := 0.0
var last_reported_position := Vector2.ZERO
var failure_position := Vector2.ZERO
var failure_reason := FailureReason.NONE
var clock: GameClock
var simulation_time := 0.0
signal hud_changed
func _init(new_clock: GameClock = null) -> void:
	clock = new_clock if new_clock != null else GameClock.SystemClock.new()
	run.health_owner.defense_multiplier = GameConfig.DEFAULT_DEFENSE
	run.changed.connect(_on_run_changed)
func _on_run_changed() -> void:
	hud_changed.emit()

func apply_profile_stats(profile: ProfileState) -> bool:
	if profile == null or not profile.is_valid():
		return false
	run.set_health(float(profile.maximum_health), float(profile.maximum_health))
	run.health_owner.defense_multiplier = profile.defense_multiplier
	return true
func now() -> float: return clock.now_seconds()

func set_support_query(query: Callable) -> void: support_query = query
func initialize_progress(position: Vector2, at: float = -1.0) -> void:
	last_reported_position = position
	last_progress_x = position.x
	last_progress_at = now() if at < 0.0 else at
func recovery_context() -> Dictionary:
	return {&"reason": failure_reason, &"position": failure_position}
func apply_damage(event: DamageStatus.DamageEvent, at: float = -1.0) -> bool:
	return apply_hit(DamageStatus.HitEnvelope.new(event), at).accepted

func apply_heal(amount: float) -> float:
	if state != State.RUNNING or not is_finite(amount) or amount <= 0.0:
		return 0.0
	var owner := run.health_owner
	var before := owner.current_health
	owner.current_health = minf(owner.maximum_health, owner.current_health + amount)
	var healed := owner.current_health - before
	if healed > 0.0:
		run.changed.emit()
	return healed

func apply_hit(hit: DamageStatus.HitEnvelope, at: float = -1.0) -> DamageStatus.HitResult:
	var now_time := now() if at < 0.0 else at
	if hit == null or state != State.RUNNING or now_time < revival_protection_until:
		return DamageStatus.HitResult.new()
	if hit.damage == null or not hit.damage.is_valid():
		return DamageStatus.HitResult.new()
	var pending_status: DamageStatus.TimedStatus = null
	if hit.effect_spec != null:
		if not hit.effect_spec is EnemyEffect:
			return DamageStatus.HitResult.new()
		var effect: EnemyEffect = hit.effect_spec
		if not effect.is_valid():
			return DamageStatus.HitResult.new()
		pending_status = effect.to_timed_status(simulation_time, hit.source_id)
		# Validate capacity before health mutates. An invalid/full envelope is a
		# complete rejection, never a partial damage transaction.
		if not run.health_owner.can_apply_status(pending_status, simulation_time):
			return DamageStatus.HitResult.new()
	# Commit every model mutation before any externally observable signal.
	var dealt := run.health_owner.apply_damage(hit.damage)
	var lethal := run.health_owner.current_health <= 0.0
	# An effect is never installed after a lethal transaction. This keeps the
	# failed/rejected lifecycle from retaining post-death delayed damage.
	if lethal:
		_begin_failure(FailureReason.HEALTH, last_reported_position, now_time)
		if dealt > 0.0: damage_landed.emit()
		return DamageStatus.HitResult.new(true, dealt, true, false)
	var installed := pending_status != null and run.health_owner.apply_status(pending_status, simulation_time)
	run.changed.emit()
	if dealt > 0.0: damage_landed.emit()
	return DamageStatus.HitResult.new(true, dealt, false, installed)
func fail_fall(at: float = -1.0) -> void:
	fail_fall_at(last_reported_position, at)
func fail_fall_at(position: Vector2, at: float = -1.0) -> void:
	if state != State.RUNNING: return
	run.health_owner.current_health = 0.0
	hud_changed.emit()
	_begin_failure(FailureReason.FALL, position, now() if at < 0.0 else at)
func begin_countdown(now_time: float) -> void:
	if state != State.RUNNING: return
	state = State.REVIVAL_COUNTDOWN; run.begin_countdown(now_time); state_changed.emit(state); hud_changed.emit()
func _begin_failure(reason: int, position: Vector2, now_time: float) -> void:
	if state != State.RUNNING:
		return
	failure_reason = reason
	failure_position = position
	begin_countdown(now_time)
func advance_simulation(delta: float) -> void:
	if state != State.RUNNING or not is_finite(delta) or delta <= 0.0:
		return
	simulation_time += delta
	run.health_owner.clear_expired_statuses(simulation_time)
	for periodic in run.health_owner.due_periodic_events(simulation_time):
		# Periodic effects go through this same authority. They cannot revive,
		# bypass defense, or build a wall-time backlog while a run is paused.
		apply_hit(DamageStatus.HitEnvelope.new(periodic), now())

func tick(at: float = -1.0) -> void:
	var now_time := now() if at < 0.0 else at
	if state == State.REVIVAL_COUNTDOWN and not run.is_countdown_active(now_time): state = State.GAME_OVER; state_changed.emit(state); hud_changed.emit()
func record_progress(position: Vector2, at: float = -1.0) -> void:
	var now_time := now() if at < 0.0 else at
	if state != State.RUNNING: return
	last_reported_position = position
	if position.x > last_progress_x + GameConfig.STUCK_PROGRESS_EPSILON:
		last_progress_x = position.x; last_progress_at = now_time
	if now_time >= revival_protection_until and now_time - last_progress_at >= GameConfig.GAME_OVER_NUMBER_OF_SECS:
		_begin_failure(FailureReason.STUCK, position, now_time)
func record_checkpoint(validated_support: Vector2) -> void:
	if state != State.RUNNING:
		return
	safe_support = validated_support
func revive(profile: ProfileState, at: float = -1.0) -> bool:
	var now_time := now() if at < 0.0 else at
	if state != State.REVIVAL_COUNTDOWN or not run.is_countdown_active(now_time) or profile.revival_potions <= 0:
		return false
	# M3 seam: terrain may reject removed support or return a nearby replacement.
	if support_query.is_valid():
		var resolved = support_query.call(safe_support, recovery_context())
		if not resolved is Vector2:
			return false
		safe_support = resolved
	if not profile.consume_revival_potion():
		return false
	run.health_owner.current_health = run.health_owner.maximum_health
	run.health_owner.statuses.clear()
	state = State.RUNNING
	revival_protection_until = now_time + GameConfig.REVIVAL_PROTECTION
	last_progress_at = now_time
	last_progress_x = safe_support.x
	last_reported_position = safe_support
	failure_reason = FailureReason.NONE
	revived.emit()
	state_changed.emit(state)
	hud_changed.emit()
	return true
