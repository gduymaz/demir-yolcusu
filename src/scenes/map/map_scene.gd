## Harita sahnesi.
## Stilize Ege haritası, durak seçimi, rota gösterimi, sefer başlatma.
extends Node2D


# -- Layout --
const VIEWPORT_W := 540
const VIEWPORT_H := 960
const MAP_Y := 80
const MAP_H := 560
const PANEL_Y := 660
const PANEL_H := 200
const BUTTON_BAR_Y := 880

# -- Harita GPS sınırları (Ege bölgesi + biraz margin) --
const MAP_LAT_MIN := 37.5   # Güney (Denizli)
const MAP_LAT_MAX := 38.7   # Kuzey (İzmir)
const MAP_LNG_MIN := 26.8   # Batı
const MAP_LNG_MAX := 29.4   # Doğu (Denizli)

# -- Boyutlar --
const STOP_RADIUS := 18.0
const STOP_RADIUS_SELECTED := 24.0

# -- Renkler --
const COLOR_BG := Color("#1a1a2e")
const COLOR_HEADER := Color("#16213e")
const COLOR_MAP_BG := Color("#0a3d62")  # Deniz mavisi
const COLOR_LAND := Color("#2d5016")    # Kara (yeşil)
const COLOR_STOP := Color("#ecf0f1")    # Normal durak
const COLOR_STOP_START := Color("#27ae60")   # Başlangıç (yeşil)
const COLOR_STOP_END := Color("#e74c3c")     # Bitiş (kırmızı)
const COLOR_STOP_BETWEEN := Color("#3498db") # Aradaki duraklar (mavi)
const COLOR_ROUTE_LINE := Color("#f39c12")   # Rota çizgisi
const COLOR_TEXT := Color("#ecf0f1")
const COLOR_GOLD := Color("#f39c12")
const COLOR_GREEN := Color("#27ae60")
const COLOR_RED := Color("#e74c3c")
const COLOR_PANEL := Color("#16213e")
const COLOR_BUTTON := Color("#2980b9")
const COLOR_BUTTON_DISABLED := Color("#555555")
const COLOR_LOCKED := Color("#333333")

# -- State --
var _stop_nodes: Array = []
var _route_line_nodes: Array = []
var _selected_start: int = -1
var _selected_end: int = -1
var _info_label: Label
var _money_label: Label
var _start_button: Control
var _start_button_bg: ColorRect
var _popup: Control = null


func _ready() -> void:
	_build_scene()
	_refresh_all()


# ==========================================================
# SAHNE İNŞASI
# ==========================================================

func _build_scene() -> void:
	_build_background()
	_build_header()
	_build_map()
	_build_stops()
	_build_panel()
	_build_buttons()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = COLOR_BG
	add_child(bg)


func _build_header() -> void:
	var header := ColorRect.new()
	header.size = Vector2(VIEWPORT_W, MAP_Y)
	header.color = COLOR_HEADER
	add_child(header)

	var title := Label.new()
	title.text = "HARITA - EGE"
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

	# Talimat
	var hint := Label.new()
	hint.text = "Baslangic ve bitis duragi sec"
	hint.position = Vector2(20, 48)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color("#888888"))
	add_child(hint)


func _build_map() -> void:
	# Deniz arka planı
	var sea := ColorRect.new()
	sea.position = Vector2(0, MAP_Y)
	sea.size = Vector2(VIEWPORT_W, MAP_H)
	sea.color = COLOR_MAP_BG
	add_child(sea)

	# Kara kütlesi (basit poligon yerine dikdörtgen)
	var land := ColorRect.new()
	land.position = Vector2(40, MAP_Y + 40)
	land.size = Vector2(VIEWPORT_W - 80, MAP_H - 80)
	land.color = COLOR_LAND
	add_child(land)

	# Kıyı çizgisi efekti
	var coast := ColorRect.new()
	coast.position = Vector2(38, MAP_Y + 38)
	coast.size = Vector2(VIEWPORT_W - 76, MAP_H - 76)
	coast.color = Color("#1a6b3d")
	coast.z_index = -1
	add_child(coast)

	# Bölge etiketleri (kilitli bölgeler)
	_add_locked_region("MARMARA", Vector2(220, MAP_Y + 50))
	_add_locked_region("IC ANADOLU", Vector2(380, MAP_Y + 200))


func _add_locked_region(region_name: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = region_name + " [KILITLI]"
	label.position = pos
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", COLOR_LOCKED)
	add_child(label)


func _build_stops() -> void:
	var gm: Node = _get_game_manager()
	if not gm:
		return

	var route: RouteData = gm.route

	# Önce rota çizgisini çiz
	for i in range(route.get_stop_count() - 1):
		var stop_a: Dictionary = route.get_stop(i)
		var stop_b: Dictionary = route.get_stop(i + 1)
		var pos_a := _gps_to_screen(stop_a["lat"], stop_a["lng"])
		var pos_b := _gps_to_screen(stop_b["lat"], stop_b["lng"])

		# Çizgi (ince dikdörtgen)
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

	# Durakları çiz
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

		# Durak ismi
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


func _build_panel() -> void:
	var panel := ColorRect.new()
	panel.position = Vector2(0, PANEL_Y)
	panel.size = Vector2(VIEWPORT_W, PANEL_H)
	panel.color = COLOR_PANEL
	add_child(panel)

	var title := Label.new()
	title.text = "SEFER BILGISI"
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


func _build_buttons() -> void:
	# Garaja Dön
	var back_btn := _create_button("GARAJA DON", Vector2(20, BUTTON_BAR_Y), Vector2(220, 55), COLOR_BUTTON)
	back_btn.name = "BackButton"
	add_child(back_btn)

	# Sefere Başla
	_start_button = _create_button("SEFERE BASLA", Vector2(260, BUTTON_BAR_Y), Vector2(260, 55), COLOR_GREEN)
	_start_button.name = "StartButton"
	_start_button_bg = _start_button.get_child(0) as ColorRect
	add_child(_start_button)


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


# ==========================================================
# GÖRSEL GÜNCELLEME
# ==========================================================

func _refresh_all() -> void:
	_refresh_money()
	_refresh_stops()
	_refresh_route_lines()
	_refresh_panel()
	_refresh_start_button()


func _refresh_money() -> void:
	var gm: Node = _get_game_manager()
	if gm:
		_money_label.text = "%d DA" % gm.economy.get_balance()


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


func _refresh_route_lines() -> void:
	for i in _route_line_nodes.size():
		var line: ColorRect = _route_line_nodes[i]
		if _is_segment_selected(i):
			line.color = COLOR_ROUTE_LINE
			line.size.y = 5
		else:
			line.color = Color("#444444")
			line.size.y = 3


func _refresh_panel() -> void:
	if _selected_start < 0 or _selected_end < 0:
		_info_label.text = "Haritadan iki durak sec.\nIlk tiklama = baslangic (yesil)\nIkinci tiklama = bitis (kirmizi)"
		return

	var gm: Node = _get_game_manager()
	if not gm:
		return

	gm.trip_planner.select_stops(_selected_start, _selected_end)
	var preview: Dictionary = gm.trip_planner.get_preview()

	var start_name: String = gm.route.get_stop(_selected_start)["name"]
	var end_name: String = gm.route.get_stop(_selected_end)["name"]

	_info_label.text = (
		"%s  -->  %s\n" % [start_name, end_name] +
		"Mesafe: %.0f km | Durak: %d\n" % [preview["distance_km"], preview["stop_count"]] +
		"Yakit maliyeti: ~%d DA\n" % preview["refuel_cost"] +
		"Tahmini gelir: ~%d DA\n" % preview["estimated_revenue"] +
		("Yakit: YETERLI" if preview["can_afford_fuel"] else "Yakit: YETERSIZ!")
	)

	if not preview["can_afford_fuel"]:
		_info_label.add_theme_color_override("font_color", COLOR_RED)
	else:
		_info_label.add_theme_color_override("font_color", COLOR_TEXT)


func _refresh_start_button() -> void:
	var can_start := _selected_start >= 0 and _selected_end >= 0
	if can_start:
		var gm: Node = _get_game_manager()
		if gm:
			var preview: Dictionary = gm.trip_planner.get_preview()
			can_start = preview.get("can_afford_fuel", false)

	_start_button_bg.color = COLOR_GREEN if can_start else COLOR_BUTTON_DISABLED


# ==========================================================
# INPUT
# ==========================================================

func _input(event: InputEvent) -> void:
	if _popup:
		_handle_popup_input(event)
		return

	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if not _is_pressed(event):
		return

	var pos := _get_event_position(event)

	# Butonlar
	var back_btn: Control = get_node("BackButton")
	if _is_in_rect(pos, back_btn.position, back_btn.size):
		get_tree().change_scene_to_file("res://src/scenes/garage/garage_scene.tscn")
		return

	var start_btn: Control = get_node("StartButton")
	if _is_in_rect(pos, start_btn.position, start_btn.size):
		_try_start_trip()
		return

	# Durak tıklama
	for i in _stop_nodes.size():
		var node: Control = _stop_nodes[i]
		if _is_in_rect(pos, node.position, node.size):
			_on_stop_clicked(i)
			return


func _handle_popup_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if not _is_pressed(event):
		return
	# Popup'ı kapat
	_popup.queue_free()
	_popup = null


func _on_stop_clicked(index: int) -> void:
	if _selected_start < 0:
		# İlk tıklama = başlangıç
		_selected_start = index
	elif _selected_end < 0:
		if index == _selected_start:
			# Aynı durak — iptal
			_selected_start = -1
		else:
			# İkinci tıklama = bitiş
			_selected_end = index
	else:
		# Zaten iki durak seçili — sıfırla ve yeniden başla
		_selected_start = index
		_selected_end = -1

	_refresh_all()


func _try_start_trip() -> void:
	if _selected_start < 0 or _selected_end < 0:
		return

	var gm: Node = _get_game_manager()
	if not gm:
		return

	gm.trip_planner.select_stops(_selected_start, _selected_end)
	if gm.trip_planner.start_trip():
		get_tree().change_scene_to_file("res://src/scenes/travel/travel_scene.tscn")


# ==========================================================
# YARDIMCILAR
# ==========================================================

func _gps_to_screen(lat: float, lng: float) -> Vector2:
	var x_ratio := (lng - MAP_LNG_MIN) / (MAP_LNG_MAX - MAP_LNG_MIN)
	# Lat ters (kuzey yukarıda)
	var y_ratio := 1.0 - (lat - MAP_LAT_MIN) / (MAP_LAT_MAX - MAP_LAT_MIN)
	var margin := 60.0
	var x := margin + x_ratio * (VIEWPORT_W - margin * 2)
	var y := MAP_Y + margin + y_ratio * (MAP_H - margin * 2)
	return Vector2(x, y)


func _is_between_selection(index: int) -> bool:
	if _selected_start < 0 or _selected_end < 0:
		return false
	var from := mini(_selected_start, _selected_end)
	var to := maxi(_selected_start, _selected_end)
	return index > from and index < to


func _is_segment_selected(segment_index: int) -> bool:
	if _selected_start < 0 or _selected_end < 0:
		return false
	var from := mini(_selected_start, _selected_end)
	var to := maxi(_selected_start, _selected_end)
	return segment_index >= from and segment_index < to


func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _get_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return event.position
	elif event is InputEventMouseButton:
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
