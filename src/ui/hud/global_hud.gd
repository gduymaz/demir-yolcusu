## Module: global_hud.gd
## Event-driven top HUD with pause controls for active gameplay scenes.

extends CanvasLayer

const VIEWPORT_W := 540
const BAR_H := 74
const FUEL_BAR_WIDTH := 158.0

const COLOR_BG := Color(0.07, 0.08, 0.15, 0.86)
const COLOR_TEXT := Color("#ecf0f1")
const COLOR_GOLD := Color("#f1c40f")
const COLOR_FUEL_OK := Color("#27ae60")
const COLOR_FUEL_WARN := Color("#f39c12")
const COLOR_FUEL_CRIT := Color("#e74c3c")

var _event_bus: Node
var _bar: ColorRect
var _money: Label
var _reputation: Label
var _achievement: Label
var _title: Label
var _fuel_fill: ColorRect
var _fuel_text: Label
var _pause_button: Button

var _pause_overlay: ColorRect
var _pause_panel: PanelContainer
var _pause_visible: bool = false

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_event_bus = get_node_or_null("/root/EventBus")
	_build()
	_bind_signals()
	_refresh()

func _build() -> void:
	_bar = ColorRect.new()
	_bar.position = Vector2.ZERO
	_bar.size = Vector2(VIEWPORT_W, BAR_H)
	_bar.color = COLOR_BG
	add_child(_bar)

	var coin := ColorRect.new()
	coin.position = Vector2(10, 13)
	coin.size = Vector2(14, 14)
	coin.color = COLOR_GOLD
	_bar.add_child(coin)

	_money = Label.new()
	_money.position = Vector2(28, 8)
	_money.size = Vector2(170, 22)
	_money.add_theme_font_size_override("font_size", 16)
	_money.add_theme_color_override("font_color", COLOR_GOLD)
	_bar.add_child(_money)

	var star := ColorRect.new()
	star.position = Vector2(10, 41)
	star.size = Vector2(14, 14)
	star.color = Color("#95a5a6")
	_bar.add_child(star)

	_reputation = Label.new()
	_reputation.position = Vector2(28, 36)
	_reputation.size = Vector2(130, 22)
	_reputation.add_theme_font_size_override("font_size", 14)
	_reputation.add_theme_color_override("font_color", COLOR_TEXT)
	_bar.add_child(_reputation)

	_achievement = Label.new()
	_achievement.position = Vector2(162, 36)
	_achievement.size = Vector2(90, 22)
	_achievement.add_theme_font_size_override("font_size", 13)
	_achievement.add_theme_color_override("font_color", Color("#f7dc6f"))
	_bar.add_child(_achievement)

	_title = Label.new()
	_title.position = Vector2(180, 8)
	_title.size = Vector2(180, 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 16)
	_title.add_theme_color_override("font_color", COLOR_TEXT)
	_bar.add_child(_title)

	var fuel_bg := ColorRect.new()
	fuel_bg.position = Vector2(365, 16)
	fuel_bg.size = Vector2(FUEL_BAR_WIDTH, 18)
	fuel_bg.color = Color("#2c3e50")
	_bar.add_child(fuel_bg)

	_fuel_fill = ColorRect.new()
	_fuel_fill.position = Vector2(365, 16)
	_fuel_fill.size = Vector2(FUEL_BAR_WIDTH, 18)
	_fuel_fill.color = COLOR_FUEL_OK
	_bar.add_child(_fuel_fill)

	_fuel_text = Label.new()
	_fuel_text.position = Vector2(365, 38)
	_fuel_text.size = Vector2(FUEL_BAR_WIDTH, 22)
	_fuel_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fuel_text.add_theme_font_size_override("font_size", 13)
	_fuel_text.add_theme_color_override("font_color", COLOR_TEXT)
	_bar.add_child(_fuel_text)

	_pause_button = Button.new()
	_pause_button.position = Vector2(500, 6)
	_pause_button.size = Vector2(34, 26)
	_pause_button.text = "||"
	_pause_button.pressed.connect(_toggle_pause_overlay)
	_bar.add_child(_pause_button)

	_build_pause_overlay()

func _build_pause_overlay() -> void:
	_pause_overlay = ColorRect.new()
	_pause_overlay.visible = false
	_pause_overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	_pause_overlay.position = Vector2.ZERO
	_pause_overlay.size = Vector2(VIEWPORT_W, 960)
	add_child(_pause_overlay)

	_pause_panel = PanelContainer.new()
	_pause_panel.size = Vector2(340, 260)
	_pause_panel.position = Vector2(100, 300)
	_pause_overlay.add_child(_pause_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(300, 220)
	_pause_panel.add_child(vbox)

	var title := Label.new()
	title.text = I18n.t("pause.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var continue_btn := Button.new()
	continue_btn.text = I18n.t("pause.continue")
	continue_btn.custom_minimum_size = Vector2(280, 40)
	continue_btn.pressed.connect(_close_pause_overlay)
	vbox.add_child(continue_btn)

	var settings_btn := Button.new()
	settings_btn.text = I18n.t("pause.settings")
	settings_btn.custom_minimum_size = Vector2(280, 40)
	settings_btn.pressed.connect(func() -> void:
		_close_pause_overlay()
		_transition_to("res://src/scenes/settings/settings_scene.tscn")
	)
	vbox.add_child(settings_btn)

	var menu_btn := Button.new()
	menu_btn.text = I18n.t("pause.main_menu")
	menu_btn.custom_minimum_size = Vector2(280, 40)
	menu_btn.pressed.connect(func() -> void:
		_close_pause_overlay()
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm:
			gm.save_game()
		_transition_to("res://src/scenes/main_menu/main_menu.tscn")
	)
	vbox.add_child(menu_btn)

func _bind_signals() -> void:
	if _event_bus:
		if not _event_bus.money_changed.is_connected(_refresh):
			_event_bus.money_changed.connect(func(_old_value: int, _new_value: int, _reason: String) -> void:
				_refresh()
			)
		if not _event_bus.reputation_changed.is_connected(_refresh):
			_event_bus.reputation_changed.connect(func(_old_value: float, _new_value: float) -> void:
				_refresh()
			)
		if not _event_bus.fuel_changed.is_connected(_refresh):
			_event_bus.fuel_changed.connect(func(_percentage: float) -> void:
				_refresh()
			)
		if not _event_bus.achievement_unlocked.is_connected(_refresh):
			_event_bus.achievement_unlocked.connect(func(_data: Dictionary) -> void:
				_refresh()
			)
	_bind_scene_signal()

func _on_scene_changed(_scene: Node) -> void:
	_close_pause_overlay()
	_refresh()

func _on_scene_changed_no_args() -> void:
	_on_scene_changed(get_tree().current_scene)

func _bind_scene_signal() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if tree.has_signal("current_scene_changed"):
		var cb := Callable(self, "_on_scene_changed")
		if not tree.is_connected("current_scene_changed", cb):
			tree.connect("current_scene_changed", cb)
		return
	if tree.has_signal("scene_changed"):
		var cb2 := Callable(self, "_on_scene_changed_no_args")
		if not tree.is_connected("scene_changed", cb2):
			tree.connect("scene_changed", cb2)

func _refresh() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		_money.text = "0 DA"
		_reputation.text = I18n.t("hud.reputation", [0.0])
		_achievement.text = I18n.t("hud.achievements", [0, 0])
		_fuel_fill.size.x = 0.0
		_fuel_text.text = I18n.t("hud.fuel_unknown")
		_title.text = I18n.t("hud.title.game")
		_pause_button.visible = false
		return

	var scene := get_tree().current_scene
	var path: String = scene.scene_file_path if scene else ""
	visible = not path.contains("main_menu") and not path.contains("splash_scene")
	if not visible:
		return

	_money.text = "%d DA" % gm.economy.get_balance()
	_reputation.text = I18n.t("hud.reputation", [gm.reputation.get_stars()])

	var unlocked_count: int = 0
	var total_count: int = 0
	if gm.achievement_system:
		unlocked_count = gm.achievement_system.get_unlocked_count()
		total_count = gm.achievement_system.get_total_count()
	_achievement.text = I18n.t("hud.achievements", [unlocked_count, total_count])

	var fuel_pct: float = gm.fuel_system.get_fuel_percentage()
	var clamped := clampf(fuel_pct, 0.0, 100.0)
	_fuel_fill.size.x = FUEL_BAR_WIDTH * (clamped / 100.0)
	_fuel_text.text = I18n.t("hud.fuel_percent", [clamped])
	if clamped < Balance.FUEL_CRITICAL_THRESHOLD:
		_fuel_fill.color = COLOR_FUEL_CRIT
	elif clamped < Balance.FUEL_LOW_THRESHOLD:
		_fuel_fill.color = COLOR_FUEL_WARN
	else:
		_fuel_fill.color = COLOR_FUEL_OK

	_title.text = _resolve_scene_title(gm)
	_pause_button.visible = _is_pause_allowed_scene()

func _resolve_scene_title(gm: Node) -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return I18n.t("hud.title.game")

	var path: String = scene.scene_file_path
	if path.contains("garage_scene"):
		return I18n.t("hud.title.garage")
	if path.contains("map_scene"):
		return I18n.t("hud.title.map")
	if path.contains("travel_scene"):
		return I18n.t("hud.title.travel")
	if path.contains("station_scene"):
		if gm.trip_planner != null and gm.trip_planner.is_trip_active():
			var stop: Dictionary = gm.trip_planner.get_current_stop()
			return stop.get("name", I18n.t("hud.title.station"))
		return I18n.t("hud.title.station")
	if path.contains("summary_scene"):
		return I18n.t("hud.title.summary")
	if path.contains("main_menu"):
		return I18n.t("menu.title")
	return I18n.t("hud.title.game")

func _is_pause_allowed_scene() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var path: String = scene.scene_file_path
	return path.contains("station_scene") or path.contains("travel_scene")

func _toggle_pause_overlay() -> void:
	if not _is_pause_allowed_scene():
		return
	if _pause_visible:
		_close_pause_overlay()
	else:
		_open_pause_overlay()

func _open_pause_overlay() -> void:
	_pause_visible = true
	_pause_overlay.visible = true
	get_tree().paused = true

func _close_pause_overlay() -> void:
	_pause_visible = false
	_pause_overlay.visible = false
	get_tree().paused = false

func _transition_to(scene_path: String) -> void:
	var transition := get_node_or_null("/root/SceneTransition")
	if transition and transition.has_method("transition_to"):
		transition.transition_to(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)
