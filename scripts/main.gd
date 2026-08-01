extends Node2D
class_name Main

class Stat:
	var multiplier
	var _value
	var minimum
	var maximum
	var value:
		get: 
			return _value
		set(val): 
			_value = max(val, minimum) if maximum == null else clampi(val, minimum, maximum) 
	
	func level_up():
		value += multiplier

	func _init(mult, _min = 0, _max = null) -> void:
		minimum = _min
		maximum = _max
		value = _min
		multiplier = mult

class Ability:
	var enabled: bool = false

class Stats:
	var currency = 0
	var max_health: Stat = Stat.new(10,100,500)
	# defense is ratio
	var defense: Stat = Stat.new(0.2, 0, 0.8)
	var jump: Stat = Stat.new(1, 2, 3)
	var climb: Stat = Stat.new(1, 2, 2)

class Abilities:
	var glide = Ability.new()
	var reverse_gravity = Ability.new()
	var fly = Ability.new()
	var dash = Ability.new()
	var fatal_dash = Ability.new()
	var teleport = Ability.new()
	var telekinesis = Ability.new()
	var invisible = Ability.new()
	var transform = Ability.new()

var stats = Stats.new()
var abilities = Abilities.new()