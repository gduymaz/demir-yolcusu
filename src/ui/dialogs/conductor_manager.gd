## Module: conductor_manager.gd
## Restored English comments for maintainability and i18n coding standards.

extends CanvasLayer

const PixelTextureLoader := preload("res://src/utils/pixel_texture_loader.gd")
const VIEWPORT_W := 540
const VIEWPORT_H := 960
const CONDUCTOR_TEXTURE_PATH := "res://assets/sprites/characters/conductor_pixel.png"

var _mascot: Control
var _bubble: PanelContainer
var _bubble_label: Label
var _hide_timer: float = 0.0
var _pending_messages: Array[String] = []
var _last_scene_path: String = ""
var _quest_popup: Label
var _quest_popup_timer: float = 0.0
var _achievement_popup: Label
var _achievement_popup_timer: float = 0.0
var _tutorial_message_key: String = ""
var _tutorial_mode: bool = false
var _tutorial_continue_btn: Button
var _tutorial_skip_btn: Button
var _tutorial_highlight: ColorRect
var _highlight_phase: float = 0.0

## Lifecycle/helper logic for `_ready`.
func _ready() -> void:
	layer = 95
	_build_ui()
	_bind_event_bus()
	set_process(true)

## Lifecycle/helper logic for `_process`.
func _process(delta: float) -> void:
	if _hide_timer > 0.0:
		_hide_timer -= delta
		if _hide_timer <= 0.0:
			_bubble.visible = false
	if _quest_popup_timer > 0.0:
		_quest_popup_timer -= delta
		if _quest_popup_timer <= 0.0 and _quest_popup:
			_quest_popup.visible = false
	if _achievement_popup_timer > 0.0:
		_achievement_popup_timer -= delta
		if _achievement_popup_timer <= 0.0 and _achievement_popup:
			_achievement_popup.visible = false
	_update_tutorial_state(delta)
	_update_tutorial_highlight(delta)

	var scene := get_tree().current_scene
	if scene and scene.scene_file_path != _last_scene_path:
		_last_scene_path = scene.scene_file_path
		_on_scene_changed(scene.scene_file_path)

## Lifecycle/helper logic for `_input`.
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

## Lifecycle/helper logic for `_build_ui`.
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

	var conductor_texture: Texture2D = PixelTextureLoader.load_texture(CONDUCTOR_TEXTURE_PATH)
	if conductor_texture != null:
		var sprite := TextureRect.new()
		sprite.texture = conductor_texture
		sprite.position = Vector2(0, 10)
		sprite.size = Vector2(48, 64)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mascot.add_child(sprite)

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
	_bubble.size = Vector2(460, 140)
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
	_bubble_label.size = Vector2(436, 94)
	_bubble_label.add_theme_font_size_override("font_size", 15)
	_bubble_label.add_theme_color_override("font_color", Color.WHITE)
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.add_child(_bubble_label)

	_tutorial_continue_btn = Button.new()
	_tutorial_continue_btn.position = Vector2(352, 108)
	_tutorial_continue_btn.size = Vector2(94, 24)
	_tutorial_continue_btn.text = I18n.t("tutorial.button.continue")
	_tutorial_continue_btn.visible = false
	_tutorial_continue_btn.pressed.connect(func() -> void:
		_bubble.visible = false
	)
	_bubble.add_child(_tutorial_continue_btn)

	_tutorial_skip_btn = Button.new()
	_tutorial_skip_btn.position = Vector2(268, 108)
	_tutorial_skip_btn.size = Vector2(80, 24)
	_tutorial_skip_btn.text = I18n.t("tutorial.button.skip")
	_tutorial_skip_btn.visible = false
	_tutorial_skip_btn.pressed.connect(func() -> void:
		var gm_skip: Node = get_node_or_null("/root/GameManager")
		if gm_skip and gm_skip.tutorial_manager:
			gm_skip.tutorial_manager.skip_tutorial()
		_tutorial_mode = false
		_tutorial_message_key = ""
		_bubble.visible = false
		if _tutorial_highlight:
			_tutorial_highlight.visible = false
	)
	_bubble.add_child(_tutorial_skip_btn)

	_quest_popup = Label.new()
	_quest_popup.position = Vector2(24, 56)
	_quest_popup.size = Vector2(VIEWPORT_W - 48, 30)
	_quest_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_popup.add_theme_font_size_override("font_size", 16)
	_quest_popup.add_theme_color_override("font_color", Color("#f1c40f"))
	_quest_popup.visible = false
	add_child(_quest_popup)

	_achievement_popup = Label.new()
	_achievement_popup.position = Vector2(24, 26)
	_achievement_popup.size = Vector2(VIEWPORT_W - 48, 28)
	_achievement_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_achievement_popup.add_theme_font_size_override("font_size", 15)
	_achievement_popup.add_theme_color_override("font_color", Color("#f7dc6f"))
	_achievement_popup.visible = false
	add_child(_achievement_popup)

	_tutorial_highlight = ColorRect.new()
	_tutorial_highlight.color = Color(0, 0, 0, 0)
	_tutorial_highlight.visible = false
	_tutorial_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tutorial_highlight)

## Lifecycle/helper logic for `_bind_event_bus`.
func _bind_event_bus() -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus == null:
		return
	if bus.quest_completed and not bus.quest_completed.is_connected(_on_quest_completed):
		bus.quest_completed.connect(_on_quest_completed)
	if bus.achievement_unlocked and not bus.achievement_unlocked.is_connected(_on_achievement_unlocked):
		bus.achievement_unlocked.connect(_on_achievement_unlocked)

## Lifecycle/helper logic for `_on_scene_changed`.
func _on_scene_changed(scene_path: String) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.tutorial_manager and not gm.tutorial_manager.is_tutorial_complete():
		_tutorial_mode = true
		return
	if gm and gm.should_show_intro() and scene_path.contains("garage_scene"):
		_pending_messages = get_intro_messages()
		_show_next_pending()
		return

	_show_context_hint(false)

## Lifecycle/helper logic for `_show_next_pending`.
func _show_next_pending() -> void:
	if _pending_messages.is_empty():
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm and gm.should_show_intro():
			gm.mark_intro_completed()
		return
	_show_tip_text(_pending_messages.pop_front())

## Lifecycle/helper logic for `_show_context_hint`.
func _show_context_hint(force: bool) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	var scene := get_tree().current_scene
	if gm == null or scene == null:
		return
	if _tutorial_mode and gm.tutorial_manager and not gm.tutorial_manager.is_tutorial_complete():
		return

	var next_stop := I18n.t("conductor.next_stop_fallback")
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

## Handles `get_context_hint`.
func get_context_hint(scene_path: String, next_stop_name: String = "") -> Dictionary:
	if next_stop_name.is_empty():
		next_stop_name = I18n.t("conductor.next_stop_fallback")
	if scene_path.contains("garage_scene"):
		return {
			"key": "tip_garage",
			"text": I18n.t("conductor.tip.garage"),
		}
	if scene_path.contains("map_scene"):
		return {
			"key": "tip_map",
			"text": I18n.t("conductor.tip.map"),
		}
	if scene_path.contains("station_scene"):
		return {
			"key": "tip_station_first",
			"text": I18n.t("conductor.tip.station_first"),
		}
	if scene_path.contains("travel_scene"):
		return {
			"key": "tip_travel",
			"text": I18n.t("conductor.tip.travel", [next_stop_name]),
		}
	return {}

## Handles `get_intro_messages`.
func get_intro_messages() -> Array[String]:
	var messages: Array[String] = [
		I18n.t("conductor.intro.1"),
		I18n.t("conductor.intro.2"),
		I18n.t("conductor.intro.3"),
		I18n.t("conductor.intro.4"),
	]
	return messages

## Handles `show_runtime_tip`.
func show_runtime_tip(key: String, text: String) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	if gm.has_tip_been_shown(key):
		return
	gm.mark_tip_shown(key)
	_show_tip_text(text)

## Lifecycle/helper logic for `_on_quest_completed`.
func _on_quest_completed(quest_id: String) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.quest_system == null:
		return
	var quest: Dictionary = gm.quest_system.get_quest(quest_id)
	if quest.is_empty():
		return
	var rewards: Dictionary = quest.get("rewards", {})
	var reward_money: int = int(rewards.get("money", 0))
	var reward_rep: float = float(rewards.get("reputation", 0.0))
	_show_tip_text(I18n.t("conductor.tip.quest_completed", [I18n.t(str(quest.get("title_key", "")))]))
	if _quest_popup:
		_quest_popup.text = I18n.t("conductor.popup.quest_reward", [reward_money, reward_rep])
		_quest_popup.visible = true
		_quest_popup_timer = 3.0

func _on_achievement_unlocked(achievement_data: Dictionary) -> void:
	var title_key: String = str(achievement_data.get("title_key", ""))
	var reward: int = int(achievement_data.get("reward_money", 0))
	_show_tip_text(I18n.t("conductor.tip.achievement_unlocked", [I18n.t(title_key)]))
	if _achievement_popup:
		_achievement_popup.text = I18n.t("achievement.popup", [I18n.t(title_key), reward])
		_achievement_popup.visible = true
		_achievement_popup_timer = 3.0

## Lifecycle/helper logic for `_show_tip_text`.
func _show_tip_text(text: String) -> void:
	_bubble_label.text = text
	_bubble.visible = true
	_hide_timer = 0.0 if _tutorial_mode else 5.0

## Lifecycle/helper logic for `_get_pos`.
func _get_pos(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return event.position
	if event is InputEventMouseButton:
		return event.position
	return Vector2.ZERO

## Lifecycle/helper logic for `_is_pressed`.
func _is_pressed(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false

## Lifecycle/helper logic for `_in_rect`.
func _in_rect(pos: Vector2, rect_pos: Vector2, rect_size: Vector2) -> bool:
	return pos.x >= rect_pos.x and pos.x <= rect_pos.x + rect_size.x \
		and pos.y >= rect_pos.y and pos.y <= rect_pos.y + rect_size.y

func _update_tutorial_state(delta: float) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.tutorial_manager == null:
		_tutorial_mode = false
		_set_tutorial_controls_visible(false)
		return
	if gm.tutorial_manager.is_tutorial_complete():
		_tutorial_mode = false
		_tutorial_message_key = ""
		_set_tutorial_controls_visible(false)
		if _tutorial_highlight:
			_tutorial_highlight.visible = false
		return
	_tutorial_mode = true
	_set_tutorial_controls_visible(true)
	var message_key: String = gm.tutorial_manager.get_current_message_key()
	if message_key.is_empty():
		return
	if message_key != _tutorial_message_key:
		_tutorial_message_key = message_key
		_show_tip_text(I18n.t(message_key))
	var scene := get_tree().current_scene
	if scene == null:
		return
	var highlight_id: String = gm.tutorial_manager.get_current_highlight_id()
	var rect := _get_tutorial_highlight_rect(highlight_id, scene.scene_file_path)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_tutorial_highlight.visible = false
		return
	_tutorial_highlight.position = rect.position
	_tutorial_highlight.size = rect.size
	_tutorial_highlight.visible = true
	_highlight_phase += delta

func _set_tutorial_controls_visible(visible: bool) -> void:
	if _tutorial_continue_btn:
		_tutorial_continue_btn.visible = visible
	if _tutorial_skip_btn:
		_tutorial_skip_btn.visible = visible

func _update_tutorial_highlight(_delta: float) -> void:
	if _tutorial_highlight == null or not _tutorial_highlight.visible:
		return
	var pulse: float = 0.55 + 0.45 * (sin(_highlight_phase * 3.0) * 0.5 + 0.5)
	_tutorial_highlight.color = Color(1.0, 0.84, 0.0, 0.08 * pulse)

func _get_tutorial_highlight_rect(highlight_id: String, scene_path: String) -> Rect2:
	if highlight_id.is_empty():
		return Rect2()
	if scene_path.contains("garage_scene"):
		if highlight_id == "garage_wagon_pool":
			return Rect2(Vector2(10, 500), Vector2(520, 250))
	if scene_path.contains("map_scene"):
		if highlight_id == "map_select_stop":
			return Rect2(Vector2(25, 120), Vector2(490, 500))
	if scene_path.contains("station_scene"):
		if highlight_id == "station_passenger":
			return Rect2(Vector2(20, 610), Vector2(500, 110))
		if highlight_id == "station_timer":
			return Rect2(Vector2(380, 74), Vector2(150, 44))
	if scene_path.contains("travel_scene"):
		if highlight_id == "travel_speed_button":
			return Rect2(Vector2(180, 770), Vector2(180, 50))
	if scene_path.contains("summary_scene"):
		if highlight_id == "summary_net":
			return Rect2(Vector2(40, 610), Vector2(460, 34))
	return Rect2()
