class_name LootRolls
extends RefCounted
## Pure deterministic loot decisions. Results depend only on the run seed,
## immutable enemy spawn identity, collectible identity, and configured chance.

static func sample_fraction(run_seed: int, enemy_spawn_id: StringName, collectible_id: StringName) -> float:
	var value: int = run_seed ^ enemy_spawn_id.hash() ^ (collectible_id.hash() * 1103515245) ^ 0x4d595df4
	value = (value ^ (value >> 16)) * 0x45d9f3b
	value = value ^ (value >> 16)
	return float(absi(value) % 1000000) / 1000000.0

static func rolls(run_seed: int, enemy_spawn_id: StringName, collectible_id: StringName, probability: float) -> bool:
	if not GameConfig.validate_drop_probability(probability):
		return false
	if probability <= 0.0:
		return false
	if probability >= 1.0:
		return true
	return sample_fraction(run_seed, enemy_spawn_id, collectible_id) < probability

static func drops_for(run_seed: int, enemy_spawn_id: StringName, enemy_id: StringName, probabilities: Dictionary = GameConfig.ENEMY_DROP_PROBABILITIES) -> Array[StringName]:
	var result: Array[StringName] = []
	var table: Dictionary = probabilities.get(enemy_id, {})
	var ids: Array[StringName] = []
	for collectible_variant in table.keys():
		ids.append(StringName(collectible_variant))
	ids.sort()
	for collectible_id in ids:
		if rolls(run_seed, enemy_spawn_id, collectible_id, float(table[collectible_id])):
			result.append(collectible_id)
	return result
