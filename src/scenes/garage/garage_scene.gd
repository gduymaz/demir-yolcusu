## Module: garage_scene.gd
## Keeps Garage scene orchestration thin by delegating rendering and interactions to manager classes.

extends Node2D

const GarageUiBuilder := preload("res://src/scenes/garage/garage_ui_builder.gd")
const GarageInteractionManager := preload("res://src/scenes/garage/garage_interaction_manager.gd")
const GarageViewManager := preload("res://src/scenes/garage/garage_view_manager.gd")

const VIEWPORT_W := 540
const VIEWPORT_H := 960
const MARGIN := 20
const HEADER_H := 50
const LOCO_PANEL_H := 80
const TRAIN_AREA_Y := 200
const TRAIN_AREA_H := 200
const INFO_BAR_Y := 410
const WAGON_POOL_Y := 480
const WAGON_POOL_H := 280
const BUTTON_BAR_Y := 790
const BUTTON_H := 60

const LOCO_SPRITE_W := 80
const LOCO_SPRITE_H := 56
const WAGON_SPRITE_W := 72
const WAGON_SPRITE_H := 48
const WAGON_SPACING := 85
const POOL_WAGON_W := 100
const POOL_WAGON_H := 60

const COLOR_BG := Color("#1a1a2e")
const COLOR_HEADER := Color("#16213e")
const COLOR_PANEL := Color("#0f3460")
const COLOR_LOCO := Color("#c0392b")
const COLOR_ECONOMY := Color("#3498db")
const COLOR_BUSINESS := Color("#2c3e50")
const COLOR_VIP := Color("#f1c40f")
const COLOR_DINING := Color("#27ae60")
const COLOR_CARGO := Color("#8b4513")
const COLOR_TEXT := Color("#ecf0f1")
const COLOR_GOLD := Color("#f39c12")
const COLOR_GREEN := Color("#27ae60")
const COLOR_RED := Color("#e74c3c")
const COLOR_BUTTON := Color("#2980b9")
const COLOR_BUTTON_DISABLED := Color("#555555")

var _money_label: Label
var _train_container: Control
var _info_label: Label
var _wagon_pool_container: Control
var _shop_panel: Control
var _shop_entries: Array = []
var _upgrade_panel: Control
var _upgrade_entries: Array = []
var _upgrade_respec_rect: Rect2 = Rect2()
var _loco_buttons: Array = []
var _train_wagon_nodes: Array = []
var _pool_wagon_nodes: Array = []

var _dragging: bool = false
var _drag_source: String = ""
var _drag_index: int = -1
var _drag_node: Control = null
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_wagon: WagonData = null

var _shop_visible: bool = false
var _upgrade_visible: bool = false
var _selected_upgrade_target: Dictionary = {"kind": "locomotive", "id": "kara_duman"}

func _ready() -> void:
	var refs: Dictionary = GarageUiBuilder.build(self)
	_money_label = refs.get("money_label")
	_train_container = refs.get("train_container")
	_info_label = refs.get("info_label")
	_wagon_pool_container = refs.get("wagon_pool_container")
	_shop_panel = refs.get("shop_panel")
	_upgrade_panel = refs.get("upgrade_panel")
	_upgrade_entries = refs.get("upgrade_entries", [])
	_upgrade_respec_rect = refs.get("upgrade_respec_rect", Rect2())
	_refresh_all()
	_apply_accessibility()
	_show_second_trip_reminder()

func _input(event: InputEvent) -> void:
	GarageInteractionManager.handle_input(self, event)

func _refresh_all() -> void:
	GarageViewManager.refresh_all(self)

func _refresh_money() -> void:
	_money_label.text = "%d DA" % _get_game_manager().economy.get_balance()

func _refresh_loco_list() -> void:
	GarageViewManager.refresh_loco_list(self)

func _refresh_train_view() -> void:
	GarageViewManager.refresh_train_view(self)

func _refresh_info_bar() -> void:
	GarageViewManager.refresh_info_bar(self)

func _refresh_wagon_pool() -> void:
	GarageViewManager.refresh_wagon_pool(self)

func _refresh_shop() -> void:
	GarageViewManager.refresh_shop(self)

func _refresh_upgrade_panel() -> void:
	GarageViewManager.refresh_upgrade_panel(self)

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
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", COLOR_TEXT)
	container.add_child(lbl)
	return container

func _handle_shop_input(event: InputEvent) -> void:
	GarageInteractionManager._handle_shop_input(self, event)

func _handle_upgrade_input(event: InputEvent) -> void:
	GarageInteractionManager._handle_upgrade_input(self, event)

func _on_press(pos: Vector2) -> void:
	GarageInteractionManager._on_press(self, pos)

func _on_drag(pos: Vector2) -> void:
	GarageInteractionManager._on_drag(self, pos)

func _on_release(pos: Vector2) -> void:
	GarageInteractionManager._on_release(self, pos)

func _start_drag_from_pool(index: int, pos: Vector2) -> void:
	GarageInteractionManager._start_drag_from_pool(self, index, pos)

func _start_drag_from_train(index: int, pos: Vector2) -> void:
	GarageInteractionManager._start_drag_from_train(self, index, pos)

func _add_wagon_to_train_from_pool() -> void:
	GarageInteractionManager._add_wagon_to_train_from_pool(self)

func _remove_wagon_from_train() -> void:
	GarageInteractionManager._remove_wagon_from_train(self)

func _select_locomotive(index: int) -> void:
	GarageInteractionManager._select_locomotive(self, index)

func _open_shop() -> void:
	_shop_visible = true
	_shop_panel.visible = true
	_refresh_shop()

func _open_upgrade() -> void:
	_upgrade_visible = true
	_upgrade_panel.visible = true
	_refresh_upgrade_panel()

func _try_buy_wagon(wagon_type: Constants.WagonType) -> void:
	var gm: Node = _get_game_manager()
	if gm.inventory.buy_wagon_with_requirement(wagon_type, _wagon_required_reputation(wagon_type), gm.reputation):
		_refresh_shop()
		_refresh_money()

func _wagon_required_reputation(wagon_type: int) -> float:
	match wagon_type:
		Constants.WagonType.VIP:
			return Balance.WAGON_REPUTATION_VIP
		Constants.WagonType.DINING:
			return Balance.WAGON_REPUTATION_DINING
		_:
			return 0.0

func _try_buy_locomotive(loco_id: String, required_reputation: float) -> void:
	var gm: Node = _get_game_manager()
	if gm.inventory.buy_locomotive(loco_id, required_reputation, gm.reputation):
		_refresh_shop()
		_refresh_all()

func _try_upgrade_entry(entry: Dictionary) -> void:
	var gm: Node = _get_game_manager()
	var kind: String = str(entry.get("kind", ""))
	var target_id: String = str(entry.get("id", ""))
	var upgrade_type: int = int(entry.get("upgrade_type", -1))
	var success: bool = false
	if kind == "locomotive":
		success = gm.upgrade_system.upgrade_locomotive(target_id, upgrade_type)
	else:
		success = gm.upgrade_system.upgrade_wagon(target_id, int(entry.get("wagon_type", Constants.WagonType.ECONOMY)), upgrade_type)
	if success:
		gm.sync_trip_wagon_count()
	_refresh_all()
	_refresh_upgrade_panel()

func _try_respec_selected_target() -> void:
	var gm: Node = _get_game_manager()
	var kind: String = str(_selected_upgrade_target.get("kind", "locomotive"))
	var target_id: String = str(_selected_upgrade_target.get("id", gm.train_config.get_locomotive().id))
	var success: bool = false
	if kind == "locomotive":
		success = gm.upgrade_system.respec_locomotive(target_id)
	else:
		success = gm.upgrade_system.respec_wagon(target_id)
	if success:
		gm.sync_trip_wagon_count()
	_refresh_all()
	_refresh_upgrade_panel()

func _set_upgrade_target_locomotive(loco_id: String) -> void:
	_selected_upgrade_target = {"kind": "locomotive", "id": loco_id}

func _set_upgrade_target_wagon(wagon: WagonData) -> void:
	if wagon != null:
		_selected_upgrade_target = {"kind": "wagon", "id": wagon.id}

func _go_to_station() -> void:
	if _get_game_manager().train_config.get_wagon_count() == 0:
		_flash_warning()
		return
	SceneTransition.transition_to("res://src/scenes/map/map_scene.tscn")

func _flash_warning() -> void:
	_info_label.text = I18n.t("garage.error.min_wagon")
	_info_label.add_theme_color_override("font_color", COLOR_RED)
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		_info_label.add_theme_color_override("font_color", COLOR_TEXT)
		_refresh_info_bar()
	)

func _get_game_manager() -> Node:
	return get_node("/root/GameManager")

func _get_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return event.position
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return event.position
	return Vector2.ZERO

func _is_pressed(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false

func _is_in_rect(pos: Vector2, rect_pos: Vector2, rect_size: Vector2) -> bool:
	return pos.x >= rect_pos.x and pos.x <= rect_pos.x + rect_size.x and pos.y >= rect_pos.y and pos.y <= rect_pos.y + rect_size.y

func _should_ignore_mouse_event(event: InputEvent) -> bool:
	if not ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false):
		return false
	return event is InputEventMouseButton or event is InputEventMouseMotion

func _get_wagon_color(wtype: Constants.WagonType) -> Color:
	match wtype:
		Constants.WagonType.ECONOMY: return COLOR_ECONOMY
		Constants.WagonType.BUSINESS: return COLOR_BUSINESS
		Constants.WagonType.VIP: return COLOR_VIP
		Constants.WagonType.DINING: return COLOR_DINING
		Constants.WagonType.CARGO: return COLOR_CARGO
		_: return Color.WHITE

func _get_wagon_short_name(wtype: Constants.WagonType) -> String:
	match wtype:
		Constants.WagonType.ECONOMY: return I18n.t("wagon.short.economy")
		Constants.WagonType.BUSINESS: return I18n.t("wagon.short.business")
		Constants.WagonType.VIP: return I18n.t("wagon.short.vip")
		Constants.WagonType.DINING: return I18n.t("wagon.short.dining")
		Constants.WagonType.CARGO: return I18n.t("wagon.short.cargo")
		_: return "?"

func _get_wagon_type_name(wtype: Constants.WagonType) -> String:
	match wtype:
		Constants.WagonType.ECONOMY: return I18n.t("wagon.type.economy")
		Constants.WagonType.BUSINESS: return I18n.t("wagon.type.business")
		Constants.WagonType.VIP: return I18n.t("wagon.type.vip")
		Constants.WagonType.DINING: return I18n.t("wagon.type.dining")
		Constants.WagonType.CARGO: return I18n.t("wagon.type.cargo")
		_: return I18n.t("wagon.type.unknown")

func _get_fuel_name(ftype: Constants.FuelType) -> String:
	match ftype:
		Constants.FuelType.COAL_OLD: return I18n.t("fuel.type.coal_old")
		Constants.FuelType.COAL_NEW: return I18n.t("fuel.type.coal_new")
		Constants.FuelType.DIESEL_OLD: return I18n.t("fuel.type.diesel_old")
		Constants.FuelType.DIESEL_NEW: return I18n.t("fuel.type.diesel_new")
		Constants.FuelType.ELECTRIC: return I18n.t("fuel.type.electric")
		_: return "?"

func _apply_accessibility() -> void:
	var gm: Node = _get_game_manager()
	if gm and gm.settings_system:
		gm.settings_system.apply_font_scale_recursive(self)

func _show_second_trip_reminder() -> void:
	var gm: Node = _get_game_manager()
	if gm.total_trips != 1:
		return
	var conductor: Node = get_node_or_null("/root/ConductorManager")
	if conductor:
		conductor.show_runtime_tip("tip_tutorial_trip2_garage", I18n.t("tutorial.trip2.garage"))
