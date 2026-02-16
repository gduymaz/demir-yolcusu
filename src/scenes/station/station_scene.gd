## Module: station_scene.gd
## Restored English comments for maintainability and i18n coding standards.

extends Node2D

var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem
var _boarding: BoardingSystem
var _patience: PatienceSystem

var _wagons: Array = []
var _waiting_passengers: Array[Dictionary] = []
var _station_time: float = Constants.STATION_TIME_LARGE
var _time_remaining: float = 0.0
var _is_active: bool = false

var _dragged_passenger_index: int = -1
var _drag_offset: Vector2 = Vector2.ZERO

var _hud_timer: Label
var _hud_station: Label
var _passenger_nodes: Array = []
var _wagon_nodes: Array = []
var _summary_panel: PanelContainer
var _summary_label: Label
var _fuel_button: Button
var _fuel_progress_bg: ColorRect
var _fuel_progress_fill: ColorRect
var _cargo_panel: PanelContainer
var _cargo_list: VBoxContainer
var _cargo_note_label: Label
var _cargo_info_label: Label
var _cargo_button_map: Dictionary = {}
var _shop_button: Button
var _shop_panel: PanelContainer
var _shop_rows: Array = []
var _event_banner: Label
var _event_icon_label: Label
var _special_action_button: Button
var _refuel_progress: float = 0.0
var _refuel_in_progress: bool = false
var _event_banner_timer: float = 0.0
var _station_ticket_start: int = 0
var _timer_half_notified: bool = false
var _first_boarded_notified: bool = false

const VIEWPORT_W := 540
const VIEWPORT_H := 960
const TRAIN_Y := 320.0
const WAGON_SPACING := 130.0
const WAITING_Y := 650.0
const WAITING_START_X := 70.0
const WAITING_SPACING := 100.0
const PASSENGER_SIZE := Vector2(40, 56)
const WAGON_SIZE := Vector2(100, 70)
const LOCO_SIZE := Vector2(100, 80)

const COLOR_BG := Color("#87CEEB")
const COLOR_PLATFORM := Color("#D4AC6E")
const COLOR_RAIL := Color("#5D6D7E")
const COLOR_LOCO := Color("#C0392B")
const COLOR_WAGON_ECONOMY := Color("#3498DB")
const COLOR_WAGON_BUSINESS := Color("#2C3E50")
const COLOR_WAGON_VIP := Color("#F1C40F")
const COLOR_WAGON_DINING := Color("#27AE60")
const COLOR_WAGON_CARGO := Color("#8B4513")
const COLOR_PASSENGER_NORMAL := Color("#3498DB")
const COLOR_PASSENGER_VIP := Color("#F1C40F")
const COLOR_PASSENGER_STUDENT := Color("#27AE60")
const COLOR_PASSENGER_ELDERLY := Color("#8E44AD")
const COLOR_SUCCESS := Color("#27AE60")
const COLOR_FAIL := Color("#E74C3C")
const COLOR_HUD_BG := Color(0.17, 0.24, 0.31, 0.85)
const COLOR_EVENT := Color("#f4d03f")
const COLOR_QUEST_TARGET := Color("#f1c40f")

## Lifecycle/helper logic for `_ready`.
func _ready() -> void:
	_setup_systems()
	_build_scene()
	_apply_accessibility()
	_start_station()

## Lifecycle/helper logic for `_process`.
func _process(delta: float) -> void:
	_process_refuel(delta)
	_update_refuel_controls()
	_update_event_banner(delta)

	if not _is_active:
		return

	_time_remaining -= delta
	_hud_timer.text = I18n.t("station.hud.time", [ceili(_time_remaining)])

	if _time_remaining <= 0.0:
		_end_station()
		return
	if not _timer_half_notified and _time_remaining <= (_station_time * 0.5):
		_timer_half_notified = true
		var gm_notify: Node = get_node_or_null("/root/GameManager")
		if gm_notify and gm_notify.tutorial_manager:
			gm_notify.tutorial_manager.notify("timer_half")

	var patience_delta: float = delta
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("get_station_patience_multiplier"):
		patience_delta *= gm.get_station_patience_multiplier(_get_current_station_name())
	var lost := _patience.update(_waiting_passengers, patience_delta)
	if lost.size() > 0:
		var conductor: Node = get_node_or_null("/root/ConductorManager")
		if conductor:
			conductor.show_runtime_tip("tip_passenger_lost", I18n.t("conductor.tip.passenger_lost"))
		_rebuild_passenger_nodes()

	_update_patience_bars()

## Lifecycle/helper logic for `_update_event_banner`.
func _update_event_banner(delta: float) -> void:
	if _event_banner == null or _event_banner_timer <= 0.0:
		return
	_event_banner_timer = maxf(0.0, _event_banner_timer - delta)
	if _event_banner_timer <= 0.0:
		_event_banner.visible = false

## Lifecycle/helper logic for `_setup_systems`.
func _setup_systems() -> void:

	var gm: Node = get_node_or_null("/root/GameManager")

	if gm:

		_event_bus = gm.event_bus
		_economy = gm.economy
		_reputation = gm.reputation

		var config: TrainConfig = gm.train_config
		_wagons = []
		for wagon in config.get_wagons():
			_wagons.append(wagon)
	else:

		_event_bus = get_node_or_null("/root/EventBus")
		if not _event_bus:
			_event_bus = load("res://src/events/event_bus.gd").new()
			add_child(_event_bus)

		_economy = EconomySystem.new()
		_economy.setup(_event_bus)
		add_child(_economy)

		_reputation = ReputationSystem.new()
		_reputation.setup(_event_bus)
		add_child(_reputation)

		_wagons = [
			WagonData.new(Constants.WagonType.ECONOMY),
			WagonData.new(Constants.WagonType.BUSINESS),
		]

	_boarding = BoardingSystem.new()
	_boarding.setup(_event_bus, _economy, _reputation)
	add_child(_boarding)

	_patience = PatienceSystem.new()
	_patience.setup(_event_bus, _reputation)
	add_child(_patience)

## Lifecycle/helper logic for `_build_scene`.
func _build_scene() -> void:
	_build_background()
	_build_hud()
	_build_train()
	_build_refuel_controls()
	_build_cargo_panel()
	_build_event_banner()
	_build_summary_panel()

## Lifecycle/helper logic for `_build_background`.
func _build_background() -> void:
	var sky_top := ColorRect.new()
	sky_top.color = Color("#9dd5ff")
	sky_top.size = Vector2(VIEWPORT_W, VIEWPORT_H * 0.45)
	sky_top.z_index = -11
	add_child(sky_top)

	var sky_bottom := ColorRect.new()
	sky_bottom.color = Color("#dbeeff")
	sky_bottom.position = Vector2(0, VIEWPORT_H * 0.45)
	sky_bottom.size = Vector2(VIEWPORT_W, VIEWPORT_H * 0.2)
	sky_bottom.z_index = -11
	add_child(sky_bottom)

	var tree_line := ColorRect.new()
	tree_line.color = Color("#4d8c3a")
	tree_line.position = Vector2(0, TRAIN_Y + 20)
	tree_line.size = Vector2(VIEWPORT_W, 12)
	tree_line.z_index = -9
	add_child(tree_line)

	var platform := ColorRect.new()
	platform.color = COLOR_PLATFORM
	platform.position = Vector2(0, TRAIN_Y + 60)
	platform.size = Vector2(VIEWPORT_W, 200)
	platform.z_index = -5
	add_child(platform)

	var platform_edge := ColorRect.new()
	platform_edge.color = Color("#f7e7b5")
	platform_edge.position = Vector2(0, TRAIN_Y + 56)
	platform_edge.size = Vector2(VIEWPORT_W, 4)
	platform_edge.z_index = -4
	add_child(platform_edge)

	for i in 2:
		var rail := ColorRect.new()
		rail.color = COLOR_RAIL
		rail.position = Vector2(0, TRAIN_Y + 50 + i * 20)
		rail.size = Vector2(VIEWPORT_W, 4)
		rail.z_index = -4
		add_child(rail)

	var wait_line := ColorRect.new()
	wait_line.color = Color(1, 1, 1, 0.3)
	wait_line.position = Vector2(20, WAITING_Y - 40)
	wait_line.size = Vector2(VIEWPORT_W - 40, 2)
	wait_line.z_index = -3
	add_child(wait_line)

	var wait_label := Label.new()
	wait_label.text = I18n.t("station.waiting_area")
	wait_label.position = Vector2(VIEWPORT_W / 2.0 - 80, WAITING_Y - 60)
	wait_label.add_theme_font_size_override("font_size", 14)
	wait_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	add_child(wait_label)

## Lifecycle/helper logic for `_build_hud`.
func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	_hud_timer = Label.new()
	_hud_timer.position = Vector2(VIEWPORT_W - 150, 82)
	_hud_timer.add_theme_font_size_override("font_size", 20)
	_hud_timer.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(_hud_timer)

	_hud_station = Label.new()
	_hud_station.position = Vector2(VIEWPORT_W - 200, 108)
	_hud_station.size = Vector2(180, 20)
	_hud_station.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_station.add_theme_font_size_override("font_size", 12)
	_hud_station.add_theme_color_override("font_color", Color("#aaaaaa"))
	canvas.add_child(_hud_station)

	_event_icon_label = Label.new()
	_event_icon_label.position = Vector2(VIEWPORT_W - 52, 128)
	_event_icon_label.size = Vector2(32, 20)
	_event_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_icon_label.add_theme_font_size_override("font_size", 16)
	_event_icon_label.visible = false
	canvas.add_child(_event_icon_label)

## Lifecycle/helper logic for `_build_refuel_controls`.
func _build_refuel_controls() -> void:
	_fuel_button = Button.new()
	_fuel_button.position = Vector2(VIEWPORT_W - 180, 92)
	_fuel_button.size = Vector2(160, 32)
	_fuel_button.text = I18n.t("station.button.refuel")
	add_child(_fuel_button)

	_fuel_progress_bg = ColorRect.new()
	_fuel_progress_bg.position = Vector2(VIEWPORT_W - 180, 128)
	_fuel_progress_bg.size = Vector2(160, 8)
	_fuel_progress_bg.color = Color("#2c3e50")
	add_child(_fuel_progress_bg)

	_fuel_progress_fill = ColorRect.new()
	_fuel_progress_fill.position = Vector2(VIEWPORT_W - 180, 128)
	_fuel_progress_fill.size = Vector2(0, 8)
	_fuel_progress_fill.color = Color("#27ae60")
	add_child(_fuel_progress_fill)

## Lifecycle/helper logic for `_build_shop_controls`.
func _build_shop_controls() -> void:
	_shop_button = Button.new()
	_shop_button.position = Vector2(VIEWPORT_W - 180, 140)
	_shop_button.size = Vector2(160, 28)
	_shop_button.text = I18n.t("station.button.shop")
	add_child(_shop_button)

	_shop_panel = PanelContainer.new()
	_shop_panel.position = Vector2(30, 180)
	_shop_panel.size = Vector2(VIEWPORT_W - 60, 220)
	_shop_panel.visible = false
	add_child(_shop_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.11, 0.2, 0.95)
	style.border_color = Color("#f39c12")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	_shop_panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	_shop_panel.add_child(box)

	var title := Label.new()
	title.text = I18n.t("station.shop.title")
	title.add_theme_font_size_override("font_size", 16)
	box.add_child(title)

	for shop_type in [Constants.ShopType.BUFFET, Constants.ShopType.SOUVENIR, Constants.ShopType.CARGO_DEPOT]:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.name = "Label"
		row.add_child(label)
		var btn := Button.new()
		btn.name = "Action"
		btn.pressed.connect(_on_shop_action_pressed.bind(shop_type))
		row.add_child(btn)
		box.add_child(row)
		_shop_rows.append(row)

	var close_btn := Button.new()
	close_btn.text = I18n.t("station.shop.close")
	close_btn.pressed.connect(func() -> void:
		_shop_panel.visible = false
	)
	box.add_child(close_btn)

## Lifecycle/helper logic for `_build_cargo_panel`.
func _build_cargo_panel() -> void:
	_cargo_panel = PanelContainer.new()
	_cargo_panel.position = Vector2(20, 760)
	_cargo_panel.size = Vector2(VIEWPORT_W - 40, 180)
	add_child(_cargo_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.1, 0.2, 0.92)
	style.border_color = Color("#2c3e50")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	_cargo_panel.add_theme_stylebox_override("panel", style)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cargo_panel.add_child(root)

	var title := Label.new()
	title.text = I18n.t("station.cargo.title")
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("#f1c40f"))
	root.add_child(title)

	_cargo_note_label = Label.new()
	_cargo_note_label.add_theme_font_size_override("font_size", 12)
	_cargo_note_label.add_theme_color_override("font_color", Color("#ecf0f1"))
	root.add_child(_cargo_note_label)

	_cargo_list = VBoxContainer.new()
	root.add_child(_cargo_list)

	_cargo_info_label = Label.new()
	_cargo_info_label.add_theme_font_size_override("font_size", 11)
	_cargo_info_label.add_theme_color_override("font_color", Color("#95a5a6"))
	root.add_child(_cargo_info_label)

## Lifecycle/helper logic for `_build_event_banner`.
func _build_event_banner() -> void:
	_event_banner = Label.new()
	_event_banner.position = Vector2(20, 80)
	_event_banner.size = Vector2(VIEWPORT_W - 40, 24)
	_event_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_event_banner.add_theme_font_size_override("font_size", 14)
	_event_banner.add_theme_color_override("font_color", Color.BLACK)
	_event_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	_event_banner.modulate = COLOR_EVENT
	_event_banner.visible = false
	add_child(_event_banner)

## Lifecycle/helper logic for `_build_train`.
func _build_train() -> void:
	_wagon_nodes.clear()

	var wagon_count := _wagons.size()

	var total_train_w := wagon_count * WAGON_SPACING + LOCO_SIZE.x + 20
	var start_x := maxf(20.0, (VIEWPORT_W - total_train_w) / 2.0)

	for i in wagon_count:
		var wagon: WagonData = _wagons[i]
		var wagon_node := ColorRect.new()
		wagon_node.size = WAGON_SIZE
		wagon_node.color = _get_wagon_color(wagon.type)
		wagon_node.position = Vector2(start_x + i * WAGON_SPACING, TRAIN_Y - WAGON_SIZE.y / 2)
		add_child(wagon_node)
		_wagon_nodes.append(wagon_node)

		if wagon.type == Constants.WagonType.CARGO:
			for x in [12.0, 34.0, 56.0, 78.0]:
				var slash_a := ColorRect.new()
				slash_a.position = Vector2(x, 10)
				slash_a.size = Vector2(2, 50)
				slash_a.rotation = deg_to_rad(38.0)
				slash_a.color = Color("#d7ccc8")
				wagon_node.add_child(slash_a)
		else:
			for w in range(3):
				var window := ColorRect.new()
				window.position = Vector2(8 + w * 30, 8)
				window.size = Vector2(20, 18)
				window.color = Color(1, 1, 1, 0.42)
				wagon_node.add_child(window)

		var label := Label.new()
		label.name = "WagonLabel"
		label.text = "%s\n0/%d" % [_get_wagon_short_name(wagon.type), wagon.get_capacity()]
		label.position = Vector2(8, 12)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		wagon_node.add_child(label)

	for i in range(wagon_count - 1):
		var conn := ColorRect.new()
		conn.color = COLOR_RAIL
		var x1 := start_x + i * WAGON_SPACING + WAGON_SIZE.x
		conn.position = Vector2(x1, TRAIN_Y - 2)
		conn.size = Vector2(WAGON_SPACING - WAGON_SIZE.x, 4)
		add_child(conn)

	var loco_x := start_x + wagon_count * WAGON_SPACING
	var loco := ColorRect.new()
	loco.size = LOCO_SIZE
	loco.color = COLOR_LOCO
	loco.position = Vector2(loco_x, TRAIN_Y - LOCO_SIZE.y / 2)
	add_child(loco)

	var chimney := Polygon2D.new()
	chimney.polygon = PackedVector2Array([
		Vector2(64, 0),
		Vector2(88, 0),
		Vector2(80, -16),
	])
	chimney.color = Color("#2c3e50")
	loco.add_child(chimney)

	for wheel_x in [12.0, 38.0, 64.0]:
		var wheel := ColorRect.new()
		wheel.position = Vector2(wheel_x, LOCO_SIZE.y - 8)
		wheel.size = Vector2(14, 14)
		wheel.color = Color("#34495e")
		loco.add_child(wheel)

	var headlight := ColorRect.new()
	headlight.position = Vector2(LOCO_SIZE.x - 12, 14)
	headlight.size = Vector2(8, 8)
	headlight.color = Color("#f1c40f")
	loco.add_child(headlight)

	if wagon_count > 0:
		var last_end := start_x + (wagon_count - 1) * WAGON_SPACING + WAGON_SIZE.x
		var loco_conn := ColorRect.new()
		loco_conn.color = COLOR_RAIL
		loco_conn.position = Vector2(last_end, TRAIN_Y - 2)
		loco_conn.size = Vector2(loco_x - last_end, 4)
		add_child(loco_conn)

	var gm: Node = get_node_or_null("/root/GameManager")
	var loco_name: String = I18n.t("locomotive.kara_duman").replace(" ", "\n")
	if gm:
		loco_name = gm.train_config.get_locomotive().loco_name

		var parts: PackedStringArray = loco_name.split(" ")
		if parts.size() > 1:
			loco_name = parts[0] + "\n" + parts[1]
	var loco_label := Label.new()
	loco_label.text = loco_name
	loco_label.position = Vector2(10, 15)
	loco_label.add_theme_font_size_override("font_size", 13)
	loco_label.add_theme_color_override("font_color", Color.WHITE)
	loco.add_child(loco_label)

## Lifecycle/helper logic for `_build_summary_panel`.
func _build_summary_panel() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)

	_summary_panel = PanelContainer.new()
	_summary_panel.position = Vector2(40, 200)
	_summary_panel.size = Vector2(VIEWPORT_W - 80, 450)
	_summary_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_HUD_BG
	style.border_color = Color("#C0392B")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	_summary_panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(_summary_panel)

	var vbox := VBoxContainer.new()
	_summary_panel.add_child(vbox)

	var title := Label.new()
	title.text = I18n.t("station.title.summary")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#F1C40F"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_summary_label = Label.new()
	_summary_label.add_theme_font_size_override("font_size", 16)
	_summary_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_summary_label)

	vbox.add_child(Control.new())

	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.trip_planner.is_trip_active():
		if not gm.trip_planner.is_at_final_stop():

			var continue_btn := Button.new()
			continue_btn.text = I18n.t("station.button.continue")
			continue_btn.add_theme_font_size_override("font_size", 18)
			continue_btn.pressed.connect(_on_continue_pressed)
			vbox.add_child(continue_btn)
		else:

			var finish_btn := Button.new()
			finish_btn.text = I18n.t("station.button.finish_trip")
			finish_btn.add_theme_font_size_override("font_size", 18)
			finish_btn.pressed.connect(_on_finish_trip_pressed)
			vbox.add_child(finish_btn)
	else:

		var restart_btn := Button.new()
		restart_btn.text = I18n.t("station.button.restart")
		restart_btn.add_theme_font_size_override("font_size", 18)
		restart_btn.pressed.connect(_on_restart_pressed)
		vbox.add_child(restart_btn)

		var garage_btn := Button.new()
		garage_btn.text = I18n.t("station.button.back_garage")
		garage_btn.add_theme_font_size_override("font_size", 18)
		garage_btn.pressed.connect(_on_garage_pressed)
		vbox.add_child(garage_btn)

## Lifecycle/helper logic for `_start_station`.
func _start_station() -> void:
	_is_active = true
	_station_time = Constants.STATION_TIME_LARGE
	_time_remaining = _station_time
	_timer_half_notified = false
	_first_boarded_notified = false
	_summary_panel.visible = false
	_event_banner.visible = false
	if _event_icon_label:
		_event_icon_label.visible = false

	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("get_station_time_multiplier"):
		var station_time_multiplier: float = gm.get_station_time_multiplier()
		_station_time *= station_time_multiplier
		_time_remaining = _station_time
	if gm and gm.tutorial_manager:
		gm.tutorial_manager.notify("station_opened")
	var passenger_multiplier: float = 1.0
	var extra_vip: int = 0
	if gm and gm.random_event_system:
		var station_delta: float = gm.random_event_system.consume_station_time_delta()
		_time_remaining = maxf(5.0, _time_remaining + station_delta)
		passenger_multiplier = gm.random_event_system.consume_passenger_multiplier()
		extra_vip = gm.random_event_system.consume_extra_vip()
		var station_event: Dictionary = gm.consume_pending_station_event()
		if not station_event.is_empty():
			_show_event_banner(station_event)
			_show_event_icon(str(station_event.get("id", "")))
			_show_conductor_event_tip(station_event)
	_setup_special_action(gm)

	var destinations := _get_destination_names()
	var distance: int = _get_current_distance()
	_waiting_passengers = []
	var batch_count: int = max(1, int(round(5.0 * passenger_multiplier)))
	var batch := PassengerFactory.create_batch(batch_count, destinations, distance)
	for p in batch:
		_waiting_passengers.append(p)
	for i in range(extra_vip):
		_waiting_passengers.append(PassengerFactory.create(Constants.PassengerType.VIP, destinations[randi() % destinations.size()], distance))

	_hud_station.text = _get_current_station_name()
	_station_ticket_start = int(_economy.get_trip_summary().get("earnings", {}).get("ticket", 0))
	_apply_dining_income(gm)
	_refresh_cargo_offers(gm)
	_refresh_shop_panel(gm)
	_show_cargo_delivery_popup(gm)
	_show_second_trip_station_reminders(gm)

	_rebuild_passenger_nodes()
	_update_hud()
	_update_wagon_labels()

## Lifecycle/helper logic for `_end_station`.
func _end_station() -> void:
	_is_active = false
	_time_remaining = 0.0
	_hud_timer.text = I18n.t("station.hud.time", [0])

	var summary := _economy.get_trip_summary()
	var boarded_count := 0
	for w in _wagons:
		var wagon: WagonData = w
		boarded_count += wagon.get_passenger_count()
	var lost_count := 5 - _waiting_passengers.size() - boarded_count
	var ticket_end := int(summary.get("earnings", {}).get("ticket", 0))
	var station_ticket := maxi(0, ticket_end - _station_ticket_start)
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		gm.record_station_result(_get_current_station_name(), station_ticket, boarded_count, lost_count)

	_summary_label.text = I18n.t(
		"station.summary.text",
		[boarded_count, _waiting_passengers.size(), lost_count, summary["total_earned"], _economy.get_balance(), _reputation.get_stars()]
	)
	_summary_panel.visible = true

	if boarded_count >= 4 and lost_count <= 0:
		var conductor: Node = get_node_or_null("/root/ConductorManager")
		if conductor:
			conductor.show_runtime_tip("tip_station_good", I18n.t("conductor.tip.station_good"))

## Lifecycle/helper logic for `_refresh_cargo_offers`.
func _refresh_cargo_offers(gm: Node) -> void:
	_clear_cargo_buttons()
	if gm == null or gm.cargo_system == null:
		_cargo_note_label.text = I18n.t("station.cargo.none")
		_cargo_info_label.text = ""
		return

	var active_quest_id: String = ""
	if gm.quest_system:
		active_quest_id = gm.quest_system.get_active_quest_id()

	var guaranteed_offer: Dictionary = {}
	if active_quest_id == "ege_03" and _get_current_station_name().to_lower().find("aydin") >= 0:
		guaranteed_offer = gm.cargo_system.get_forced_offer_for_quest(active_quest_id)

	var offers: Array = gm.cargo_system.generate_offers(_get_current_station_name(), guaranteed_offer)
	if offers.is_empty():
		_cargo_note_label.text = I18n.t("station.cargo.none")
	else:
		_cargo_note_label.text = I18n.t("station.cargo.available", [offers.size()])

	var has_cargo_wagon: bool = gm.cargo_system.is_cargo_wagon_available()
	var capacity: int = gm.cargo_system.get_available_capacity()
	_cargo_info_label.text = I18n.t("station.cargo.capacity", [capacity])
	if not has_cargo_wagon:
		_cargo_info_label.text = I18n.t("station.cargo.no_wagon")

	for offer in offers:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 11)
		label.text = I18n.t(
			"station.cargo.offer",
			[
				I18n.t("cargo.%s" % str(offer.get("name", ""))),
				str(offer.get("destination_station", "")),
				int(offer.get("reward", 0)),
				int(offer.get("remaining_trips", 0)),
			]
		)
		row.add_child(label)

		var load_btn := Button.new()
		load_btn.text = I18n.t("station.cargo.load")
		load_btn.disabled = (not has_cargo_wagon) or (capacity < int(offer.get("weight", 1)))
		if load_btn.disabled and not has_cargo_wagon:
			load_btn.tooltip_text = I18n.t("station.cargo.no_wagon")
		load_btn.pressed.connect(_on_cargo_load_pressed.bind(str(offer.get("id", ""))))
		row.add_child(load_btn)
		_cargo_button_map[str(offer.get("id", ""))] = load_btn

		_cargo_list.add_child(row)

func _apply_dining_income(gm: Node) -> void:
	if gm == null or not gm.has_method("get_dining_income_per_station"):
		return
	var dining_income: int = gm.get_dining_income_per_station()
	if dining_income <= 0:
		return
	_economy.earn(dining_income, "dining")
	_show_event_text(I18n.t("station.dining.income", [dining_income]))

func _toggle_shop_panel() -> void:
	if _shop_panel == null:
		return
	_shop_panel.visible = not _shop_panel.visible
	if _shop_panel.visible:
		_refresh_shop_panel(get_node_or_null("/root/GameManager"))

func _refresh_shop_panel(gm: Node) -> void:
	if _shop_rows.is_empty():
		return
	var station_name: String = _get_current_station_name()
	for i in range(_shop_rows.size()):
		var row: HBoxContainer = _shop_rows[i]
		var shop_type: int = [Constants.ShopType.BUFFET, Constants.ShopType.SOUVENIR, Constants.ShopType.CARGO_DEPOT][i]
		var level: int = 0
		if gm and gm.shop_system:
			level = gm.shop_system.get_station_shop_level(station_name, shop_type)
		var label: Label = row.get_node("Label")
		label.text = "%s  Lv.%d" % [_shop_type_name(shop_type), level]
		var btn: Button = row.get_node("Action")
		if level <= 0:
			btn.text = I18n.t("station.shop.open")
			btn.disabled = gm == null or gm.shop_system == null
		elif level < Balance.SHOP_MAX_LEVEL:
			btn.text = I18n.t("station.shop.upgrade")
			btn.disabled = gm == null or gm.shop_system == null
		else:
			btn.text = I18n.t("station.shop.max")
			btn.disabled = true

func _on_shop_action_pressed(shop_type: int) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.shop_system == null:
		return
	var station_name: String = _get_current_station_name()
	var level: int = gm.shop_system.get_station_shop_level(station_name, shop_type)
	var ok: bool = false
	if level <= 0:
		ok = gm.shop_system.open_shop(station_name, shop_type)
	else:
		ok = gm.shop_system.upgrade_shop(station_name, shop_type)
	if ok:
		_show_event_text(I18n.t("station.shop.success"))
	else:
		_show_event_text(I18n.t("station.shop.failed"))
	_refresh_shop_panel(gm)
	_update_hud()

func _shop_type_name(shop_type: int) -> String:
	match shop_type:
		Constants.ShopType.BUFFET:
			return I18n.t("shop.type.buffet")
		Constants.ShopType.SOUVENIR:
			return I18n.t("shop.type.souvenir")
		Constants.ShopType.CARGO_DEPOT:
			return I18n.t("shop.type.cargo_depot")
		_:
			return "?"

## Lifecycle/helper logic for `_show_cargo_delivery_popup`.
func _show_cargo_delivery_popup(gm: Node) -> void:
	if gm == null:
		return
	var summary: Dictionary = gm.consume_pending_cargo_delivery_summary()
	var total_reward: int = int(summary.get("total_reward", 0))
	if total_reward <= 0:
		return
	_show_event_text(I18n.t("station.cargo.delivered", [total_reward]))

## Lifecycle/helper logic for `_setup_special_action`.
func _setup_special_action(gm: Node) -> void:
	if _special_action_button != null:
		_special_action_button.queue_free()
		_special_action_button = null
	if gm == null or gm.random_event_system == null:
		return
	var reputation_bonus: float = gm.random_event_system.consume_reputation_bonus()
	if reputation_bonus <= 0.0:
		return
	_special_action_button = Button.new()
	_special_action_button.position = Vector2(20, 112)
	_special_action_button.size = Vector2(180, 30)
	_special_action_button.text = I18n.t("station.button.help_sick")
	_special_action_button.pressed.connect(func() -> void:
		_reputation.add(reputation_bonus, "event")
		_show_event_text(I18n.t("station.sick.reward", [reputation_bonus]))
		_special_action_button.disabled = true
	)
	add_child(_special_action_button)

## Lifecycle/helper logic for `_show_conductor_event_tip`.
func _show_conductor_event_tip(event_data: Dictionary) -> void:
	var description_key: String = str(event_data.get("description_key", ""))
	if description_key.is_empty():
		return
	var conductor: Node = get_node_or_null("/root/ConductorManager")
	if conductor:
		var tip_key: String = "tip_event_%s" % str(event_data.get("id", ""))
		conductor.show_runtime_tip(tip_key, I18n.t(description_key))

## Lifecycle/helper logic for `_show_event_banner`.
func _show_event_banner(event_data: Dictionary) -> void:
	var title_key: String = str(event_data.get("title_key", ""))
	if title_key.is_empty():
		return
	_show_event_text(I18n.t("station.event.banner", [I18n.t(title_key)]))

## Lifecycle/helper logic for `_show_event_icon`.
func _show_event_icon(event_id: String) -> void:
	if _event_icon_label == null:
		return
	var icon_key: String = "travel.event.icon.%s" % event_id
	var icon_text: String = I18n.t(icon_key)
	if icon_text == icon_key:
		_event_icon_label.visible = false
		return
	_event_icon_label.text = icon_text
	_event_icon_label.visible = true

## Lifecycle/helper logic for `_show_event_text`.
func _show_event_text(text: String) -> void:
	if _event_banner == null:
		return
	_event_banner.text = text
	_event_banner.visible = true
	_event_banner_timer = 3.0

## Lifecycle/helper logic for `_clear_cargo_buttons`.
func _clear_cargo_buttons() -> void:
	_cargo_button_map.clear()
	if _cargo_list == null:
		return
	for child in _cargo_list.get_children():
		child.queue_free()

## Lifecycle/helper logic for `_on_restart_pressed`.
func _on_restart_pressed() -> void:
	_start_station()

## Lifecycle/helper logic for `_on_garage_pressed`.
func _on_garage_pressed() -> void:
	SceneTransition.transition_to("res://src/scenes/garage/garage_scene.tscn")

## Lifecycle/helper logic for `_on_continue_pressed`.
func _on_continue_pressed() -> void:

	SceneTransition.transition_to("res://src/scenes/travel/travel_scene.tscn")

## Lifecycle/helper logic for `_on_finish_trip_pressed`.
func _on_finish_trip_pressed() -> void:

	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		gm.trip_planner.end_trip()
	SceneTransition.transition_to("res://src/scenes/summary/summary_scene.tscn")

## Lifecycle/helper logic for `_on_cargo_load_pressed`.
func _on_cargo_load_pressed(cargo_id: String) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.cargo_system == null:
		return
	if not gm.cargo_system.is_cargo_wagon_available():
		var conductor: Node = get_node_or_null("/root/ConductorManager")
		if conductor:
			conductor.show_runtime_tip("tip_cargo_need_wagon", I18n.t("conductor.tip.cargo_no_wagon"))
		return
	if gm.cargo_system.load_offer(cargo_id):
		_show_event_text(I18n.t("station.cargo.loaded"))
		_refresh_cargo_offers(gm)
		_update_wagon_labels()

## Lifecycle/helper logic for `_get_destination_names`.
func _get_destination_names() -> Array:
	var gm: Node = get_node_or_null("/root/GameManager")
	if not gm or not gm.trip_planner.is_trip_active():
		return ["denizli", "torbali", "selcuk", "nazilli"]

	var destinations: Array = []
	var trip_stops: Array = gm.trip_planner.get_trip_stops()
	var current: int = gm.trip_planner.get_current_stop_index()
	for i in range(current + 1, trip_stops.size()):
		var stop: Dictionary = trip_stops[i]
		destinations.append(stop["name"].to_lower())

	if destinations.is_empty():
		destinations.append(I18n.t("station.destination.final"))
	return destinations

## Lifecycle/helper logic for `_get_current_distance`.
func _get_current_distance() -> int:
	var gm: Node = get_node_or_null("/root/GameManager")
	if not gm or not gm.trip_planner.is_trip_active():
		return 120

	var stop: Dictionary = gm.trip_planner.get_current_stop()
	return int(stop.get("km_from_start", 120))

## Lifecycle/helper logic for `_get_current_station_name`.
func _get_current_station_name() -> String:
	var gm: Node = get_node_or_null("/root/GameManager")
	if not gm or not gm.trip_planner.is_trip_active():
		return I18n.t("station.name.fallback")
	var stop: Dictionary = gm.trip_planner.get_current_stop()
	return stop.get("name", I18n.t("station.name.fallback"))

## Lifecycle/helper logic for `_input`.
func _input(event: InputEvent) -> void:
	if not _is_active:
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pos := _get_event_position(event)
		var pressed := _is_pressed(event)

		if pressed:
			if _shop_panel and _shop_panel.visible and _is_in_rect(pos, _shop_panel.position, _shop_panel.size):
				return
			if _shop_button and _is_in_rect(pos, _shop_button.position, _shop_button.size):
				_toggle_shop_panel()
				return
			if _is_in_rect(pos, _fuel_button.position, _fuel_button.size):
				_try_refuel()
				return
			if _cargo_panel and _is_in_rect(pos, _cargo_panel.position, _cargo_panel.size):
				return
			_try_start_drag(pos)
		else:
			_try_end_drag(pos)

	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragged_passenger_index >= 0:
			var pos := _get_event_position(event)
			_passenger_nodes[_dragged_passenger_index].position = pos - _drag_offset

## Lifecycle/helper logic for `_get_event_position`.
func _get_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return event.position
	elif event is InputEventScreenDrag:
		return event.position
	elif event is InputEventMouse:
		return event.position
	return Vector2.ZERO

## Lifecycle/helper logic for `_is_pressed`.
func _is_pressed(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	elif event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false

## Lifecycle/helper logic for `_try_start_drag`.
func _try_start_drag(pos: Vector2) -> void:
	for i in _passenger_nodes.size():
		var node: Control = _passenger_nodes[i]
		var rect := Rect2(node.position, PASSENGER_SIZE)
		if rect.has_point(pos):
			_dragged_passenger_index = i
			_drag_offset = pos - node.position
			node.z_index = 100
			node.modulate = Color(1, 1, 1, 0.8)
			return

## Lifecycle/helper logic for `_try_end_drag`.
func _try_end_drag(pos: Vector2) -> void:
	if _dragged_passenger_index < 0:
		return

	var passenger := _waiting_passengers[_dragged_passenger_index]
	var boarded := false

	for i in _wagon_nodes.size():
		var wnode: ColorRect = _wagon_nodes[i]
		var wagon_rect := Rect2(wnode.position, WAGON_SIZE)
		if wagon_rect.has_point(pos):
			if _boarding.board_passenger(passenger, _wagons[i]):
				var gm: Node = get_node_or_null("/root/GameManager")
				if gm and gm.has_method("get_wagon_comfort_bonus"):
					var comfort_bonus: float = gm.get_wagon_comfort_bonus((_wagons[i] as WagonData).id)
					if comfort_bonus > 0.0:
						_reputation.add(comfort_bonus, "wagon_comfort")
				if gm and gm.tutorial_manager and not _first_boarded_notified:
					_first_boarded_notified = true
					gm.tutorial_manager.notify("first_boarded")
				boarded = true
				_flash_wagon(i, COLOR_SUCCESS)
				_waiting_passengers.remove_at(_dragged_passenger_index)
				_rebuild_passenger_nodes()
				_update_hud()
				_update_wagon_labels()
			else:
				_flash_wagon(i, COLOR_FAIL)
			break

	if not boarded and _dragged_passenger_index >= 0 and _dragged_passenger_index < _passenger_nodes.size():
		_passenger_nodes[_dragged_passenger_index].position = _get_passenger_position(_dragged_passenger_index)
		_passenger_nodes[_dragged_passenger_index].z_index = 0
		_passenger_nodes[_dragged_passenger_index].modulate = Color.WHITE

	_dragged_passenger_index = -1

## Lifecycle/helper logic for `_rebuild_passenger_nodes`.
func _rebuild_passenger_nodes() -> void:
	for node in _passenger_nodes:
		node.queue_free()
	_passenger_nodes.clear()

	for i in _waiting_passengers.size():
		var p := _waiting_passengers[i]
		var node := _create_passenger_node(p)
		node.position = _get_passenger_position(i)
		add_child(node)
		_passenger_nodes.append(node)

## Lifecycle/helper logic for `_create_passenger_node`.
func _create_passenger_node(passenger: Dictionary) -> Control:
	var root := Control.new()
	root.size = PASSENGER_SIZE

	var shadow := ColorRect.new()
	shadow.size = Vector2(PASSENGER_SIZE.x - 8, 8)
	shadow.position = Vector2(4, PASSENGER_SIZE.y - 6)
	shadow.color = Color(0, 0, 0, 0.22)
	root.add_child(shadow)

	var torso := ColorRect.new()
	torso.size = Vector2(22, 26)
	torso.position = Vector2(9, 20)
	torso.color = _get_passenger_color(passenger["type"])
	root.add_child(torso)

	var head := ColorRect.new()
	head.size = Vector2(16, 16)
	head.position = Vector2(12, 2)
	head.color = Color("#f5d7b2")
	root.add_child(head)

	var type_label := Label.new()
	type_label.text = _get_passenger_type_letter(passenger["type"])
	type_label.position = Vector2(12, 22)
	type_label.add_theme_font_size_override("font_size", 14)
	type_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(type_label)

	var fare_label := Label.new()
	fare_label.text = "%d DA" % passenger["fare"]
	fare_label.position = Vector2(2, 30)
	fare_label.add_theme_font_size_override("font_size", 10)
	fare_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(fare_label)

	var dest_label := Label.new()
	dest_label.text = passenger["destination"].substr(0, 3).to_upper()
	dest_label.position = Vector2(2, 45)
	dest_label.add_theme_font_size_override("font_size", 9)
	dest_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	root.add_child(dest_label)

	var bar_bg := ColorRect.new()
	bar_bg.size = Vector2(PASSENGER_SIZE.x - 4, 5)
	bar_bg.position = Vector2(2, -8)
	bar_bg.color = Color(0, 0, 0, 0.5)
	bar_bg.name = "PatienceBarBG"
	root.add_child(bar_bg)

	var bar_fill := ColorRect.new()
	bar_fill.size = Vector2(PASSENGER_SIZE.x - 4, 5)
	bar_fill.position = Vector2(2, -8)
	bar_fill.color = COLOR_SUCCESS
	bar_fill.name = "PatienceBarFill"
	root.add_child(bar_fill)

	if _is_quest_target_passenger(passenger):
		var highlight := PanelContainer.new()
		highlight.name = "QuestHighlight"
		highlight.position = Vector2(-2, -2)
		highlight.size = PASSENGER_SIZE + Vector2(4, 4)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight.add_theme_stylebox_override("panel", _make_quest_highlight_style())
		root.add_child(highlight)

	return root

## Lifecycle/helper logic for `_update_patience_bars`.
func _update_patience_bars() -> void:
	for i in _passenger_nodes.size():
		if i >= _waiting_passengers.size():
			break
		var p: Dictionary = _waiting_passengers[i]
		var percent := PatienceSystem.get_patience_percent(p)
		var pnode: Control = _passenger_nodes[i]
		var bar: ColorRect = pnode.get_node("PatienceBarFill")
		bar.size.x = (PASSENGER_SIZE.x - 4) * (percent / 100.0)

		if percent > 60:
			bar.color = COLOR_SUCCESS
		elif percent > 30:
			bar.color = Color("#F39C12")
		else:
			bar.color = COLOR_FAIL

## Lifecycle/helper logic for `_get_passenger_position`.
func _get_passenger_position(index: int) -> Vector2:
	return Vector2(WAITING_START_X + index * WAITING_SPACING, WAITING_Y)

## Lifecycle/helper logic for `_is_quest_target_passenger`.
func _is_quest_target_passenger(passenger: Dictionary) -> bool:
	var target_station: String = _get_active_transport_target_station()
	if target_station.is_empty():
		return false
	var destination: String = str(passenger.get("destination", "")).to_lower()
	return destination.find(target_station) >= 0

## Lifecycle/helper logic for `_get_active_transport_target_station`.
func _get_active_transport_target_station() -> String:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.quest_system == null:
		return ""
	var active_quest: Dictionary = gm.quest_system.get_active_quest()
	if active_quest.is_empty():
		return ""
	if int(active_quest.get("type", -1)) != Constants.QuestType.TRANSPORT:
		return ""
	return str(active_quest.get("conditions", {}).get("destination", "")).to_lower()

## Lifecycle/helper logic for `_make_quest_highlight_style`.
func _make_quest_highlight_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = COLOR_QUEST_TARGET
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

## Lifecycle/helper logic for `_get_passenger_color`.
func _get_passenger_color(type: Constants.PassengerType) -> Color:
	match type:
		Constants.PassengerType.VIP: return COLOR_PASSENGER_VIP
		Constants.PassengerType.STUDENT: return COLOR_PASSENGER_STUDENT
		Constants.PassengerType.ELDERLY: return COLOR_PASSENGER_ELDERLY
		_: return COLOR_PASSENGER_NORMAL

## Lifecycle/helper logic for `_get_passenger_type_letter`.
func _get_passenger_type_letter(type: Constants.PassengerType) -> String:
	match type:
		Constants.PassengerType.VIP: return "V"
		Constants.PassengerType.STUDENT: return "O"
		Constants.PassengerType.ELDERLY: return "Y"
		_: return "N"

## Lifecycle/helper logic for `_update_hud`.
func _update_hud() -> void:
	_update_refuel_controls()

## Lifecycle/helper logic for `_update_refuel_controls`.
func _update_refuel_controls() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		_fuel_button.disabled = true
		_fuel_button.text = I18n.t("station.button.refuel")
		return

	var fuel: FuelSystem = gm.fuel_system
	var missing := maxf(0.0, fuel.get_tank_capacity() - fuel.get_current_fuel())
	var cost: int = fuel.get_refuel_cost(missing)
	if _refuel_in_progress:
		_fuel_button.disabled = true
		_fuel_button.text = I18n.t("station.button.refuel_progress")
	elif missing <= 0.0:
		_fuel_button.disabled = true
		_fuel_button.text = I18n.t("station.button.refuel_full")
	else:
		_fuel_button.disabled = not _economy.can_afford(cost)
		_fuel_button.text = I18n.t("station.button.refuel_with_cost", [cost])

## Lifecycle/helper logic for `_try_refuel`.
func _try_refuel() -> void:
	if _refuel_in_progress:
		return
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var fuel: FuelSystem = gm.fuel_system
	var missing := maxf(0.0, fuel.get_tank_capacity() - fuel.get_current_fuel())
	var cost: int = fuel.get_refuel_cost(missing)
	if missing <= 0.0 or not _economy.can_afford(cost):
		return
	_refuel_in_progress = true
	_refuel_progress = 0.0
	_fuel_progress_fill.size.x = 0

## Lifecycle/helper logic for `_process_refuel`.
func _process_refuel(delta: float) -> void:
	if not _refuel_in_progress:
		return
	_refuel_progress += delta / 1.5
	var p := clampf(_refuel_progress, 0.0, 1.0)
	_fuel_progress_fill.size.x = 160.0 * p
	if p >= 1.0:
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm:
			var fuel: FuelSystem = gm.fuel_system
			var missing := maxf(0.0, fuel.get_tank_capacity() - fuel.get_current_fuel())
			fuel.buy_refuel(missing)
		_refuel_in_progress = false
		_refuel_progress = 0.0
		_fuel_progress_fill.size.x = 0
		_update_hud()

## Lifecycle/helper logic for `_update_wagon_labels`.
func _update_wagon_labels() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	var cargo_loaded: int = 0
	if gm and gm.cargo_system:
		cargo_loaded = gm.cargo_system.get_loaded_weight()
	for i in _wagon_nodes.size():
		if i >= _wagons.size():
			break
		var wagon: WagonData = _wagons[i]
		var wnode: ColorRect = _wagon_nodes[i]
		var label := wnode.get_node_or_null("WagonLabel") as Label
		if label == null:
			continue
		if wagon.type == Constants.WagonType.CARGO:
			label.text = "%s\n%s %d/%d" % [
				_get_wagon_short_name(wagon.type),
				I18n.t("station.cargo.boxes_icon"),
				cargo_loaded,
				wagon.get_capacity(),
			]
		else:
			label.text = "%s\n%d/%d" % [_get_wagon_short_name(wagon.type), wagon.get_passenger_count(), wagon.get_capacity()]

## Lifecycle/helper logic for `_flash_wagon`.
func _flash_wagon(wagon_index: int, color: Color) -> void:
	var node: ColorRect = _wagon_nodes[wagon_index]
	var tween := create_tween()
	node.modulate = color
	tween.tween_property(node, "modulate", Color.WHITE, 0.3)

## Lifecycle/helper logic for `_get_wagon_color`.
func _get_wagon_color(wtype: Constants.WagonType) -> Color:
	match wtype:
		Constants.WagonType.ECONOMY: return COLOR_WAGON_ECONOMY
		Constants.WagonType.BUSINESS: return COLOR_WAGON_BUSINESS
		Constants.WagonType.VIP: return COLOR_WAGON_VIP
		Constants.WagonType.DINING: return COLOR_WAGON_DINING
		Constants.WagonType.CARGO: return COLOR_WAGON_CARGO
		_: return Color.WHITE

## Lifecycle/helper logic for `_get_wagon_short_name`.
func _get_wagon_short_name(wtype: Constants.WagonType) -> String:
	match wtype:
		Constants.WagonType.ECONOMY: return I18n.t("wagon.short.economy")
		Constants.WagonType.BUSINESS: return I18n.t("wagon.short.business")
		Constants.WagonType.VIP: return I18n.t("wagon.short.vip")
		Constants.WagonType.DINING: return I18n.t("wagon.short.dining")
		Constants.WagonType.CARGO: return I18n.t("wagon.short.cargo")
		_: return "?"

## Lifecycle/helper logic for `_is_in_rect`.
func _is_in_rect(pos: Vector2, rect_pos: Vector2, rect_size: Vector2) -> bool:
	return pos.x >= rect_pos.x and pos.x <= rect_pos.x + rect_size.x \
		and pos.y >= rect_pos.y and pos.y <= rect_pos.y + rect_size.y

func _apply_accessibility() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.settings_system:
		gm.settings_system.apply_font_scale_recursive(self)

func _show_second_trip_station_reminders(gm: Node) -> void:
	if gm == null or gm.total_trips != 1:
		return
	var conductor: Node = get_node_or_null("/root/ConductorManager")
	if conductor == null:
		return
	if gm.fuel_system and gm.fuel_system.is_fuel_low():
		conductor.show_runtime_tip("tip_tutorial_trip2_fuel", I18n.t("tutorial.trip2.fuel_low"))
	if gm.cargo_system:
		var offers_exist: bool = _cargo_list != null and _cargo_list.get_child_count() > 0
		if offers_exist and gm.cargo_system.is_cargo_wagon_available():
			conductor.show_runtime_tip("tip_tutorial_trip2_cargo", I18n.t("tutorial.trip2.cargo"))
