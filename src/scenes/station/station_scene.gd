## Durak sahnesi — ilk oynanabilir prototip.
## Yolcuları sürükleyerek vagonlara bindir, para kazan.
extends Node2D


# -- Sistemler --
var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem
var _boarding: BoardingSystem
var _patience: PatienceSystem

# -- Veri --
var _wagons: Array[WagonData] = []
var _waiting_passengers: Array[Dictionary] = []
var _station_time: float = Constants.STATION_TIME_LARGE  # 20 saniye
var _time_remaining: float = 0.0
var _is_active: bool = false

# -- Sürükleme --
var _dragged_passenger_index: int = -1
var _drag_offset: Vector2 = Vector2.ZERO

# -- Node referansları --
var _hud_money: Label
var _hud_reputation: Label
var _hud_timer: Label
var _passenger_nodes: Array = []
var _wagon_nodes: Array = []
var _summary_panel: PanelContainer
var _summary_label: Label

# -- Sabitler (layout) --
const VIEWPORT_W := 540
const VIEWPORT_H := 960
const TRAIN_Y := 320.0
const WAGON_START_X := 80.0
const WAGON_SPACING := 160.0
const LOCO_X := 380.0
const WAITING_Y := 650.0
const WAITING_START_X := 70.0
const WAITING_SPACING := 100.0
const PASSENGER_SIZE := Vector2(40, 56)
const WAGON_SIZE := Vector2(120, 80)
const LOCO_SIZE := Vector2(140, 100)

# -- Renkler (Style Guide'dan) --
const COLOR_BG := Color("#87CEEB")        # Ege gökyüzü
const COLOR_PLATFORM := Color("#D4AC6E")  # Kum/peron
const COLOR_RAIL := Color("#5D6D7E")      # Ray
const COLOR_LOCO := Color("#C0392B")      # TCDD kırmızı
const COLOR_WAGON_ECONOMY := Color("#3498DB")
const COLOR_WAGON_BUSINESS := Color("#2C3E50")
const COLOR_PASSENGER_NORMAL := Color("#3498DB")
const COLOR_PASSENGER_VIP := Color("#F1C40F")
const COLOR_PASSENGER_STUDENT := Color("#27AE60")
const COLOR_PASSENGER_ELDERLY := Color("#8E44AD")
const COLOR_SUCCESS := Color("#27AE60")
const COLOR_FAIL := Color("#E74C3C")
const COLOR_HUD_BG := Color(0.17, 0.24, 0.31, 0.85)


func _ready() -> void:
	_setup_systems()
	_build_scene()
	_start_station()


func _process(delta: float) -> void:
	if not _is_active:
		return

	# Geri sayım
	_time_remaining -= delta
	_hud_timer.text = "Süre: %d sn" % ceili(_time_remaining)

	if _time_remaining <= 0.0:
		_end_station()
		return

	# Sabır güncelle
	var lost := _patience.update(_waiting_passengers, delta)
	if lost.size() > 0:
		_rebuild_passenger_nodes()

	# Sabır barlarını güncelle
	_update_patience_bars()


# ==========================================================
# SİSTEM KURULUMU
# ==========================================================

func _setup_systems() -> void:
	# EventBus autoload'dan al (varsa) yoksa yeni oluştur
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

	_boarding = BoardingSystem.new()
	_boarding.setup(_event_bus, _economy, _reputation)
	add_child(_boarding)

	_patience = PatienceSystem.new()
	_patience.setup(_event_bus, _reputation)
	add_child(_patience)


# ==========================================================
# SAHNE OLUŞTURMA
# ==========================================================

func _build_scene() -> void:
	_build_background()
	_build_hud()
	_build_train()
	_build_summary_panel()


func _build_background() -> void:
	# Gökyüzü
	var sky := ColorRect.new()
	sky.color = COLOR_BG
	sky.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	sky.z_index = -10
	add_child(sky)

	# Peron
	var platform := ColorRect.new()
	platform.color = COLOR_PLATFORM
	platform.position = Vector2(0, TRAIN_Y + 60)
	platform.size = Vector2(VIEWPORT_W, 200)
	platform.z_index = -5
	add_child(platform)

	# Ray çizgileri
	for i in 2:
		var rail := ColorRect.new()
		rail.color = COLOR_RAIL
		rail.position = Vector2(0, TRAIN_Y + 50 + i * 20)
		rail.size = Vector2(VIEWPORT_W, 4)
		rail.z_index = -4
		add_child(rail)

	# Bekleme alanı çizgisi
	var wait_line := ColorRect.new()
	wait_line.color = Color(1, 1, 1, 0.3)
	wait_line.position = Vector2(20, WAITING_Y - 40)
	wait_line.size = Vector2(VIEWPORT_W - 40, 2)
	wait_line.z_index = -3
	add_child(wait_line)

	# "Bekleme Alanı" etiketi
	var wait_label := Label.new()
	wait_label.text = "- Bekleme Alanı -"
	wait_label.position = Vector2(VIEWPORT_W / 2.0 - 80, WAITING_Y - 60)
	wait_label.add_theme_font_size_override("font_size", 14)
	wait_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	add_child(wait_label)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	# HUD arka plan
	var hud_bg := ColorRect.new()
	hud_bg.color = COLOR_HUD_BG
	hud_bg.size = Vector2(VIEWPORT_W, 80)
	canvas.add_child(hud_bg)

	# Para
	_hud_money = Label.new()
	_hud_money.position = Vector2(20, 15)
	_hud_money.add_theme_font_size_override("font_size", 20)
	_hud_money.add_theme_color_override("font_color", Color("#F1C40F"))
	canvas.add_child(_hud_money)

	# İtibar
	_hud_reputation = Label.new()
	_hud_reputation.position = Vector2(20, 45)
	_hud_reputation.add_theme_font_size_override("font_size", 16)
	_hud_reputation.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(_hud_reputation)

	# Geri sayım
	_hud_timer = Label.new()
	_hud_timer.position = Vector2(VIEWPORT_W - 150, 15)
	_hud_timer.add_theme_font_size_override("font_size", 24)
	_hud_timer.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(_hud_timer)


func _build_train() -> void:
	# Lokomotif
	var loco := _create_rect_node(LOCO_SIZE, COLOR_LOCO)
	loco.position = Vector2(LOCO_X, TRAIN_Y - LOCO_SIZE.y / 2)
	add_child(loco)

	var loco_label := Label.new()
	loco_label.text = "Kara\nDuman"
	loco_label.position = Vector2(15, 25)
	loco_label.add_theme_font_size_override("font_size", 14)
	loco_label.add_theme_color_override("font_color", Color.WHITE)
	loco.add_child(loco_label)

	# Vagonlar
	_wagons = [
		WagonData.new(Constants.WagonType.ECONOMY),
		WagonData.new(Constants.WagonType.BUSINESS),
	]

	var wagon_colors := [COLOR_WAGON_ECONOMY, COLOR_WAGON_BUSINESS]
	var wagon_labels := ["Ekonomi\n0/%d" % Constants.CAPACITY_ECONOMY, "Business\n0/%d" % Constants.CAPACITY_BUSINESS]

	for i in _wagons.size():
		var wagon_node := _create_rect_node(WAGON_SIZE, wagon_colors[i])
		wagon_node.position = Vector2(WAGON_START_X + i * WAGON_SPACING, TRAIN_Y - WAGON_SIZE.y / 2)
		add_child(wagon_node)
		_wagon_nodes.append(wagon_node)

		var label := Label.new()
		label.text = wagon_labels[i]
		label.position = Vector2(10, 15)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		wagon_node.add_child(label)

	# Vagonlar arası bağlantı çizgileri
	for i in range(0, _wagons.size() - 1):
		var conn := ColorRect.new()
		conn.color = COLOR_RAIL
		var x1 := WAGON_START_X + i * WAGON_SPACING + WAGON_SIZE.x
		conn.position = Vector2(x1, TRAIN_Y - 2)
		conn.size = Vector2(WAGON_SPACING - WAGON_SIZE.x, 4)
		add_child(conn)

	# Lokomotif bağlantısı
	var loco_conn := ColorRect.new()
	loco_conn.color = COLOR_RAIL
	var last_wagon_end := WAGON_START_X + (_wagons.size() - 1) * WAGON_SPACING + WAGON_SIZE.x
	loco_conn.position = Vector2(last_wagon_end, TRAIN_Y - 2)
	loco_conn.size = Vector2(LOCO_X - last_wagon_end, 4)
	add_child(loco_conn)


func _build_summary_panel() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)

	_summary_panel = PanelContainer.new()
	_summary_panel.position = Vector2(40, 200)
	_summary_panel.size = Vector2(VIEWPORT_W - 80, 400)
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
	title.text = "Sefer Özeti"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#F1C40F"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_summary_label = Label.new()
	_summary_label.add_theme_font_size_override("font_size", 16)
	_summary_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_summary_label)

	vbox.add_child(Control.new())  # spacer

	var restart_btn := Button.new()
	restart_btn.text = "Tekrar Oyna"
	restart_btn.add_theme_font_size_override("font_size", 18)
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)


# ==========================================================
# OYUN AKıŞı
# ==========================================================

func _start_station() -> void:
	_is_active = true
	_time_remaining = _station_time
	_economy.reset_trip_summary()
	_summary_panel.visible = false

	# Yolcuları üret
	var destinations := ["denizli", "afyon", "selcuk", "nazilli"]
	_waiting_passengers = []
	var batch := PassengerFactory.create_batch(5, destinations, 120)
	for p in batch:
		_waiting_passengers.append(p)

	_rebuild_passenger_nodes()
	_update_hud()


func _end_station() -> void:
	_is_active = false
	_time_remaining = 0.0
	_hud_timer.text = "Süre: 0 sn"

	# Özet göster
	var summary := _economy.get_trip_summary()
	var boarded_count := 0
	for w in _wagons:
		boarded_count += w.get_passenger_count()
	var lost_count := 5 - _waiting_passengers.size() - boarded_count

	_summary_label.text = (
		"\nBindirilen yolcu: %d\n" % boarded_count +
		"Kalan yolcu: %d\n" % _waiting_passengers.size() +
		"Kaybedilen yolcu: %d\n\n" % lost_count +
		"Toplam kazanç: %d DA\n" % summary["total_earned"] +
		"Net bakiye: %d DA\n\n" % _economy.get_balance() +
		"Itibar: %.1f yildiz\n" % _reputation.get_stars()
	)
	_summary_panel.visible = true


func _on_restart_pressed() -> void:
	# Vagonları temizle
	_wagons = [
		WagonData.new(Constants.WagonType.ECONOMY),
		WagonData.new(Constants.WagonType.BUSINESS),
	]
	_update_wagon_labels()
	_start_station()


# ==========================================================
# SÜRÜKLE - BIRAK
# ==========================================================

func _input(event: InputEvent) -> void:
	if not _is_active:
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pos := _get_event_position(event)
		var pressed := _is_pressed(event)

		if pressed:
			_try_start_drag(pos)
		else:
			_try_end_drag(pos)

	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragged_passenger_index >= 0:
			var pos := _get_event_position(event)
			_passenger_nodes[_dragged_passenger_index].position = pos - _drag_offset


func _get_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return event.position
	elif event is InputEventScreenDrag:
		return event.position
	elif event is InputEventMouse:
		return event.position
	return Vector2.ZERO


func _is_pressed(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	elif event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false


func _try_start_drag(pos: Vector2) -> void:
	for i in _passenger_nodes.size():
		var node: Control = _passenger_nodes[i]
		var rect := Rect2(node.position, PASSENGER_SIZE)
		if rect.has_point(pos):
			_dragged_passenger_index = i
			_drag_offset = pos - node.position
			node.z_index = 100  # Sürüklenen en üstte
			node.modulate = Color(1, 1, 1, 0.8)
			return


func _try_end_drag(pos: Vector2) -> void:
	if _dragged_passenger_index < 0:
		return

	var passenger := _waiting_passengers[_dragged_passenger_index]
	var boarded := false

	# Hangi vagona bırakıldı?
	for i in _wagon_nodes.size():
		var wnode: ColorRect = _wagon_nodes[i]
		var wagon_rect := Rect2(wnode.position, WAGON_SIZE)
		if wagon_rect.has_point(pos):
			if _boarding.board_passenger(passenger, _wagons[i]):
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
		# Geri yerine koy
		_passenger_nodes[_dragged_passenger_index].position = _get_passenger_position(_dragged_passenger_index)
		_passenger_nodes[_dragged_passenger_index].z_index = 0
		_passenger_nodes[_dragged_passenger_index].modulate = Color.WHITE

	_dragged_passenger_index = -1


# ==========================================================
# GÖRSEL GÜNCELLEME
# ==========================================================

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


func _create_passenger_node(passenger: Dictionary) -> Control:
	var root := Control.new()
	root.size = PASSENGER_SIZE

	# Gövde (renkli dikdörtgen)
	var body := ColorRect.new()
	body.size = PASSENGER_SIZE
	body.color = _get_passenger_color(passenger["type"])
	root.add_child(body)

	# Tip harfi
	var type_label := Label.new()
	type_label.text = _get_passenger_type_letter(passenger["type"])
	type_label.position = Vector2(12, 8)
	type_label.add_theme_font_size_override("font_size", 18)
	type_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(type_label)

	# Ücret
	var fare_label := Label.new()
	fare_label.text = "%d DA" % passenger["fare"]
	fare_label.position = Vector2(2, 30)
	fare_label.add_theme_font_size_override("font_size", 10)
	fare_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(fare_label)

	# Hedef
	var dest_label := Label.new()
	dest_label.text = passenger["destination"].substr(0, 3).to_upper()
	dest_label.position = Vector2(2, 42)
	dest_label.add_theme_font_size_override("font_size", 9)
	dest_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	root.add_child(dest_label)

	# Sabır barı (arka plan)
	var bar_bg := ColorRect.new()
	bar_bg.size = Vector2(PASSENGER_SIZE.x - 4, 5)
	bar_bg.position = Vector2(2, -8)
	bar_bg.color = Color(0, 0, 0, 0.5)
	bar_bg.name = "PatienceBarBG"
	root.add_child(bar_bg)

	# Sabır barı (doluluk)
	var bar_fill := ColorRect.new()
	bar_fill.size = Vector2(PASSENGER_SIZE.x - 4, 5)
	bar_fill.position = Vector2(2, -8)
	bar_fill.color = COLOR_SUCCESS
	bar_fill.name = "PatienceBarFill"
	root.add_child(bar_fill)

	return root


func _update_patience_bars() -> void:
	for i in _passenger_nodes.size():
		if i >= _waiting_passengers.size():
			break
		var p: Dictionary = _waiting_passengers[i]
		var percent := PatienceSystem.get_patience_percent(p)
		var pnode: Control = _passenger_nodes[i]
		var bar: ColorRect = pnode.get_node("PatienceBarFill")
		bar.size.x = (PASSENGER_SIZE.x - 4) * (percent / 100.0)

		# Renk: yeşil→sarı→kırmızı
		if percent > 60:
			bar.color = COLOR_SUCCESS
		elif percent > 30:
			bar.color = Color("#F39C12")  # Turuncu
		else:
			bar.color = COLOR_FAIL


func _get_passenger_position(index: int) -> Vector2:
	return Vector2(WAITING_START_X + index * WAITING_SPACING, WAITING_Y)


func _get_passenger_color(type: Constants.PassengerType) -> Color:
	match type:
		Constants.PassengerType.VIP:
			return COLOR_PASSENGER_VIP
		Constants.PassengerType.STUDENT:
			return COLOR_PASSENGER_STUDENT
		Constants.PassengerType.ELDERLY:
			return COLOR_PASSENGER_ELDERLY
		_:
			return COLOR_PASSENGER_NORMAL


func _get_passenger_type_letter(type: Constants.PassengerType) -> String:
	match type:
		Constants.PassengerType.VIP:
			return "V"
		Constants.PassengerType.STUDENT:
			return "Ö"
		Constants.PassengerType.ELDERLY:
			return "Y"
		_:
			return "N"


func _update_hud() -> void:
	_hud_money.text = "%d DA" % _economy.get_balance()
	_hud_reputation.text = "%.1f yildiz" % _reputation.get_stars()


func _update_wagon_labels() -> void:
	var names := ["Ekonomi", "Business"]
	for i in _wagon_nodes.size():
		var wnode: ColorRect = _wagon_nodes[i]
		var label: Label = wnode.get_child(0)
		label.text = "%s\n%d/%d" % [names[i], _wagons[i].get_passenger_count(), _wagons[i].get_capacity()]


func _flash_wagon(wagon_index: int, color: Color) -> void:
	var node: ColorRect = _wagon_nodes[wagon_index]
	@warning_ignore("unused_variable")
	var original_color: Color = node.get_child(0).color if node.get_child(0) is ColorRect else Color.WHITE

	# Flash: ColorRect'in rengini geçici değiştirmek yerine modulate kullan
	var tween := create_tween()
	node.modulate = color
	tween.tween_property(node, "modulate", Color.WHITE, 0.3)


func _create_rect_node(size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.size = size
	rect.color = color
	return rect
