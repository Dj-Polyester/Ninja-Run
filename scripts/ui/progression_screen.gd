class_name ProgressionScreen
extends Control

const ProfileShopRuntime = preload("res://scripts/models/profile_shop.gd")
const CharacterCatalogRuntime = preload("res://scripts/characters/character_catalog.gd")
const AbilityCatalogRuntime = preload("res://scripts/abilities/ability_catalog.gd")
const WeaponCatalogRuntime = preload("res://scripts/weapons/weapon_catalog.gd")

@export_enum("characters", "stats", "abilities", "weapons", "settings") var mode: String = "characters"

var profile: ProfileState
var _content: VBoxContainer
var _gold_label: Label
var _title_label: Label

func _ready() -> void:
	profile = get_node("/root/RunSession").profile as ProfileState
	_build_shell()
	if profile != null and not profile.changed.is_connected(_refresh):
		profile.changed.connect(_refresh)
	_refresh()

func _exit_tree() -> void:
	if profile != null and profile.changed.is_connected(_refresh):
		profile.changed.disconnect(_refresh)

func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color(0.02, 0.035, 0.07, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var art := TextureRect.new()
	art.texture = load("res://assets/UI/PNG/Window/Cartoon RPG UI_Window - Wide.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.modulate = Color(1, 1, 1, 0.22)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 70)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 14)
	margin.add_child(root_box)

	var header := HBoxContainer.new()
	root_box.add_child(header)
	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	_gold_label = Label.new()
	_gold_label.name = "GoldLabel"
	_gold_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_gold_label)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_box.add_child(scroll)
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)

	var back := Button.new()
	back.name = "Back"
	back.text = "Back to Main Menu"
	back.custom_minimum_size = Vector2(0, 48)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	root_box.add_child(back)

func _refresh() -> void:
	if profile == null or _content == null:
		return
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_gold_label.text = "Gold: %d" % profile.gold
	match mode:
		"characters":
			_title_label.text = "Characters"
			_build_characters()
		"stats":
			_title_label.text = "Stats"
			_build_stats()
		"abilities":
			_title_label.text = "Abilities"
			_build_abilities()
		"weapons":
			_title_label.text = "Weapons"
			_build_weapons()
		"settings":
			_title_label.text = "Settings"
			_build_settings()

func _pretty(id: StringName) -> String:
	return String(id).replace("_", " ").capitalize()

func _row(title: String, detail: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = title.replace(" ", "")
	row.custom_minimum_size = Vector2(0, 56)
	var label := Label.new()
	label.text = "%s
%s" % [title, detail]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	_content.add_child(row)
	return row

func _action_button(row: HBoxContainer, text_value: String, action: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(150, 44)
	button.disabled = disabled
	button.pressed.connect(action)
	row.add_child(button)
	return button

func _build_characters() -> void:
	for definition in CharacterCatalogRuntime.definitions():
		var unlocked: bool = bool(profile.unlocked_characters.get(definition.id, false))
		var selected: bool = profile.selected_character == definition.id
		var detail := "Selected" if selected else ("Unlocked" if unlocked else "Unlock: %d gold" % definition.unlock_cost)
		var row := _row(definition.display_name, detail)
		if selected:
			_action_button(row, "Selected", func() -> void: pass, true)
		elif unlocked:
			_action_button(row, "Select", func(id := definition.id) -> void: ProfileShopRuntime.select_character(profile, id))
		else:
			_action_button(row, "Unlock", func(id := definition.id) -> void: ProfileShopRuntime.purchase_character(profile, id), not profile.can_afford(definition.unlock_cost))

func _build_stats() -> void:
	var specs: Array = [
		[ProfileShopRuntime.STAT_MAXIMUM_HEALTH, "Maximum Health", profile.maximum_health, GameConfig.MAXIMUM_HEALTH_UPGRADE_GOLDS, true],
		[ProfileShopRuntime.STAT_DEFENSE, "Defense Multiplier", profile.defense_multiplier, GameConfig.DEFENSE_UPGRADE_GOLDS, true],
		[ProfileShopRuntime.STAT_MELEE_POWER, "Melee Power", profile.melee_power, GameConfig.MELEE_POWER_UPGRADE_GOLDS, true],
		[ProfileShopRuntime.STAT_ENEMY_FIRE_RATE, "Enemy Fire Interval", profile.enemy_fire_interval_multiplier, GameConfig.ENEMY_FIRE_RATE_UPGRADE_GOLDS, true],
		[ProfileShopRuntime.STAT_INVISIBILITY_DURATION, "Invisibility Duration", profile.invisibility_duration, GameConfig.INVISIBILITY_DURATION_UPGRADE_GOLDS, profile.abilities.unlocked.get(&"invisibility", false)],
		[ProfileShopRuntime.STAT_SLOW_DOWN_DURATION, "Slow-down Duration", profile.slow_down_duration, GameConfig.SLOW_DOWN_DURATION_UPGRADE_GOLDS, profile.abilities.unlocked.get(&"slow_down_time", false)],
	]
	for spec in specs:
		var available: bool = bool(spec[4])
		var detail := "Value: %s | Cost: %d gold" % [str(spec[2]), int(spec[3])] if available else "Unlock the related ability first"
		var row := _row(String(spec[1]), detail)
		_action_button(row, "Upgrade", func(id := StringName(spec[0])) -> void: ProfileShopRuntime.upgrade_stat(profile, id), not available or not profile.can_afford(int(spec[3])))

func _build_abilities() -> void:
	for definition in AbilityCatalogRuntime.definitions():
		var unlocked: bool = bool(profile.abilities.unlocked.get(definition.id, false))
		var equipped: bool = definition.id in profile.abilities.equipped
		var detail := "Level %d/%d" % [profile.ability_level(definition.id), definition.max_level] if unlocked else "Unlock: %d gold" % GameConfig.ABILITY_UNLOCK_GOLDS
		if unlocked and not definition.cooldown_exempt:
			detail += " | Cooldown %.1fs" % profile.ability_cooldown(definition.id)
		var row := _row(_pretty(definition.id), detail)
		if not unlocked:
			_action_button(row, "Unlock", func(id := definition.id) -> void: ProfileShopRuntime.purchase_ability(profile, id), not profile.can_afford(GameConfig.ABILITY_UNLOCK_GOLDS))
			continue
		_action_button(row, "Unequip" if equipped else "Equip", func(id := definition.id, want := not equipped) -> void: ProfileShopRuntime.set_ability_equipped(profile, id, want))
		if definition.max_level > 1:
			_action_button(row, "Level +", func(id := definition.id) -> void: ProfileShopRuntime.upgrade_ability_level(profile, id), profile.ability_level(definition.id) >= definition.max_level or not profile.can_afford(GameConfig.ABILITY_LEVEL_UPGRADE_GOLDS))
		if not definition.cooldown_exempt:
			_action_button(row, "Cooldown -", func(id := definition.id) -> void: ProfileShopRuntime.upgrade_ability_cooldown(profile, id), is_equal_approx(profile.ability_cooldown(definition.id), GameConfig.MIN_ABILITY_COOLDOWN) or not profile.can_afford(GameConfig.ABILITY_COOLDOWN_UPGRADE_GOLDS))

func _build_weapons() -> void:
	var shooting_unlocked: bool = bool(profile.abilities.unlocked.get(AbilityEligibility.SHOOTING, false))
	if not shooting_unlocked:
		var gate := Label.new()
		gate.text = "Unlock Shooting before buying or equipping weapons."
		_content.add_child(gate)
	for definition in WeaponCatalogRuntime.definitions():
		var unlocked: bool = bool(profile.weapons.unlocked.get(definition.id, false))
		var equipped: bool = definition.id in profile.weapons.equipped
		var detail := "Damage %.0f | Trajectory %s | Aim %s | Targets %d | Fire %.2fs" % [definition.damage, _pretty(definition.trajectory), _pretty(definition.aim_mode), definition.target_count, definition.fire_interval]
		var row := _row(_pretty(definition.id), detail)
		if not unlocked:
			_action_button(row, "Unlock %d" % GameConfig.WEAPON_UNLOCK_GOLDS, func(id := definition.id) -> void: ProfileShopRuntime.purchase_weapon(profile, id), not shooting_unlocked or not profile.can_afford(GameConfig.WEAPON_UNLOCK_GOLDS))
		else:
			_action_button(row, "Unequip" if equipped else "Equip", func(id := definition.id, want := not equipped) -> void: ProfileShopRuntime.set_weapon_equipped(profile, id, want))

func _build_settings() -> void:
	var current := profile.mobile_auxiliary_button_corner
	var row := _row("Mobile ability buttons", "Current: %s" % _pretty(current))
	_action_button(row, "Bottom Left", func() -> void: ProfileShopRuntime.set_mobile_auxiliary_button_corner(profile, &"bottom_left"), current == &"bottom_left")
	_action_button(row, "Bottom Right", func() -> void: ProfileShopRuntime.set_mobile_auxiliary_button_corner(profile, &"bottom_right"), current == &"bottom_right")
