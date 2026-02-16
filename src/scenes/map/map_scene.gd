## Module: map_scene.gd
## Restored English comments for maintainability and i18n coding standards.

extends Node2D

const VIEWPORT_W := 540
const VIEWPORT_H := 960
const MAP_Y := 80
const MAP_H := 560
const PANEL_Y := 660
const PANEL_H := 200
const BUTTON_BAR_Y := 880

const MAP_LAT_MIN := 37.5
const MAP_LAT_MAX := 38.7
const MAP_LNG_MIN := 26.8
const MAP_LNG_MAX := 29.4

const STOP_RADIUS := 18.0
const STOP_RADIUS_SELECTED := 24.0

const COLOR_BG := Color("#1a1a2e")
const COLOR_HEADER := Color("#16213e")
const COLOR_MAP_BG := Color("#0a3d62")
const COLOR_LAND := Color("#2d5016")
const COLOR_STOP := Color("#ecf0f1")
const COLOR_STOP_START := Color("#27ae60")
const COLOR_STOP_END := Color("#e74c3c")
const COLOR_STOP_BETWEEN := Color("#3498db")
const COLOR_ROUTE_LINE := Color("#f39c12")
const COLOR_TEXT := Color("#ecf0f1")
const COLOR_GOLD := Color("#f39c12")
const COLOR_GREEN := Color("#27ae60")
const COLOR_RED := Color("#e74c3c")
const COLOR_PANEL := Color("#16213e")
const COLOR_BUTTON := Color("#2980b9")
const COLOR_BUTTON_DISABLED := Color("#555555")
const COLOR_LOCKED := Color("#333333")

var _stop_nodes: Array = []
var _route_line_nodes: Array = []
var _selected_start: int = -1
var _selected_end: int = -1
var _info_label: Label
var _quest_title_label: Label
var _quest_detail_label: Label
var _money_label: Label
var _start_button: Control
var _start_button_bg: ColorRect
var _popup: Control = null

## Lifecycle/helper logic for `_ready`.
func _ready() -> void:
	_build_scene()
	_refresh_all()
	_apply_accessibility()

## Lifecycle/helper logic for `_build_scene`.
func _build_scene() -> void:
	_build_background()
	_build_header()
	_build_map()
	_build_stops()
	_build_panel()
	_build_buttons()

## Lifecycle/helper logic for `_build_background`.
func _build_background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = COLOR_BG
	add_child(bg)

## Lifecycle/helper logic for `_build_header`.
func _build_header() -> void:
	var header := ColorRect.new()
	header.size = Vector2(VIEWPORT_W, MAP_Y)
	header.color = COLOR_HEADER
	add_child(header)

	var title := Label.new()
	title.text = I18n.t("map.title")
	title.position = Vector2(20, 15)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	add_child(title)

	_money_label = Label.new()
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_money_label.position = Vector2(VIEWPORT_W - 160, 15)
	_money_label.size = Vector2(140, 30)
	_money_label.add_theme_font_size_override("font_size", 18)
	_money_label.add_theme_color_override("font_color", COLOR_GOLD)
	add_child(_money_label)

	var hint := Label.new()
	hint.text = I18n.t("map.hint.select")
	hint.position = Vector2(20, 48)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color("#888888"))
	add_child(hint)

## Lifecycle/helper logic for `_build_map`.
func _build_map() -> void:

	var sea := ColorRect.new()
	sea.position = Vector2(0, MAP_Y)
	sea.size = Vector2(VIEWPORT_W, MAP_H)
	sea.color = COLOR_MAP_BG
	add_child(sea)

	var land := ColorRect.new()
	land.position = Vector2(40, MAP_Y + 40)
	land.size = Vector2(VIEWPORT_W - 80, MAP_H - 80)
	land.color = COLOR_LAND
	add_child(land)

	var coast := ColorRect.new()
	coast.position = Vector2(38, MAP_Y + 38)
	coast.size = Vector2(VIEWPORT_W - 76, MAP_H - 76)
	coast.color = Color("#1a6b3d")
	coast.z_index = -1
	add_child(coast)

	_add_locked_region(I18n.t("map.region.marmara"), Vector2(220, MAP_Y + 50))
	_add_locked_region(I18n.t("map.region.inner_anatolia"), Vector2(380, MAP_Y + 200))

## Lifecycle/helper logic for `_add_locked_region`.
func _add_locked_region(region_name: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = I18n.t("map.region.locked", [region_name])
	label.position = pos
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", COLOR_LOCKED)
	add_child(label)

## Lifecycle/helper logic for `_build_stops`.
func _build_stops() -> void:
	var gm: Node = _get_game_manager()
	if not gm:
		return

	var route: RouteData = gm.route

	for i in range(route.get_stop_count() - 1):
		var stop_a: Dictionary = route.get_stop(i)
		var stop_b: Dictionary = route.get_stop(i + 1)
		var pos_a := _gps_to_screen(stop_a["lat"], stop_a["lng"])
		var pos_b := _gps_to_screen(stop_b["lat"], stop_b["lng"])

		var dx := pos_b.x - pos_a.x
		var dy := pos_b.y - pos_a.y
		var length := sqrt(dx * dx + dy * dy)
		var angle := atan2(dy, dx)

		var line := ColorRect.new()
		line.size = Vector2(length, 3)
		line.position = pos_a
		line.rotation = angle
		line.color = Color("#444444")
		line.z_index = 1
		add_child(line)
		_route_line_nodes.append(line)

	for i in route.get_stop_count():
		var stop: Dictionary = route.get_stop(i)
		var pos := _gps_to_screen(stop["lat"], stop["lng"])

		var node := Control.new()
		node.position = pos - Vector2(STOP_RADIUS, STOP_RADIUS)
		node.size = Vector2(STOP_RADIUS * 2, STOP_RADIUS * 2)
		node.z_index = 5

		var circle := ColorRect.new()
		circle.size = Vector2(STOP_RADIUS * 2, STOP_RADIUS * 2)
		circle.color = COLOR_STOP
		node.add_child(circle)

		var label := Label.new()
		var display_name: String = stop["name"]
		if display_name.length() > 10:
			display_name = display_name.substr(0, 10)
		label.text = display_name
		label.position = Vector2(-15, STOP_RADIUS * 2 + 2)
		label.size = Vector2(STOP_RADIUS * 2 + 30, 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", COLOR_TEXT)
		node.add_child(label)

		add_child(node)
		_stop_nodes.append(node)

## Lifecycle/helper logic for `_build_panel`.
func _build_panel() -> void:
	var panel := ColorRect.new()
	panel.position = Vector2(0, PANEL_Y)
	panel.size = Vector2(VIEWPORT_W, PANEL_H)
	panel.color = COLOR_PANEL
	add_child(panel)

	var title := Label.new()
	title.text = I18n.t("map.panel.title")
	title.position = Vector2(20, PANEL_Y + 10)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("#888888"))
	add_child(title)

	_info_label = Label.new()
	_info_label.position = Vector2(20, PANEL_Y + 35)
	_info_label.size = Vector2(VIEWPORT_W - 40, 150)
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", COLOR_TEXT)
	add_child(_info_label)

	_quest_title_label = Label.new()
	_quest_title_label.position = Vector2(20, PANEL_Y + 125)
	_quest_title_label.size = Vector2(VIEWPORT_W - 40, 20)
	_quest_title_label.add_theme_font_size_override("font_size", 13)
	_quest_title_label.add_theme_color_override("font_color", Color("#f1c40f"))
	add_child(_quest_title_label)

	_quest_detail_label = Label.new()
	_quest_detail_label.position = Vector2(20, PANEL_Y + 145)
	_quest_detail_label.size = Vector2(VIEWPORT_W - 40, 48)
	_quest_detail_label.add_theme_font_size_override("font_size", 11)
	_quest_detail_label.add_theme_color_override("font_color", Color("#d5d8dc"))
	_quest_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_quest_detail_label)

## Lifecycle/helper logic for `_build_buttons`.
func _build_buttons() -> void:

	var back_btn := _create_button(I18n.t("map.button.back_garage"), Vector2(20, BUTTON_BAR_Y), Vector2(220, 55), COLOR_BUTTON)
	back_btn.name = "BackButton"
	add_child(back_btn)

	_start_button = _create_button(I18n.t("map.button.start_trip"), Vector2(260, BUTTON_BAR_Y), Vector2(260, 55), COLOR_GREEN)
	_start_button.name = "StartButton"
	_start_button_bg = _start_button.get_child(0) as ColorRect
	add_child(_start_button)

	var achievements_btn := _create_button(I18n.t("map.button.achievements"), Vector2(20, BUTTON_BAR_Y - 54), Vector2(160, 44), Color("#9b59b6"))
	achievements_btn.name = "AchievementsButton"
	add_child(achievements_btn)

	var settings_btn := _create_button(I18n.t("map.button.settings"), Vector2(190, BUTTON_BAR_Y - 54), Vector2(160, 44), Color("#34495e"))
	settings_btn.name = "SettingsButton"
	add_child(settings_btn)

## Lifecycle/helper logic for `_create_button`.
func _create_button(text: String, pos: Vector2, btn_size: Vector2, color: Color) -> Control:
	var container := Control.new()
	container.position = pos
	container.size = btn_size

	var bg := ColorRect.new()
	bg.size = btn_size
	bg.color = color
	container.add_child(bg)

	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(0, btn_size.y * 0.25)
	lbl.size = btn_size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", COLOR_TEXT)
	container.add_child(lbl)

	return container

## Lifecycle/helper logic for `_refresh_all`.
func _refresh_all() -> void:
	_refresh_money()
	_refresh_stops()
	_refresh_route_lines()
	_refresh_panel()
	_refresh_quest_panel()
	_refresh_stop_badges()
	_refresh_start_button()

## Lifecycle/helper logic for `_refresh_money`.
func _refresh_money() -> void:
	var gm: Node = _get_game_manager()
	if gm:
		_money_label.text = "%d DA" % gm.economy.get_balance()

## Lifecycle/helper logic for `_refresh_stops`.
func _refresh_stops() -> void:
	var gm: Node = _get_game_manager()
	if not gm:
		return

	for i in _stop_nodes.size():
		var node: Control = _stop_nodes[i]
		var circle: ColorRect = node.get_child(0)

		if i == _selected_start:
			circle.color = COLOR_STOP_START
			circle.size = Vector2(STOP_RADIUS_SELECTED * 2, STOP_RADIUS_SELECTED * 2)
			node.position = _gps_to_screen(
				gm.route.get_stop(i)["lat"], gm.route.get_stop(i)["lng"]
			) - Vector2(STOP_RADIUS_SELECTED, STOP_RADIUS_SELECTED)
		elif i == _selected_end:
			circle.color = COLOR_STOP_END
			circle.size = Vector2(STOP_RADIUS_SELECTED * 2, STOP_RADIUS_SELECTED * 2)
			node.position = _gps_to_screen(
				gm.route.get_stop(i)["lat"], gm.route.get_stop(i)["lng"]
			) - Vector2(STOP_RADIUS_SELECTED, STOP_RADIUS_SELECTED)
		elif _is_between_selection(i):
			circle.color = COLOR_STOP_BETWEEN
			circle.size = Vector2(STOP_RADIUS * 2, STOP_RADIUS * 2)
		else:
			circle.color = COLOR_STOP
			circle.size = Vector2(STOP_RADIUS * 2, STOP_RADIUS * 2)

## Lifecycle/helper logic for `_refresh_route_lines`.
func _refresh_route_lines() -> void:
	for i in _route_line_nodes.size():
		var line: ColorRect = _route_line_nodes[i]
		if _is_segment_selected(i):
			line.color = COLOR_ROUTE_LINE
			line.size.y = 5
		else:
			line.color = Color("#444444")
			line.size.y = 3

## Lifecycle/helper logic for `_refresh_panel`.
func _refresh_panel() -> void:
	if _selected_start < 0 or _selected_end < 0:
		_info_label.text = I18n.t("map.info.select_stops")
		return

	var gm: Node = _get_game_manager()
	if not gm:
		return

	gm.sync_trip_wagon_count()
	gm.trip_planner.select_stops(_selected_start, _selected_end)
	var preview: Dictionary = gm.trip_planner.get_preview()

	var start_name: String = gm.route.get_stop(_selected_start)["name"]
	var end_name: String = gm.route.get_stop(_selected_end)["name"]

	var fuel_status := I18n.t("map.info.fuel_ok") if preview["can_afford_fuel"] else I18n.t("map.info.fuel_insufficient")
	_info_label.text = (
		"%s  -->  %s\n" % [start_name, end_name] +
		I18n.t(
			"map.info.preview",
			[preview["distance_km"], preview["stop_count"], preview["refuel_cost"], preview["estimated_revenue"], fuel_status]
		)
	)

	if not preview["can_afford_fuel"]:
		_info_label.add_theme_color_override("font_color", COLOR_RED)
	else:
		_info_label.add_theme_color_override("font_color", COLOR_TEXT)

## Lifecycle/helper logic for `_refresh_start_button`.
func _refresh_start_button() -> void:
	var can_start := _selected_start >= 0 and _selected_end >= 0
	if can_start:
		var gm: Node = _get_game_manager()
		if gm:
			var preview: Dictionary = gm.trip_planner.get_preview()
			can_start = preview.get("can_afford_fuel", false)

	_start_button_bg.color = COLOR_GREEN if can_start else COLOR_BUTTON_DISABLED

## Lifecycle/helper logic for `_refresh_quest_panel`.
func _refresh_quest_panel() -> void:
	var gm: Node = _get_game_manager()
	if gm == null or gm.quest_system == null:
		_quest_title_label.text = I18n.t("map.quest.none")
		_quest_detail_label.text = ""
		return

	var active: Dictionary = gm.quest_system.get_active_quest()
	if active.is_empty() and gm.quest_system.activate_available_quest():
		active = gm.quest_system.get_active_quest()
	if active.is_empty():
		_quest_title_label.text = I18n.t("map.quest.none")
		_quest_detail_label.text = ""
		return

	var progress: Dictionary = gm.quest_system.get_quest_progress(str(active.get("id", "")))
	var current: int = int(progress.get("current", 0))
	var target: int = int(progress.get("target", 1))
	_quest_title_label.text = I18n.t("map.quest.title", [I18n.t(str(active.get("title_key", "")))])
	_quest_detail_label.text = "%s\n%s" % [
		I18n.t(str(active.get("description_key", ""))),
		I18n.t("map.quest.progress", [current, target]),
	]

## Lifecycle/helper logic for `_refresh_stop_badges`.
func _refresh_stop_badges() -> void:
	var gm: Node = _get_game_manager()
	if gm == null:
		return

	var active: Dictionary = {}
	if gm.quest_system:
		active = gm.quest_system.get_active_quest()

	for i in _stop_nodes.size():
		var node: Control = _stop_nodes[i]
		for child in node.get_children():
			if child is Label and (child.name == "QuestBadge" or child.name == "CargoBadge" or child.name == "ShopBadge"):
				child.queue_free()

		var stop: Dictionary = gm.route.get_stop(i)
		var stop_name: String = str(stop.get("name", ""))
		if _is_quest_target_stop(stop_name, active):
			var quest_badge := Label.new()
			quest_badge.name = "QuestBadge"
			quest_badge.text = "!"
			quest_badge.position = Vector2(STOP_RADIUS * 2 - 6, -10)
			quest_badge.add_theme_font_size_override("font_size", 16)
			quest_badge.add_theme_color_override("font_color", Color("#f1c40f"))
			node.add_child(quest_badge)

		if gm.cargo_system and gm.cargo_system.has_offers_for_station(stop_name):
			var cargo_badge := Label.new()
			cargo_badge.name = "CargoBadge"
			cargo_badge.text = I18n.t("map.badge.cargo")
			cargo_badge.position = Vector2(-10, -10)
			cargo_badge.add_theme_font_size_override("font_size", 12)
			cargo_badge.add_theme_color_override("font_color", Color("#2ecc71"))
			node.add_child(cargo_badge)

		if gm.shop_system and not gm.shop_system.get_station_shops(stop_name).is_empty():
			var shop_badge := Label.new()
			shop_badge.name = "ShopBadge"
			shop_badge.text = I18n.t("map.badge.shop")
			shop_badge.position = Vector2(14, -10)
			shop_badge.add_theme_font_size_override("font_size", 12)
			shop_badge.add_theme_color_override("font_color", Color("#f1c40f"))
			node.add_child(shop_badge)

## Lifecycle/helper logic for `_is_quest_target_stop`.
func _is_quest_target_stop(stop_name: String, active_quest: Dictionary) -> bool:
	if active_quest.is_empty():
		return false
	var conditions: Dictionary = active_quest.get("conditions", {})
	var quest_type: int = int(active_quest.get("type", -1))
	var normalized: String = stop_name.to_lower()

	if quest_type == Constants.QuestType.CARGO_DELIVERY:
		var origin: String = str(conditions.get("origin", ""))
		return normalized.find(origin) >= 0

	var destination: String = str(conditions.get("destination", ""))
	if destination.is_empty():
		return false
	return normalized.find(destination) >= 0

## Lifecycle/helper logic for `_input`.
func _input(event: InputEvent) -> void:
	if _should_ignore_mouse_event(event):
		return

	if _popup:
		_handle_popup_input(event)
		return

	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if not _is_pressed(event):
		return

	var pos := _get_event_position(event)

	var back_btn: Control = get_node("BackButton")
	if _is_in_rect(pos, back_btn.position, back_btn.size):
		get_tree().change_scene_to_file("res://src/scenes/garage/garage_scene.tscn")
		return

	var achievements_btn: Control = get_node("AchievementsButton")
	if _is_in_rect(pos, achievements_btn.position, achievements_btn.size):
		get_tree().change_scene_to_file("res://src/scenes/achievements/achievements_scene.tscn")
		return

	var settings_btn: Control = get_node("SettingsButton")
	if _is_in_rect(pos, settings_btn.position, settings_btn.size):
		get_tree().change_scene_to_file("res://src/scenes/settings/settings_scene.tscn")
		return

	var start_btn: Control = get_node("StartButton")
	if _is_in_rect(pos, start_btn.position, start_btn.size):
		_try_start_trip()
		return

	for i in _stop_nodes.size():
		var node: Control = _stop_nodes[i]
		if _is_in_rect(pos, node.position, node.size):
			_on_stop_clicked(i)
			return

## Lifecycle/helper logic for `_handle_popup_input`.
func _handle_popup_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if not _is_pressed(event):
		return

	_popup.queue_free()
	_popup = null

## Lifecycle/helper logic for `_on_stop_clicked`.
func _on_stop_clicked(index: int) -> void:
	if _selected_start < 0:

		_selected_start = index
	elif _selected_end < 0:
		if index == _selected_start:

			_selected_start = -1
		else:

			_selected_end = index
			var gm: Node = _get_game_manager()
			if gm and gm.tutorial_manager:
				gm.tutorial_manager.notify("map_selected")
	else:

		_selected_start = index
		_selected_end = -1

	_refresh_all()

## Lifecycle/helper logic for `_try_start_trip`.
func _try_start_trip() -> void:
	if _selected_start < 0 or _selected_end < 0:
		return

	var gm: Node = _get_game_manager()
	if not gm:
		return

	gm.sync_trip_wagon_count()
	gm.trip_planner.select_stops(_selected_start, _selected_end)
	if gm.trip_planner.start_trip():
		get_tree().change_scene_to_file("res://src/scenes/travel/travel_scene.tscn")

## Lifecycle/helper logic for `_gps_to_screen`.
func _gps_to_screen(lat: float, lng: float) -> Vector2:
	var x_ratio := (lng - MAP_LNG_MIN) / (MAP_LNG_MAX - MAP_LNG_MIN)

	var y_ratio := 1.0 - (lat - MAP_LAT_MIN) / (MAP_LAT_MAX - MAP_LAT_MIN)
	var margin := 60.0
	var x := margin + x_ratio * (VIEWPORT_W - margin * 2)
	var y := MAP_Y + margin + y_ratio * (MAP_H - margin * 2)
	return Vector2(x, y)

## Lifecycle/helper logic for `_is_between_selection`.
func _is_between_selection(index: int) -> bool:
	if _selected_start < 0 or _selected_end < 0:
		return false
	var from := mini(_selected_start, _selected_end)
	var to := maxi(_selected_start, _selected_end)
	return index > from and index < to

## Lifecycle/helper logic for `_is_segment_selected`.
func _is_segment_selected(segment_index: int) -> bool:
	if _selected_start < 0 or _selected_end < 0:
		return false
	var from := mini(_selected_start, _selected_end)
	var to := maxi(_selected_start, _selected_end)
	return segment_index >= from and segment_index < to

## Lifecycle/helper logic for `_get_game_manager`.
func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

## Lifecycle/helper logic for `_get_event_position`.
func _get_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return event.position
	elif event is InputEventMouseButton:
		return event.position
	return Vector2.ZERO

## Lifecycle/helper logic for `_is_pressed`.
func _is_pressed(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	elif event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false

## Lifecycle/helper logic for `_is_in_rect`.
func _is_in_rect(pos: Vector2, rect_pos: Vector2, rect_size: Vector2) -> bool:
	return pos.x >= rect_pos.x and pos.x <= rect_pos.x + rect_size.x \
		and pos.y >= rect_pos.y and pos.y <= rect_pos.y + rect_size.y

## Lifecycle/helper logic for `_should_ignore_mouse_event`.
func _should_ignore_mouse_event(event: InputEvent) -> bool:
	var emulate_touch: bool = ProjectSettings.get_setting(
		"input_devices/pointing/emulate_touch_from_mouse",
		false
	)
	if not emulate_touch:
		return false
	return event is InputEventMouseButton

func _apply_accessibility() -> void:
	var gm: Node = _get_game_manager()
	if gm and gm.settings_system:
		gm.settings_system.apply_font_scale_recursive(self)
