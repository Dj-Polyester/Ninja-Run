class_name BiomeData
extends Resource

enum Id { GRASS, TUNDRA, SNOW, DESERT, ASTRO, FORT }
enum HazardType { NONE, SNOW_VARIANCE, DESERT_HEAT, ASTRO_FALLING_TILE, FORT_SPIKES }

@export_enum("Grass", "Tundra", "Snow", "Desert", "Astro", "Fort") var id: int = Id.GRASS
@export var display_name := "Grass"
@export var terrain_set: StringName = &"grass"
@export var background_color := Color(0.13, 0.20, 0.30, 1.0)
@export var enemy_pool: Array[StringName] = []
@export var terrain_top_atlas := Vector2i.ZERO
@export var terrain_center_atlas := Vector2i.ZERO
@export var terrain_left_atlas := Vector2i.ZERO
@export var terrain_middle_atlas := Vector2i.ZERO
@export var terrain_right_atlas := Vector2i.ZERO
@export var layout_weights: Dictionary = {}
@export_enum("None", "Snow Variance", "Desert Heat", "Astro Falling Tile", "Fort Spikes") var hazard_type: int = HazardType.NONE
@export_range(0.0, 1.0, 0.01) var hazard_spawn_chance := 0.0
@export var collectible_weights: Dictionary = {}
@export_file var particle_effect := ""
@export var snow_jump_modifier_min := 0.0
@export var snow_jump_modifier_max := 0.0

func atlas_coords_for_segment(index: int, width: int) -> Vector2i:
	if width <= 1:
		return terrain_top_atlas
	if index == 0:
		return terrain_left_atlas
	if index == width - 1:
		return terrain_right_atlas
	return terrain_middle_atlas

func total_layout_weight() -> float:
	var total := 0.0
	for value in layout_weights.values():
		total += maxf(0.0, float(value))
	return total

func has_hazard(hazard: int) -> bool:
	return hazard_type == hazard
