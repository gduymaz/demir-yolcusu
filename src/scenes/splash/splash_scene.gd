## Module: splash_scene.gd
## Lightweight startup splash before entering the main menu.

extends Node2D

const VIEWPORT_W := 540
const VIEWPORT_H := 960
const SPLASH_SECONDS := 2.0

var _elapsed: float = 0.0
var _train: ColorRect
var _did_transition: bool = false

func _ready() -> void:
	_build_scene()

func _process(delta: float) -> void:
	if _did_transition:
		return
	_elapsed += delta
	var t: float = fmod(_elapsed, SPLASH_SECONDS) / SPLASH_SECONDS
	_train.position.x = -80.0 + (VIEWPORT_W + 160.0) * t
	if _elapsed >= SPLASH_SECONDS:
		_did_transition = true
		SceneTransition.transition_to("res://src/scenes/main_menu/main_menu.tscn")

func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = Color("#2c3e50")
	add_child(bg)

	var logo := Label.new()
	logo.text = I18n.t("menu.title")
	logo.position = Vector2(20, 400)
	logo.size = Vector2(VIEWPORT_W - 40, 64)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 42)
	logo.add_theme_color_override("font_color", Color("#e74c3c"))
	add_child(logo)

	_train = ColorRect.new()
	_train.position = Vector2(-80, 500)
	_train.size = Vector2(72, 26)
	_train.color = Color("#c0392b")
	add_child(_train)
