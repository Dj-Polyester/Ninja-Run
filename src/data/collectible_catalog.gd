class_name CollectibleCatalog
extends RefCounted

const BRONZE_COIN = preload("res://data/collectibles/bronze_coin.tres")
const SILVER_COIN = preload("res://data/collectibles/silver_coin.tres")
const GOLD_COIN = preload("res://data/collectibles/gold_coin.tres")
const GEM_BLUE = preload("res://data/collectibles/gem_blue.tres")
const GEM_GREEN = preload("res://data/collectibles/gem_green.tres")
const GEM_YELLOW = preload("res://data/collectibles/gem_yellow.tres")

const ALL := [BRONZE_COIN, SILVER_COIN, GOLD_COIN, GEM_BLUE, GEM_GREEN, GEM_YELLOW]
const GEM_IDS: Array[StringName] = [&"gem_blue", &"gem_green", &"gem_yellow"]

static func get_by_id(collectible_id: StringName):
	for collectible in ALL:
		if collectible.id == collectible_id:
			return collectible
	return null

static func resolve_weight_key(weight_key, rng: RngService):
	var key := StringName(String(weight_key))
	if key != &"gem":
		return get_by_id(key)
	var gem_weights := {
		&"gem_blue": 0.55,
		&"gem_green": 0.30,
		&"gem_yellow": 0.15,
	}
	var selected = rng.weighted_key(gem_weights)
	return get_by_id(StringName(selected)) if selected != null else null

static func maximum_coin_value() -> int:
	return maxi(BRONZE_COIN.gold_value, maxi(SILVER_COIN.gold_value, GOLD_COIN.gold_value))

static func minimum_gem_value() -> int:
	return mini(GEM_BLUE.gold_value, mini(GEM_GREEN.gold_value, GEM_YELLOW.gold_value))
