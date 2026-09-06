class_name AbilityData
extends Resource

@export var id: StringName = &""
@export var display_name := ""
@export var has_cooldown := true
@export_range(1, 99, 1) var max_level := 1
@export_range(0, 1000000, 1) var unlock_cost := 0

func is_valid() -> bool:
	return id != &"" and not display_name.is_empty() and max_level >= 1 and unlock_cost >= 0
