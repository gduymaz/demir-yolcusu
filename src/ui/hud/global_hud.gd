extends CanvasLayer

const VIEWPORT_W := 540
const BAR_H := 74

const COLOR_BG := Color(0.07, 0.08, 0.15, 0.86)
const COLOR_TEXT := Color("#ecf0f1")
const COLOR_GOLD := Color("#f1c40f")
const COLOR_FUEL_OK := Color("#27ae60")
const COLOR_FUEL_WARN := Color("#f39c12")
const COLOR_FUEL_CRIT := Color("#e74c3c")

var _bar: ColorRect
var _money: Label
var _reputation: Label
var _title: Label
var _fuel_bg: ColorRect
var _fuel_fill: ColorRect
var _fuel_text: Label


func _ready() -> void:
	layer = 90
	_build()
	set_process(true)


func _process(_delta: float) -> void:
	_refresh()


func _build() -> void:
	_bar = ColorRect.new()
	_bar.position = Vector2.ZERO
	_bar.size = Vector2(VIEWPORT_W, BAR_H)
	_bar.color = COLOR_BG
	add_child(_bar)

	# Sikke placeholder (sari daire)
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

	# Yildiz placeholder
	var star := ColorRect.new()
	star.position = Vector2(10, 41)
	star.size = Vector2(14, 14)
	star.color = Color("#95a5a6")
	_bar.add_child(star)

	_reputation = Label.new()
	_reputation.position = Vector2(28, 36)
	_reputation.size = Vector2(170, 22)
	_reputation.add_theme_font_size_override("font_size", 14)
	_reputation.add_theme_color_override("font_color", COLOR_TEXT)
	_bar.add_child(_reputation)

	_title = Label.new()
	_title.position = Vector2(180, 8)
	_title.size = Vector2(180, 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 16)
	_title.add_theme_color_override("font_color", COLOR_TEXT)
	_bar.add_child(_title)

	_fuel_bg = ColorRect.new()
	_fuel_bg.position = Vector2(365, 16)
	_fuel_bg.size = Vector2(158, 18)
	_fuel_bg.color = Color("#2c3e50")
	_bar.add_child(_fuel_bg)

	_fuel_fill = ColorRect.new()
	_fuel_fill.position = Vector2(365, 16)
	_fuel_fill.size = Vector2(158, 18)
	_fuel_fill.color = COLOR_FUEL_OK
	_bar.add_child(_fuel_fill)

	_fuel_text = Label.new()
	_fuel_text.position = Vector2(365, 38)
	_fuel_text.size = Vector2(158, 22)
	_fuel_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fuel_text.add_theme_font_size_override("font_size", 13)
	_fuel_text.add_theme_color_override("font_color", COLOR_TEXT)
	_bar.add_child(_fuel_text)


func _refresh() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		_money.text = "0 DA"
		_reputation.text = "0.0 yildiz"
		_fuel_fill.size.x = 0
		_fuel_text.text = "Yakit: -"
		_title.text = "DEMIR YOLCUSU"
		return

	_money.text = "%d DA" % gm.economy.get_balance()
	_reputation.text = "%.1f yildiz" % gm.reputation.get_stars()

	var fuel_pct: float = gm.fuel_system.get_fuel_percentage()
	var clamped := clampf(fuel_pct, 0.0, 100.0)
	_fuel_fill.size.x = 158.0 * (clamped / 100.0)
	_fuel_text.text = "Yakit: %.0f%%" % clamped

	if clamped < Balance.FUEL_CRITICAL_THRESHOLD:
		_fuel_fill.color = COLOR_FUEL_CRIT
	elif clamped < Balance.FUEL_LOW_THRESHOLD:
		_fuel_fill.color = COLOR_FUEL_WARN
	else:
		_fuel_fill.color = COLOR_FUEL_OK

	_title.text = _resolve_scene_title(gm)


func _resolve_scene_title(gm: Node) -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return "DEMIR YOLCUSU"

	var path: String = scene.scene_file_path
	if path.contains("garage_scene"):
		return "GARAJ"
	if path.contains("map_scene"):
		return "HARITA"
	if path.contains("travel_scene"):
		return "SEYIR"
	if path.contains("station_scene"):
		if gm.trip_planner != null and gm.trip_planner.is_trip_active():
			var stop: Dictionary = gm.trip_planner.get_current_stop()
			return stop.get("name", "DURAK")
		return "DURAK"
	if path.contains("summary_scene"):
		return "SEFER OZETI"
	return "DEMIR YOLCUSU"
