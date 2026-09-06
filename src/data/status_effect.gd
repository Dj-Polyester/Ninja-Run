class_name StatusEffect
extends Resource

enum StackPolicy {
	REFRESH,
	EXTEND,
	STACK,
	IGNORE,
}

@export var id: StringName = &"status"
@export var display_name := "Status"
@export_range(0.01, 60.0, 0.01) var duration := 1.0
@export_range(0.0, 60.0, 0.01) var tick_interval := 0.0
@export_enum("Refresh", "Extend", "Stack", "Ignore") var stack_policy: int = StackPolicy.REFRESH
@export_range(1, 16, 1) var max_stacks := 1
@export_range(0.0, 1000.0, 0.1) var tick_damage := 0.0
@export_range(0.05, 2.0, 0.01) var movement_speed_multiplier := 1.0
@export_range(0.05, 3.0, 0.01) var damage_taken_multiplier := 1.0
@export var tint := Color.WHITE
@export_range(-100, 100, 1) var visual_priority := 0
@export var emits_flames := false
@export var blink_red_on_tick := false

func is_valid() -> bool:
	if id == &"" or duration <= 0.0:
		return false
	if tick_interval < 0.0 or tick_damage < 0.0:
		return false
	if max_stacks < 1 or movement_speed_multiplier <= 0.0 or damage_taken_multiplier <= 0.0:
		return false
	return stack_policy >= StackPolicy.REFRESH and stack_policy <= StackPolicy.IGNORE

func on_apply(target: Node, stacks: int) -> void:
	if target != null and target.has_method(&"status_effect_applied"):
		target.call(&"status_effect_applied", self, stacks)

func on_tick(target: Node, stacks: int) -> void:
	if target == null:
		return
	if tick_damage > 0.0 and target.has_method(&"apply_status_tick_damage"):
		target.call(&"apply_status_tick_damage", tick_damage * float(maxi(1, stacks)), self)
	if target.has_method(&"status_effect_ticked"):
		target.call(&"status_effect_ticked", self, stacks)

func on_remove(target: Node) -> void:
	if target != null and target.has_method(&"status_effect_removed"):
		target.call(&"status_effect_removed", self)
