## Module: achievements_scene.gd
## Renders achievement categories and progress details.

extends Node2D

const VIEWPORT_W := 540
const VIEWPORT_H := 960

const CATEGORY_ORDER := [
	Constants.AchievementCategory.TRIP,
	Constants.AchievementCategory.PASSENGER,
	Constants.AchievementCategory.COLLECTION,
	Constants.AchievementCategory.DISCOVERY,
]

var _active_category: int = Constants.AchievementCategory.TRIP
var _rows_container: VBoxContainer
var _tab_buttons: Dictionary = {}

func _ready() -> void:
	_build_scene()
	_refresh()
	_apply_accessibility()

func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = Color("#0b1220")
	add_child(bg)

	var panel := ColorRect.new()
	panel.position = Vector2(16, 80)
	panel.size = Vector2(VIEWPORT_W - 32, VIEWPORT_H - 120)
	panel.color = Color("#16213e")
	add_child(panel)

	var title := Label.new()
	title.text = I18n.t("achievements.title")
	title.position = Vector2(32, 96)
	title.size = Vector2(VIEWPORT_W - 64, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#f1c40f"))
	add_child(title)

	var tabs := HBoxContainer.new()
	tabs.position = Vector2(24, 136)
	tabs.size = Vector2(VIEWPORT_W - 48, 40)
	add_child(tabs)

	for category in CATEGORY_ORDER:
		var tab_btn := Button.new()
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.text = I18n.t(_category_key(category))
		tab_btn.pressed.connect(_on_tab_pressed.bind(category))
		tabs.add_child(tab_btn)
		_tab_buttons[category] = tab_btn

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 188)
	scroll.size = Vector2(VIEWPORT_W - 48, VIEWPORT_H - 280)
	add_child(scroll)

	_rows_container = VBoxContainer.new()
	_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_rows_container)

	var back_btn := Button.new()
	back_btn.position = Vector2(170, VIEWPORT_H - 70)
	back_btn.size = Vector2(200, 42)
	back_btn.text = I18n.t("achievements.button.back")
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)

func _refresh() -> void:
	for category in _tab_buttons.keys():
		var btn: Button = _tab_buttons[category]
		btn.disabled = int(category) == _active_category

	for child in _rows_container.get_children():
		child.queue_free()

	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.achievement_system == null:
		return

	var all_items: Array = gm.achievement_system.get_all_achievements()
	all_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", ""))
	)

	for item in all_items:
		var achievement: Dictionary = item
		if int(achievement.get("category", -1)) != _active_category:
			continue
		_rows_container.add_child(_build_row(gm, achievement))

func _build_row(gm: Node, achievement: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(460, 114)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0f1b34")
	style.border_color = Color("#2c3e50")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var id_key: String = str(achievement.get("id", ""))
	var visible: bool = bool(achievement.get("is_visible", false))
	var unlocked: bool = bool(achievement.get("is_unlocked", false))

	var title := Label.new()
	if not visible and not unlocked:
		title.text = I18n.t("achievements.hidden")
	else:
		title.text = I18n.t(str(achievement.get("title_key", "")))
	if unlocked:
		title.text += "  %s" % I18n.t("achievements.unlocked_mark")
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("#ecf0f1"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color("#bdc3c7"))
	if not visible and not unlocked:
		desc.text = I18n.t("achievements.hidden_desc")
	else:
		desc.text = I18n.t(str(achievement.get("description_key", "")))
	vbox.add_child(desc)

	var progress: Dictionary = gm.achievement_system.get_progress(id_key)
	var current: int = int(progress.get("current", 0))
	var target: int = maxi(1, int(progress.get("target", 1)))
	if unlocked:
		current = target

	var progress_text := Label.new()
	progress_text.text = I18n.t("achievements.progress", [current, target])
	progress_text.add_theme_font_size_override("font_size", 11)
	progress_text.add_theme_color_override("font_color", Color("#95a5a6"))
	vbox.add_child(progress_text)

	var progress_bg := ColorRect.new()
	progress_bg.custom_minimum_size = Vector2(430, 8)
	progress_bg.color = Color("#2c3e50")
	vbox.add_child(progress_bg)

	var progress_fill := ColorRect.new()
	progress_fill.size = Vector2(430 * clampf(float(current) / float(target), 0.0, 1.0), 8)
	progress_fill.color = Color("#f1c40f") if unlocked else Color("#3498db")
	progress_bg.add_child(progress_fill)

	var reward := Label.new()
	reward.text = I18n.t("achievements.reward", [int(achievement.get("reward_money", 0))])
	reward.add_theme_font_size_override("font_size", 11)
	reward.add_theme_color_override("font_color", Color("#f7dc6f"))
	vbox.add_child(reward)

	return card

func _on_tab_pressed(category: int) -> void:
	_active_category = category
	_refresh()

func _on_back_pressed() -> void:
	var previous: String = "res://src/scenes/garage/garage_scene.tscn"
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.trip_planner and gm.trip_planner.is_trip_active():
		previous = "res://src/scenes/map/map_scene.tscn"
	get_tree().change_scene_to_file(previous)

func _category_key(category: int) -> String:
	match category:
		Constants.AchievementCategory.TRIP:
			return "achievements.tab.trip"
		Constants.AchievementCategory.PASSENGER:
			return "achievements.tab.passenger"
		Constants.AchievementCategory.COLLECTION:
			return "achievements.tab.collection"
		Constants.AchievementCategory.DISCOVERY:
			return "achievements.tab.discovery"
		_:
			return "achievements.tab.trip"

func _apply_accessibility() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.settings_system:
		gm.settings_system.apply_font_scale_recursive(self)
