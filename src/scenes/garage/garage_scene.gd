## Module: garage_scene.gd
## Restored English comments for maintainability and i18n coding standards.

extends Node2D
const GarageUiBuilder := preload("res://src/scenes/garage/garage_ui_builder.gd")
const GarageInteractionManager := preload("res://src/scenes/garage/garage_interaction_manager.gd")

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
const COLOR_TRAIN_BG := Color("#1a1a2e")
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
const COLOR_SELECTED := Color("#e74c3c")

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

## Lifecycle/helper logic for `_ready`.
func _ready() -> void:
	_build_scene()
	_refresh_all()
	_apply_accessibility()
	_show_second_trip_reminder()

## Lifecycle/helper logic for `_build_scene`.
func _build_scene() -> void:
	var refs: Dictionary = GarageUiBuilder.build(self)
	_money_label = refs.get("money_label")
	_train_container = refs.get("train_container")
	_info_label = refs.get("info_label")
	_wagon_pool_container = refs.get("wagon_pool_container")
	_shop_panel = refs.get("shop_panel")
	_upgrade_panel = refs.get("upgrade_panel")
	_upgrade_entries = refs.get("upgrade_entries", [])
	_upgrade_respec_rect = refs.get("upgrade_respec_rect", Rect2())

## Lifecycle/helper logic for `_create_button`.
func _create_button(text: String, pos: Vector2, btn_size: Vector2, color: Color) -> Control:
	var container := Control.new()
	container.position = pos
	container.size = btn_size

	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
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

## Lifecycle/helper logic for `_refresh_all`.
func _refresh_all() -> void:
	_refresh_money()
	_refresh_loco_list()
	_refresh_train_view()
	_refresh_info_bar()
	_refresh_wagon_pool()
	if _upgrade_visible:
		_refresh_upgrade_panel()

## Lifecycle/helper logic for `_refresh_money`.
func _refresh_money() -> void:
	var gm: Node = _get_game_manager()
	_money_label.text = "%d DA" % gm.economy.get_balance()

## Lifecycle/helper logic for `_refresh_loco_list`.
func _refresh_loco_list() -> void:
	var container: Control = get_node("LocoContainer")

	for child in container.get_children():
		child.queue_free()
	_loco_buttons.clear()

	var gm: Node = _get_game_manager()
	var locos: Array = gm.inventory.get_locomotives()
	var selected_id: String = gm.train_config.get_locomotive().id

	for i in range(locos.size()):
		var loco: LocomotiveData = locos[i]
		var is_selected: bool = (loco.id == selected_id)

		var btn := Control.new()
		btn.position = Vector2(i * 170, 0)
		btn.size = Vector2(160, 45)

		var btn_bg := ColorRect.new()
		btn_bg.size = Vector2(160, 45)
		btn_bg.color = COLOR_SELECTED if is_selected else COLOR_BUTTON
		btn.add_child(btn_bg)

		var btn_label := Label.new()
		btn_label.text = loco.loco_name + (" *" if is_selected else "")
		btn_label.position = Vector2(10, 10)
		btn_label.size = Vector2(140, 25)
		btn_label.add_theme_font_size_override("font_size", 14)
		btn_label.add_theme_color_override("font_color", COLOR_TEXT)
		btn.add_child(btn_label)

		container.add_child(btn)
		_loco_buttons.append(btn)

## Lifecycle/helper logic for `_refresh_train_view`.
func _refresh_train_view() -> void:

	for child in _train_container.get_children():
		child.queue_free()
	_train_wagon_nodes.clear()

	var gm: Node = _get_game_manager()
	var config: TrainConfig = gm.train_config
	var loco: LocomotiveData = config.get_locomotive()

	var loco_node := ColorRect.new()
	loco_node.position = Vector2(MARGIN, (TRAIN_AREA_H - LOCO_SPRITE_H) / 2.0)
	loco_node.size = Vector2(LOCO_SPRITE_W, LOCO_SPRITE_H)
	loco_node.color = COLOR_LOCO
	_train_container.add_child(loco_node)

	var loco_label := Label.new()
	loco_label.text = loco.loco_name
	loco_label.position = Vector2(MARGIN, (TRAIN_AREA_H - LOCO_SPRITE_H) / 2.0 + LOCO_SPRITE_H + 2)
	loco_label.size = Vector2(LOCO_SPRITE_W, 16)
	loco_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loco_label.add_theme_font_size_override("font_size", 10)
	loco_label.add_theme_color_override("font_color", COLOR_TEXT)
	_train_container.add_child(loco_label)

	var wagons: Array = config.get_wagons()
	var start_x := MARGIN + LOCO_SPRITE_W + 15

	for i in range(wagons.size()):
		var wagon: WagonData = wagons[i]
		var wagon_node := ColorRect.new()
		wagon_node.position = Vector2(start_x + i * WAGON_SPACING, (TRAIN_AREA_H - WAGON_SPRITE_H) / 2.0)
		wagon_node.size = Vector2(WAGON_SPRITE_W, WAGON_SPRITE_H)
		wagon_node.color = _get_wagon_color(wagon.type)
		_train_container.add_child(wagon_node)

		var type_label := Label.new()
		type_label.text = _get_wagon_short_name(wagon.type)
		type_label.position = Vector2(start_x + i * WAGON_SPACING, (TRAIN_AREA_H - WAGON_SPRITE_H) / 2.0 + WAGON_SPRITE_H + 2)
		type_label.size = Vector2(WAGON_SPRITE_W, 16)
		type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_label.add_theme_font_size_override("font_size", 10)
		type_label.add_theme_color_override("font_color", COLOR_TEXT)
		_train_container.add_child(type_label)

		_train_wagon_nodes.append(wagon_node)

	for i in range(wagons.size(), config.get_max_wagons()):
		var slot := ColorRect.new()
		slot.position = Vector2(start_x + i * WAGON_SPACING, (TRAIN_AREA_H - WAGON_SPRITE_H) / 2.0)
		slot.size = Vector2(WAGON_SPRITE_W, WAGON_SPRITE_H)
		slot.color = Color("#333344")
		_train_container.add_child(slot)

		var slot_label := Label.new()
		slot_label.text = "+"
		slot_label.position = Vector2(start_x + i * WAGON_SPACING, (TRAIN_AREA_H - WAGON_SPRITE_H) / 2.0 + 12)
		slot_label.size = Vector2(WAGON_SPRITE_W, 24)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 20)
		slot_label.add_theme_color_override("font_color", Color("#666666"))
		_train_container.add_child(slot_label)

## Lifecycle/helper logic for `_refresh_info_bar`.
func _refresh_info_bar() -> void:
	var gm: Node = _get_game_manager()
	var config: TrainConfig = gm.train_config
	var wagon_count := config.get_wagon_count()
	var max_wagons := config.get_max_wagons()
	var capacity := config.get_total_passenger_capacity()
	var loco: LocomotiveData = config.get_locomotive()
	var fuel_name := _get_fuel_name(loco.fuel_type)
	_info_label.text = I18n.t("garage.info.train", [wagon_count, max_wagons, capacity, fuel_name])

## Lifecycle/helper logic for `_refresh_wagon_pool`.
func _refresh_wagon_pool() -> void:

	for child in _wagon_pool_container.get_children():
		child.queue_free()
	_pool_wagon_nodes.clear()

	var gm: Node = _get_game_manager()
	var available: Array = gm.inventory.get_available_wagons()

	if available.size() == 0:
		var empty_label := Label.new()
		empty_label.text = I18n.t("garage.info.empty_pool")
		empty_label.position = Vector2(60, 40)
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color("#888888"))
		_wagon_pool_container.add_child(empty_label)
		return

	var col_w := 250
	var row_h := 75

	for i in range(available.size()):
		var wagon: WagonData = available[i]
		var col := i % 2
		var row := i / 2

		var wagon_node := Control.new()
		wagon_node.position = Vector2(col * col_w, row * row_h)
		wagon_node.size = Vector2(POOL_WAGON_W + 120, POOL_WAGON_H)

		var wagon_sprite := ColorRect.new()
		wagon_sprite.position = Vector2.ZERO
		wagon_sprite.size = Vector2(POOL_WAGON_W, POOL_WAGON_H)
		wagon_sprite.color = _get_wagon_color(wagon.type)
		wagon_node.add_child(wagon_sprite)

		var wagon_label := Label.new()
		wagon_label.text = _get_wagon_type_name(wagon.type)
		wagon_label.position = Vector2(POOL_WAGON_W + 8, 8)
		wagon_label.add_theme_font_size_override("font_size", 12)
		wagon_label.add_theme_color_override("font_color", COLOR_TEXT)
		wagon_node.add_child(wagon_label)

		var cap_label := Label.new()
		cap_label.text = "Kap: %d" % wagon.get_capacity()
		cap_label.position = Vector2(POOL_WAGON_W + 8, 28)
		cap_label.add_theme_font_size_override("font_size", 11)
		cap_label.add_theme_color_override("font_color", Color("#aaaaaa"))
		wagon_node.add_child(cap_label)

		_wagon_pool_container.add_child(wagon_node)
		_pool_wagon_nodes.append(wagon_node)

## Lifecycle/helper logic for `_refresh_shop`.
func _refresh_shop() -> void:
	var container: Control = _shop_panel.get_node("ShopItemsContainer")
	for child in container.get_children():
		child.queue_free()
	_shop_entries.clear()

	var gm: Node = _get_game_manager()
	var balance: int = gm.economy.get_balance()

	var wagon_types := [
		Constants.WagonType.ECONOMY,
		Constants.WagonType.BUSINESS,
		Constants.WagonType.VIP,
		Constants.WagonType.DINING,
		Constants.WagonType.CARGO,
	]

	for i in range(wagon_types.size()):
		var wtype: Constants.WagonType = wagon_types[i]
		var price := PlayerInventory.get_wagon_price(wtype)
		var required_rep: float = _wagon_required_reputation(wtype)
		var can_afford: bool = balance >= price and gm.reputation.meets_requirement(required_rep)

		var item := Control.new()
		item.position = Vector2(0, i * 90)
		item.size = Vector2(400, 80)

		var color_box := ColorRect.new()
		color_box.position = Vector2(0, 5)
		color_box.size = Vector2(60, 50)
		color_box.color = _get_wagon_color(wtype)
		item.add_child(color_box)

		var name_label := Label.new()
		name_label.text = _get_wagon_type_name(wtype)
		name_label.position = Vector2(75, 5)
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", COLOR_TEXT)
		item.add_child(name_label)

		var cap_label := Label.new()
		cap_label.text = I18n.t("garage.shop.capacity", [WagonData._get_capacity_for_type(wtype)])
		cap_label.position = Vector2(75, 28)
		cap_label.add_theme_font_size_override("font_size", 12)
		cap_label.add_theme_color_override("font_color", Color("#aaaaaa"))
		item.add_child(cap_label)

		if required_rep > 0.0:
			var req := Label.new()
			req.text = I18n.t("garage.shop.rep_required", [required_rep])
			req.position = Vector2(75, 48)
			req.add_theme_font_size_override("font_size", 10)
			req.add_theme_color_override("font_color", COLOR_RED if not gm.reputation.meets_requirement(required_rep) else Color("#95a5a6"))
			item.add_child(req)

		var buy_btn := _create_button(
			"%d DA" % price,
			Vector2(280, 5),
			Vector2(110, 45),
			COLOR_GREEN if can_afford else COLOR_BUTTON_DISABLED
		)
		buy_btn.name = "BuyBtn_%d" % wtype
		item.add_child(buy_btn)

		container.add_child(item)
		_shop_entries.append({"kind": "wagon", "type": wtype, "rect": Rect2(container.position + Vector2(280, i * 90 + 5), Vector2(110, 45))})

	var loco_header := Label.new()
	loco_header.text = I18n.t("garage.shop.locomotives")
	loco_header.position = Vector2(0, wagon_types.size() * 90 + 10)
	loco_header.add_theme_font_size_override("font_size", 16)
	loco_header.add_theme_color_override("font_color", Color("#f1c40f"))
	container.add_child(loco_header)

	var loco_defs := [
		{"id": "demir_yurek", "price": Balance.LOCOMOTIVE_COST_DEMIR_YUREK, "rep": Balance.LOCOMOTIVE_REPUTATION_DEMIR_YUREK},
		{"id": "boz_kaplan", "price": Balance.LOCOMOTIVE_COST_BOZ_KAPLAN, "rep": Balance.LOCOMOTIVE_REPUTATION_BOZ_KAPLAN},
	]
	for j in range(loco_defs.size()):
		var def: Dictionary = loco_defs[j]
		var row_y := wagon_types.size() * 90 + 40 + j * 90
		var loco_item := Control.new()
		loco_item.position = Vector2(0, row_y)
		loco_item.size = Vector2(400, 80)

		var tag := ColorRect.new()
		tag.position = Vector2(0, 5)
		tag.size = Vector2(60, 50)
		tag.color = COLOR_LOCO
		loco_item.add_child(tag)

		var loco_name := Label.new()
		loco_name.text = I18n.t("locomotive.%s" % str(def["id"]))
		loco_name.position = Vector2(75, 5)
		loco_name.add_theme_font_size_override("font_size", 16)
		loco_name.add_theme_color_override("font_color", COLOR_TEXT)
		loco_item.add_child(loco_name)

		var loco_req := Label.new()
		loco_req.text = I18n.t("garage.shop.rep_required", [float(def["rep"])])
		loco_req.position = Vector2(75, 28)
		loco_req.add_theme_font_size_override("font_size", 11)
		loco_req.add_theme_color_override("font_color", COLOR_RED if not gm.reputation.meets_requirement(float(def["rep"])) else Color("#95a5a6"))
		loco_item.add_child(loco_req)

		var owned: bool = gm.inventory.has_locomotive(str(def["id"]))
		var can_buy_loco: bool = (not owned) and balance >= int(def["price"]) and gm.reputation.meets_requirement(float(def["rep"]))
		var loco_buy := _create_button(
			I18n.t("garage.shop.owned") if owned else "%d DA" % int(def["price"]),
			Vector2(280, 5),
			Vector2(110, 45),
			COLOR_GREEN if can_buy_loco else COLOR_BUTTON_DISABLED
		)
		loco_item.add_child(loco_buy)
		container.add_child(loco_item)
		_shop_entries.append({"kind": "locomotive", "id": str(def["id"]), "rep": float(def["rep"]), "rect": Rect2(container.position + Vector2(280, row_y + 5), Vector2(110, 45))})

func _refresh_upgrade_panel() -> void:
	var content: Control = _upgrade_panel.get_node("UpgradeContent")
	for child in content.get_children():
		child.queue_free()
	_upgrade_entries.clear()
	_upgrade_respec_rect = Rect2()

	var gm: Node = _get_game_manager()
	var target_kind: String = str(_selected_upgrade_target.get("kind", "locomotive"))
	var target_id: String = str(_selected_upgrade_target.get("id", gm.train_config.get_locomotive().id))
	if target_kind == "wagon" and _find_wagon_by_id(target_id) == null:
		_set_upgrade_target_locomotive(gm.train_config.get_locomotive().id)
		target_kind = "locomotive"
		target_id = gm.train_config.get_locomotive().id
	var target_title := Label.new()
	target_title.text = I18n.t("garage.upgrade.target", [_get_upgrade_target_name()])
	target_title.position = Vector2(0, 0)
	target_title.size = Vector2(420, 30)
	target_title.add_theme_font_size_override("font_size", 16)
	target_title.add_theme_color_override("font_color", COLOR_TEXT)
	content.add_child(target_title)

	var info := Label.new()
	info.text = I18n.t("garage.upgrade.select_hint")
	info.position = Vector2(0, 28)
	info.size = Vector2(420, 24)
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color("#95a5a6"))
	content.add_child(info)

	var row_y: int = 70
	if target_kind == "locomotive":
		var types := [
			Constants.UpgradeType.SPEED,
			Constants.UpgradeType.CAPACITY,
			Constants.UpgradeType.FUEL_EFFICIENCY,
			Constants.UpgradeType.DURABILITY,
		]
		for upgrade_type in types:
			var can_state: Dictionary = gm.upgrade_system.can_upgrade_locomotive(target_id, upgrade_type)
			var level: int = gm.upgrade_system.get_locomotive_level(target_id, upgrade_type)
			var next_level: int = int(can_state.get("next_level", level))
			var cost: int = int(can_state.get("cost", 0))
			var row := _create_upgrade_row(
				I18n.t(_loco_upgrade_name_key(upgrade_type)),
				level,
				next_level,
				cost,
				_loco_upgrade_effect_text(upgrade_type),
				bool(can_state.get("ok", false))
			)
			row.position = Vector2(0, row_y)
			content.add_child(row)
			_upgrade_entries.append({"kind": "locomotive", "id": target_id, "upgrade_type": upgrade_type, "rect": Rect2(content.position + Vector2(300, row_y + 8), Vector2(110, 36))})
			if not bool(can_state.get("ok", false)):
				var reason_label := Label.new()
				reason_label.text = I18n.t(_upgrade_reason_key(str(can_state.get("reason", ""))))
				reason_label.position = Vector2(0, row_y + 58)
				reason_label.size = Vector2(420, 18)
				reason_label.add_theme_font_size_override("font_size", 10)
				reason_label.add_theme_color_override("font_color", COLOR_RED)
				content.add_child(reason_label)
			row_y += 88
	else:
		var wagon_data: Variant = _find_wagon_by_id(target_id)
		var wagon_type: int = Constants.WagonType.ECONOMY
		if wagon_data != null:
			wagon_type = int((wagon_data as WagonData).type)
		var types := [
			Constants.WagonUpgradeType.COMFORT,
			Constants.WagonUpgradeType.CAPACITY,
			Constants.WagonUpgradeType.MAINTENANCE,
		]
		for upgrade_type in types:
			var can_state: Dictionary = gm.upgrade_system.can_upgrade_wagon(target_id, upgrade_type)
			var level: int = gm.upgrade_system.get_wagon_level(target_id, upgrade_type)
			var next_level: int = int(can_state.get("next_level", level))
			var cost: int = int(can_state.get("cost", 0))
			var row := _create_upgrade_row(
				I18n.t(_wagon_upgrade_name_key(upgrade_type)),
				level,
				next_level,
				cost,
				_wagon_upgrade_effect_text(upgrade_type, wagon_type),
				bool(can_state.get("ok", false))
			)
			row.position = Vector2(0, row_y)
			content.add_child(row)
			_upgrade_entries.append({"kind": "wagon", "id": target_id, "wagon_type": wagon_type, "upgrade_type": upgrade_type, "rect": Rect2(content.position + Vector2(300, row_y + 8), Vector2(110, 36))})
			if not bool(can_state.get("ok", false)):
				var reason_label := Label.new()
				reason_label.text = I18n.t(_upgrade_reason_key(str(can_state.get("reason", ""))))
				reason_label.position = Vector2(0, row_y + 58)
				reason_label.size = Vector2(420, 18)
				reason_label.add_theme_font_size_override("font_size", 10)
				reason_label.add_theme_color_override("font_color", COLOR_RED)
				content.add_child(reason_label)
			row_y += 88

	var respec_btn := _create_button(I18n.t("garage.upgrade.respec"), Vector2(0, 470), Vector2(180, 42), Color("#16a085"))
	content.add_child(respec_btn)
	_upgrade_respec_rect = Rect2(content.position + Vector2(0, 470), Vector2(180, 42))

## Lifecycle/helper logic for `_input`.
func _input(event: InputEvent) -> void:
	GarageInteractionManager.handle_input(self, event)

## Lifecycle/helper logic for `_handle_shop_input`.
func _handle_shop_input(event: InputEvent) -> void:
	GarageInteractionManager._handle_shop_input(self, event)

func _handle_upgrade_input(event: InputEvent) -> void:
	GarageInteractionManager._handle_upgrade_input(self, event)

## Lifecycle/helper logic for `_on_press`.
func _on_press(pos: Vector2) -> void:
	GarageInteractionManager._on_press(self, pos)

## Lifecycle/helper logic for `_on_drag`.
func _on_drag(pos: Vector2) -> void:
	GarageInteractionManager._on_drag(self, pos)

## Lifecycle/helper logic for `_on_release`.
func _on_release(pos: Vector2) -> void:
	GarageInteractionManager._on_release(self, pos)

## Lifecycle/helper logic for `_start_drag_from_pool`.
func _start_drag_from_pool(index: int, pos: Vector2) -> void:
	GarageInteractionManager._start_drag_from_pool(self, index, pos)

## Lifecycle/helper logic for `_start_drag_from_train`.
func _start_drag_from_train(index: int, pos: Vector2) -> void:
	GarageInteractionManager._start_drag_from_train(self, index, pos)

## Lifecycle/helper logic for `_add_wagon_to_train_from_pool`.
func _add_wagon_to_train_from_pool() -> void:
	GarageInteractionManager._add_wagon_to_train_from_pool(self)

## Lifecycle/helper logic for `_remove_wagon_from_train`.
func _remove_wagon_from_train() -> void:
	GarageInteractionManager._remove_wagon_from_train(self)

## Lifecycle/helper logic for `_select_locomotive`.
func _select_locomotive(index: int) -> void:
	GarageInteractionManager._select_locomotive(self, index)

## Lifecycle/helper logic for `_open_shop`.
func _open_shop() -> void:
	_shop_visible = true
	_shop_panel.visible = true
	_refresh_shop()

func _open_upgrade() -> void:
	_upgrade_visible = true
	_upgrade_panel.visible = true
	_refresh_upgrade_panel()

## Lifecycle/helper logic for `_try_buy_wagon`.
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

func _create_upgrade_row(title: String, level: int, next_level: int, cost: int, effect_text: String, can_upgrade: bool) -> Control:
	var row := Control.new()
	row.size = Vector2(420, 80)
	var row_bg := ColorRect.new()
	row_bg.position = Vector2.ZERO
	row_bg.size = row.size
	row_bg.color = Color("#123456")
	row.add_child(row_bg)

	var name_label := Label.new()
	name_label.text = "%s (Lv.%d)" % [title, level]
	name_label.position = Vector2(10, 8)
	name_label.size = Vector2(260, 20)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(name_label)

	var effect_label := Label.new()
	effect_label.text = effect_text
	effect_label.position = Vector2(10, 30)
	effect_label.size = Vector2(280, 18)
	effect_label.add_theme_font_size_override("font_size", 11)
	effect_label.add_theme_color_override("font_color", Color("#95a5a6"))
	row.add_child(effect_label)

	var cost_label := Label.new()
	cost_label.text = I18n.t("garage.upgrade.cost", [next_level, cost])
	cost_label.position = Vector2(10, 52)
	cost_label.size = Vector2(260, 18)
	cost_label.add_theme_font_size_override("font_size", 11)
	cost_label.add_theme_color_override("font_color", Color("#f1c40f"))
	row.add_child(cost_label)

	var upgrade_btn := _create_button(I18n.t("garage.upgrade.button"), Vector2(300, 8), Vector2(110, 36), COLOR_GREEN if can_upgrade else COLOR_BUTTON_DISABLED)
	row.add_child(upgrade_btn)
	return row

func _set_upgrade_target_locomotive(loco_id: String) -> void:
	_selected_upgrade_target = {"kind": "locomotive", "id": loco_id}

func _set_upgrade_target_wagon(wagon: WagonData) -> void:
	if wagon == null:
		return
	_selected_upgrade_target = {"kind": "wagon", "id": wagon.id}

func _get_upgrade_target_name() -> String:
	var gm: Node = _get_game_manager()
	var kind: String = str(_selected_upgrade_target.get("kind", "locomotive"))
	var target_id: String = str(_selected_upgrade_target.get("id", gm.train_config.get_locomotive().id))
	if kind == "locomotive":
		return I18n.t("locomotive.%s" % target_id)
	var wagon_data: Variant = _find_wagon_by_id(target_id)
	if wagon_data == null:
		return I18n.t("garage.upgrade.unknown_target")
	var wagon: WagonData = wagon_data as WagonData
	return "%s #%s" % [_get_wagon_type_name(wagon.type), target_id.substr(0, mini(6, target_id.length()))]

func _find_wagon_by_id(wagon_id: String):
	var gm: Node = _get_game_manager()
	for wagon in gm.inventory.get_wagons():
		var w: WagonData = wagon
		if w.id == wagon_id:
			return w
	return null

func _loco_upgrade_name_key(upgrade_type: int) -> String:
	match upgrade_type:
		Constants.UpgradeType.SPEED:
			return "garage.upgrade.loco.speed"
		Constants.UpgradeType.CAPACITY:
			return "garage.upgrade.loco.capacity"
		Constants.UpgradeType.FUEL_EFFICIENCY:
			return "garage.upgrade.loco.fuel"
		Constants.UpgradeType.DURABILITY:
			return "garage.upgrade.loco.durability"
		_:
			return "garage.upgrade.unknown_target"

func _wagon_upgrade_name_key(upgrade_type: int) -> String:
	match upgrade_type:
		Constants.WagonUpgradeType.COMFORT:
			return "garage.upgrade.wagon.comfort"
		Constants.WagonUpgradeType.CAPACITY:
			return "garage.upgrade.wagon.capacity"
		Constants.WagonUpgradeType.MAINTENANCE:
			return "garage.upgrade.wagon.maintenance"
		_:
			return "garage.upgrade.unknown_target"

func _upgrade_reason_key(reason: String) -> String:
	match reason:
		"insufficient_money":
			return "garage.upgrade.reason.money"
		"insufficient_reputation":
			return "garage.upgrade.reason.reputation"
		"line_not_completed":
			return "garage.upgrade.reason.line"
		"max_level":
			return "garage.upgrade.reason.max"
		_:
			return "garage.upgrade.reason.generic"

func _loco_upgrade_effect_text(upgrade_type: int) -> String:
	match upgrade_type:
		Constants.UpgradeType.SPEED:
			return I18n.t("garage.upgrade.effect.speed")
		Constants.UpgradeType.CAPACITY:
			return I18n.t("garage.upgrade.effect.capacity")
		Constants.UpgradeType.FUEL_EFFICIENCY:
			return I18n.t("garage.upgrade.effect.fuel")
		Constants.UpgradeType.DURABILITY:
			return I18n.t("garage.upgrade.effect.durability")
		_:
			return I18n.t("garage.upgrade.reason.generic")

func _wagon_upgrade_effect_text(upgrade_type: int, wagon_type: int) -> String:
	match upgrade_type:
		Constants.WagonUpgradeType.COMFORT:
			return I18n.t("garage.upgrade.effect.wagon.comfort")
		Constants.WagonUpgradeType.CAPACITY:
			var amount: int = Balance.UPGRADE_WAGON_CAPACITY_CARGO_PER_LEVEL if wagon_type == Constants.WagonType.CARGO else Balance.UPGRADE_WAGON_CAPACITY_PASSENGER_PER_LEVEL
			return I18n.t("garage.upgrade.effect.wagon.capacity", [amount])
		Constants.WagonUpgradeType.MAINTENANCE:
			return I18n.t("garage.upgrade.effect.wagon.maintenance")
		_:
			return I18n.t("garage.upgrade.reason.generic")

## Lifecycle/helper logic for `_go_to_station`.
func _go_to_station() -> void:
	var gm: Node = _get_game_manager()
	if gm.train_config.get_wagon_count() == 0:
		_flash_warning()
		return
	SceneTransition.transition_to("res://src/scenes/map/map_scene.tscn")

## Lifecycle/helper logic for `_flash_warning`.
func _flash_warning() -> void:
	_info_label.text = I18n.t("garage.error.min_wagon")
	_info_label.add_theme_color_override("font_color", COLOR_RED)
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func() -> void:
		_info_label.add_theme_color_override("font_color", COLOR_TEXT)
		_refresh_info_bar()
	)

## Lifecycle/helper logic for `_get_game_manager`.
func _get_game_manager() -> Node:
	return get_node("/root/GameManager")

## Lifecycle/helper logic for `_get_event_position`.
func _get_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return event.position
	elif event is InputEventScreenDrag:
		return event.position
	elif event is InputEventMouseButton:
		return event.position
	elif event is InputEventMouseMotion:
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
	return event is InputEventMouseButton or event is InputEventMouseMotion

## Lifecycle/helper logic for `_get_wagon_color`.
func _get_wagon_color(wtype: Constants.WagonType) -> Color:
	match wtype:
		Constants.WagonType.ECONOMY: return COLOR_ECONOMY
		Constants.WagonType.BUSINESS: return COLOR_BUSINESS
		Constants.WagonType.VIP: return COLOR_VIP
		Constants.WagonType.DINING: return COLOR_DINING
		Constants.WagonType.CARGO: return COLOR_CARGO
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

## Lifecycle/helper logic for `_get_wagon_type_name`.
func _get_wagon_type_name(wtype: Constants.WagonType) -> String:
	match wtype:
		Constants.WagonType.ECONOMY: return I18n.t("wagon.type.economy")
		Constants.WagonType.BUSINESS: return I18n.t("wagon.type.business")
		Constants.WagonType.VIP: return I18n.t("wagon.type.vip")
		Constants.WagonType.DINING: return I18n.t("wagon.type.dining")
		Constants.WagonType.CARGO: return I18n.t("wagon.type.cargo")
		_: return I18n.t("wagon.type.unknown")

## Lifecycle/helper logic for `_get_fuel_name`.
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
	if gm == null:
		return
	if gm.total_trips != 1:
		return
	var conductor: Node = get_node_or_null("/root/ConductorManager")
	if conductor:
		conductor.show_runtime_tip("tip_tutorial_trip2_garage", I18n.t("tutorial.trip2.garage"))
