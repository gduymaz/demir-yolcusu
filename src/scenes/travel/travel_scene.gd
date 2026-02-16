## Seyir sahnesi.
## Duraklar arası tren yolculuğu animasyonu.
## İlerleme barı, yakıt tüketimi, hızlandır butonu.
extends Node2D


# -- Layout --
const VIEWPORT_W := 540
const VIEWPORT_H := 960
const SKY_H := 400
const GROUND_Y := 400
const RAIL_Y := 500
const TRAIN_Y := 460
const HUD_H := 100
const PROGRESS_Y := 620
const INFO_Y := 700

# -- Boyutlar --
const TRAIN_W := 120
const TRAIN_H := 60

# -- Renkler --
const COLOR_SKY := Color("#87CEEB")
const COLOR_GROUND := Color("#7B8B3A")
const COLOR_RAIL := Color("#5D6D7E")
const COLOR_TRAIN := Color("#C0392B")
const COLOR_BG := Color("#1a1a2e")
const COLOR_TEXT := Color("#ecf0f1")
const COLOR_GOLD := Color("#f39c12")
const COLOR_GREEN := Color("#27ae60")
const COLOR_PANEL := Color("#16213e")

# -- State --
var _travel_speed := 1.0  # 1x veya 2x
var _progress := 0.0      # 0.0 → 1.0
var _travel_duration := 3.0  # Saniye (seyir süresi)
var _is_traveling := true
var _arrived := false

# -- Nodes --
var _train_node: ColorRect
var _progress_bar: ColorRect
var _progress_bg: ColorRect
var _distance_label: Label
var _from_label: Label
var _to_label: Label
var _speed_label: Label
var _fuel_label: Label
var _warning_label: Label


func _ready() -> void:
	_build_scene()
	_start_travel()


func _process(delta: float) -> void:
	if not _is_traveling:
		return

	_progress += delta * _get_effective_speed() / _travel_duration
	if _progress >= 1.0:
		_progress = 1.0
		_arrive_at_station()

	_update_visuals()


# ==========================================================
# SAHNE İNŞASI
# ==========================================================

func _build_scene() -> void:
	_build_landscape()
	_build_train()
	_build_hud()
	_build_progress()
	_build_info()
	_build_speed_button()


func _build_landscape() -> void:
	# Arka plan
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = COLOR_BG
	add_child(bg)

	# Gökyüzü
	var sky := ColorRect.new()
	sky.position = Vector2(0, HUD_H)
	sky.size = Vector2(VIEWPORT_W, SKY_H - HUD_H)
	sky.color = COLOR_SKY
	add_child(sky)

	# Dağlar (basit üçgen temsilcisi)
	var mountain := ColorRect.new()
	mountain.position = Vector2(100, 260)
	mountain.size = Vector2(150, 140)
	mountain.color = Color("#2E4053")
	add_child(mountain)

	var mountain2 := ColorRect.new()
	mountain2.position = Vector2(300, 290)
	mountain2.size = Vector2(120, 110)
	mountain2.color = Color("#34495E")
	add_child(mountain2)

	# Zemin
	var ground := ColorRect.new()
	ground.position = Vector2(0, GROUND_Y)
	ground.size = Vector2(VIEWPORT_W, 200)
	ground.color = COLOR_GROUND
	add_child(ground)

	# Ray
	var rail := ColorRect.new()
	rail.position = Vector2(0, RAIL_Y)
	rail.size = Vector2(VIEWPORT_W, 6)
	rail.color = COLOR_RAIL
	add_child(rail)

	# Traversler (ray bağlantıları)
	for i in range(20):
		var tie := ColorRect.new()
		tie.position = Vector2(i * 30.0, RAIL_Y - 3)
		tie.size = Vector2(4, 12)
		tie.color = Color("#3E2723")
		add_child(tie)


func _build_train() -> void:
	_train_node = ColorRect.new()
	_train_node.size = Vector2(TRAIN_W, TRAIN_H)
	_train_node.position = Vector2(-TRAIN_W, TRAIN_Y)
	_train_node.color = COLOR_TRAIN
	_train_node.z_index = 10
	add_child(_train_node)

	# Baca
	var chimney := ColorRect.new()
	chimney.position = Vector2(TRAIN_W - 25, -15)
	chimney.size = Vector2(15, 15)
	chimney.color = Color("#2C3E50")
	_train_node.add_child(chimney)

	# Pencereler
	for i in range(3):
		var window := ColorRect.new()
		window.position = Vector2(10 + i * 30, 10)
		window.size = Vector2(20, 15)
		window.color = Color("#AED6F1")
		_train_node.add_child(window)


func _build_hud() -> void:
	var hud_bg := ColorRect.new()
	hud_bg.size = Vector2(VIEWPORT_W, HUD_H)
	hud_bg.color = COLOR_PANEL
	hud_bg.z_index = 20
	add_child(hud_bg)

	# Güzergah
	_from_label = Label.new()
	_from_label.position = Vector2(20, 15)
	_from_label.add_theme_font_size_override("font_size", 16)
	_from_label.add_theme_color_override("font_color", COLOR_GREEN)
	_from_label.z_index = 21
	add_child(_from_label)

	var arrow := Label.new()
	arrow.text = "-->"
	arrow.position = Vector2(220, 15)
	arrow.add_theme_font_size_override("font_size", 16)
	arrow.add_theme_color_override("font_color", COLOR_TEXT)
	arrow.z_index = 21
	add_child(arrow)

	_to_label = Label.new()
	_to_label.position = Vector2(270, 15)
	_to_label.add_theme_font_size_override("font_size", 16)
	_to_label.add_theme_color_override("font_color", COLOR_GOLD)
	_to_label.z_index = 21
	add_child(_to_label)

	# Yakıt
	_fuel_label = Label.new()
	_fuel_label.position = Vector2(20, 50)
	_fuel_label.add_theme_font_size_override("font_size", 14)
	_fuel_label.add_theme_color_override("font_color", COLOR_TEXT)
	_fuel_label.z_index = 21
	add_child(_fuel_label)

	_warning_label = Label.new()
	_warning_label.position = Vector2(180, 50)
	_warning_label.size = Vector2(160, 20)
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.add_theme_font_size_override("font_size", 13)
	_warning_label.add_theme_color_override("font_color", Color("#e74c3c"))
	add_child(_warning_label)

	# Hız
	_speed_label = Label.new()
	_speed_label.position = Vector2(350, 50)
	_speed_label.add_theme_font_size_override("font_size", 14)
	_speed_label.add_theme_color_override("font_color", COLOR_TEXT)
	_speed_label.z_index = 21
	add_child(_speed_label)


func _build_progress() -> void:
	# İlerleme barı arka planı
	_progress_bg = ColorRect.new()
	_progress_bg.position = Vector2(40, PROGRESS_Y)
	_progress_bg.size = Vector2(VIEWPORT_W - 80, 30)
	_progress_bg.color = Color("#333333")
	add_child(_progress_bg)

	# İlerleme barı doluluk
	_progress_bar = ColorRect.new()
	_progress_bar.position = Vector2(40, PROGRESS_Y)
	_progress_bar.size = Vector2(0, 30)
	_progress_bar.color = COLOR_GREEN
	add_child(_progress_bar)

	# Mesafe etiketi
	_distance_label = Label.new()
	_distance_label.position = Vector2(40, PROGRESS_Y + 38)
	_distance_label.size = Vector2(VIEWPORT_W - 80, 20)
	_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_distance_label.add_theme_font_size_override("font_size", 16)
	_distance_label.add_theme_color_override("font_color", COLOR_TEXT)
	add_child(_distance_label)


func _build_info() -> void:
	# Bilgi paneli
	var panel := ColorRect.new()
	panel.position = Vector2(0, INFO_Y + 50)
	panel.size = Vector2(VIEWPORT_W, VIEWPORT_H - INFO_Y - 50)
	panel.color = COLOR_PANEL
	add_child(panel)


func _build_speed_button() -> void:
	var btn := _create_button("HIZ: 1x", Vector2(180, INFO_Y + 70), Vector2(180, 50), Color("#2980b9"))
	btn.name = "SpeedButton"
	add_child(btn)

	# Varış butonu (başta gizli)
	var arrive_btn := _create_button("DURAGA GIR", Vector2(140, INFO_Y + 140), Vector2(260, 60), COLOR_GREEN)
	arrive_btn.name = "ArriveButton"
	arrive_btn.visible = false
	add_child(arrive_btn)


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


# ==========================================================
# SEYİR
# ==========================================================

func _start_travel() -> void:
	var gm: Node = _get_game_manager()
	if not gm:
		return

	var current := gm.trip_planner.get_current_stop()
	var next := gm.trip_planner.get_next_stop()

	if current.is_empty() or next.is_empty():
		# Son durağa ulaşıldı
		_show_trip_end()
		return

	_from_label.text = current["name"]
	_to_label.text = next["name"]

	var distance := gm.trip_planner.get_distance_to_next_stop()
	# Seyir süresi: mesafeye orantılı (yaklaşık 1s / 30km)
	_travel_duration = maxf(1.5, distance / 30.0)

	_fuel_label.text = "Yakit: %.0f%%" % gm.fuel_system.get_fuel_percentage()
	_speed_label.text = "Hiz: %dx" % int(_travel_speed)
	_warning_label.text = ""
	_is_traveling = true
	_arrived = false
	_progress = 0.0


func _arrive_at_station() -> void:
	_is_traveling = false
	_arrived = true

	var gm: Node = _get_game_manager()
	if gm:
		gm.trip_planner.advance_to_next_stop()
		_fuel_label.text = "Yakit: %.0f%%" % gm.fuel_system.get_fuel_percentage()

	# Varış butonunu göster
	var arrive_btn: Control = get_node("ArriveButton")
	arrive_btn.visible = true

	# Son duraktaysa buton metnini değiştir
	if gm and gm.trip_planner.is_at_final_stop():
		var lbl: Label = arrive_btn.get_child(1)
		lbl.text = "SEFER SONU"


func _show_trip_end() -> void:
	_is_traveling = false
	_from_label.text = "Sefer Tamamlandi!"
	_to_label.text = ""
	var arrive_btn: Control = get_node("ArriveButton")
	arrive_btn.visible = true
	var lbl: Label = arrive_btn.get_child(1)
	lbl.text = "SEFER OZETI"


# ==========================================================
# GÖRSEL GÜNCELLEME
# ==========================================================

func _update_visuals() -> void:
	# Tren pozisyonu
	var train_x := lerpf(-TRAIN_W, VIEWPORT_W, _progress)
	_train_node.position.x = train_x

	# İlerleme barı
	var bar_width := (VIEWPORT_W - 80) * _progress
	_progress_bar.size.x = bar_width

	# Mesafe
	var gm: Node = _get_game_manager()
	if gm:
		var total_dist := gm.trip_planner.get_distance_to_next_stop()
		var current_km := total_dist * _progress
		_distance_label.text = "%.0f km / %.0f km" % [current_km, total_dist]
		var fuel_pct := gm.fuel_system.get_fuel_percentage()
		_fuel_label.text = "Yakit: %.0f%%" % fuel_pct
		if gm.fuel_system.is_fuel_empty():
			_warning_label.text = "Yakit azaliyor!"
			var conductor: Node = get_node_or_null("/root/ConductorManager")
			if conductor:
				conductor.show_runtime_tip("tip_fuel_empty", "Yakit azaliyor! Hizimiz dustu, ilk durakta ikmal yapalim!")
		elif gm.fuel_system.is_fuel_critical():
			_warning_label.text = "Kritik yakit!"
			var conductor2: Node = get_node_or_null("/root/ConductorManager")
			if conductor2:
				conductor2.show_runtime_tip("tip_fuel_low", "Yakitimiz azaliyor, bir sonraki durakta dolduralim!")
		else:
			_warning_label.text = ""


# ==========================================================
# INPUT
# ==========================================================

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if not _is_pressed(event):
		return

	var pos := _get_event_position(event)

	# Hız butonu
	var speed_btn: Control = get_node("SpeedButton")
	if _is_in_rect(pos, speed_btn.position, speed_btn.size):
		_toggle_speed()
		return

	# Varış butonu
	var arrive_btn: Control = get_node("ArriveButton")
	if arrive_btn.visible and _is_in_rect(pos, arrive_btn.position, arrive_btn.size):
		_on_arrive_pressed()
		return


func _toggle_speed() -> void:
	_travel_speed = 2.0 if _travel_speed == 1.0 else 1.0
	_speed_label.text = "Hiz: %dx" % int(_travel_speed)
	var speed_btn: Control = get_node("SpeedButton")
	var lbl: Label = speed_btn.get_child(1)
	lbl.text = "HIZ: %dx" % int(_travel_speed)


func _get_effective_speed() -> float:
	var gm: Node = _get_game_manager()
	if gm and gm.fuel_system.is_fuel_empty():
		return _travel_speed * 0.5
	return _travel_speed


func _on_arrive_pressed() -> void:
	var gm: Node = _get_game_manager()
	if not gm:
		return

	if _from_label.text == "Sefer Tamamlandi!":
		gm.trip_planner.end_trip()
		get_tree().change_scene_to_file("res://src/scenes/summary/summary_scene.tscn")
	else:
		# Durağa gir (son durak dahil)
		get_tree().change_scene_to_file("res://src/scenes/station/station_scene.tscn")


# ==========================================================
# YARDIMCILAR
# ==========================================================

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
