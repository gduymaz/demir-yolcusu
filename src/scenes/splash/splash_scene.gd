## Module: splash_scene.gd
## Tile-based startup splash before entering the main menu.

extends Node2D

const VIEWPORT_W := 540
const VIEWPORT_H := 960
const TILE_SIZE := 32
const SPLASH_SECONDS := 2.0
const TRAIN_TRAVEL_MARGIN := 320.0

const STATION_SHEET_PATH := "res://assets/tilemaps/station.png"
const TRAIN_SHEET_PATH := "res://assets/tilemaps/train-exterior.png"

var _elapsed: float = 0.0
var _train_root: Node2D
var _smoke_nodes: Array[ColorRect] = []
var _did_transition: bool = false

var _sheet_cache: Dictionary = {}
var _atlas_cache: Dictionary = {}

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
		_transition_to_main_menu()

func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = Color("#2c3e50")
	bg.z_index = -20
	add_child(bg)

	var tile_background := Node2D.new()
	tile_background.name = "StationTileBackground"
	tile_background.z_index = -10
	add_child(tile_background)
	_build_station_background(tile_background)

	var station_platform := Node2D.new()
	station_platform.name = "StationPlatform"
	station_platform.z_index = -3
	add_child(station_platform)
	_build_station_platform(station_platform)

	var rail_layer := Node2D.new()
	rail_layer.name = "RailLayer"
	rail_layer.z_index = 1
	add_child(rail_layer)
	_build_rails(rail_layer)

	_train_root = Node2D.new()
	_train_root.name = "TrainRoot"
	_train_root.z_index = 3
	_train_root.position = Vector2(-TRAIN_TRAVEL_MARGIN, 672)
	add_child(_train_root)
	_build_train(_train_root)

	_build_title_overlay()

func _build_title_overlay() -> void:
	var title_backdrop := ColorRect.new()
	title_backdrop.position = Vector2(0, 78)
	title_backdrop.size = Vector2(VIEWPORT_W, 130)
	title_backdrop.color = Color(0.05, 0.08, 0.14, 0.38)
	add_child(title_backdrop)

	var logo := Label.new()
	logo.text = _tr("menu.title")
	logo.position = Vector2(20, 106)
	logo.size = Vector2(VIEWPORT_W - 40, 70)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 44)
	logo.add_theme_color_override("font_color", Color("#f4d03f"))
	add_child(logo)

	var subtitle := Label.new()
	subtitle.text = _tr("menu.version")
	subtitle.position = Vector2(20, 162)
	subtitle.size = Vector2(VIEWPORT_W - 40, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#ecf0f1"))
	add_child(subtitle)

func _build_station_background(parent: Node2D) -> void:
	var cols := int(ceil(float(VIEWPORT_W) / float(TILE_SIZE))) + 1

	# Base composition: central paved station, grassy sides/top/bottom.
	for row in range(0, 28):
		for col in range(cols):
			var is_side := col <= 1 or col >= cols - 2
			var is_border_row := row <= 1 or row >= 24
			if is_side or is_border_row:
				_add_tile(parent, STATION_SHEET_PATH, 10, 3 + ((col + row) % 5), col, row)
			else:
				var paved_cols := [2, 3, 4, 6, 5, 7]
				_add_tile(parent, STATION_SHEET_PATH, 5, paved_cols[(col + row) % paved_cols.size()], col, row)

	# Upper station pavement strip.
	for row in range(2, 9):
		for col in range(1, cols - 1):
			var upper_cols := [2, 3, 4, 5, 6, 7]
			_add_tile(parent, STATION_SHEET_PATH, 5 + int(row % 2), upper_cols[(col + row) % upper_cols.size()], col, row)

	# Top station building.
	var building_x := 5
	for i in range(8):
		_add_tile(parent, STATION_SHEET_PATH, 0, 24 + i, building_x + i, 1)
		_add_tile(parent, STATION_SHEET_PATH, 1, 24 + i, building_x + i, 2)
	for i in range(6):
		_add_tile(parent, STATION_SHEET_PATH, 2, 25 + i, building_x + 1 + i, 3)
	for i in range(6):
		_add_tile(parent, STATION_SHEET_PATH, 3, 25 + i, building_x + 1 + i, 4)

	# Walk bridge / lower canopy.
	for col in range(2, cols - 2):
		_add_tile(parent, STATION_SHEET_PATH, 5, 16 + (col % 7), col, 14)
		_add_tile(parent, STATION_SHEET_PATH, 6, 16 + (col % 7), col, 15)

	# Mid concourse pavement.
	for row in range(16, 21):
		for col in range(1, cols - 1):
			var concourse_cols := [2, 3, 4, 6, 7, 5]
			_add_tile(parent, STATION_SHEET_PATH, 5 + int(row % 2), concourse_cols[(col + 2) % concourse_cols.size()], col, row)

	# Side vegetation accents.
	for row in [3, 6, 18, 22]:
		_add_tile(parent, STATION_SHEET_PATH, 4, 20 + (row % 4), 1, row)
		_add_tile(parent, STATION_SHEET_PATH, 4, 20 + ((row + 1) % 4), cols - 2, row)

func _build_station_platform(parent: Node2D) -> void:
	var cols := int(ceil(float(VIEWPORT_W) / float(TILE_SIZE))) + 1

	# Upper platform band.
	for col in range(cols):
		_add_tile(parent, STATION_SHEET_PATH, 8, col % 4, col, 9)
		_add_tile(parent, STATION_SHEET_PATH, 9, 17 + (col % 6), col, 10)

	# Lower main platform.
	for col in range(cols):
		_add_tile(parent, STATION_SHEET_PATH, 8, (col + 1) % 4, col, 19)
		_add_tile(parent, STATION_SHEET_PATH, 10, 16 + (col % 5), col, 20)

	# Furniture accents.
	for col in [3, 8, 13]:
		_add_tile(parent, STATION_SHEET_PATH, 1, 23, col, 8)
	for col in [4, 9, 13]:
		_add_tile(parent, STATION_SHEET_PATH, 1, 23, col, 18)
	for col in [5, 11]:
		_add_tile(parent, STATION_SHEET_PATH, 3, 21, col, 8)
	for col in [4, 10, 14]:
		_add_tile(parent, STATION_SHEET_PATH, 3, 26, col, 18)
	for col in [6, 12]:
		_add_tile(parent, STATION_SHEET_PATH, 4, 17 + (col % 2), col, 18)
	_add_tile(parent, STATION_SHEET_PATH, 7, 10, 6, 8)
	_add_tile(parent, STATION_SHEET_PATH, 8, 13, 9, 8)
	_add_tile(parent, STATION_SHEET_PATH, 8, 16, 10, 8)
	_add_tile(parent, STATION_SHEET_PATH, 8, 14, 8, 18)
	_add_tile(parent, STATION_SHEET_PATH, 8, 15, 9, 18)

	# Pole stacks (for train occlusion).
	for pole_x in [2, 8, 14]:
		_add_tile(parent, STATION_SHEET_PATH, 7, 15, pole_x, 17)
		_add_tile(parent, STATION_SHEET_PATH, 5, 15, pole_x, 16)
		_add_tile(parent, STATION_SHEET_PATH, 3, 15, pole_x, 15)
		_add_tile(parent, STATION_SHEET_PATH, 2, 15, pole_x, 14)

	# Narrow crossing visual around center.
	for y in [10, 13, 20]:
		_add_tile(parent, STATION_SHEET_PATH, 8, 2, 8, y)

func _build_rails(parent: Node2D) -> void:
	var cols := int(ceil(float(VIEWPORT_W) / float(TILE_SIZE))) + 1

	# Upper rail lane.
	for col in range(cols):
		_add_tile(parent, STATION_SHEET_PATH, 11, 13, col, 11)
		_add_tile(parent, STATION_SHEET_PATH, 11, 13, col, 12)

	# Lower rail lane.
	for col in range(cols):
		_add_tile(parent, STATION_SHEET_PATH, 11, 13, col, 21)
		_add_tile(parent, STATION_SHEET_PATH, 11, 13, col, 22)

	# Static edge wagons on lower lane.
	for start_x in [1, cols - 4]:
		for i in range(3):
			_add_tile(parent, STATION_SHEET_PATH, 6, 30 + i, start_x + i, 20)
			_add_tile(parent, STATION_SHEET_PATH, 7, 30 + i, start_x + i, 21)

	# Center crossing details over rails.
	for y in [11, 12, 21, 22]:
		_add_tile(parent, STATION_SHEET_PATH, 11, 14, 8, y)

func _build_train(parent: Node2D) -> void:
	# Train body uses 3 aligned rows from train-exterior sheet.
	var upper := [24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34]
	var middle := [24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34]
	var lower := [24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34]

	for i in range(upper.size()):
		_add_tile(parent, TRAIN_SHEET_PATH, 0, upper[i], i, 0)
		_add_tile(parent, TRAIN_SHEET_PATH, 1, middle[i], i, 1)
		_add_tile(parent, TRAIN_SHEET_PATH, 2, lower[i], i, 2)

	for i in range(3):
		var smoke := ColorRect.new()
		smoke.color = Color(0.9, 0.9, 0.9, 0.5)
		smoke.size = Vector2(6 + i * 2, 6 + i * 2)
		smoke.position = Vector2(208, -8 - i * 10)
		parent.add_child(smoke)
		_smoke_nodes.append(smoke)

func _add_tile(parent: Node2D, sheet_path: String, row: int, col: int, grid_x: int, grid_y: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _atlas_texture(sheet_path, row, col)
	sprite.centered = false
	sprite.position = Vector2(grid_x * TILE_SIZE, grid_y * TILE_SIZE)
	parent.add_child(sprite)

func _atlas_texture(sheet_path: String, row: int, col: int) -> AtlasTexture:
	var key := "%s:%d:%d" % [sheet_path, row, col]
	if _atlas_cache.has(key):
		return _atlas_cache[key]

	var sheet := _sheet_texture(sheet_path)
	if sheet == null:
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	_atlas_cache[key] = atlas
	return atlas

func _sheet_texture(sheet_path: String) -> Texture2D:
	if _sheet_cache.has(sheet_path):
		return _sheet_cache[sheet_path]
	if not FileAccess.file_exists(sheet_path):
		return null
	var image := Image.new()
	if image.load(sheet_path) != OK:
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	_make_black_pixels_transparent(image)
	var texture := ImageTexture.create_from_image(image)
	_sheet_cache[sheet_path] = texture
	return texture

func _make_black_pixels_transparent(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var px := image.get_pixel(x, y)
			if px.r <= 0.03 and px.g <= 0.03 and px.b <= 0.03:
				image.set_pixel(x, y, Color(px.r, px.g, px.b, 0.0))

func _update_smoke(delta: float) -> void:
	for i in range(_smoke_nodes.size()):
		var smoke: ColorRect = _smoke_nodes[i]
		smoke.position.y -= delta * (16.0 + i * 5.0)
		smoke.modulate.a = maxf(0.0, smoke.modulate.a - delta * 0.35)
		if smoke.position.y < -52.0:
			smoke.position.y = -18.0 - i * 6.0
			smoke.modulate.a = 0.5

func _transition_to_main_menu() -> void:
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("transition_to"):
		transition.transition_to("res://src/scenes/main_menu/main_menu.tscn")
		return
	get_tree().change_scene_to_file("res://src/scenes/main_menu/main_menu.tscn")

func _tr(key: String) -> String:
	var i18n := get_node_or_null("/root/I18n")
	if i18n != null and i18n.has_method("t"):
		return i18n.t(key)
	return key
