class_name AstroFallCoordinator
extends RefCounted
## Run-local, deterministic state for destructible Astro terrain.
## Descriptions never change; this registry overlays only the currently streamed
## realization. A tile id plus its registration epoch rejects stale callbacks.

enum State { STABLE, ARMED, FALLING, REMOVED }

signal cell_state_changed(tile_id: StringName, epoch: int, previous_state: int, next_state: int)

var cells: Dictionary = {} # StringName -> { id, epoch, column, row, state, node, chunk_index, world_y }
var _last_time := 0.0
var solid_below_query: Callable = Callable()
var contact_enabled := false

func set_solid_below_query(query: Callable) -> void:
	solid_below_query = query

func set_contact_enabled(enabled: bool) -> void:
	var became_enabled := enabled and not contact_enabled
	contact_enabled = enabled
	if became_enabled:
		for cell: Dictionary in cells.values():
			var block := cell.get(&"node") as Node
			if is_instance_valid(block) and block.has_method("check_current_top_contact"):
				block.call("check_current_top_contact")

func arm_from_contact(tile_id: StringName, epoch: int, direction: StringName = &"top") -> bool:
	return contact_enabled and arm(tile_id, epoch, direction)

func register_cell(tile_id: StringName, epoch: int, column: int, row: int, chunk_index: int, world_y: float, node: Node) -> bool:
	if tile_id.is_empty() or cells.has(tile_id):
		return false
	cells[tile_id] = {&"id": tile_id, &"epoch": epoch, &"column": column, &"row": row, &"chunk_index": chunk_index, &"world_y": world_y, &"state": State.STABLE, &"node": node}
	return true

func arm(tile_id: StringName, epoch: int = -1, direction: StringName = &"top") -> bool:
	if direction != &"top" or not cells.has(tile_id):
		return false
	var cell: Dictionary = cells[tile_id]
	if epoch >= 0 and int(cell[&"epoch"]) != epoch:
		return false
	if int(cell[&"state"]) != State.STABLE:
		return false
	cell[&"state"] = State.ARMED
	cells[tile_id] = cell
	cell_state_changed.emit(tile_id, int(cell[&"epoch"]), State.STABLE, State.ARMED)
	var block := cell.get(&"node") as Node
	if is_instance_valid(block) and block.has_method("on_armed"):
		block.call("on_armed")
	return true

func advance(now_seconds: float, running: bool, tile_size: float, speed: float, delay: float, fixed_step: float, fall_limit: float) -> void:
	if not running or not is_finite(now_seconds):
		return
	if now_seconds < _last_time:
		_last_time = now_seconds
		return
	var remaining := now_seconds - _last_time
	_last_time = now_seconds
	while remaining > 0.000001:
		var step := minf(remaining, fixed_step)
		_step(step, tile_size, speed, delay, fall_limit)
		remaining -= step

func remove_cell(tile_id: StringName, epoch: int = -1) -> bool:
	if not cells.has(tile_id):
		return false
	var cell: Dictionary = cells[tile_id]
	if epoch >= 0 and int(cell[&"epoch"]) != epoch:
		return false
	var previous := int(cell[&"state"])
	cell[&"state"] = State.REMOVED
	cells[tile_id] = cell
	cell_state_changed.emit(tile_id, int(cell[&"epoch"]), previous, State.REMOVED)
	var block := cell.get(&"node") as Node
	if is_instance_valid(block) and block.has_method("on_removed"):
		block.call("on_removed")
	return true

func retire(tile_id: StringName, epoch: int) -> void:
	if not cells.has(tile_id):
		return
	var cell: Dictionary = cells[tile_id]
	if int(cell[&"epoch"]) != epoch:
		return
	cells.erase(tile_id)

func is_stable(tile_id: StringName) -> bool:
	return cells.has(tile_id) and int((cells[tile_id] as Dictionary)[&"state"]) == State.STABLE

func is_present(tile_id: StringName) -> bool:
	return cells.has(tile_id) and int((cells[tile_id] as Dictionary)[&"state"]) != State.REMOVED

func state_for(tile_id: StringName) -> int:
	return int((cells.get(tile_id, {}) as Dictionary).get(&"state", State.REMOVED))

func _step(delta: float, tile_size: float, speed: float, delay: float, fall_limit: float) -> void:
	var ordered: Array[StringName] = []
	for id: StringName in cells:
		ordered.append(id)
	ordered.sort()
	for id in ordered:
		if not cells.has(id):
			continue
		var cell: Dictionary = cells[id]
		var state := int(cell[&"state"])
		if state == State.ARMED:
			cell[&"armed_seconds"] = float(cell.get(&"armed_seconds", 0.0)) + delta
			if float(cell[&"armed_seconds"]) >= delay:
				cell[&"state"] = State.FALLING
				cell_state_changed.emit(id, int(cell[&"epoch"]), State.ARMED, State.FALLING)
				var start_node := cell.get(&"node") as Node
				if is_instance_valid(start_node) and start_node.has_method("on_falling"):
					start_node.call("on_falling")
			cells[id] = cell
		elif state == State.FALLING:
			var old_y := float(cell.get(&"fall_y", cell[&"world_y"]))
			var new_y := old_y + speed * delta
			# Every present lower Astro cell is collidable at its current position,
			# including independently armed or falling cells. This has no dependence
			# on iteration order: the upper cell is always clamped to one full tile.
			var below := _first_present_below(int(cell[&"column"]), old_y, new_y, tile_size)
			if not below.is_empty():
				new_y = minf(new_y, _current_y(below) - tile_size)
			cell[&"fall_y"] = new_y
			cells[id] = cell
			var node := cell.get(&"node") as Node
			if is_instance_valid(node) and node.has_method("set_fall_world_y"):
				node.call("set_fall_world_y", new_y)
			if not below.is_empty():
				var contact_y := _current_y(below) - tile_size
				cell[&"fall_y"] = contact_y
				cell[&"blocked_by"] = below[&"id"]
				cells[id] = cell
				if is_instance_valid(node) and node.has_method("set_fall_world_y"):
					node.call("set_fall_world_y", contact_y)
				if int(below[&"state"]) == State.STABLE:
					arm(StringName(below[&"id"]), int(below[&"epoch"]), &"top")
			elif solid_below_query.is_valid() and bool(solid_below_query.call(int(cell[&"column"]), old_y + tile_size * 0.5, new_y + tile_size * 0.5)):
				remove_cell(id, int(cell[&"epoch"]))
				continue
			if new_y >= float(cell[&"world_y"]) + fall_limit:
				remove_cell(id, int(cell[&"epoch"]))

func _current_y(cell: Dictionary) -> float:
	return float(cell.get(&"fall_y", cell[&"world_y"]))

func _first_present_below(column: int, old_y: float, new_y: float, tile_size: float) -> Dictionary:
	var candidate: Dictionary = {}
	for cell: Dictionary in cells.values():
		if int(cell[&"column"]) != column or int(cell[&"state"]) == State.REMOVED:
			continue
		var target_y := _current_y(cell)
		# Sweep falling bottom against lower top; do not wait for centers to pass.
		var contact_y := target_y - tile_size
		if target_y > old_y + 0.001 and old_y <= contact_y + 0.001 and new_y >= contact_y - 0.001:
			if candidate.is_empty() or target_y < _current_y(candidate):
				candidate = cell
	return candidate
