## Module: station_scene.gd
## Keeps Station scene orchestration thin by delegating flow and interactions.

extends Node2D

const StationInteractionManager := preload("res://src/scenes/station/station_interaction_manager.gd")
const StationFlowManager := preload("res://src/scenes/station/station_flow_manager.gd")

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

func _ready() -> void:
	StationFlowManager.setup_systems(self)
	StationFlowManager.build_scene(self)
	_apply_accessibility()
	_start_station()

func _process(delta: float) -> void:
	StationFlowManager.process(self, delta)

func _start_station() -> void:
	StationFlowManager.start_station(self)

func _end_station() -> void:
	StationFlowManager.end_station(self)

func _refresh_cargo_offers(gm: Node) -> void:
	StationFlowManager.refresh_cargo_offers(self, gm)

func _apply_dining_income(gm: Node) -> void:
	StationFlowManager.apply_dining_income(self, gm)

func _toggle_shop_panel() -> void:
	StationFlowManager.toggle_shop_panel(self)

func _refresh_shop_panel(gm: Node) -> void:
	StationFlowManager.refresh_shop_panel(self, gm)

func _on_shop_action_pressed(shop_type: int) -> void:
	StationFlowManager.on_shop_action_pressed(self, shop_type)

func _shop_type_name(shop_type: int) -> String:
	return StationFlowManager.shop_type_name(shop_type)

func _show_cargo_delivery_popup(gm: Node) -> void:
	StationFlowManager.show_cargo_delivery_popup(self, gm)

func _setup_special_action(gm: Node) -> void:
	StationFlowManager.setup_special_action(self, gm)

func _show_conductor_event_tip(event_data: Dictionary) -> void:
	StationFlowManager.show_conductor_event_tip(self, event_data)

func _show_event_banner(event_data: Dictionary) -> void:
	StationFlowManager.show_event_banner(self, event_data)

func _show_event_icon(event_id: String) -> void:
	StationFlowManager.show_event_icon(self, event_id)

func _show_event_text(text: String) -> void:
	StationFlowManager.show_event_text(self, text)

func _clear_cargo_buttons() -> void:
	StationFlowManager.clear_cargo_buttons(self)

func _on_restart_pressed() -> void:
	StationFlowManager.on_restart_pressed(self)

func _on_garage_pressed() -> void:
	StationFlowManager.on_garage_pressed(self)

func _on_continue_pressed() -> void:
	StationFlowManager.on_continue_pressed(self)

func _on_finish_trip_pressed() -> void:
	StationFlowManager.on_finish_trip_pressed(self)

func _on_cargo_load_pressed(cargo_id: String) -> void:
	StationFlowManager.on_cargo_load_pressed(self, cargo_id)

func _get_destination_names() -> Array:
	return StationFlowManager.get_destination_names(self)

func _get_current_distance() -> int:
	return StationFlowManager.get_current_distance(self)

func _get_current_station_name() -> String:
	return StationFlowManager.get_current_station_name(self)

func _input(event: InputEvent) -> void:
	StationInteractionManager.handle_input(self, event)

func _get_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return event.position
	if event is InputEventMouse:
		return event.position
	return Vector2.ZERO

func _is_pressed(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false

func _try_start_drag(pos: Vector2) -> void:
	for i in _passenger_nodes.size():
		var node: Control = _passenger_nodes[i]
		if Rect2(node.position, PASSENGER_SIZE).has_point(pos):
			_dragged_passenger_index = i
			_drag_offset = pos - node.position
			node.z_index = 100
			node.modulate = Color(1, 1, 1, 0.8)
			return

func _try_end_drag(pos: Vector2) -> void:
	if _dragged_passenger_index < 0:
		return
	var passenger := _waiting_passengers[_dragged_passenger_index]
	var boarded := false
	for i in _wagon_nodes.size():
		var wnode: ColorRect = _wagon_nodes[i]
		if Rect2(wnode.position, WAGON_SIZE).has_point(pos):
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

func _rebuild_passenger_nodes() -> void:
	StationInteractionManager.rebuild_passenger_nodes(self)

func _create_passenger_node(passenger: Dictionary) -> Control:
	return StationFlowManager.create_passenger_node(self, passenger)

func _update_patience_bars() -> void:
	StationInteractionManager.update_patience_bars(self)

func _get_passenger_position(index: int) -> Vector2:
	return StationFlowManager.get_passenger_position(self, index)

func _is_quest_target_passenger(passenger: Dictionary) -> bool:
	return StationFlowManager.is_quest_target_passenger(self, passenger)

func _get_active_transport_target_station() -> String:
	return StationFlowManager.get_active_transport_target_station(self)

func _make_quest_highlight_style() -> StyleBoxFlat:
	return StationFlowManager.make_quest_highlight_style(self)

func _get_passenger_color(passenger_type: Constants.PassengerType) -> Color:
	return StationFlowManager.get_passenger_color(self, passenger_type)

func _get_passenger_type_letter(passenger_type: Constants.PassengerType) -> String:
	return StationFlowManager.get_passenger_type_letter(self, passenger_type)

func _update_hud() -> void:
	_update_refuel_controls()

func _update_refuel_controls() -> void:
	StationInteractionManager.update_refuel_controls(self)

func _try_refuel() -> void:
	StationInteractionManager.try_refuel(self)

func _process_refuel(delta: float) -> void:
	StationInteractionManager.process_refuel(self, delta)

func _update_wagon_labels() -> void:
	StationInteractionManager.update_wagon_labels(self)

func _flash_wagon(wagon_index: int, color: Color) -> void:
	StationFlowManager.flash_wagon(self, wagon_index, color)

func _get_wagon_color(wtype: Constants.WagonType) -> Color:
	return StationFlowManager.get_wagon_color(self, wtype)

func _get_wagon_short_name(wtype: Constants.WagonType) -> String:
	return StationFlowManager.get_wagon_short_name(self, wtype)

func _is_in_rect(pos: Vector2, rect_pos: Vector2, rect_size: Vector2) -> bool:
	return pos.x >= rect_pos.x and pos.x <= rect_pos.x + rect_size.x and pos.y >= rect_pos.y and pos.y <= rect_pos.y + rect_size.y

func _apply_accessibility() -> void:
	StationFlowManager.apply_accessibility(self)

func _show_second_trip_station_reminders(gm: Node) -> void:
	StationFlowManager.show_second_trip_station_reminders(self, gm)
