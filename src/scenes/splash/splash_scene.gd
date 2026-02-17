## Module: splash_scene.gd
## Lightweight startup splash before entering the main menu.

extends Node2D

const VIEWPORT_W := 540
const VIEWPORT_H := 960
const SPLASH_SECONDS := 2.0
const PixelTextureLoader := preload("res://src/utils/pixel_texture_loader.gd")
const STATION_REFERENCE_BG_TEXTURE_PATH := "res://assets/references/GuttyKreum_Train_Stationv8/TrainstationExampleStill.png"
const TRAIN_REFERENCE_SHEET_TEXTURE_PATH := "res://assets/references/Guttykreum_Train_Exterior_v1/Tilemap/MainTileMap.png"
const SPLASH_BG_TEXTURE_PATH := "res://assets/sprites/splash/splash_bg_generated.png"
const SPLASH_LOGO_FRAME_TEXTURE_PATH := "res://assets/sprites/splash/splash_logo_frame_generated.png"
const TRAIN_REGION := Rect2(0, 108, 560, 86)
const TRAIN_TRAVEL_MARGIN := 320.0

var _elapsed: float = 0.0
var _train_root: Node2D
var _smoke_nodes: Array[ColorRect] = []
var _did_transition: bool = false

func _ready() -> void:
	_build_scene()

func _process(delta: float) -> void:
	if _did_transition:
		return
	_elapsed += delta
	var t: float = fmod(_elapsed, SPLASH_SECONDS) / SPLASH_SECONDS
	_train_root.position.x = -TRAIN_TRAVEL_MARGIN + (VIEWPORT_W + (TRAIN_TRAVEL_MARGIN * 2.0)) * t
	_update_smoke(delta)
	if _elapsed >= SPLASH_SECONDS:
		_did_transition = true
		SceneTransition.transition_to("res://src/scenes/main_menu/main_menu.tscn")

func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = Color("#2c3e50")
	add_child(bg)

	var bg_tex: Texture2D = PixelTextureLoader.load_texture(STATION_REFERENCE_BG_TEXTURE_PATH)
	if bg_tex == null:
		bg_tex = PixelTextureLoader.load_texture(SPLASH_BG_TEXTURE_PATH)
	if bg_tex != null:
		var bg_image := TextureRect.new()
		bg_image.texture = bg_tex
		bg_image.size = Vector2(VIEWPORT_W, VIEWPORT_H)
		bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_image.modulate = Color(1, 1, 1, 0.96)
		add_child(bg_image)

	var title_backdrop := ColorRect.new()
	title_backdrop.position = Vector2(0, 70)
	title_backdrop.size = Vector2(VIEWPORT_W, 170)
	title_backdrop.color = Color(0.05, 0.08, 0.14, 0.52)
	add_child(title_backdrop)

	var logo := Label.new()
	logo.text = I18n.t("menu.title")
	logo.position = Vector2(20, 108)
	logo.size = Vector2(VIEWPORT_W - 40, 70)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 48)
	logo.add_theme_color_override("font_color", Color("#f4d03f"))

	var logo_frame_tex: Texture2D = PixelTextureLoader.load_texture(SPLASH_LOGO_FRAME_TEXTURE_PATH)
	if logo_frame_tex != null:
		var logo_frame := TextureRect.new()
		logo_frame.texture = logo_frame_tex
		logo_frame.position = Vector2(42, 86)
		logo_frame.size = Vector2(VIEWPORT_W - 84, 132)
		logo_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_frame.modulate = Color(1, 1, 1, 0.92)
		add_child(logo_frame)

	add_child(logo)

	var subtitle := Label.new()
	subtitle.text = I18n.t("menu.version")
	subtitle.position = Vector2(20, 178)
	subtitle.size = Vector2(VIEWPORT_W - 40, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#ecf0f1"))
	add_child(subtitle)

	var station_platform := Node2D.new()
	station_platform.name = "StationPlatform"
	add_child(station_platform)

	var station_base := ColorRect.new()
	station_base.position = Vector2(0, 640)
	station_base.size = Vector2(VIEWPORT_W, 42)
	station_base.color = Color("#596275")
	station_platform.add_child(station_base)

	var station_edge := ColorRect.new()
	station_edge.position = Vector2(0, 678)
	station_edge.size = Vector2(VIEWPORT_W, 6)
	station_edge.color = Color("#f4d03f")
	station_platform.add_child(station_edge)

	var rail := ColorRect.new()
	rail.position = Vector2(0, 714)
	rail.size = Vector2(VIEWPORT_W, 6)
	rail.color = Color("#2c3e50")
	add_child(rail)

	_train_root = Node2D.new()
	_train_root.name = "TrainRoot"
	_train_root.position = Vector2(-TRAIN_TRAVEL_MARGIN, 626)
	add_child(_train_root)

	var train_tex: Texture2D = PixelTextureLoader.load_texture(TRAIN_REFERENCE_SHEET_TEXTURE_PATH)
	if train_tex != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = train_tex
		atlas.region = TRAIN_REGION
		var train := Sprite2D.new()
		train.texture = atlas
		train.position = Vector2(0, 0)
		train.scale = Vector2(0.9, 0.9)
		_train_root.add_child(train)

	for i in range(3):
		var smoke := ColorRect.new()
		smoke.color = Color(0.9, 0.9, 0.9, 0.5)
		smoke.size = Vector2(6 + i * 2, 6 + i * 2)
		smoke.position = Vector2(242, -8 - i * 10)
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
