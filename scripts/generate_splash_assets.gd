extends SceneTree

const OUT_SPLASH_DIR := "res://assets/sprites/splash"
const OUT_UI_DIR := "res://assets/sprites/ui"

const SPLASH_BG_PATH := "res://assets/sprites/splash/splash_bg_generated.png"
const SPLASH_TRAIN_PATH := "res://assets/sprites/splash/splash_train_generated.png"
const SPLASH_LOGO_FRAME_PATH := "res://assets/sprites/splash/splash_logo_frame_generated.png"

const MENU_BG_PATH := "res://assets/sprites/ui/menu_bg_generated.png"
const MENU_TRAIN_PATH := "res://assets/sprites/ui/menu_train_generated.png"
const MENU_LOGO_FRAME_PATH := "res://assets/sprites/ui/menu_logo_frame_generated.png"

const HUD_BG_PATH := "res://assets/sprites/ui/hud_bar_bg_generated.png"
const HUD_COIN_PATH := "res://assets/sprites/ui/hud_coin_icon_generated.png"
const HUD_STAR_PATH := "res://assets/sprites/ui/hud_star_icon_generated.png"
const HUD_PAUSE_PATH := "res://assets/sprites/ui/hud_pause_icon_generated.png"

const SKY_TOP := Color8(132, 149, 173)
const SKY_BOTTOM := Color8(95, 113, 141)
const TERRAIN := Color8(156, 162, 117)
const TERRAIN_DARK := Color8(124, 131, 92)
const PLAZA := Color8(86, 96, 118)
const PLAZA_DARK := Color8(65, 74, 95)
const RETAINING_WALL := Color8(73, 66, 72)
const RETAINING_WALL_DARK := Color8(54, 49, 55)
const RAIL_METAL := Color8(49, 56, 75)
const RAIL_WOOD := Color8(98, 74, 52)
const GLASS := Color8(103, 151, 182, 206)
const BUILDING := Color8(111, 118, 134)
const BUILDING_DARK := Color8(82, 90, 109)
const ROOF := Color8(198, 146, 118)
const TRAIN_LIGHT := Color8(225, 222, 218)
const TRAIN_ACCENT := Color8(210, 122, 88)
const TRAIN_WINDOW := Color8(83, 102, 144)
const TRAIN_SHADOW := Color8(26, 30, 41, 120)

const FRAME_DARK := Color8(29, 35, 54, 240)
const FRAME_LIGHT := Color8(219, 190, 121, 255)
const FRAME_ACCENT := Color8(204, 86, 61, 255)

func _init() -> void:
	_ensure_output_dirs()
	_generate_splash_assets()
	_generate_menu_assets()
	_generate_hud_assets()
	print("Generated splash/menu/hud assets")
	quit(0)

func _ensure_output_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_SPLASH_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_UI_DIR))

func _generate_splash_assets() -> void:
	var bg := _build_station_backdrop(false)
	bg.save_png(ProjectSettings.globalize_path(SPLASH_BG_PATH))
	_build_train_sprite(240, 104).save_png(ProjectSettings.globalize_path(SPLASH_TRAIN_PATH))
	_build_logo_frame(460, 124).save_png(ProjectSettings.globalize_path(SPLASH_LOGO_FRAME_PATH))

func _generate_menu_assets() -> void:
	var bg := _build_station_backdrop(true)
	bg.save_png(ProjectSettings.globalize_path(MENU_BG_PATH))
	_build_train_sprite(340, 120).save_png(ProjectSettings.globalize_path(MENU_TRAIN_PATH))
	_build_logo_frame(500, 132).save_png(ProjectSettings.globalize_path(MENU_LOGO_FRAME_PATH))

func _generate_hud_assets() -> void:
	_build_hud_bar(540, 74).save_png(ProjectSettings.globalize_path(HUD_BG_PATH))
	_build_coin_icon(16, 16).save_png(ProjectSettings.globalize_path(HUD_COIN_PATH))
	_build_star_icon(16, 16).save_png(ProjectSettings.globalize_path(HUD_STAR_PATH))
	_build_pause_icon(16, 16).save_png(ProjectSettings.globalize_path(HUD_PAUSE_PATH))

func _build_station_backdrop(darker: bool) -> Image:
	var w := 540
	var h := 960
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	_draw_vertical_gradient(img, Rect2i(0, 0, w, 340), SKY_TOP, SKY_BOTTOM)
	_draw_rect(img, Rect2i(0, 340, w, h - 340), TERRAIN)
	_apply_dither(img, Rect2i(0, 340, w, h - 340), TERRAIN_DARK, 7, 4, 3)

	# Ground breaks at both sides for the canyon-like frame.
	_draw_rect(img, Rect2i(0, 116, 42, 650), Color8(38, 75, 114))
	_draw_rect(img, Rect2i(w - 38, 120, 38, 638), Color8(38, 75, 114))
	_draw_rect(img, Rect2i(42, 132, w - 80, 352), Color8(44, 86, 37))

	# Upper plaza and station shell.
	_draw_rect(img, Rect2i(0, 104, w, 286), PLAZA)
	_draw_rect(img, Rect2i(0, 390, w, 54), PLAZA_DARK)
	_draw_rect(img, Rect2i(72, 116, 396, 138), BUILDING)
	_draw_rect(img, Rect2i(90, 136, 360, 84), BUILDING_DARK)
	_draw_roof(img, Rect2i(112, 84, 316, 64), ROOF)

	# Building supports and details.
	for x in [152, 384]:
		_draw_rect(img, Rect2i(x, 140, 16, 86), Color8(97, 104, 121))
	for x in [100, 180, 260, 340, 420]:
		_draw_rect(img, Rect2i(x, 230, 26, 12), Color8(80, 62, 46))
	for x in [95, 432]:
		_draw_rect(img, Rect2i(x, 170, 10, 56), Color8(172, 176, 184))
		_draw_rect(img, Rect2i(x + 2, 174, 6, 44), Color8(214, 102, 94))

	# Upper platform rail lane.
	_draw_track_lane(img, 414)

	# Retaining wall and middle deck.
	_draw_retaining_wall(img, Rect2i(0, 444, w, 86))
	_draw_rect(img, Rect2i(0, 530, w, 142), Color8(69, 78, 103))
	_draw_rect(img, Rect2i(78, 548, 384, 102), Color8(82, 94, 118))
	_draw_rect(img, Rect2i(92, 560, 356, 78), GLASS)
	for x in range(94, 444, 12):
		_draw_rect(img, Rect2i(x, 560, 1, 78), Color8(132, 174, 198, 140))
	for y in range(566, 634, 8):
		_draw_rect(img, Rect2i(92, y, 356, 1), Color8(148, 198, 220, 165))
	for x in [118, 214, 312, 406]:
		_draw_rect(img, Rect2i(x, 640, 8, 32), Color8(124, 112, 96))

	# Middle and lower rail lanes.
	_draw_track_lane(img, 700)
	_draw_track_lane(img, 824)

	# Lower retaining wall and depth shading.
	_draw_retaining_wall(img, Rect2i(0, 730, w, 90))
	_draw_retaining_wall(img, Rect2i(0, 854, w, 74))

	# Stair paths connecting levels.
	for i in range(9):
		_draw_rect(img, Rect2i(258, 386 + i * 14, 24, 9), Color8(105, 140, 184))
		_draw_rect(img, Rect2i(258, 676 + i * 14, 24, 9), Color8(105, 140, 184))

	# Signals and poles.
	for x in [12, 134, 266, 398, 520]:
		_draw_rect(img, Rect2i(x, 374, 6, 56), Color8(132, 140, 161))
		_draw_rect(img, Rect2i(x + 1, 362, 4, 12), Color8(88, 95, 118))
	for x in [72, 154, 386, 468]:
		_draw_rect(img, Rect2i(x, 644, 6, 64), Color8(132, 140, 161))

	# Scenic clutter.
	_draw_rect(img, Rect2i(160, 584, 38, 24), Color8(116, 126, 146))
	_draw_rect(img, Rect2i(206, 578, 44, 30), Color8(76, 108, 70))
	_draw_rect(img, Rect2i(210, 582, 6, 22), Color8(44, 80, 44))
	_draw_rect(img, Rect2i(118, 220, 16, 12), Color8(94, 86, 72))
	_draw_rect(img, Rect2i(336, 222, 16, 12), Color8(94, 86, 72))

	# Trains in three lanes.
	_draw_train_car(img, Vector2i(352, 356), 150, 46)
	_draw_train_car(img, Vector2i(318, 648), 170, 48)
	_draw_train_car(img, Vector2i(30, 772), 164, 48)

	if darker:
		# Menu version slightly darker so buttons pop.
		for y in range(h):
			for x in range(w):
				var c := img.get_pixel(x, y)
				img.set_pixel(x, y, c.darkened(0.2))

	return img

func _draw_track_lane(img: Image, y: int) -> void:
	_draw_rect(img, Rect2i(0, y, img.get_width(), 6), RAIL_METAL)
	_draw_rect(img, Rect2i(0, y + 18, img.get_width(), 6), RAIL_METAL)
	for x in range(0, img.get_width(), 14):
		_draw_rect(img, Rect2i(x, y + 7, 8, 10), RAIL_WOOD)

func _build_train_sprite(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var scale := 1 if w < 300 else 2

	# Compact metro body + head.
	_draw_rect(img, Rect2i(16 * scale, 40 * scale, 92 * scale, 34 * scale), TRAIN_LIGHT)
	_draw_rect(img, Rect2i(16 * scale, 66 * scale, 92 * scale, 8 * scale), TRAIN_ACCENT)
	_draw_rect(img, Rect2i(110 * scale, 34 * scale, 104 * scale, 42 * scale), TRAIN_LIGHT)
	_draw_rect(img, Rect2i(114 * scale, 38 * scale, 96 * scale, 34 * scale), TRAIN_LIGHT.lightened(0.04))
	_draw_rect(img, Rect2i(166 * scale, 22 * scale, 24 * scale, 14 * scale), TRAIN_LIGHT)
	_draw_rect(img, Rect2i(206 * scale, 52 * scale, 6 * scale, 10 * scale), TRAIN_ACCENT)

	for i in range(3):
		_draw_rect(img, Rect2i((24 + i * 24) * scale, 48 * scale, 14 * scale, 18 * scale), TRAIN_WINDOW)
	for i in range(3):
		_draw_rect(img, Rect2i((124 + i * 20) * scale, 45 * scale, 14 * scale, 14 * scale), TRAIN_WINDOW)

	_draw_rect(img, Rect2i(206 * scale, 50 * scale, 6 * scale, 6 * scale), Color8(244, 203, 74))
	_draw_rect(img, Rect2i(210 * scale, 48 * scale, 4 * scale, 10 * scale), RAIL_METAL)
	_draw_rect(img, Rect2i(104 * scale, 68 * scale, 8 * scale, 4 * scale), Color8(90, 94, 108))

	for x in [28, 58, 88, 132, 168, 198]:
		_draw_rect(img, Rect2i(x * scale, 76 * scale, 12 * scale, 12 * scale), RAIL_METAL)
		_draw_rect(img, Rect2i((x + 3) * scale, 79 * scale, 6 * scale, 6 * scale), Color8(96, 118, 146))

	return img

func _draw_train_car(img: Image, pos: Vector2i, w: int, h: int) -> void:
	_draw_rect(img, Rect2i(pos.x + 4, pos.y + h, w - 8, 4), TRAIN_SHADOW)
	_draw_rect(img, Rect2i(pos.x, pos.y, w, h), TRAIN_LIGHT)
	_draw_rect(img, Rect2i(pos.x + 2, pos.y + 2, w - 4, h - 4), TRAIN_LIGHT.lightened(0.08))
	_draw_rect(img, Rect2i(pos.x, pos.y + h - 6, w, 6), TRAIN_ACCENT)
	for i in range(4):
		_draw_rect(img, Rect2i(pos.x + 16 + i * 28, pos.y + 10, 20, 16), TRAIN_WINDOW)
	_draw_rect(img, Rect2i(pos.x + w - 18, pos.y + 9, 10, h - 18), Color8(122, 150, 86))

func _draw_vertical_gradient(img: Image, area: Rect2i, top_color: Color, bottom_color: Color) -> void:
	for y in range(area.position.y, area.position.y + area.size.y):
		var t := float(y - area.position.y) / float(max(1, area.size.y - 1))
		var c := top_color.lerp(bottom_color, t)
		for x in range(area.position.x, area.position.x + area.size.x):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				img.set_pixel(x, y, c)

func _apply_dither(img: Image, area: Rect2i, color: Color, modulo: int, x_stride: int, y_stride: int) -> void:
	for y in range(area.position.y, area.position.y + area.size.y):
		for x in range(area.position.x, area.position.x + area.size.x):
			if ((x / x_stride) + (y / y_stride)) % modulo == 0:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

func _draw_roof(img: Image, area: Rect2i, color: Color) -> void:
	for i in range(area.size.y):
		var inset := int(i * 1.65)
		var y := area.position.y + i
		var x := area.position.x + inset
		var width := area.size.x - inset * 2
		if width > 0:
			_draw_rect(img, Rect2i(x, y, width, 1), color)
	for i in range(area.size.y):
		var y := area.position.y + i
		if i % 4 == 0:
			_draw_rect(img, Rect2i(area.position.x + 44, y, 2, 1), color.darkened(0.15))
			_draw_rect(img, Rect2i(area.position.x + area.size.x - 46, y, 2, 1), color.darkened(0.15))

func _draw_retaining_wall(img: Image, area: Rect2i) -> void:
	_draw_rect(img, area, RETAINING_WALL)
	for y in range(area.position.y, area.position.y + area.size.y):
		for x in range(area.position.x, area.position.x + area.size.x):
			if ((x / 8) + (y / 6)) % 5 == 0:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, RETAINING_WALL_DARK)
	for y in range(area.position.y + 6, area.position.y + area.size.y, 12):
		_draw_rect(img, Rect2i(area.position.x, y, area.size.x, 1), RETAINING_WALL_DARK)

func _build_logo_frame(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_rect(img, Rect2i(0, 0, w, h), FRAME_DARK)
	_draw_rect(img, Rect2i(4, 4, w - 8, h - 8), FRAME_DARK.lightened(0.15))
	for x in range(6, w - 6):
		img.set_pixel(x, 8, FRAME_LIGHT)
		img.set_pixel(x, h - 9, FRAME_LIGHT)
	for y in range(8, h - 8):
		img.set_pixel(8, y, FRAME_LIGHT)
		img.set_pixel(w - 9, y, FRAME_LIGHT)
	_draw_rect(img, Rect2i(12, 12, 22, 6), FRAME_ACCENT)
	_draw_rect(img, Rect2i(w - 34, 12, 22, 6), FRAME_ACCENT)
	_draw_rect(img, Rect2i(12, h - 18, 22, 6), FRAME_ACCENT)
	_draw_rect(img, Rect2i(w - 34, h - 18, 22, 6), FRAME_ACCENT)
	return img

func _build_hud_bar(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color8(18, 24, 40, 214))
	for y in range(h):
		for x in range(w):
			if ((x / 6) + (y / 4)) % 9 == 0:
				img.set_pixel(x, y, Color8(32, 44, 66, 220))
	for x in range(w):
		img.set_pixel(x, 0, FRAME_LIGHT)
		img.set_pixel(x, h - 1, Color8(66, 76, 96))
	return img

func _build_coin_icon(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_rect(img, Rect2i(2, 2, 12, 12), Color8(236, 193, 60))
	_draw_rect(img, Rect2i(4, 4, 8, 8), Color8(248, 219, 97))
	_draw_rect(img, Rect2i(6, 6, 4, 4), Color8(232, 170, 46))
	return img

func _build_star_icon(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Color8(160, 171, 196)
	for p in [Vector2i(8, 1), Vector2i(6, 5), Vector2i(2, 6), Vector2i(5, 9), Vector2i(4, 14), Vector2i(8, 11), Vector2i(12, 14), Vector2i(11, 9), Vector2i(14, 6), Vector2i(10, 5)]:
		_draw_rect(img, Rect2i(p.x, p.y, 2, 2), c)
	return img

func _build_pause_icon(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_rect(img, Rect2i(4, 3, 3, 10), FRAME_LIGHT)
	_draw_rect(img, Rect2i(9, 3, 3, 10), FRAME_LIGHT)
	_draw_rect(img, Rect2i(3, 2, 10, 1), FRAME_ACCENT)
	return img

func _draw_rect(img: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		if y < 0 or y >= img.get_height():
			continue
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x < 0 or x >= img.get_width():
				continue
			img.set_pixel(x, y, color)
