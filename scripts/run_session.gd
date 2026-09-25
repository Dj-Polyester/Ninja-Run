extends Node
## Application-lifetime persistent profile plus transient production run-seed ownership.

const SaveServiceRuntime = preload("res://scripts/models/save_service.gd")

var profile := ProfileState.new()
var save_path: String = SaveServiceRuntime.DEFAULT_PATH
var autosave_enabled := true
var production_run_seed: int = 0
var _production_seed_serial: int = 0

func _ready() -> void:
	var absolute := ProjectSettings.globalize_path(save_path)
	var had_save := FileAccess.file_exists(absolute)
	replace_profile(SaveServiceRuntime.load_profile(save_path))
	if not had_save and profile.revival_potions == 0:
		# Preserve the pre-M7 starter inventory without re-granting a consumed
		# potion on later launches once a save file exists.
		profile.revival_potions = 1

func replace_profile(new_profile: ProfileState) -> bool:
	if new_profile == null or not new_profile.is_valid():
		return false
	if profile != null and profile.changed.is_connected(_on_profile_changed):
		profile.changed.disconnect(_on_profile_changed)
	profile = new_profile
	if not profile.changed.is_connected(_on_profile_changed):
		profile.changed.connect(_on_profile_changed)
	return true

func reset_profile_for_tests() -> void:
	autosave_enabled = false
	replace_profile(ProfileState.new())

func commit_run_rewards(run: RunState) -> int:
	if run == null or run.earned_gold <= 0:
		return 0
	var amount := run.earned_gold
	run.earned_gold = 0
	run.changed.emit()
	profile.add_gold(amount)
	return amount

func save_profile() -> bool:
	return SaveServiceRuntime.save_profile(profile, save_path)

func reload_profile() -> bool:
	return replace_profile(SaveServiceRuntime.load_profile(save_path))

func _on_profile_changed() -> void:
	if autosave_enabled:
		save_profile()

func acquire_production_run_seed(new_run: bool = true) -> int:
	# This is run setup state, not terrain-generator state. A Level construction
	# is a genuinely new run (including Restart); revival never calls here and
	# consequently retains its director seed.
	if production_run_seed == 0 or new_run:
		_production_seed_serial += 1
		production_run_seed = int((Time.get_ticks_usec() + _production_seed_serial * 1103515245) & 0x7fffffff)
		if production_run_seed == 0:
			production_run_seed = _production_seed_serial
	return production_run_seed
