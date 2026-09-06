class_name RngService
extends RefCounted

var generator := RandomNumberGenerator.new()
var seed_value := 1

func _init(seed: int = 1) -> void:
	seed_value = seed
	generator.seed = seed

func reseed(seed: int) -> void:
	seed_value = seed
	generator.seed = seed

func chance(probability: float) -> bool:
	return generator.randf() < clampf(probability, 0.0, 1.0)

func range_i(minimum: int, maximum: int) -> int:
	if maximum <= minimum:
		return minimum
	return generator.randi_range(minimum, maximum)

func range_f(minimum: float, maximum: float) -> float:
	if maximum <= minimum:
		return minimum
	return generator.randf_range(minimum, maximum)

func weighted_key(weights: Dictionary):
	var total := 0.0
	for value in weights.values():
		total += maxf(0.0, float(value))
	if total <= 0.0:
		return null
	var roll := generator.randf() * total
	for key in weights.keys():
		roll -= maxf(0.0, float(weights[key]))
		if roll <= 0.0:
			return key
	return weights.keys()[-1] if not weights.is_empty() else null
