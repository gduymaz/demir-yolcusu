## Garaj sahnesi.
## Oyuncu burada lokomotif seçer, vagonları sürükleyerek trene takıp çıkarır.
## "Sefere Çık" butonu durak sahnesine geçiş yapar.
extends Node2D


# -- Layout sabitleri --
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

# -- Boyutlar --
const LOCO_SPRITE_W := 80
const LOCO_SPRITE_H := 56
const WAGON_SPRITE_W := 72
const WAGON_SPRITE_H := 48
const WAGON_SPACING := 85
const POOL_WAGON_W := 100
const POOL_WAGON_H := 60

# -- Renkler --
const COLOR_BG := Color("#1a1a2e")
const COLOR_HEADER := Color("#16213e")
const COLOR_PANEL := Color("#0f3460")
const COLOR_TRAIN_BG := Color("#1a1a2e")
const COLOR_LOCO := Color("#c0392b")       # TCDD kırmızı
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

# -- Referanslar --
var _money_label: Label
var _train_container: Control  # Tren görünüm alanı
var _info_label: Label
var _wagon_pool_container: Control
var _shop_panel: Control
var _loco_buttons: Array = []
var _train_wagon_nodes: Array = []
var _pool_wagon_nodes: Array = []

# -- Sürükleme state --
var _dragging: bool = false
var _drag_source: String = ""  # "pool" veya "train"
var _drag_index: int = -1
var _drag_node: Control = null
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_wagon: WagonData = null

# -- Mağaza state --
var _shop_visible: bool = false


func _ready() -> void:
	_build_scene()
	_refresh_all()


# ==========================================================
# SAHNE İNŞASI
# ==========================================================

func _build_scene() -> void:
	_build_background()
	_build_header()
	_build_loco_panel()
	_build_train_area()
	_build_info_bar()
	_build_wagon_pool()
	_build_button_bar()
	_build_shop_panel()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = COLOR_BG
	add_child(bg)


func _build_header() -> void:
	var header_bg := ColorRect.new()
	header_bg.position = Vector2.ZERO
	header_bg.size = Vector2(VIEWPORT_W, HEADER_H)
	header_bg.color = COLOR_HEADER
	add_child(header_bg)

	var title := Label.new()
	title.text = "GARAJ"
	title.position = Vector2(MARGIN, 10)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	add_child(title)

	_money_label = Label.new()
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_money_label.position = Vector2(VIEWPORT_W - 160, 10)
	_money_label.size = Vector2(140, 30)
	_money_label.add_theme_font_size_override("font_size", 20)
	_money_label.add_theme_color_override("font_color", COLOR_GOLD)
	add_child(_money_label)


func _build_loco_panel() -> void:
	var panel_bg := ColorRect.new()
	panel_bg.position = Vector2(0, HEADER_H)
	panel_bg.size = Vector2(VIEWPORT_W, LOCO_PANEL_H)
	panel_bg.color = COLOR_PANEL
	add_child(panel_bg)

	var section_label := Label.new()
	section_label.text = "LOKOMOTiF"
	section_label.position = Vector2(MARGIN, HEADER_H + 5)
	section_label.add_theme_font_size_override("font_size", 12)
	section_label.add_theme_color_override("font_color", Color("#888888"))
	add_child(section_label)

	# Lokomotif butonları (dinamik, refresh'te doldurulur)
	# Placeholder container
	var container := Control.new()
	container.position = Vector2(MARGIN, HEADER_H + 25)
	container.size = Vector2(VIEWPORT_W - MARGIN * 2, 50)
	container.name = "LocoContainer"
	add_child(container)


func _build_train_area() -> void:
	# Arka plan
	var area_bg := ColorRect.new()
	area_bg.position = Vector2(0, TRAIN_AREA_Y)
	area_bg.size = Vector2(VIEWPORT_W, TRAIN_AREA_H)
	area_bg.color = Color("#111122")
	add_child(area_bg)

	# Ray çizgisi
	var rail := ColorRect.new()
	rail.position = Vector2(0, TRAIN_AREA_Y + TRAIN_AREA_H - 20)
	rail.size = Vector2(VIEWPORT_W, 4)
	rail.color = Color("#444444")
	add_child(rail)

	# Tren container
	_train_container = Control.new()
	_train_container.position = Vector2(0, TRAIN_AREA_Y)
	_train_container.size = Vector2(VIEWPORT_W, TRAIN_AREA_H)
	_train_container.name = "TrainContainer"
	add_child(_train_container)


func _build_info_bar() -> void:
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(0, INFO_BAR_Y)
	bar_bg.size = Vector2(VIEWPORT_W, 40)
	bar_bg.color = COLOR_HEADER
	add_child(bar_bg)

	_info_label = Label.new()
	_info_label.position = Vector2(MARGIN, INFO_BAR_Y + 8)
	_info_label.size = Vector2(VIEWPORT_W - MARGIN * 2, 24)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", COLOR_TEXT)
	add_child(_info_label)


func _build_wagon_pool() -> void:
	var pool_bg := ColorRect.new()
	pool_bg.position = Vector2(0, WAGON_POOL_Y)
	pool_bg.size = Vector2(VIEWPORT_W, WAGON_POOL_H)
	pool_bg.color = COLOR_PANEL.darkened(0.2)
	add_child(pool_bg)

	var section_label := Label.new()
	section_label.text = "VAGONLARIM"
	section_label.position = Vector2(MARGIN, WAGON_POOL_Y + 5)
	section_label.add_theme_font_size_override("font_size", 12)
	section_label.add_theme_color_override("font_color", Color("#888888"))
	add_child(section_label)

	_wagon_pool_container = Control.new()
	_wagon_pool_container.position = Vector2(MARGIN, WAGON_POOL_Y + 25)
	_wagon_pool_container.size = Vector2(VIEWPORT_W - MARGIN * 2, WAGON_POOL_H - 30)
	_wagon_pool_container.name = "WagonPoolContainer"
	add_child(_wagon_pool_container)


func _build_button_bar() -> void:
	# Mağaza butonu
	var shop_btn := _create_button("MAGAZA", Vector2(MARGIN, BUTTON_BAR_Y), Vector2(230, BUTTON_H), COLOR_BUTTON)
	shop_btn.name = "ShopButton"
	add_child(shop_btn)

	# Haritaya Git butonu
	var go_btn := _create_button("HARITAYA GIT", Vector2(270, BUTTON_BAR_Y), Vector2(250, BUTTON_H), COLOR_GREEN)
	go_btn.name = "GoButton"
	add_child(go_btn)


func _build_shop_panel() -> void:
	# Mağaza paneli (başlangıçta gizli)
	_shop_panel = Control.new()
	_shop_panel.position = Vector2(0, 0)
	_shop_panel.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	_shop_panel.visible = false
	_shop_panel.name = "ShopPanel"
	add_child(_shop_panel)

	# Yarı saydam arka plan
	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	overlay.color = Color(0, 0, 0, 0.7)
	_shop_panel.add_child(overlay)

	# Panel kutusu
	var box := ColorRect.new()
	box.position = Vector2(40, 150)
	box.size = Vector2(460, 600)
	box.color = COLOR_PANEL
	_shop_panel.add_child(box)

	var title := Label.new()
	title.text = "MAGAZA"
	title.position = Vector2(180, 165)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	_shop_panel.add_child(title)

	# Vagon satın alma seçenekleri (dinamik)
	var shop_items_container := Control.new()
	shop_items_container.position = Vector2(60, 210)
	shop_items_container.size = Vector2(420, 400)
	shop_items_container.name = "ShopItemsContainer"
	_shop_panel.add_child(shop_items_container)

	# Kapat butonu
	var close_btn := _create_button("KAPAT", Vector2(170, 650), Vector2(200, 50), COLOR_RED)
	close_btn.name = "ShopCloseButton"
	_shop_panel.add_child(close_btn)


# ==========================================================
# YARDIMCI: BUTON OLUŞTURMA
# ==========================================================

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


# ==========================================================
# GÖRÜNÜM GÜNCELLEME
# ==========================================================

func _refresh_all() -> void:
	_refresh_money()
	_refresh_loco_list()
	_refresh_train_view()
	_refresh_info_bar()
	_refresh_wagon_pool()


func _refresh_money() -> void:
	var gm: Node = _get_game_manager()
	_money_label.text = "%d DA" % gm.economy.get_balance()


func _refresh_loco_list() -> void:
	var container: Control = get_node("LocoContainer")
	# Eski butonları temizle
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


func _refresh_train_view() -> void:
	# Eski node'ları temizle
	for child in _train_container.get_children():
		child.queue_free()
	_train_wagon_nodes.clear()

	var gm: Node = _get_game_manager()
	var config: TrainConfig = gm.train_config
	var loco: LocomotiveData = config.get_locomotive()

	# Lokomotif sprite
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

	# Vagonlar
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

	# Boş slotlar (mevcut + max arasındaki fark)
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


func _refresh_info_bar() -> void:
	var gm: Node = _get_game_manager()
	var config: TrainConfig = gm.train_config
	var wagon_count := config.get_wagon_count()
	var max_wagons := config.get_max_wagons()
	var capacity := config.get_total_passenger_capacity()
	var loco: LocomotiveData = config.get_locomotive()
	var fuel_name := _get_fuel_name(loco.fuel_type)
	_info_label.text = "Vagon: %d/%d | Kapasite: %d yolcu | Yakit: %s" % [wagon_count, max_wagons, capacity, fuel_name]


func _refresh_wagon_pool() -> void:
	# Eski node'ları temizle
	for child in _wagon_pool_container.get_children():
		child.queue_free()
	_pool_wagon_nodes.clear()

	var gm: Node = _get_game_manager()
	var available: Array = gm.inventory.get_available_wagons()

	if available.size() == 0:
		var empty_label := Label.new()
		empty_label.text = "(Tum vagonlar trende)"
		empty_label.position = Vector2(60, 40)
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color("#888888"))
		_wagon_pool_container.add_child(empty_label)
		return

	# Grid layout: 2 sütun
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


func _refresh_shop() -> void:
	var container: Control = _shop_panel.get_node("ShopItemsContainer")
	for child in container.get_children():
		child.queue_free()

	var gm: Node = _get_game_manager()
	var balance: int = gm.economy.get_balance()

	var wagon_types := [
		Constants.WagonType.ECONOMY,
		Constants.WagonType.BUSINESS,
		Constants.WagonType.VIP,
		Constants.WagonType.CARGO,
	]

	for i in range(wagon_types.size()):
		var wtype: Constants.WagonType = wagon_types[i]
		var price := PlayerInventory.get_wagon_price(wtype)
		var can_afford: bool = balance >= price

		var item := Control.new()
		item.position = Vector2(0, i * 90)
		item.size = Vector2(400, 80)

		# Vagon renk kutusu
		var color_box := ColorRect.new()
		color_box.position = Vector2(0, 5)
		color_box.size = Vector2(60, 50)
		color_box.color = _get_wagon_color(wtype)
		item.add_child(color_box)

		# İsim
		var name_label := Label.new()
		name_label.text = _get_wagon_type_name(wtype)
		name_label.position = Vector2(75, 5)
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", COLOR_TEXT)
		item.add_child(name_label)

		# Kapasite
		var cap_label := Label.new()
		cap_label.text = "Kapasite: %d" % WagonData._get_capacity_for_type(wtype)
		cap_label.position = Vector2(75, 28)
		cap_label.add_theme_font_size_override("font_size", 12)
		cap_label.add_theme_color_override("font_color", Color("#aaaaaa"))
		item.add_child(cap_label)

		# Satın al butonu
		var buy_btn := _create_button(
			"%d DA" % price,
			Vector2(280, 5),
			Vector2(110, 45),
			COLOR_GREEN if can_afford else COLOR_BUTTON_DISABLED
		)
		buy_btn.name = "BuyBtn_%d" % wtype
		item.add_child(buy_btn)

		container.add_child(item)


# ==========================================================
# INPUT
# ==========================================================

func _input(event: InputEvent) -> void:
	if _should_ignore_mouse_event(event):
		return

	if _shop_visible:
		_handle_shop_input(event)
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pos := _get_event_position(event)
		var pressed := _is_pressed(event)

		if pressed:
			_on_press(pos)
		else:
			_on_release(pos)

	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and _dragging:
		var pos := _get_event_position(event)
		_on_drag(pos)


func _handle_shop_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if not _is_pressed(event):
		return

	var pos := _get_event_position(event)

	# Kapat butonu
	var close_btn: Control = _shop_panel.get_node("ShopCloseButton")
	if _is_in_rect(pos, close_btn.position, close_btn.size):
		_shop_visible = false
		_shop_panel.visible = false
		_refresh_all()
		return

	# Satın al butonları
	var container: Control = _shop_panel.get_node("ShopItemsContainer")
	var wagon_types := [
		Constants.WagonType.ECONOMY,
		Constants.WagonType.BUSINESS,
		Constants.WagonType.VIP,
		Constants.WagonType.CARGO,
	]

	for i in range(wagon_types.size()):
		var wtype: Constants.WagonType = wagon_types[i]
		# Buton pozisyonu: container offset + item offset + buton offset
		var btn_global := container.position + Vector2(0, i * 90) + Vector2(280, 5)
		if _is_in_rect(pos, btn_global, Vector2(110, 45)):
			_try_buy_wagon(wtype)
			return


func _on_press(pos: Vector2) -> void:
	if _dragging:
		return

	# Mağaza butonu
	var shop_btn: Control = get_node("ShopButton")
	if _is_in_rect(pos, shop_btn.position, shop_btn.size):
		_open_shop()
		return

	# Sefere Çık butonu
	var go_btn: Control = get_node("GoButton")
	if _is_in_rect(pos, go_btn.position, go_btn.size):
		_go_to_station()
		return

	# Trendeki vagona tıklama (çıkarma)
	var gm: Node = _get_game_manager()
	var config: TrainConfig = gm.train_config
	for i in range(_train_wagon_nodes.size()):
		var node: Control = _train_wagon_nodes[i]
		var node_global := node.position + _train_container.position
		if _is_in_rect(pos, node_global, node.size):
			_start_drag_from_train(i, pos)
			return

	# Havuzdaki vagona tıklama (sürükleme)
	for i in range(_pool_wagon_nodes.size()):
		var node: Control = _pool_wagon_nodes[i]
		var node_global := node.position + _wagon_pool_container.position
		if _is_in_rect(pos, node_global, node.size):
			_start_drag_from_pool(i, pos)
			return

	# Lokomotif butonları
	var loco_container: Control = get_node("LocoContainer")
	for i in range(_loco_buttons.size()):
		var btn: Control = _loco_buttons[i]
		var btn_global := btn.position + loco_container.position
		if _is_in_rect(pos, btn_global, btn.size):
			_select_locomotive(i)
			return


func _on_drag(pos: Vector2) -> void:
	if _drag_node:
		_drag_node.position = pos - _drag_offset


func _on_release(pos: Vector2) -> void:
	if not _dragging:
		return

	_dragging = false

	# Tren alanına bırakılmış mı?
	var in_train_area := pos.y >= TRAIN_AREA_Y and pos.y <= TRAIN_AREA_Y + TRAIN_AREA_H

	if _drag_source == "pool" and in_train_area:
		# Havuzdan trene ekleme
		_add_wagon_to_train_from_pool()
	elif _drag_source == "train" and not in_train_area:
		# Trenden çıkarma
		_remove_wagon_from_train()
	# else: bırakılan yer geçersiz → geri dön

	# Sürükleme node'unu temizle
	if _drag_node:
		_drag_node.queue_free()
		_drag_node = null

	_refresh_all()


# ==========================================================
# SÜRÜKLEME İŞLEMLERİ
# ==========================================================

func _start_drag_from_pool(index: int, pos: Vector2) -> void:
	var gm: Node = _get_game_manager()
	var available: Array = gm.inventory.get_available_wagons()
	if index >= available.size():
		return

	_dragging = true
	_drag_source = "pool"
	_drag_index = index
	_drag_wagon = available[index]

	# Sürükleme görsel node'u
	_drag_node = ColorRect.new()
	_drag_node.size = Vector2(WAGON_SPRITE_W, WAGON_SPRITE_H)
	_drag_node.color = _get_wagon_color(_drag_wagon.type)
	_drag_node.modulate = Color(1, 1, 1, 0.7)
	_drag_node.z_index = 100
	_drag_offset = Vector2(WAGON_SPRITE_W / 2.0, WAGON_SPRITE_H / 2.0)
	_drag_node.position = pos - _drag_offset
	add_child(_drag_node)


func _start_drag_from_train(index: int, pos: Vector2) -> void:
	var gm: Node = _get_game_manager()
	var wagons: Array = gm.train_config.get_wagons()
	if index >= wagons.size():
		return

	_dragging = true
	_drag_source = "train"
	_drag_index = index
	_drag_wagon = wagons[index]

	_drag_node = ColorRect.new()
	_drag_node.size = Vector2(WAGON_SPRITE_W, WAGON_SPRITE_H)
	_drag_node.color = _get_wagon_color(_drag_wagon.type)
	_drag_node.modulate = Color(1, 1, 1, 0.7)
	_drag_node.z_index = 100
	_drag_offset = Vector2(WAGON_SPRITE_W / 2.0, WAGON_SPRITE_H / 2.0)
	_drag_node.position = pos - _drag_offset
	add_child(_drag_node)


func _add_wagon_to_train_from_pool() -> void:
	var gm: Node = _get_game_manager()
	var config: TrainConfig = gm.train_config
	if config.is_full() or _drag_wagon == null:
		return
	if config.add_wagon(_drag_wagon):
		gm.inventory.mark_wagon_in_use(_drag_wagon)


func _remove_wagon_from_train() -> void:
	var gm: Node = _get_game_manager()
	var config: TrainConfig = gm.train_config
	var removed := config.remove_wagon_at(_drag_index)
	if removed:
		gm.inventory.unmark_wagon_in_use(removed)


# ==========================================================
# LOKOMOTİF SEÇİMİ
# ==========================================================

func _select_locomotive(index: int) -> void:
	var gm: Node = _get_game_manager()
	var locos: Array = gm.inventory.get_locomotives()
	if index >= locos.size():
		return

	var loco: LocomotiveData = locos[index]
	var old_config: TrainConfig = gm.train_config

	# Eski vagonları boşalt
	for wagon in old_config.get_wagons():
		gm.inventory.unmark_wagon_in_use(wagon)

	# Yeni konfigürasyon
	gm.train_config = TrainConfig.new(loco)

	# Eski vagonları yenisine taşı (max kadar)
	for wagon in old_config.get_wagons():
		if gm.train_config.is_full():
			break
		gm.train_config.add_wagon(wagon)
		gm.inventory.mark_wagon_in_use(wagon)

	_refresh_all()


# ==========================================================
# MAĞAZA
# ==========================================================

func _open_shop() -> void:
	_shop_visible = true
	_shop_panel.visible = true
	_refresh_shop()


func _try_buy_wagon(wagon_type: Constants.WagonType) -> void:
	var gm: Node = _get_game_manager()
	if gm.inventory.buy_wagon(wagon_type):
		_refresh_shop()
		_refresh_money()


# ==========================================================
# SAHNE GEÇİŞİ
# ==========================================================

func _go_to_station() -> void:
	var gm: Node = _get_game_manager()
	if gm.train_config.get_wagon_count() == 0:
		_flash_warning()
		return
	get_tree().change_scene_to_file("res://src/scenes/map/map_scene.tscn")


func _flash_warning() -> void:
	_info_label.text = "En az 1 vagon gerekli!"
	_info_label.add_theme_color_override("font_color", COLOR_RED)
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func() -> void:
		_info_label.add_theme_color_override("font_color", COLOR_TEXT)
		_refresh_info_bar()
	)


# ==========================================================
# YARDIMCILAR
# ==========================================================

func _get_game_manager() -> Node:
	return get_node("/root/GameManager")


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


func _is_pressed(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	elif event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false


func _is_in_rect(pos: Vector2, rect_pos: Vector2, rect_size: Vector2) -> bool:
	return pos.x >= rect_pos.x and pos.x <= rect_pos.x + rect_size.x \
		and pos.y >= rect_pos.y and pos.y <= rect_pos.y + rect_size.y


func _should_ignore_mouse_event(event: InputEvent) -> bool:
	var emulate_touch: bool = ProjectSettings.get_setting(
		"input_devices/pointing/emulate_touch_from_mouse",
		false
	)
	if not emulate_touch:
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
		Constants.WagonType.ECONOMY: return "Eko."
		Constants.WagonType.BUSINESS: return "Biz."
		Constants.WagonType.VIP: return "VIP"
		Constants.WagonType.DINING: return "Ym."
		Constants.WagonType.CARGO: return "Kar."
		_: return "?"


func _get_wagon_type_name(wtype: Constants.WagonType) -> String:
	match wtype:
		Constants.WagonType.ECONOMY: return "Ekonomi"
		Constants.WagonType.BUSINESS: return "Business"
		Constants.WagonType.VIP: return "VIP"
		Constants.WagonType.DINING: return "Yemekli"
		Constants.WagonType.CARGO: return "Kargo"
		_: return "Bilinmeyen"


func _get_fuel_name(ftype: Constants.FuelType) -> String:
	match ftype:
		Constants.FuelType.COAL_OLD: return "Komur (Eski)"
		Constants.FuelType.COAL_NEW: return "Komur (Yeni)"
		Constants.FuelType.DIESEL_OLD: return "Dizel (Eski)"
		Constants.FuelType.DIESEL_NEW: return "Dizel (Yeni)"
		Constants.FuelType.ELECTRIC: return "Elektrik"
		_: return "?"
