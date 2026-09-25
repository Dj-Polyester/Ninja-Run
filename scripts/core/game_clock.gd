class_name GameClock
extends RefCounted
## Injectable clock contract. Production and deterministic tests share this API.

func now_seconds() -> float:
	return 0.0


class SystemClock extends GameClock:
	func now_seconds() -> float:
		return Time.get_ticks_msec() / 1000.0


class ManualClock extends GameClock:
	var _now: float = 0.0

	func now_seconds() -> float:
		return _now

	func advance(seconds: float) -> void:
		assert(seconds >= 0.0, "ManualClock cannot move backward.")
		_now += seconds
