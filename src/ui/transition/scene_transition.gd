## Module: scene_transition.gd
## Centralized fade-through-black scene changes with a small loading indicator.

extends CanvasLayer

const VIEWPORT_W := 540
const VIEWPORT_H := 960
const FADE_SECONDS := 0.3

var _overlay: ColorRect
var _loading_label: Label
var _spinner: ColorRect
var _spinner_angle: float = 0.0
var _is_transitioning: bool = false
var _pending_scene_path: String = ""
var _last_scene_path: String = ""

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _process(delta: float) -> void:
	if not _loading_label.visible:
		return
	_spinner_angle += delta * 4.0
	_spinner.rotation = _spinner_angle

func transition_to(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	if _is_transitioning:
		return
	_pending_scene_path = scene_path
	_transition_sequence.call_deferred()

func get_pending_scene_path() -> String:
	return _pending_scene_path

func is_transitioning() -> bool:
	return _is_transitioning

func get_last_scene_path() -> String:
	return _last_scene_path

func _build() -> void:
	_overlay = ColorRect.new()
	_overlay.position = Vector2.ZERO
	_overlay.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	_loading_label = Label.new()
	_loading_label.visible = false
	_loading_label.text = I18n.t("loading.text")
	_loading_label.position = Vector2(170, 458)
	_loading_label.size = Vector2(200, 24)
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_size_override("font_size", 18)
	_loading_label.add_theme_color_override("font_color", Color.WHITE)
	_loading_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_loading_label)

	_spinner = ColorRect.new()
	_spinner.visible = false
	_spinner.size = Vector2(20, 12)
	_spinner.position = Vector2(260, 490)
	_spinner.color = Color("#c0392b")
	_spinner.pivot_offset = _spinner.size * 0.5
	_spinner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_spinner)

func _transition_sequence() -> void:
	if _pending_scene_path.is_empty():
		return
	_is_transitioning = true
	_loading_label.visible = true
	_spinner.visible = true

	var fade_out: Tween = create_tween()
	fade_out.tween_property(_overlay, "color:a", 1.0, FADE_SECONDS)
	await fade_out.finished

	var current := get_tree().current_scene
	_last_scene_path = current.scene_file_path if current else ""
	get_tree().change_scene_to_file(_pending_scene_path)

	var fade_in: Tween = create_tween()
	fade_in.tween_property(_overlay, "color:a", 0.0, FADE_SECONDS)
	await fade_in.finished

	_loading_label.visible = false
	_spinner.visible = false
	_is_transitioning = false
