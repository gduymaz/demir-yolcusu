## Module: station_ui_builder.gd
## Builds StationScene UI nodes and returns key references.

extends RefCounted

static func build(scene: Node) -> Dictionary:
	_build_background(scene)
	var hud := _build_hud(scene)
	var train := _build_train(scene)
	var refuel := _build_refuel_controls(scene)
	var cargo := _build_cargo_panel(scene)
	var event_banner := _build_event_banner(scene)
	var summary := _build_summary_panel(scene)
	return {
		"hud_timer": hud.get("timer"),
		"hud_station": hud.get("station"),
		"event_icon_label": hud.get("event_icon"),
		"wagon_nodes": train.get("wagon_nodes", []),
		"fuel_button": refuel.get("button"),
		"fuel_progress_bg": refuel.get("progress_bg"),
		"fuel_progress_fill": refuel.get("progress_fill"),
		"cargo_panel": cargo.get("panel"),
		"cargo_list": cargo.get("list"),
		"cargo_note_label": cargo.get("note_label"),
		"cargo_info_label": cargo.get("info_label"),
		"event_banner": event_banner,
		"summary_panel": summary.get("panel"),
		"summary_label": summary.get("label"),
	}

static func _build_background(scene: Node) -> void:
	var sky_top := ColorRect.new()
	sky_top.color = Color("#9dd5ff")
	sky_top.size = Vector2(scene.VIEWPORT_W, scene.VIEWPORT_H * 0.45)
	sky_top.z_index = -11
	scene.add_child(sky_top)

	var sky_bottom := ColorRect.new()
	sky_bottom.color = Color("#dbeeff")
	sky_bottom.position = Vector2(0, scene.VIEWPORT_H * 0.45)
	sky_bottom.size = Vector2(scene.VIEWPORT_W, scene.VIEWPORT_H * 0.2)
	sky_bottom.z_index = -11
	scene.add_child(sky_bottom)

	var tree_line := ColorRect.new()
	tree_line.color = Color("#4d8c3a")
	tree_line.position = Vector2(0, scene.TRAIN_Y + 20)
	tree_line.size = Vector2(scene.VIEWPORT_W, 12)
	tree_line.z_index = -9
	scene.add_child(tree_line)

	var platform := ColorRect.new()
	platform.color = scene.COLOR_PLATFORM
	platform.position = Vector2(0, scene.TRAIN_Y + 60)
	platform.size = Vector2(scene.VIEWPORT_W, 200)
	platform.z_index = -5
	scene.add_child(platform)

	var platform_edge := ColorRect.new()
	platform_edge.color = Color("#f7e7b5")
	platform_edge.position = Vector2(0, scene.TRAIN_Y + 56)
	platform_edge.size = Vector2(scene.VIEWPORT_W, 4)
	platform_edge.z_index = -4
	scene.add_child(platform_edge)

	for i in 2:
		var rail := ColorRect.new()
		rail.color = scene.COLOR_RAIL
		rail.position = Vector2(0, scene.TRAIN_Y + 50 + i * 20)
		rail.size = Vector2(scene.VIEWPORT_W, 4)
		rail.z_index = -4
		scene.add_child(rail)

	var wait_line := ColorRect.new()
	wait_line.color = Color(1, 1, 1, 0.3)
	wait_line.position = Vector2(20, scene.WAITING_Y - 40)
	wait_line.size = Vector2(scene.VIEWPORT_W - 40, 2)
	wait_line.z_index = -3
	scene.add_child(wait_line)

	var wait_label := Label.new()
	wait_label.text = I18n.t("station.waiting_area")
	wait_label.position = Vector2(scene.VIEWPORT_W / 2.0 - 80, scene.WAITING_Y - 60)
	wait_label.add_theme_font_size_override("font_size", 14)
	wait_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	scene.add_child(wait_label)

static func _build_hud(scene: Node) -> Dictionary:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	scene.add_child(canvas)

	var hud_timer := Label.new()
	hud_timer.position = Vector2(scene.VIEWPORT_W - 150, 82)
	hud_timer.add_theme_font_size_override("font_size", 20)
	hud_timer.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(hud_timer)

	var hud_station := Label.new()
	hud_station.position = Vector2(scene.VIEWPORT_W - 200, 108)
	hud_station.size = Vector2(180, 20)
	hud_station.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_station.add_theme_font_size_override("font_size", 12)
	hud_station.add_theme_color_override("font_color", Color("#aaaaaa"))
	canvas.add_child(hud_station)

	var event_icon_label := Label.new()
	event_icon_label.position = Vector2(scene.VIEWPORT_W - 52, 128)
	event_icon_label.size = Vector2(32, 20)
	event_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_icon_label.add_theme_font_size_override("font_size", 16)
	event_icon_label.visible = false
	canvas.add_child(event_icon_label)

	return {
		"timer": hud_timer,
		"station": hud_station,
		"event_icon": event_icon_label,
	}

static func _build_refuel_controls(scene: Node) -> Dictionary:
	var fuel_button := Button.new()
	fuel_button.position = Vector2(scene.VIEWPORT_W - 180, 92)
	fuel_button.size = Vector2(160, 32)
	fuel_button.text = I18n.t("station.button.refuel")
	scene.add_child(fuel_button)

	var fuel_progress_bg := ColorRect.new()
	fuel_progress_bg.position = Vector2(scene.VIEWPORT_W - 180, 128)
	fuel_progress_bg.size = Vector2(160, 8)
	fuel_progress_bg.color = Color("#2c3e50")
	scene.add_child(fuel_progress_bg)

	var fuel_progress_fill := ColorRect.new()
	fuel_progress_fill.position = Vector2(scene.VIEWPORT_W - 180, 128)
	fuel_progress_fill.size = Vector2(0, 8)
	fuel_progress_fill.color = Color("#27ae60")
	scene.add_child(fuel_progress_fill)

	return {
		"button": fuel_button,
		"progress_bg": fuel_progress_bg,
		"progress_fill": fuel_progress_fill,
	}

static func _build_cargo_panel(scene: Node) -> Dictionary:
	var cargo_panel := PanelContainer.new()
	cargo_panel.position = Vector2(20, 760)
	cargo_panel.size = Vector2(scene.VIEWPORT_W - 40, 180)
	scene.add_child(cargo_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.1, 0.2, 0.92)
	style.border_color = Color("#2c3e50")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	cargo_panel.add_theme_stylebox_override("panel", style)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cargo_panel.add_child(root)

	var title := Label.new()
	title.text = I18n.t("station.cargo.title")
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("#f1c40f"))
	root.add_child(title)

	var cargo_note_label := Label.new()
	cargo_note_label.add_theme_font_size_override("font_size", 12)
	cargo_note_label.add_theme_color_override("font_color", Color("#ecf0f1"))
	root.add_child(cargo_note_label)

	var cargo_list := VBoxContainer.new()
	root.add_child(cargo_list)

	var cargo_info_label := Label.new()
	cargo_info_label.add_theme_font_size_override("font_size", 11)
	cargo_info_label.add_theme_color_override("font_color", Color("#95a5a6"))
	root.add_child(cargo_info_label)

	return {
		"panel": cargo_panel,
		"list": cargo_list,
		"note_label": cargo_note_label,
		"info_label": cargo_info_label,
	}

static func _build_event_banner(scene: Node) -> Label:
	var event_banner := Label.new()
	event_banner.position = Vector2(20, 80)
	event_banner.size = Vector2(scene.VIEWPORT_W - 40, 24)
	event_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	event_banner.add_theme_font_size_override("font_size", 14)
	event_banner.add_theme_color_override("font_color", Color.BLACK)
	event_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	event_banner.modulate = scene.COLOR_EVENT
	event_banner.visible = false
	scene.add_child(event_banner)
	return event_banner

static func _build_train(scene: Node) -> Dictionary:
	var wagon_nodes: Array = []
	var wagon_count := scene._wagons.size()
	var total_train_w := wagon_count * scene.WAGON_SPACING + scene.LOCO_SIZE.x + 20
	var start_x := maxf(20.0, (scene.VIEWPORT_W - total_train_w) / 2.0)

	for i in wagon_count:
		var wagon: WagonData = scene._wagons[i]
		var wagon_node := ColorRect.new()
		wagon_node.size = scene.WAGON_SIZE
		wagon_node.color = scene._get_wagon_color(wagon.type)
		wagon_node.position = Vector2(start_x + i * scene.WAGON_SPACING, scene.TRAIN_Y - scene.WAGON_SIZE.y / 2)
		scene.add_child(wagon_node)
		wagon_nodes.append(wagon_node)

		if wagon.type == Constants.WagonType.CARGO:
			for x in [12.0, 34.0, 56.0, 78.0]:
				var slash_a := ColorRect.new()
				slash_a.position = Vector2(x, 10)
				slash_a.size = Vector2(2, 50)
				slash_a.rotation = deg_to_rad(38.0)
				slash_a.color = Color("#d7ccc8")
				wagon_node.add_child(slash_a)
		else:
			for w in range(3):
				var window := ColorRect.new()
				window.position = Vector2(8 + w * 30, 8)
				window.size = Vector2(20, 18)
				window.color = Color(1, 1, 1, 0.42)
				wagon_node.add_child(window)

		var label := Label.new()
		label.name = "WagonLabel"
		label.text = "%s\n0/%d" % [scene._get_wagon_short_name(wagon.type), wagon.get_capacity()]
		label.position = Vector2(8, 12)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		wagon_node.add_child(label)

	for i in range(wagon_count - 1):
		var conn := ColorRect.new()
		conn.color = scene.COLOR_RAIL
		var x1 := start_x + i * scene.WAGON_SPACING + scene.WAGON_SIZE.x
		conn.position = Vector2(x1, scene.TRAIN_Y - 2)
		conn.size = Vector2(scene.WAGON_SPACING - scene.WAGON_SIZE.x, 4)
		scene.add_child(conn)

	var loco_x := start_x + wagon_count * scene.WAGON_SPACING
	var loco := ColorRect.new()
	loco.size = scene.LOCO_SIZE
	loco.color = scene.COLOR_LOCO
	loco.position = Vector2(loco_x, scene.TRAIN_Y - scene.LOCO_SIZE.y / 2)
	scene.add_child(loco)

	var chimney := Polygon2D.new()
	chimney.polygon = PackedVector2Array([Vector2(64, 0), Vector2(88, 0), Vector2(80, -16)])
	chimney.color = Color("#2c3e50")
	loco.add_child(chimney)

	for wheel_x in [12.0, 38.0, 64.0]:
		var wheel := ColorRect.new()
		wheel.position = Vector2(wheel_x, scene.LOCO_SIZE.y - 8)
		wheel.size = Vector2(14, 14)
		wheel.color = Color("#34495e")
		loco.add_child(wheel)

	var headlight := ColorRect.new()
	headlight.position = Vector2(scene.LOCO_SIZE.x - 12, 14)
	headlight.size = Vector2(8, 8)
	headlight.color = Color("#f1c40f")
	loco.add_child(headlight)

	if wagon_count > 0:
		var last_end := start_x + (wagon_count - 1) * scene.WAGON_SPACING + scene.WAGON_SIZE.x
		var loco_conn := ColorRect.new()
		loco_conn.color = scene.COLOR_RAIL
		loco_conn.position = Vector2(last_end, scene.TRAIN_Y - 2)
		loco_conn.size = Vector2(loco_x - last_end, 4)
		scene.add_child(loco_conn)

	var gm: Node = scene.get_node_or_null("/root/GameManager")
	var loco_name: String = I18n.t("locomotive.kara_duman").replace(" ", "\n")
	if gm:
		loco_name = gm.train_config.get_locomotive().loco_name
		var parts: PackedStringArray = loco_name.split(" ")
		if parts.size() > 1:
			loco_name = parts[0] + "\n" + parts[1]
	var loco_label := Label.new()
	loco_label.text = loco_name
	loco_label.position = Vector2(10, 15)
	loco_label.add_theme_font_size_override("font_size", 13)
	loco_label.add_theme_color_override("font_color", Color.WHITE)
	loco.add_child(loco_label)

	return {"wagon_nodes": wagon_nodes}

static func _build_summary_panel(scene: Node) -> Dictionary:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	scene.add_child(canvas)

	var summary_panel := PanelContainer.new()
	summary_panel.position = Vector2(40, 200)
	summary_panel.size = Vector2(scene.VIEWPORT_W - 80, 450)
	summary_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = scene.COLOR_HUD_BG
	style.border_color = Color("#C0392B")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	summary_panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(summary_panel)

	var vbox := VBoxContainer.new()
	summary_panel.add_child(vbox)

	var title := Label.new()
	title.text = I18n.t("station.title.summary")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#F1C40F"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var summary_label := Label.new()
	summary_label.add_theme_font_size_override("font_size", 16)
	summary_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(summary_label)
	vbox.add_child(Control.new())

	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm and gm.trip_planner.is_trip_active():
		if not gm.trip_planner.is_at_final_stop():
			var continue_btn := Button.new()
			continue_btn.text = I18n.t("station.button.continue")
			continue_btn.add_theme_font_size_override("font_size", 18)
			continue_btn.pressed.connect(scene._on_continue_pressed)
			vbox.add_child(continue_btn)
		else:
			var finish_btn := Button.new()
			finish_btn.text = I18n.t("station.button.finish_trip")
			finish_btn.add_theme_font_size_override("font_size", 18)
			finish_btn.pressed.connect(scene._on_finish_trip_pressed)
			vbox.add_child(finish_btn)
	else:
		var restart_btn := Button.new()
		restart_btn.text = I18n.t("station.button.restart")
		restart_btn.add_theme_font_size_override("font_size", 18)
		restart_btn.pressed.connect(scene._on_restart_pressed)
		vbox.add_child(restart_btn)

		var garage_btn := Button.new()
		garage_btn.text = I18n.t("station.button.back_garage")
		garage_btn.add_theme_font_size_override("font_size", 18)
		garage_btn.pressed.connect(scene._on_garage_pressed)
		vbox.add_child(garage_btn)

	return {
		"panel": summary_panel,
		"label": summary_label,
	}
