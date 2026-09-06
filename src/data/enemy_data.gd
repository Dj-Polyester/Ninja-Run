class_name EnemyData
extends Resource

enum MovementMode { STATIONARY, PATROL }
enum AttackMode { MELEE = 1, SHOOT = 2 }
enum RangedStyle { PROJECTILE, BEAM }

@export var id: StringName = &"enemy"
@export var display_name := "Enemy"
@export_enum("Grass", "Tundra", "Snow", "Desert", "Astro", "Fort") var biome_id: int = BiomeData.Id.GRASS
@export_range(1, 99, 1) var minimum_encounter := 1

@export var base_health := 40.0
@export var health_per_level := 12.0
@export var base_damage := 8.0
@export var damage_per_level := 2.0

@export_enum("Stationary", "Patrol") var movement_mode: int = MovementMode.STATIONARY
@export var move_speed_tiles := 1.4
@export var patrol_range_tiles := 2.0
@export_flags("Melee", "Shoot") var attack_modes: int = AttackMode.MELEE
@export var melee_range_tiles := 0.85
@export var melee_interval := 0.85
@export var vicinity_tiles := 5.0
@export var shooting_interval := 1.6
@export_enum("Projectile", "Beam") var ranged_style: int = RangedStyle.PROJECTILE
@export var projectile_speed_tiles := 6.0

@export var status_effect: Resource
@export var drop_table: Array[Dictionary] = [
	{"collectible_id": &"bronze_coin", "probability": 0.70, "min_count": 1, "max_count": 2},
	{"collectible_id": &"silver_coin", "probability": 0.30, "min_count": 1, "max_count": 1},
	{"collectible_id": &"gold_coin", "probability": 0.15, "min_count": 1, "max_count": 1},
	{"collectible_id": &"gem_blue", "probability": 0.05, "min_count": 1, "max_count": 1},
	{"collectible_id": &"gem_green", "probability": 0.03, "min_count": 1, "max_count": 1},
	{"collectible_id": &"gem_yellow", "probability": 0.01, "min_count": 1, "max_count": 1},
]
@export_dir var animation_root := ""
@export var idle_animation_folder := "Idle"
@export var walk_animation_folder := "Walking"
@export var melee_animation_folder := "Slashing"
@export var shoot_animation_folder := "Throwing"
@export var hurt_animation_folder := "Hurt"
@export var death_animation_folder := "Dying"
@export var sprite_scale := 0.22

func health_for_level(level: int) -> float:
	return maxf(1.0, base_health + health_per_level * float(maxi(1, level) - 1))

func damage_for_level(level: int) -> float:
	return maxf(0.0, base_damage + damage_per_level * float(maxi(1, level) - 1))

func has_attack(mode: int) -> bool:
	return (attack_modes & mode) != 0

func appears_in_encounter(encounter_number: int) -> bool:
	return maxi(1, encounter_number) >= minimum_encounter

func projectile_speed_pixels() -> float:
	return GameConfig.tiles_to_pixels(maxf(0.0, projectile_speed_tiles))

func has_valid_drop_table() -> bool:
	if drop_table.is_empty():
		return false
	for entry in drop_table:
		var probability := float(entry.get("probability", -1.0))
		var min_count := int(entry.get("min_count", -1))
		var max_count := int(entry.get("max_count", -1))
		if String(entry.get("collectible_id", "")).is_empty():
			return false
		if probability < 0.0 or probability > 1.0:
			return false
		if min_count < 0 or max_count < min_count:
			return false
	return true
