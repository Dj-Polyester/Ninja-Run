class_name DamageStatus
extends RefCounted
## Run-local health and timed statuses are owned by the damaged actor, never by attackers.

class DamageEvent:
	var amount: float
	var source_id: StringName

	func _init(new_amount: float, new_source_id: StringName = &"") -> void:
		amount = maxf(0.0, new_amount) if is_finite(new_amount) else NAN
		source_id = new_source_id

	func is_valid() -> bool:
		return is_finite(amount) and amount >= 0.0

## A hit is an all-or-nothing request. `effect_spec` deliberately remains a
## Variant here so core health has no dependency on the enemy content catalog.
class HitEnvelope:
	var damage: DamageEvent
	var effect_spec: Variant
	var source_id: StringName

	func _init(new_damage: DamageEvent, new_effect_spec: Variant = null, new_source_id: StringName = &"") -> void:
		damage = new_damage if new_damage != null else DamageEvent.new(0.0, new_source_id)
		effect_spec = new_effect_spec
		source_id = new_source_id if not new_source_id.is_empty() else damage.source_id

class HitResult:
	var accepted := false
	var dealt := 0.0
	var lethal := false
	var effect_installed := false

	func _init(new_accepted: bool = false, new_dealt: float = 0.0, new_lethal: bool = false, new_effect_installed: bool = false) -> void:
		accepted = new_accepted
		dealt = new_dealt
		lethal = new_lethal
		effect_installed = new_effect_installed

class TimedStatus:
	var status_id: StringName
	var expires_at: float
	var duration_seconds: float
	var interval_seconds: float
	var next_tick_at: float
	var periodic_damage: float
	var source_id: StringName
	var movement_multiplier: float
	var appearance: StringName

	func _init(new_status_id: StringName, new_duration_seconds: float, now_seconds: float, new_interval_seconds: float = 0.0, new_periodic_damage: float = 0.0, new_source_id: StringName = &"", new_movement_multiplier: float = 1.0, new_appearance: StringName = &"") -> void:
		status_id = new_status_id
		duration_seconds = maxf(0.0, new_duration_seconds)
		expires_at = now_seconds + duration_seconds
		interval_seconds = maxf(0.0, new_interval_seconds)
		periodic_damage = maxf(0.0, new_periodic_damage)
		source_id = new_source_id
		movement_multiplier = clampf(new_movement_multiplier, GameConfig.MIN_SLOWDOWN_SPEED_MULTIPLIER, 1.0)
		appearance = new_appearance
		next_tick_at = now_seconds + interval_seconds if interval_seconds > 0.0 else INF

	func is_active(now_seconds: float) -> bool:
		return now_seconds < expires_at

	func is_valid() -> bool:
		return not status_id.is_empty() and is_finite(duration_seconds) and duration_seconds >= GameConfig.MIN_STATUS_DURATION and duration_seconds <= GameConfig.MAX_STATUS_DURATION and is_finite(interval_seconds) and interval_seconds >= 0.0 and is_finite(periodic_damage) and periodic_damage >= 0.0 and periodic_damage <= GameConfig.MAX_STATUS_PERIODIC_DAMAGE and is_finite(movement_multiplier) and movement_multiplier >= GameConfig.MIN_SLOWDOWN_SPEED_MULTIPLIER and movement_multiplier <= 1.0 and (periodic_damage <= 0.0 or interval_seconds >= GameConfig.MIN_STATUS_TICK_INTERVAL)

	func refresh(now_seconds: float, new_duration_seconds: float) -> void:
		# A refresh extends the exclusive expiry but intentionally never shifts a
		# pending periodic cadence. This prevents reapplication from gaming ticks.
		duration_seconds = maxf(0.0, new_duration_seconds)
		expires_at = maxf(expires_at, now_seconds + duration_seconds)

class HealthOwner:
	var maximum_health: float
	var current_health: float
	var defense_multiplier: float
	var statuses: Dictionary = {}

	func _init(maximum: float, defense: float = 1.0) -> void:
		maximum_health = maxf(1.0, maximum)
		current_health = maximum_health
		defense_multiplier = maxf(0.0, defense)

	func apply_damage(event: DamageEvent) -> float:
		var dealt := event.amount * defense_multiplier
		current_health = maxf(0.0, current_health - dealt)
		return dealt

	func can_apply_status(status: TimedStatus, now_seconds: float) -> bool:
		clear_expired_statuses(now_seconds)
		return status != null and status.is_valid() and (statuses.has(status.status_id) or statuses.size() < GameConfig.MAX_ACTIVE_STATUS_IDENTITIES)

	func apply_status(status: TimedStatus, now_seconds: float = 0.0) -> bool:
		if not can_apply_status(status, now_seconds):
			return false
		var existing: TimedStatus = statuses.get(status.status_id)
		if existing != null:
			existing.refresh(status.expires_at - status.duration_seconds, status.duration_seconds)
			# Strength is deterministic: stronger periodic damage wins; a tie uses
			# the shorter interval. Refresh never moves the existing next_tick_at.
			existing.movement_multiplier = minf(existing.movement_multiplier, status.movement_multiplier)
			var incoming_stronger := status.periodic_damage > existing.periodic_damage or (is_equal_approx(status.periodic_damage, existing.periodic_damage) and status.interval_seconds > 0.0 and (existing.interval_seconds <= 0.0 or status.interval_seconds < existing.interval_seconds))
			if incoming_stronger:
				var had_periodic_cadence := existing.interval_seconds > 0.0 and is_finite(existing.next_tick_at)
				existing.periodic_damage = status.periodic_damage
				existing.interval_seconds = status.interval_seconds
				# A non-periodic status has no pending cadence (`INF`). Its first
				# periodic refresh starts from the incoming effect's exact due time.
				# Existing periodic statuses retain their phase on every refresh.
				if not had_periodic_cadence:
					existing.next_tick_at = status.next_tick_at
				# Attribution follows the effect actually responsible for a tick.
				if not status.source_id.is_empty(): existing.source_id = status.source_id
			elif existing.source_id.is_empty() and not status.source_id.is_empty():
				existing.source_id = status.source_id
			if not status.appearance.is_empty():
				existing.appearance = status.appearance
			return true
		statuses[status.status_id] = status
		return true

	func has_status(status_id: StringName, now_seconds: float) -> bool:
		var status: TimedStatus = statuses.get(status_id)
		return status != null and status.is_active(now_seconds)

	func clear_expired_statuses(now_seconds: float) -> void:
		for status_id: StringName in statuses.keys():
			var status: TimedStatus = statuses[status_id]
			if not status.is_active(now_seconds):
				statuses.erase(status_id)

	func movement_multiplier(now_seconds: float) -> float:
		clear_expired_statuses(now_seconds)
		var result := 1.0
		for status: TimedStatus in statuses.values():
			if status.is_active(now_seconds):
				result = minf(result, status.movement_multiplier)
		return clampf(result, GameConfig.MIN_SLOWDOWN_SPEED_MULTIPLIER, 1.0)

	func due_periodic_events(simulation_time: float) -> Array[DamageEvent]:
		var events: Array[DamageEvent] = []
		# Periodic-only consumers must enforce the same exclusive expiry contract
		# as movement/appearance consumers; otherwise an expired inert entry can
		# indefinitely occupy bounded identity capacity.
		clear_expired_statuses(simulation_time)
		for status_id: StringName in statuses.keys():
			var status: TimedStatus = statuses[status_id]
			if not status.is_active(simulation_time) or status.interval_seconds <= 0.0 or status.periodic_damage <= 0.0:
				continue
			# At most one event per simulation advancement. No backlog is created
			# across paused wall time or a coarse frame.
			if simulation_time + 0.000001 >= status.next_tick_at and status.next_tick_at < status.expires_at:
				events.append(DamageEvent.new(status.periodic_damage, status.source_id))
				# O(1), drift-resistant catch-up: the largest whole cadence count
				# skipped by this one simulation sample is discarded, never emitted.
				var skipped := maxi(1, floori((simulation_time - status.next_tick_at) / status.interval_seconds) + 1)
				status.next_tick_at += float(skipped) * status.interval_seconds
		return events
