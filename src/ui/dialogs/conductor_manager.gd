extends CanvasLayer

const VIEWPORT_W := 540
const VIEWPORT_H := 960

var _mascot: Control
var _bubble: PanelContainer
var _bubble_label: Label
var _hide_timer: float = 0.0
var _pending_messages: Array[String] = []
var _last_scene_path: String = ""


func _ready() -> void:
	layer = 95
	_build_ui()
	set_process(true)


func _process(delta: float) -> void:
	if _hide_timer > 0.0:
		_hide_timer -= delta
		if _hide_timer <= 0.0:
			_bubble.visible = false

	var scene := get_tree().current_scene
	if scene and scene.scene_file_path != _last_scene_path:
		_last_scene_path = scene.scene_file_path
		_on_scene_changed(scene.scene_file_path)


func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if not _is_pressed(event):
		return

	var pos := _get_pos(event)
	if _in_rect(pos, _mascot.position, _mascot.size):
		if _pending_messages.is_empty():
			_show_context_hint(true)
		else:
			_show_next_pending()
		return

	if _bubble.visible and _in_rect(pos, _bubble.position, _bubble.size):
		_bubble.visible = false


func _build_ui() -> void:
	_mascot = Control.new()
	_mascot.position = Vector2(VIEWPORT_W - 78, VIEWPORT_H - 124)
	_mascot.size = Vector2(58, 86)
	add_child(_mascot)

	var body := ColorRect.new()
	body.position = Vector2(8, 18)
	body.size = Vector2(32, 48)
	body.color = Color("#d35400")
	_mascot.add_child(body)

	var hat := Polygon2D.new()
	hat.polygon = PackedVector2Array([Vector2(2, 20), Vector2(24, 2), Vector2(46, 20)])
	hat.color = Color("#2c3e50")
	_mascot.add_child(hat)

	var letter := Label.new()
	letter.text = "K"
	letter.position = Vector2(16, 30)
	letter.add_theme_font_size_override("font_size", 18)
	letter.add_theme_color_override("font_color", Color.WHITE)
	_mascot.add_child(letter)

	_bubble = PanelContainer.new()
	_bubble.position = Vector2(60, VIEWPORT_H - 210)
	_bubble.size = Vector2(460, 120)
	_bubble.visible = false
	add_child(_bubble)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.15, 0.94)
	style.border_color = Color("#f39c12")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	_bubble.add_theme_stylebox_override("panel", style)

	_bubble_label = Label.new()
	_bubble_label.position = Vector2(12, 12)
	_bubble_label.size = Vector2(436, 96)
	_bubble_label.add_theme_font_size_override("font_size", 15)
	_bubble_label.add_theme_color_override("font_color", Color.WHITE)
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.add_child(_bubble_label)


func _on_scene_changed(scene_path: String) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.should_show_intro() and scene_path.contains("garage_scene"):
		_pending_messages = [
			"Hos geldin Makinist! Deden sana eski bir lokomotif birakti.",
			"Bu 'Kara Duman' - komurlu, eski ama sadik bir lokomotif.",
			"Haydi, ilk seferine cikalim! Garajda trenini hazirla.",
		]
		_show_next_pending()
		return

	_show_context_hint(false)


func _show_next_pending() -> void:
	if _pending_messages.is_empty():
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm and gm.should_show_intro():
			gm.mark_intro_completed()
		return
	_show_tip_text(_pending_messages.pop_front())


func _show_context_hint(force: bool) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	var scene := get_tree().current_scene
	if gm == null or scene == null:
		return

	var next_stop := "sonraki durak"
	if gm.trip_planner:
		var n: Dictionary = gm.trip_planner.get_next_stop()
		next_stop = n.get("name", next_stop)
	var hint: Dictionary = get_context_hint(scene.scene_file_path, next_stop)
	var key: String = hint.get("key", "")
	var text: String = hint.get("text", "")
	if key.is_empty() or text.is_empty():
		return

	if not force and gm.has_tip_been_shown(key):
		return
	gm.mark_tip_shown(key)
	_show_tip_text(text)


func get_context_hint(scene_path: String, next_stop_name: String = "sonraki durak") -> Dictionary:
	if scene_path.contains("garage_scene"):
		return {
			"key": "tip_garage",
			"text": "Vagonlari surukleyerek trene ekle. Sefere hazir olunca butona bas!",
		}
	if scene_path.contains("map_scene"):
		return {
			"key": "tip_map",
			"text": "Baslangic ve bitis duragini sec. Yakit maliyetine dikkat et!",
		}
	if scene_path.contains("station_scene"):
		return {
			"key": "tip_station_first",
			"text": "Yolculari surukleyip dogru vagona birak. Mavi yolcular ekonomi vagona biner.",
		}
	if scene_path.contains("travel_scene"):
		return {
			"key": "tip_travel",
			"text": "Guzel manzara degil mi? Bir sonraki durak: %s" % next_stop_name,
		}
	return {}


func show_runtime_tip(key: String, text: String) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	if gm.has_tip_been_shown(key):
		return
	gm.mark_tip_shown(key)
	_show_tip_text(text)


func _show_tip_text(text: String) -> void:
	_bubble_label.text = text
	_bubble.visible = true
	_hide_timer = 5.0


func _get_pos(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return event.position
	if event is InputEventMouseButton:
		return event.position
	return Vector2.ZERO


func _is_pressed(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false


func _in_rect(pos: Vector2, rect_pos: Vector2, rect_size: Vector2) -> bool:
	return pos.x >= rect_pos.x and pos.x <= rect_pos.x + rect_size.x \
		and pos.y >= rect_pos.y and pos.y <= rect_pos.y + rect_size.y
