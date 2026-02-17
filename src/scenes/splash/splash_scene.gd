## Module: splash_scene.gd
## Lightweight startup splash before entering the main menu.

extends Node2D

const VIEWPORT_W := 540
const VIEWPORT_H := 960
const SPLASH_SECONDS := 2.0
const PixelTextureLoader := preload("res://src/utils/pixel_texture_loader.gd")
const SPLASH_BG_TEXTURE_PATH := "res://assets/sprites/splash/splash_bg_generated.png"
const SPLASH_TRAIN_TEXTURE_PATH := "res://assets/sprites/splash/splash_train_generated.png"
const SPLASH_LOGO_FRAME_TEXTURE_PATH := "res://assets/sprites/splash/splash_logo_frame_generated.png"

var _elapsed: float = 0.0
var _train_root: Control
var _smoke_nodes: Array[ColorRect] = []
var _did_transition: bool = false

func _ready() -> void:
	_build_scene()

func _process(delta: float) -> void:
	if _did_transition:
		return
	_elapsed += delta
	var t: float = fmod(_elapsed, SPLASH_SECONDS) / SPLASH_SECONDS
	_train_root.position.x = -220.0 + (VIEWPORT_W + 440.0) * t
	_update_smoke(delta)
	if _elapsed >= SPLASH_SECONDS:
		_did_transition = true
		SceneTransition.transition_to("res://src/scenes/main_menu/main_menu.tscn")

func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = Color("#2c3e50")
	add_child(bg)

	var bg_tex: Texture2D = PixelTextureLoader.load_texture(SPLASH_BG_TEXTURE_PATH)
	if bg_tex != null:
		var bg_image := TextureRect.new()
		bg_image.texture = bg_tex
		bg_image.size = Vector2(VIEWPORT_W, VIEWPORT_H)
		bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_image.modulate = Color(1, 1, 1, 0.45)
		add_child(bg_image)

	var logo := Label.new()
	logo.text = I18n.t("menu.title")
	logo.position = Vector2(20, 350)
	logo.size = Vector2(VIEWPORT_W - 40, 64)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 42)
	logo.add_theme_color_override("font_color", Color("#e74c3c"))

	var logo_frame_tex: Texture2D = PixelTextureLoader.load_texture(SPLASH_LOGO_FRAME_TEXTURE_PATH)
	if logo_frame_tex != null:
		var logo_frame := TextureRect.new()
		logo_frame.texture = logo_frame_tex
		logo_frame.position = Vector2(40, 322)
		logo_frame.size = Vector2(VIEWPORT_W - 80, 124)
		logo_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_frame.modulate = Color(1, 1, 1, 0.92)
		add_child(logo_frame)

	add_child(logo)

	var subtitle := Label.new()
	subtitle.text = I18n.t("menu.version")
	subtitle.position = Vector2(20, 410)
	subtitle.size = Vector2(VIEWPORT_W - 40, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#ecf0f1"))
	add_child(subtitle)

	var rail := ColorRect.new()
	rail.position = Vector2(0, 620)
	rail.size = Vector2(VIEWPORT_W, 6)
	rail.color = Color("#2c3e50")
	add_child(rail)

	_train_root = Control.new()
	_train_root.position = Vector2(-220, 548)
	_train_root.size = Vector2(220, 92)
	add_child(_train_root)

	var train_tex: Texture2D = PixelTextureLoader.load_texture(SPLASH_TRAIN_TEXTURE_PATH)
	if train_tex != null:
		var train := TextureRect.new()
		train.texture = train_tex
		train.position = Vector2(0, 0)
		train.size = Vector2(220, 92)
		train.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		train.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		train.modulate = Color(1, 1, 1, 0.98)
		_train_root.add_child(train)

	for i in range(3):
		var smoke := ColorRect.new()
		smoke.color = Color(0.9, 0.9, 0.9, 0.5)
		smoke.size = Vector2(6 + i * 2, 6 + i * 2)
		smoke.position = Vector2(182, 8 - i * 10)
		_train_root.add_child(smoke)
		_smoke_nodes.append(smoke)

func _update_smoke(delta: float) -> void:
	for i in range(_smoke_nodes.size()):
		var smoke: ColorRect = _smoke_nodes[i]
		smoke.position.y -= delta * (16.0 + i * 5.0)
		smoke.modulate.a = maxf(0.0, smoke.modulate.a - delta * 0.35)
		if smoke.position.y < -52.0:
			smoke.position.y = -18.0 - i * 6.0
			smoke.modulate.a = 0.5
