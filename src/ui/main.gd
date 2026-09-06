extends Control

const CHARACTER_CATALOG_SCRIPT := preload("res://src/data/character_catalog.gd")
const CHARACTER_INVENTORY_SERVICE_SCRIPT := preload("res://src/gameplay/progression/character_inventory_service.gd")
const STAT_CATALOG_SCRIPT := preload("res://src/data/stat_catalog.gd")
const STAT_UPGRADE_SERVICE_SCRIPT := preload("res://src/gameplay/progression/stat_upgrade_service.gd")
const ABILITY_CATALOG_SCRIPT := preload("res://src/data/ability_catalog.gd")
const ABILITY_INVENTORY_SERVICE_SCRIPT := preload("res://src/gameplay/abilities/ability_inventory_service.gd")
const WEAPON_CATALOG_SCRIPT := preload("res://src/data/weapon_catalog.gd")
const WEAPON_INVENTORY_SERVICE_SCRIPT := preload("res://src/gameplay/combat/weapon_inventory_service.gd")

const UI_WINDOW_WIDE_PATH := "res://assets/UI/PNG/Window/Cartoon RPG UI_Window - Wide.png"
const UI_PLAY_ICON_PATH := "res://assets/UI/PNG/Buttons/Normal/Buttons_Button Normal - Play.png"
const UI_PROFILE_ICON_PATH := "res://assets/UI/PNG/Buttons/Normal/Buttons_Button Normal - Profile.png"
const UI_STATS_ICON_PATH := "res://assets/UI/PNG/Buttons/Normal/Buttons_Button Normal - Increase.png"
const UI_SHOP_ICON_PATH := "res://assets/UI/PNG/Buttons/Normal/Buttons_Button Normal - Shopping Cart.png"
const UI_SETTINGS_ICON_PATH := "res://assets/UI/PNG/Buttons/Normal/Buttons_Button Normal - Settings.png"
const UI_HOME_ICON_PATH := "res://assets/UI/PNG/Buttons/Normal/Buttons_Button Normal - Home.png"
const UI_CLOSE_ICON_PATH := "res://assets/UI/PNG/Buttons/Normal/Buttons_Button Normal - Close.png"
const UI_COIN_ICON_PATH := "res://assets/UI/PNG/Game Icon/Cartoon RPG UI_Game Icon - Coin.png"
const UI_MAGIC_ICON_PATH := "res://assets/UI/PNG/Game Icon/Cartoon RPG UI_Game Icon - Magic.png"
const UI_WEAPON_SLOT_PATH := "res://assets/UI/PNG/Item Slot/Cartoon RPG UI_Slot - Weapon.png"
const UI_AVATAR_SLOT_PATH := "res://assets/UI/PNG/Item Slot/Cartoon RPG UI_Slot - Avatar.png"

const SCREEN_MAIN := &"main"
const SCREEN_CHARACTER := &"character"
const SCREEN_STATS := &"stats"
const SCREEN_ABILITIES := &"abilities"
const SCREEN_WEAPONS := &"weapons"
const SCREEN_SETTINGS := &"settings"

@onready var screen_host: Control = $ScreenHost
@onready var ui_backdrop: TextureRect = $UIBackdrop

var current_screen: StringName = SCREEN_MAIN
var notice_text := ""

func _ready() -> void:
	ui_backdrop.texture = _load_runtime_texture(UI_WINDOW_WIDE_PATH)
	show_screen(SCREEN_MAIN)

func show_screen(screen_id: StringName, notice: String = "") -> void:
	current_screen = screen_id
	notice_text = notice
	_clear_screen_host()
	match screen_id:
		SCREEN_CHARACTER:
			_build_character_screen()
		SCREEN_STATS:
			_build_stats_screen()
		SCREEN_ABILITIES:
			_build_abilities_screen()
		SCREEN_WEAPONS:
			_build_weapons_screen()
		SCREEN_SETTINGS:
			_build_settings_screen()
		_:
			current_screen = SCREEN_MAIN
			_build_main_screen()

func _build_main_screen() -> void:
	var column := _begin_screen("NINJA RUN", "Endless runner profile & loadout", Vector2(720, 650), false)
	var selected = GameState.selected_character_data()
	var selected_name: String = selected.display_name if selected != null else "Ninja"
	var summary := Label.new()
	summary.name = "ProfileSummary"
	summary.text = "Selected: %s   •   Gold: %d" % [selected_name, GameState.gold_count()]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 18)
	column.add_child(summary)

	column.add_spacer(false)
	var start_button := _make_button("START RUN", _load_runtime_texture(UI_PLAY_ICON_PATH), 58)
	start_button.name = "StartButton"
	start_button.pressed.connect(_on_start_pressed)
	column.add_child(start_button)

	var nav_grid := GridContainer.new()
	nav_grid.name = "ProfileNavigation"
	nav_grid.columns = 2
	nav_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_grid.add_theme_constant_override("h_separation", 14)
	nav_grid.add_theme_constant_override("v_separation", 14)
	column.add_child(nav_grid)
	_add_navigation_button(nav_grid, "CHARACTERS", "CharacterButton", _load_runtime_texture(UI_PROFILE_ICON_PATH), SCREEN_CHARACTER)
	_add_navigation_button(nav_grid, "STATS", "StatsButton", _load_runtime_texture(UI_STATS_ICON_PATH), SCREEN_STATS)
	_add_navigation_button(nav_grid, "ABILITIES", "AbilitiesButton", _load_runtime_texture(UI_MAGIC_ICON_PATH), SCREEN_ABILITIES)
	_add_navigation_button(nav_grid, "WEAPONS", "WeaponsButton", _load_runtime_texture(UI_SHOP_ICON_PATH), SCREEN_WEAPONS)
	_add_navigation_button(nav_grid, "SETTINGS", "SettingsButton", _load_runtime_texture(UI_SETTINGS_ICON_PATH), SCREEN_SETTINGS)

	var quit_button := _make_button("QUIT", _load_runtime_texture(UI_CLOSE_ICON_PATH), 46)
	quit_button.name = "QuitButton"
	quit_button.pressed.connect(_on_quit_pressed)
	nav_grid.add_child(quit_button)

	var controls := Label.new()
	controls.name = "ControlsSummary"
	controls.text = "Desktop: ↑ Jump   ↓ Roll   1–4 Abilities\nMobile: Tap Jump   •   Swipe Down Roll"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_color_override("font_color", Color(0.78, 0.84, 0.92))
	column.add_child(controls)
	_focus_named_button("StartButton")

func _build_character_screen() -> void:
	var column := _begin_screen("CHARACTERS", "Unlock a character with gold, then choose the runner used in every run.", Vector2(1160, 680))
	var scroll := ScrollContainer.new()
	scroll.name = "CharacterScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "CharacterGrid"
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for character in CHARACTER_CATALOG_SCRIPT.all():
		grid.add_child(_build_character_card(character))

func _build_character_card(character) -> Control:
	var card := PanelContainer.new()
	card.name = "Character_%02d" % int(character.id)
	card.custom_minimum_size = Vector2(202, 228)
	card.add_theme_stylebox_override("panel", _card_style())
	var margin := _margin_container(10)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var preview_frame := TextureRect.new()
	preview_frame.name = "AvatarSlot"
	preview_frame.texture = _load_runtime_texture(UI_AVATAR_SLOT_PATH)
	preview_frame.custom_minimum_size = Vector2(82, 82)
	preview_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(preview_frame)
	var preview := TextureRect.new()
	preview.name = "CharacterPreview"
	preview.texture = _character_preview_texture(character)
	preview.custom_minimum_size = Vector2(72, 54)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(preview)

	var title := Label.new()
	title.text = character.display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	column.add_child(title)

	var unlocked := GameState.is_character_unlocked(character.id)
	var selected: bool = GameState.selected_character_id() == character.id
	var state_label := Label.new()
	state_label.name = "StateLabel"
	state_label.text = "SELECTED" if selected else ("UNLOCKED" if unlocked else "LOCKED • %d GOLD" % int(character.unlock_cost))
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_color_override("font_color", _state_color(selected, unlocked))
	column.add_child(state_label)

	var action := _make_button("SELECTED" if selected else ("SELECT" if unlocked else "UNLOCK — %d" % int(character.unlock_cost)), null, 38)
	action.name = "ActionButton"
	action.disabled = selected
	action.pressed.connect(_on_character_action.bind(int(character.id)))
	column.add_child(action)
	return card

func _build_stats_screen() -> void:
	var column := _begin_screen("STATS", "Spend gold on persistent upgrades. Ability-gated stats unlock automatically with their ability.", Vector2(1080, 680))
	var scroll := ScrollContainer.new()
	scroll.name = "StatsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "StatsList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 9)
	scroll.add_child(list)
	for stat in STAT_CATALOG_SCRIPT.all():
		list.add_child(_build_stat_row(stat))

func _build_stat_row(stat) -> Control:
	var row := PanelContainer.new()
	row.name = "Stat_%s" % String(stat.id)
	row.custom_minimum_size = Vector2(980, 88)
	row.add_theme_stylebox_override("panel", _card_style())
	var margin := _margin_container(12)
	row.add_child(margin)
	var horizontal := HBoxContainer.new()
	horizontal.add_theme_constant_override("separation", 18)
	margin.add_child(horizontal)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal.add_child(details)
	var title := Label.new()
	title.text = stat.display_name
	title.add_theme_font_size_override("font_size", 18)
	details.add_child(title)
	var level := GameState.stat_level(stat.id)
	var current_value = GameState.stat_value(stat.id)
	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "Level %d / %d   •   Current: %s" % [level, stat.max_level(), _format_stat_value(stat, current_value)]
	details.add_child(value_label)
	var unlocked := GameState.is_stat_unlocked(stat.id)
	var status := Label.new()
	status.name = "RequirementLabel"
	if not unlocked:
		var ability = ABILITY_CATALOG_SCRIPT.get_by_id(stat.required_ability)
		status.text = "LOCKED • Requires %s" % (ability.display_name if ability != null else String(stat.required_ability))
	else:
		var next_text := "MAXIMUM REACHED"
		if level < stat.max_level():
			next_text = "Next: %s • Cost: %d gold" % [_format_stat_value(stat, stat.value_for_level(level + 1)), stat.upgrade_golds]
		status.text = next_text
	details.add_child(status)

	var button := _make_button("LOCKED" if not unlocked else ("MAX" if level >= stat.max_level() else "UPGRADE — %d" % stat.upgrade_golds), _load_runtime_texture(UI_STATS_ICON_PATH), 46)
	button.name = "UpgradeButton"
	button.custom_minimum_size.x = 210
	button.disabled = not unlocked or level >= stat.max_level()
	button.pressed.connect(_on_stat_upgrade.bind(stat.id))
	horizontal.add_child(button)
	return row

func _build_abilities_screen() -> void:
	var column := _begin_screen("ABILITIES", "Unlock, equip, and upgrade abilities. At most %d may be equipped; Jump and Reverse Gravity conflict." % GameConfig.NUM_EQUIPABLE_ABILITIES, Vector2(1120, 680))
	var equipment := Label.new()
	equipment.name = "AbilityEquipmentSummary"
	equipment.text = "Equipped: %s" % _ability_equipment_summary()
	equipment.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(equipment)
	var scroll := ScrollContainer.new()
	scroll.name = "AbilitiesScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "AbilitiesGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for ability in ABILITY_CATALOG_SCRIPT.ORDERED:
		grid.add_child(_build_ability_card(ability))

func _build_ability_card(ability) -> Control:
	var card := PanelContainer.new()
	card.name = "Ability_%s" % String(ability.id)
	card.custom_minimum_size = Vector2(515, 184)
	card.add_theme_stylebox_override("panel", _card_style())
	var margin := _margin_container(12)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)

	var heading := HBoxContainer.new()
	column.add_child(heading)
	var icon := TextureRect.new()
	icon.texture = _load_runtime_texture(UI_MAGIC_ICON_PATH)
	icon.custom_minimum_size = Vector2(34, 34)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heading.add_child(icon)
	var title := Label.new()
	title.text = ability.display_name
	title.add_theme_font_size_override("font_size", 19)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)

	var unlocked := GameState.is_ability_unlocked(ability.id)
	var equipped := GameState.is_ability_equipped(ability.id)
	var levels = GameState.profile.get("ability_levels", {})
	var level := clampi(int(levels.get(String(ability.id), 1)), 1, ability.max_level) if levels is Dictionary else 1
	var state := Label.new()
	state.name = "StateLabel"
	state.text = ("EQUIPPED" if equipped else "UNLOCKED") if unlocked else "LOCKED"
	state.add_theme_color_override("font_color", _state_color(equipped, unlocked))
	column.add_child(state)
	var metadata := Label.new()
	metadata.name = "MetadataLabel"
	metadata.text = "Level %d / %d   •   Cooldown: %s   •   Price: %d gold" % [level, ability.max_level, ("%.1fs" % GameConfig.COOLDOWN_PERIOD) if ability.has_cooldown else "None", ability.unlock_cost]
	column.add_child(metadata)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	if not unlocked:
		var unlock_button := _make_button("UNLOCK — %d GOLD" % int(ability.unlock_cost), _load_runtime_texture(UI_SHOP_ICON_PATH), 40)
		unlock_button.name = "UnlockButton"
		unlock_button.pressed.connect(_on_ability_unlock.bind(ability.id))
		actions.add_child(unlock_button)
	else:
		var equip_button := _make_button("UNEQUIP" if equipped else "EQUIP", null, 40)
		equip_button.name = "EquipButton"
		equip_button.pressed.connect(_on_ability_equip_toggle.bind(ability.id))
		actions.add_child(equip_button)
		if ability.max_level > 1:
			var upgrade_button := _make_button("MAX LEVEL" if level >= ability.max_level else "UPGRADE TO LV %d" % (level + 1), _load_runtime_texture(UI_STATS_ICON_PATH), 40)
			upgrade_button.name = "UpgradeButton"
			upgrade_button.disabled = level >= ability.max_level
			upgrade_button.pressed.connect(_on_ability_upgrade.bind(ability.id))
			actions.add_child(upgrade_button)
	return card

func _build_weapons_screen() -> void:
	var column := _begin_screen("WEAPONS", "Weapons fire automatically when enemies are on-screen. At most %d may be equipped." % GameConfig.NUM_EQUIPPABLE_WEAPONS, Vector2(1120, 680))
	var requirement := Label.new()
	requirement.name = "ShootingRequirement"
	requirement.text = "Shooting ability unlocked — weapon shop active." if GameState.shooting_unlocked() else "LOCKED: Unlock the Shooting ability before buying or equipping weapons."
	requirement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	requirement.add_theme_color_override("font_color", Color(0.62, 0.95, 0.68) if GameState.shooting_unlocked() else Color(1.0, 0.62, 0.48))
	column.add_child(requirement)
	var scroll := ScrollContainer.new()
	scroll.name = "WeaponsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "WeaponsList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for weapon in WEAPON_CATALOG_SCRIPT.all():
		list.add_child(_build_weapon_card(weapon))

func _build_weapon_card(weapon) -> Control:
	var card := PanelContainer.new()
	card.name = "Weapon_%s" % String(weapon.id)
	card.custom_minimum_size = Vector2(1010, 132)
	card.add_theme_stylebox_override("panel", _card_style())
	var margin := _margin_container(10)
	card.add_child(margin)
	var horizontal := HBoxContainer.new()
	horizontal.add_theme_constant_override("separation", 14)
	margin.add_child(horizontal)

	var slot := TextureRect.new()
	slot.name = "WeaponSlot"
	slot.texture = _load_runtime_texture(UI_WEAPON_SLOT_PATH)
	slot.custom_minimum_size = Vector2(92, 92)
	slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	horizontal.add_child(slot)
	var weapon_texture := TextureRect.new()
	weapon_texture.name = "WeaponTexture"
	weapon_texture.texture = _load_runtime_texture(weapon.texture_path)
	weapon_texture.custom_minimum_size = Vector2(82, 82)
	weapon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	horizontal.add_child(weapon_texture)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal.add_child(details)
	var title := Label.new()
	title.text = weapon.display_name
	title.add_theme_font_size_override("font_size", 19)
	details.add_child(title)
	var description := GridContainer.new()
	description.name = "WeaponDescription"
	description.columns = 2
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(description)
	_add_weapon_field(description, "DamageLabel", "Damage", _format_number(weapon.damage))
	_add_weapon_field(description, "TrajectoryLabel", "Trajectory", weapon.trajectory_description())
	_add_weapon_field(description, "AimLabel", "Aim", weapon.aim_description())
	_add_weapon_field(description, "TargetsLabel", "Targets", str(weapon.target_count))

	var unlocked := GameState.is_weapon_unlocked(weapon.id)
	var equipped_raw = GameState.profile.get("equipped_weapons", [])
	var equipped: bool = equipped_raw is Array and equipped_raw.has(String(weapon.id))
	var action_column := VBoxContainer.new()
	action_column.custom_minimum_size.x = 220
	horizontal.add_child(action_column)
	var state := Label.new()
	state.name = "StateLabel"
	state.text = "EQUIPPED" if equipped else ("UNLOCKED" if unlocked else "LOCKED")
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.add_theme_color_override("font_color", _state_color(equipped, unlocked))
	action_column.add_child(state)
	var price := Label.new()
	price.name = "PriceLabel"
	price.text = "Price: %d gold" % int(weapon.unlock_cost)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_column.add_child(price)
	var button := _make_button("UNEQUIP" if equipped else ("EQUIP" if unlocked else "UNLOCK — %d" % int(weapon.unlock_cost)), _load_runtime_texture(UI_SHOP_ICON_PATH) if not unlocked else null, 42)
	button.name = "ActionButton"
	button.disabled = not GameState.shooting_unlocked()
	button.pressed.connect(_on_weapon_action.bind(weapon.id))
	action_column.add_child(button)
	return card

func _build_settings_screen() -> void:
	var column := _begin_screen("SETTINGS", "Input presentation settings are stored in the persistent profile.", Vector2(850, 620))
	var section := PanelContainer.new()
	section.name = "ActionButtonSideSetting"
	section.add_theme_stylebox_override("panel", _card_style())
	column.add_child(section)
	var margin := _margin_container(18)
	section.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	margin.add_child(body)
	var title := Label.new()
	title.text = "Mobile action-button cluster"
	title.add_theme_font_size_override("font_size", 20)
	body.add_child(title)
	var description := Label.new()
	description.text = "Choose which bottom corner contains direct-action ability buttons. Tap-to-jump and swipe-down-to-roll remain full-screen gestures."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(description)
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 12)
	body.add_child(choices)
	var current_side := GameState.action_button_side()
	var left := _make_button("BOTTOM LEFT", null, 52)
	left.name = "BottomLeftButton"
	left.toggle_mode = true
	left.button_pressed = current_side == PlayerProfile.ACTION_BUTTON_SIDE_LEFT
	left.pressed.connect(_on_action_button_side_pressed.bind(PlayerProfile.ACTION_BUTTON_SIDE_LEFT))
	choices.add_child(left)
	var right := _make_button("BOTTOM RIGHT", null, 52)
	right.name = "BottomRightButton"
	right.toggle_mode = true
	right.button_pressed = current_side == PlayerProfile.ACTION_BUTTON_SIDE_RIGHT
	right.pressed.connect(_on_action_button_side_pressed.bind(PlayerProfile.ACTION_BUTTON_SIDE_RIGHT))
	choices.add_child(right)

	var controls := Label.new()
	controls.name = "InputReference"
	controls.text = "DESKTOP\n↑ Jump   •   ↓ Roll   •   1–4 mapped abilities\n\nMOBILE\nTap Jump   •   Swipe Down Roll   •   Other equipped actions use the selected corner"
	controls.add_theme_font_size_override("font_size", 17)
	column.add_child(controls)

func _begin_screen(title_text: String, subtitle_text: String, minimum_size: Vector2, show_back := true) -> VBoxContainer:
	var center := CenterContainer.new()
	center.name = "%sScreen" % String(current_screen).capitalize().replace(" ", "")
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_host.add_child(center)
	var frame := PanelContainer.new()
	frame.name = "Window"
	frame.custom_minimum_size = minimum_size
	frame.add_theme_stylebox_override("panel", _window_style())
	center.add_child(frame)
	var margin := _margin_container(26)
	frame.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "Content"
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	if show_back:
		var back := _make_button("BACK", _load_runtime_texture(UI_HOME_ICON_PATH), 44)
		back.name = "BackButton"
		back.custom_minimum_size.x = 120
		back.pressed.connect(_on_back_pressed)
		header.add_child(back)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	var title := Label.new()
	title.name = "ScreenTitle"
	title.text = title_text
	title.add_theme_font_size_override("font_size", 30 if show_back else 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "ScreenSubtitle"
	subtitle.text = subtitle_text
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(subtitle)
	if show_back:
		header.add_child(_gold_badge())

	if not notice_text.is_empty():
		var notice := Label.new()
		notice.name = "NoticeLabel"
		notice.text = notice_text
		notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notice.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48))
		column.add_child(notice)
	return column

func _gold_badge() -> Control:
	var badge := HBoxContainer.new()
	badge.name = "GoldBadge"
	badge.custom_minimum_size.x = 132
	var icon := TextureRect.new()
	icon.texture = _load_runtime_texture(UI_COIN_ICON_PATH)
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.add_child(icon)
	var label := Label.new()
	label.name = "GoldLabel"
	label.text = str(GameState.gold_count())
	label.add_theme_font_size_override("font_size", 18)
	badge.add_child(label)
	return badge

func _add_navigation_button(parent: Control, text: String, node_name: String, icon: Texture2D, destination: StringName) -> void:
	var button := _make_button(text, icon, 52)
	button.name = node_name
	button.pressed.connect(_on_navigation_pressed.bind(destination))
	parent.add_child(button)

func _make_button(text: String, icon: Texture2D = null, height := 46) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if icon != null:
		button.icon = icon
		button.icon_max_width = 30
	return button

func _margin_container(amount: int) -> MarginContainer:
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, amount)
	return margin

func _window_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.065, 0.105, 0.97)
	style.border_color = Color(0.55, 0.64, 0.78, 0.95)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	return style

func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.085, 0.115, 0.17, 0.96)
	style.border_color = Color(0.28, 0.36, 0.49, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _state_color(primary: bool, unlocked: bool) -> Color:
	if primary:
		return Color(0.45, 1.0, 0.62)
	if unlocked:
		return Color(0.62, 0.82, 1.0)
	return Color(1.0, 0.58, 0.48)

func _character_preview_texture(character) -> Texture2D:
	if DisplayServer.get_name() == "headless" or character == null:
		return null
	var folder: String = character.animation_root.path_join("Fast Run")
	for file_name in character.list_animation_files(folder):
		if String(file_name).to_lower().ends_with(".png"):
			return character.load_texture(folder.path_join(String(file_name)))
	return null

func _load_runtime_texture(path: String) -> Texture2D:
	if DisplayServer.get_name() == "headless" or path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return null

func _format_stat_value(stat, value) -> String:
	return str(int(value)) if stat.integer_value else "%.2f" % float(value)

func _format_number(value: float) -> String:
	return str(int(round(value))) if is_equal_approx(value, round(value)) else "%.1f" % value

func _ability_equipment_summary() -> String:
	var equipped = GameState.profile.get("equipped_abilities", [])
	if not equipped is Array or equipped.is_empty():
		return "None"
	var names: Array[String] = []
	for raw_id in equipped:
		var ability = ABILITY_CATALOG_SCRIPT.get_by_id(StringName(raw_id))
		names.append(ability.display_name if ability != null else String(raw_id))
	return ", ".join(names)

func _add_weapon_field(grid: GridContainer, node_name: String, heading: String, value: String) -> void:
	var key := Label.new()
	key.text = "%s:" % heading
	grid.add_child(key)
	var label := Label.new()
	label.name = node_name
	label.text = value
	grid.add_child(label)

func _clear_screen_host() -> void:
	for child in screen_host.get_children():
		screen_host.remove_child(child)
		child.queue_free()

func _focus_named_button(node_name: String) -> void:
	var button := find_child(node_name, true, false) as Button
	if button != null:
		button.grab_focus()

func _on_navigation_pressed(destination: StringName) -> void:
	show_screen(destination)

func _on_back_pressed() -> void:
	show_screen(SCREEN_MAIN)

func _on_start_pressed() -> void:
	SaveManager.save_profile()
	get_tree().change_scene_to_file("res://scenes/level/level.tscn")

func _on_quit_pressed() -> void:
	SaveManager.save_profile()
	get_tree().quit()

func _on_character_action(character_id: int) -> void:
	var result: int
	var message: String
	if not GameState.is_character_unlocked(character_id):
		result = GameState.unlock_character(character_id)
		message = _character_result_message(result, true)
	else:
		result = GameState.select_character(character_id)
		message = _character_result_message(result, false)
	if result == CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS:
		SaveManager.save_profile()
	show_screen(SCREEN_CHARACTER, message)

func _on_stat_upgrade(stat_id: StringName) -> void:
	var result := GameState.upgrade_stat(stat_id)
	if result == STAT_UPGRADE_SERVICE_SCRIPT.Result.SUCCESS:
		SaveManager.save_profile()
	show_screen(SCREEN_STATS, _stat_result_message(result))

func _on_ability_unlock(ability_id: StringName) -> void:
	var result := GameState.unlock_ability(ability_id)
	if result == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS:
		SaveManager.save_profile()
	show_screen(SCREEN_ABILITIES, _ability_result_message(result))

func _on_ability_equip_toggle(ability_id: StringName) -> void:
	var result := GameState.unequip_ability(ability_id) if GameState.is_ability_equipped(ability_id) else GameState.equip_ability(ability_id)
	if result == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS:
		SaveManager.save_profile()
	show_screen(SCREEN_ABILITIES, _ability_result_message(result))

func _on_ability_upgrade(ability_id: StringName) -> void:
	var result := GameState.upgrade_ability(ability_id)
	if result == ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS:
		SaveManager.save_profile()
	show_screen(SCREEN_ABILITIES, _ability_result_message(result))

func _on_weapon_action(weapon_id: StringName) -> void:
	var result: int
	if not GameState.is_weapon_unlocked(weapon_id):
		result = GameState.unlock_weapon(weapon_id)
	else:
		var equipped = GameState.profile.get("equipped_weapons", [])
		result = GameState.unequip_weapon(weapon_id) if equipped is Array and equipped.has(String(weapon_id)) else GameState.equip_weapon(weapon_id)
	if result == WEAPON_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS:
		SaveManager.save_profile()
	show_screen(SCREEN_WEAPONS, _weapon_result_message(result))

func _on_action_button_side_pressed(side: String) -> void:
	if GameState.set_action_button_side(side):
		SaveManager.save_profile()
		show_screen(SCREEN_SETTINGS, "Mobile action buttons moved to the bottom %s." % side)
	else:
		show_screen(SCREEN_SETTINGS, "Invalid action-button side.")

func _character_result_message(result: int, unlocking: bool) -> String:
	match result:
		CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS:
			return "Character unlocked." if unlocking else "Character selected."
		CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.NOT_ENOUGH_GOLD:
			return "Not enough gold to unlock that character."
		CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.NOT_UNLOCKED:
			return "Unlock that character before selecting it."
		CHARACTER_INVENTORY_SERVICE_SCRIPT.Result.ALREADY_SELECTED:
			return "That character is already selected."
	return "Character action could not be completed."

func _stat_result_message(result: int) -> String:
	match result:
		STAT_UPGRADE_SERVICE_SCRIPT.Result.SUCCESS:
			return "Stat upgraded and saved."
		STAT_UPGRADE_SERVICE_SCRIPT.Result.LOCKED:
			return "That stat is still ability-locked."
		STAT_UPGRADE_SERVICE_SCRIPT.Result.AT_LIMIT:
			return "That stat is already at its limit."
		STAT_UPGRADE_SERVICE_SCRIPT.Result.NOT_ENOUGH_GOLD:
			return "Not enough gold for that upgrade."
	return "Stat upgrade could not be completed."

func _ability_result_message(result: int) -> String:
	match result:
		ABILITY_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS:
			return "Ability loadout updated and saved."
		ABILITY_INVENTORY_SERVICE_SCRIPT.Result.NOT_ENOUGH_GOLD:
			return "Not enough gold to unlock that ability."
		ABILITY_INVENTORY_SERVICE_SCRIPT.Result.EQUIPMENT_LIMIT:
			return "Ability equipment limit reached (%d)." % GameConfig.NUM_EQUIPABLE_ABILITIES
		ABILITY_INVENTORY_SERVICE_SCRIPT.Result.INCOMPATIBLE:
			return "Jump and Reverse Gravity cannot be equipped together."
		ABILITY_INVENTORY_SERVICE_SCRIPT.Result.MAX_LEVEL:
			return "That ability is already at maximum level."
		ABILITY_INVENTORY_SERVICE_SCRIPT.Result.NOT_UNLOCKED:
			return "Unlock that ability first."
	return "Ability action could not be completed."

func _weapon_result_message(result: int) -> String:
	match result:
		WEAPON_INVENTORY_SERVICE_SCRIPT.Result.SUCCESS:
			return "Weapon loadout updated and saved."
		WEAPON_INVENTORY_SERVICE_SCRIPT.Result.SHOOTING_LOCKED:
			return "Unlock Shooting before using the weapon shop."
		WEAPON_INVENTORY_SERVICE_SCRIPT.Result.NOT_ENOUGH_GOLD:
			return "Not enough gold to unlock that weapon."
		WEAPON_INVENTORY_SERVICE_SCRIPT.Result.EQUIPMENT_LIMIT:
			return "Weapon equipment limit reached (%d)." % GameConfig.NUM_EQUIPPABLE_WEAPONS
		WEAPON_INVENTORY_SERVICE_SCRIPT.Result.NOT_UNLOCKED:
			return "Unlock that weapon first."
	return "Weapon action could not be completed."
