class_name CollectibleCatalog
extends RefCounted

const Definition = preload("res://scripts/collectibles/collectible_definition.gd")

static func definitions() -> Array[Definition]:
	return [
		Definition.new(&"coin_bronze", Definition.KIND_GOLD, "res://assets/Collectibles/spawnable/coin_bronze.png", GameConfig.COIN_BRONZE_GOLD, 0.0, true, false),
		Definition.new(&"coin_silver", Definition.KIND_GOLD, "res://assets/Collectibles/spawnable/coin_silver.png", GameConfig.COIN_SILVER_GOLD, 0.0, true, false),
		Definition.new(&"coin_gold", Definition.KIND_GOLD, "res://assets/Collectibles/spawnable/coin_gold.png", GameConfig.COIN_GOLD_GOLD, 0.0, true, false),
		Definition.new(&"heart", Definition.KIND_HEALTH, "res://assets/Collectibles/spawnable/heart.png", 0, GameConfig.HEALTH_PICKUP_AMOUNT, true, false),
		Definition.new(&"gem_blue", Definition.KIND_GOLD, "res://assets/Collectibles/droppable/gem_blue.png", GameConfig.GEM_BLUE_GOLD, 0.0, false, true),
		Definition.new(&"gem_green", Definition.KIND_GOLD, "res://assets/Collectibles/droppable/gem_green.png", GameConfig.GEM_GREEN_GOLD, 0.0, false, true),
		Definition.new(&"gem_yellow", Definition.KIND_GOLD, "res://assets/Collectibles/droppable/gem_yellow.png", GameConfig.GEM_YELLOW_GOLD, 0.0, false, true),
	]

static func by_id(id: StringName) -> Definition:
	for definition: Definition in definitions():
		if definition.id == id:
			return definition
	return null

static func spawnable_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition: Definition in definitions():
		if definition.spawnable:
			result.append(definition.id)
	result.sort()
	return result

static func droppable_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition: Definition in definitions():
		if definition.droppable:
			result.append(definition.id)
	result.sort()
	return result
