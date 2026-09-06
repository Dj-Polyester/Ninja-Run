class_name BiomeCatalog
extends RefCounted

const GRASS: BiomeData = preload("res://data/biomes/grass.tres")
const TUNDRA: BiomeData = preload("res://data/biomes/tundra.tres")
const SNOW: BiomeData = preload("res://data/biomes/snow.tres")
const DESERT: BiomeData = preload("res://data/biomes/desert.tres")
const ASTRO: BiomeData = preload("res://data/biomes/astro.tres")
const FORT: BiomeData = preload("res://data/biomes/fort.tres")

const ORDERED: Array[BiomeData] = [GRASS, TUNDRA, SNOW, DESERT, ASTRO, FORT]

static func get_by_id(id: int) -> BiomeData:
	if id < 0 or id >= ORDERED.size():
		return GRASS
	return ORDERED[id]

static func all() -> Array[BiomeData]:
	return ORDERED.duplicate()
