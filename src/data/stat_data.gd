class_name StatData
extends Resource

enum Direction { INCREASING, DECREASING }

@export var id: StringName = &""
@export var display_name := ""
@export var direction := Direction.INCREASING
@export var minimum_value := 0.0
@export var maximum_value := 1.0
@export var upgrade_step := 1.0
@export var upgrade_golds := 0
@export var integer_value := false
@export var required_ability: StringName = &""

func max_level() -> int:
	if upgrade_step <= 0.0 or maximum_value <= minimum_value:
		return 0
	return maxi(0, int(round((maximum_value - minimum_value) / upgrade_step)))

func value_for_level(level: int):
	var clamped_level := clampi(level, 0, max_level())
	var value := minimum_value + upgrade_step * clamped_level
	if direction == Direction.DECREASING:
		value = maximum_value - upgrade_step * clamped_level
	value = clampf(value, minimum_value, maximum_value)
	return int(round(value)) if integer_value else value

func level_for_value(value: float) -> int:
	var clamped_value := clampf(value, minimum_value, maximum_value)
	var offset := clamped_value - minimum_value
	if direction == Direction.DECREASING:
		offset = maximum_value - clamped_value
	return clampi(int(round(offset / upgrade_step)), 0, max_level()) if upgrade_step > 0.0 else 0

func is_unlocked(profile: Dictionary) -> bool:
	if required_ability == &"":
		return true
	var unlocked = profile.get("unlocked_abilities", [])
	return unlocked is Array and unlocked.has(String(required_ability))

func is_valid() -> bool:
	if id == &"" or display_name.strip_edges().is_empty():
		return false
	if minimum_value >= maximum_value or upgrade_step <= 0.0 or upgrade_golds < 0:
		return false
	var raw_levels := (maximum_value - minimum_value) / upgrade_step
	return is_equal_approx(raw_levels, round(raw_levels))
