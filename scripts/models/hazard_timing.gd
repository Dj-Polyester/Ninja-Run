class_name HazardTiming
extends RefCounted
## Pure simulation-clock contracts shared by every streamed terrain hazard.
## Callers own advancement of `now_seconds`; this class never reads wall time.

static func phase_time(now_seconds: float, phase: float, period_seconds: float) -> float:
	if not is_finite(now_seconds) or not is_finite(phase) or not is_finite(period_seconds) or period_seconds <= 0.0:
		return 0.0
	return fposmod(now_seconds + clampf(phase, 0.0, 0.999999) * period_seconds, period_seconds)

static func fort_extension(now_seconds: float, phase: float, period_seconds: float, extended_seconds: float, transition_seconds: float = 0.25) -> float:
	if period_seconds <= 0.0 or extended_seconds <= 0.0:
		return 0.0
	var visible_window := minf(extended_seconds, period_seconds)
	var rise_fall := minf(maxf(0.0, transition_seconds), visible_window * 0.5)
	var local_time := phase_time(now_seconds, phase, period_seconds)
	if local_time >= visible_window:
		return 0.0
	if is_zero_approx(rise_fall):
		return 1.0
	if local_time < rise_fall:
		return local_time / rise_fall
	if local_time > visible_window - rise_fall:
		return (visible_window - local_time) / rise_fall
	return 1.0

class ContactCadence:
	var next_damage_at := -INF

	func can_emit(now_seconds: float, touching: bool, active: bool, cadence_seconds: float) -> bool:
		if not touching or not active or not is_finite(now_seconds) or not is_finite(cadence_seconds) or cadence_seconds <= 0.0:
			return false
		if now_seconds + 0.000001 < next_damage_at:
			return false
		next_damage_at = now_seconds + cadence_seconds
		return true
