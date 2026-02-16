## Module: garage_ui_builder.gd
## Builds GarageScene UI structure and returns key node references.

extends RefCounted

static func build(scene: Node) -> Dictionary:
	_build_background(scene)
	var money_label := _build_header(scene)
	_build_utility_buttons(scene)
	_build_loco_panel(scene)
	var train_container := _build_train_area(scene)
	var info_label := _build_info_bar(scene)
	var wagon_pool_container := _build_wagon_pool(scene)
	_build_button_bar(scene)
	var shop_panel := _build_shop_panel(scene)
	var upgrade_data := _build_upgrade_panel(scene)
	return {
		"money_label": money_label,
		"train_container": train_container,
		"info_label": info_label,
		"wagon_pool_container": wagon_pool_container,
		"shop_panel": shop_panel,
		"upgrade_panel": upgrade_data.get("panel"),
		"upgrade_entries": upgrade_data.get("entries", []),
		"upgrade_respec_rect": upgrade_data.get("respec_rect", Rect2()),
	}

static func _build_background(scene: Node) -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(scene.VIEWPORT_W, scene.VIEWPORT_H)
	bg.color = scene.COLOR_BG
	scene.add_child(bg)

static func _build_header(scene: Node) -> Label:
	var header_bg := ColorRect.new()
	header_bg.position = Vector2.ZERO
	header_bg.size = Vector2(scene.VIEWPORT_W, scene.HEADER_H)
	header_bg.color = scene.COLOR_HEADER
	scene.add_child(header_bg)

	var title := Label.new()
	title.text = I18n.t("garage.title")
	title.position = Vector2(scene.MARGIN, 10)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", scene.COLOR_TEXT)
	scene.add_child(title)

	var money_label := Label.new()
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money_label.position = Vector2(scene.VIEWPORT_W - 160, 10)
	money_label.size = Vector2(140, 30)
	money_label.add_theme_font_size_override("font_size", 20)
	money_label.add_theme_color_override("font_color", scene.COLOR_GOLD)
	scene.add_child(money_label)
	return money_label

static func _build_utility_buttons(scene: Node) -> void:
	var achievements_btn := _create_button(
		I18n.t("garage.button.achievements"),
		Vector2(scene.VIEWPORT_W - 250, 52),
		Vector2(110, 34),
		Color("#9b59b6"),
		scene.COLOR_TEXT
	)
	achievements_btn.name = "AchievementsButton"
	scene.add_child(achievements_btn)

	var settings_btn := _create_button(
		I18n.t("garage.button.settings"),
		Vector2(scene.VIEWPORT_W - 130, 52),
		Vector2(110, 34),
		Color("#34495e"),
		scene.COLOR_TEXT
	)
	settings_btn.name = "SettingsButton"
	scene.add_child(settings_btn)

static func _build_loco_panel(scene: Node) -> void:
	var panel_bg := ColorRect.new()
	panel_bg.position = Vector2(0, scene.HEADER_H)
	panel_bg.size = Vector2(scene.VIEWPORT_W, scene.LOCO_PANEL_H)
	panel_bg.color = scene.COLOR_PANEL
	scene.add_child(panel_bg)

	var section_label := Label.new()
	section_label.text = I18n.t("garage.section.locomotive")
	section_label.position = Vector2(scene.MARGIN, scene.HEADER_H + 5)
	section_label.add_theme_font_size_override("font_size", 12)
	section_label.add_theme_color_override("font_color", Color("#888888"))
	scene.add_child(section_label)

	var container := Control.new()
	container.position = Vector2(scene.MARGIN, scene.HEADER_H + 25)
	container.size = Vector2(scene.VIEWPORT_W - scene.MARGIN * 2, 50)
	container.name = "LocoContainer"
	scene.add_child(container)

static func _build_train_area(scene: Node) -> Control:
	var area_bg := ColorRect.new()
	area_bg.position = Vector2(0, scene.TRAIN_AREA_Y)
	area_bg.size = Vector2(scene.VIEWPORT_W, scene.TRAIN_AREA_H)
	area_bg.color = Color("#111122")
	scene.add_child(area_bg)

	var rail := ColorRect.new()
	rail.position = Vector2(0, scene.TRAIN_AREA_Y + scene.TRAIN_AREA_H - 20)
	rail.size = Vector2(scene.VIEWPORT_W, 4)
	rail.color = Color("#444444")
	scene.add_child(rail)

	var train_container := Control.new()
	train_container.position = Vector2(0, scene.TRAIN_AREA_Y)
	train_container.size = Vector2(scene.VIEWPORT_W, scene.TRAIN_AREA_H)
	train_container.name = "TrainContainer"
	scene.add_child(train_container)
	return train_container

static func _build_info_bar(scene: Node) -> Label:
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(0, scene.INFO_BAR_Y)
	bar_bg.size = Vector2(scene.VIEWPORT_W, 40)
	bar_bg.color = scene.COLOR_HEADER
	scene.add_child(bar_bg)

	var info_label := Label.new()
	info_label.position = Vector2(scene.MARGIN, scene.INFO_BAR_Y + 8)
	info_label.size = Vector2(scene.VIEWPORT_W - scene.MARGIN * 2, 24)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", scene.COLOR_TEXT)
	scene.add_child(info_label)
	return info_label

static func _build_wagon_pool(scene: Node) -> Control:
	var pool_bg := ColorRect.new()
	pool_bg.position = Vector2(0, scene.WAGON_POOL_Y)
	pool_bg.size = Vector2(scene.VIEWPORT_W, scene.WAGON_POOL_H)
	pool_bg.color = scene.COLOR_PANEL.darkened(0.2)
	scene.add_child(pool_bg)

	var section_label := Label.new()
	section_label.text = I18n.t("garage.section.wagons")
	section_label.position = Vector2(scene.MARGIN, scene.WAGON_POOL_Y + 5)
	section_label.add_theme_font_size_override("font_size", 12)
	section_label.add_theme_color_override("font_color", Color("#888888"))
	scene.add_child(section_label)

	var wagon_pool_container := Control.new()
	wagon_pool_container.position = Vector2(scene.MARGIN, scene.WAGON_POOL_Y + 25)
	wagon_pool_container.size = Vector2(scene.VIEWPORT_W - scene.MARGIN * 2, scene.WAGON_POOL_H - 30)
	wagon_pool_container.name = "WagonPoolContainer"
	scene.add_child(wagon_pool_container)
	return wagon_pool_container

static func _build_button_bar(scene: Node) -> void:
	var shop_btn := _create_button(
		I18n.t("garage.button.shop"),
		Vector2(scene.MARGIN, scene.BUTTON_BAR_Y),
		Vector2(160, scene.BUTTON_H),
		scene.COLOR_BUTTON,
		scene.COLOR_TEXT
	)
	shop_btn.name = "ShopButton"
	scene.add_child(shop_btn)

	var upgrade_btn := _create_button(
		I18n.t("garage.button.upgrade"),
		Vector2(190, scene.BUTTON_BAR_Y),
		Vector2(160, scene.BUTTON_H),
		Color("#8e44ad"),
		scene.COLOR_TEXT
	)
	upgrade_btn.name = "UpgradeButton"
	scene.add_child(upgrade_btn)

	var go_btn := _create_button(
		I18n.t("garage.button.go_map"),
		Vector2(360, scene.BUTTON_BAR_Y),
		Vector2(160, scene.BUTTON_H),
		scene.COLOR_GREEN,
		scene.COLOR_TEXT
	)
	go_btn.name = "GoButton"
	scene.add_child(go_btn)

static func _build_shop_panel(scene: Node) -> Control:
	var shop_panel := Control.new()
	shop_panel.position = Vector2.ZERO
	shop_panel.size = Vector2(scene.VIEWPORT_W, scene.VIEWPORT_H)
	shop_panel.visible = false
	shop_panel.name = "ShopPanel"
	scene.add_child(shop_panel)

	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(scene.VIEWPORT_W, scene.VIEWPORT_H)
	overlay.color = Color(0, 0, 0, 0.7)
	shop_panel.add_child(overlay)

	var box := ColorRect.new()
	box.position = Vector2(40, 150)
	box.size = Vector2(460, 600)
	box.color = scene.COLOR_PANEL
	shop_panel.add_child(box)

	var title := Label.new()
	title.text = I18n.t("garage.shop.title")
	title.position = Vector2(180, 165)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", scene.COLOR_GOLD)
	shop_panel.add_child(title)

	var shop_items_container := Control.new()
	shop_items_container.position = Vector2(60, 210)
	shop_items_container.size = Vector2(420, 400)
	shop_items_container.name = "ShopItemsContainer"
	shop_panel.add_child(shop_items_container)

	var close_btn := _create_button(
		I18n.t("garage.shop.close"),
		Vector2(170, 650),
		Vector2(200, 50),
		scene.COLOR_RED,
		scene.COLOR_TEXT
	)
	close_btn.name = "ShopCloseButton"
	shop_panel.add_child(close_btn)
	return shop_panel

static func _build_upgrade_panel(scene: Node) -> Dictionary:
	var upgrade_panel := Control.new()
	upgrade_panel.position = Vector2.ZERO
	upgrade_panel.size = Vector2(scene.VIEWPORT_W, scene.VIEWPORT_H)
	upgrade_panel.visible = false
	upgrade_panel.name = "UpgradePanel"
	scene.add_child(upgrade_panel)

	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(scene.VIEWPORT_W, scene.VIEWPORT_H)
	overlay.color = Color(0, 0, 0, 0.7)
	upgrade_panel.add_child(overlay)

	var box := ColorRect.new()
	box.position = Vector2(35, 110)
	box.size = Vector2(470, 690)
	box.color = scene.COLOR_PANEL
	upgrade_panel.add_child(box)

	var title := Label.new()
	title.text = I18n.t("garage.upgrade.title")
	title.position = Vector2(145, 125)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", scene.COLOR_GOLD)
	upgrade_panel.add_child(title)

	var content := Control.new()
	content.position = Vector2(55, 170)
	content.size = Vector2(430, 560)
	content.name = "UpgradeContent"
	upgrade_panel.add_child(content)

	var close_btn := _create_button(
		I18n.t("garage.shop.close"),
		Vector2(170, 740),
		Vector2(200, 50),
		scene.COLOR_RED,
		scene.COLOR_TEXT
	)
	close_btn.name = "UpgradeCloseButton"
	upgrade_panel.add_child(close_btn)

	return {
		"panel": upgrade_panel,
		"entries": [],
		"respec_rect": Rect2(),
	}

static func _create_button(text: String, pos: Vector2, btn_size: Vector2, color: Color, font_color: Color) -> Control:
	var container := Control.new()
	container.position = pos
	container.size = btn_size

	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = btn_size
	bg.color = color
	container.add_child(bg)

	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(0, btn_size.y * 0.25)
	lbl.size = btn_size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", font_color)
	container.add_child(lbl)
	return container
