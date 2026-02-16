## Module: garage_view_manager.gd
## Handles GarageScene view refresh and upgrade panel rendering.

extends RefCounted

const PixelTextureLoader := preload("res://src/utils/pixel_texture_loader.gd")
const WAGON_TEXTURE_PATH := "res://assets/sprites/vehicles/wagon_pixel.png"
const LOCO_TEXTURE_PATH := "res://assets/sprites/vehicles/loco_pixel.png"

static func refresh_all(scene: Node) -> void:
	scene._refresh_money()
	refresh_loco_list(scene)
	refresh_train_view(scene)
	refresh_info_bar(scene)
	refresh_wagon_pool(scene)
	if scene._upgrade_visible:
		refresh_upgrade_panel(scene)

static func refresh_loco_list(scene: Node) -> void:
	var container: Control = scene.get_node("LocoContainer")
	for c in container.get_children():
		c.queue_free()
	scene._loco_buttons.clear()

	var gm: Node = scene._get_game_manager()
	var locos: Array = gm.inventory.get_locomotives()
	var selected: LocomotiveData = gm.train_config.get_locomotive()

	var x := 0.0
	for loco in locos:
		var l: LocomotiveData = loco
		var btn := ColorRect.new()
		btn.position = Vector2(x, 0)
		btn.size = Vector2(140, 45)
		btn.color = scene.COLOR_LOCO if l.id == selected.id else scene.COLOR_LOCO.darkened(0.3)
		container.add_child(btn)

		var lbl := Label.new()
		lbl.text = l.loco_name
		lbl.position = Vector2(5, 10)
		lbl.size = Vector2(130, 24)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", scene.COLOR_TEXT)
		btn.add_child(lbl)

		scene._loco_buttons.append(btn)
		x += 150.0

static func refresh_train_view(scene: Node) -> void:
	for c in scene._train_container.get_children():
		c.queue_free()
	scene._train_wagon_nodes.clear()

	var gm: Node = scene._get_game_manager()
	var config: TrainConfig = gm.train_config
	var wagons: Array = config.get_wagons()
	var loco: LocomotiveData = config.get_locomotive()

	var start_x := 20.0
	var y := 60.0

	var loco_node := ColorRect.new()
	loco_node.position = Vector2(start_x, y)
	loco_node.size = Vector2(scene.LOCO_SPRITE_W, scene.LOCO_SPRITE_H)
	loco_node.color = scene.COLOR_LOCO
	scene._train_container.add_child(loco_node)
	_apply_texture(loco_node, LOCO_TEXTURE_PATH)

	var chimney := Polygon2D.new()
	chimney.polygon = PackedVector2Array([Vector2(56, 0), Vector2(74, 0), Vector2(68, -10)])
	chimney.color = Color("#2c3e50")
	loco_node.add_child(chimney)

	var headlight := ColorRect.new()
	headlight.position = Vector2(scene.LOCO_SPRITE_W - 10, 16)
	headlight.size = Vector2(6, 6)
	headlight.color = Color("#f1c40f")
	loco_node.add_child(headlight)

	for wheel_x in [8.0, 30.0, 52.0]:
		var wheel := ColorRect.new()
		wheel.position = Vector2(wheel_x, scene.LOCO_SPRITE_H - 8)
		wheel.size = Vector2(10, 10)
		wheel.color = Color("#34495e")
		loco_node.add_child(wheel)

	var loco_label := Label.new()
	loco_label.text = loco.loco_name
	loco_label.position = Vector2(0, 15)
	loco_label.size = Vector2(scene.LOCO_SPRITE_W, 24)
	loco_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loco_label.add_theme_font_size_override("font_size", 12)
	loco_label.add_theme_color_override("font_color", scene.COLOR_TEXT)
	loco_node.add_child(loco_label)

	for i in range(wagons.size()):
		var wagon: WagonData = wagons[i]
		var wagon_node := ColorRect.new()
		wagon_node.position = Vector2(start_x + scene.LOCO_SPRITE_W + 10 + i * scene.WAGON_SPACING, y + 4)
		wagon_node.size = Vector2(scene.WAGON_SPRITE_W, scene.WAGON_SPRITE_H)
		wagon_node.color = scene._get_wagon_color(wagon.type)
		scene._train_container.add_child(wagon_node)
		scene._train_wagon_nodes.append(wagon_node)
		_apply_texture(wagon_node, WAGON_TEXTURE_PATH)

		if wagon.type == Constants.WagonType.CARGO:
			for x in [10.0, 28.0, 46.0]:
				var cross := ColorRect.new()
				cross.position = Vector2(x, 8)
				cross.size = Vector2(2, scene.WAGON_SPRITE_H - 16)
				cross.rotation = deg_to_rad(30.0)
				cross.color = Color("#d7ccc8")
				wagon_node.add_child(cross)
		else:
			for w in range(2):
				var window := ColorRect.new()
				window.position = Vector2(10 + w * 30, 8)
				window.size = Vector2(22, 14)
				window.color = Color(1.0, 1.0, 1.0, 0.4)
				wagon_node.add_child(window)

		for wheel_x in [10.0, 44.0]:
			var wagon_wheel := ColorRect.new()
			wagon_wheel.position = Vector2(wheel_x, scene.WAGON_SPRITE_H - 8)
			wagon_wheel.size = Vector2(10, 10)
			wagon_wheel.color = Color("#2c3e50")
			wagon_node.add_child(wagon_wheel)

		var label := Label.new()
		label.text = scene._get_wagon_short_name(wagon.type)
		label.position = Vector2(0, 14)
		label.size = Vector2(scene.WAGON_SPRITE_W, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", scene.COLOR_TEXT)
		wagon_node.add_child(label)

	for i in range(config.get_max_wagons()):
		if i < wagons.size():
			continue
		var slot := ColorRect.new()
		slot.position = Vector2(start_x + scene.LOCO_SPRITE_W + 10 + i * scene.WAGON_SPACING, y + 4)
		slot.size = Vector2(scene.WAGON_SPRITE_W, scene.WAGON_SPRITE_H)
		slot.color = Color("#333344")
		scene._train_container.add_child(slot)

		var slot_label := Label.new()
		slot_label.text = "+"
		slot_label.position = Vector2(slot.position.x, slot.position.y + 12)
		slot_label.size = Vector2(scene.WAGON_SPRITE_W, 24)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 20)
		slot_label.add_theme_color_override("font_color", Color("#666666"))
		scene._train_container.add_child(slot_label)

static func refresh_info_bar(scene: Node) -> void:
	var gm: Node = scene._get_game_manager()
	var cfg: TrainConfig = gm.train_config
	var fuel_name: String = scene._get_fuel_name(cfg.get_locomotive().fuel_type)
	scene._info_label.text = I18n.t(
		"garage.info.train",
		[
			cfg.get_wagon_count(),
			cfg.get_max_wagons(),
			cfg.get_total_passenger_capacity(),
			fuel_name,
		]
	)

static func refresh_wagon_pool(scene: Node) -> void:
	for c in scene._wagon_pool_container.get_children():
		c.queue_free()
	scene._pool_wagon_nodes.clear()

	var gm: Node = scene._get_game_manager()
	var available: Array = gm.inventory.get_available_wagons()
	var columns := 4
	for i in range(available.size()):
		var wagon: WagonData = available[i]
		var col: int = i % columns
		var row := int(i / columns)
		var x: float = float(col * (scene.POOL_WAGON_W + 8))
		var y: float = float(row * (scene.POOL_WAGON_H + 10))

		var card := ColorRect.new()
		card.position = Vector2(x, y)
		card.size = Vector2(scene.POOL_WAGON_W, scene.POOL_WAGON_H)
		card.color = scene._get_wagon_color(wagon.type)
		scene._wagon_pool_container.add_child(card)
		scene._pool_wagon_nodes.append(card)
		_apply_texture(card, WAGON_TEXTURE_PATH)

		if wagon.type == Constants.WagonType.CARGO:
			for line_x in [14.0, 36.0, 58.0, 80.0]:
				var slash := ColorRect.new()
				slash.position = Vector2(line_x, 8)
				slash.size = Vector2(2, 40)
				slash.rotation = deg_to_rad(34.0)
				slash.color = Color("#d7ccc8")
				card.add_child(slash)
		else:
			for w in range(3):
				var pwindow := ColorRect.new()
				pwindow.position = Vector2(8 + w * 28, 10)
				pwindow.size = Vector2(18, 12)
				pwindow.color = Color(1.0, 1.0, 1.0, 0.4)
				card.add_child(pwindow)

		var lbl := Label.new()
		lbl.text = scene._get_wagon_short_name(wagon.type)
		lbl.position = Vector2(0, 6)
		lbl.size = Vector2(scene.POOL_WAGON_W, 18)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", scene.COLOR_TEXT)
		card.add_child(lbl)

		var cap := Label.new()
		cap.text = "%d" % wagon.get_capacity()
		cap.position = Vector2(0, 28)
		cap.size = Vector2(scene.POOL_WAGON_W, 16)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.add_theme_font_size_override("font_size", 10)
		cap.add_theme_color_override("font_color", Color("#dddddd"))
		card.add_child(cap)

static func refresh_shop(scene: Node) -> void:
	scene._shop_entries.clear()
	var container: Control = scene._shop_panel.get_node("ShopItemsContainer")
	for child in container.get_children():
		child.queue_free()

	var gm: Node = scene._get_game_manager()
	var balance: int = gm.economy.get_balance()
	var wagon_types := [
		Constants.WagonType.ECONOMY,
		Constants.WagonType.BUSINESS,
		Constants.WagonType.VIP,
		Constants.WagonType.CARGO,
		Constants.WagonType.DINING,
	]
	for i in range(wagon_types.size()):
		var wtype: int = wagon_types[i]
		var item := Control.new()
		item.position = Vector2(0, i * 90)
		item.size = Vector2(400, 80)

		var tag := ColorRect.new()
		tag.position = Vector2(0, 5)
		tag.size = Vector2(60, 50)
		tag.color = scene._get_wagon_color(wtype)
		item.add_child(tag)

		var name_label := Label.new()
		name_label.text = scene._get_wagon_type_name(wtype)
		name_label.position = Vector2(75, 5)
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", scene.COLOR_TEXT)
		item.add_child(name_label)

		var price: int = gm.inventory.get_wagon_price(wtype)
		var required_rep: float = scene._wagon_required_reputation(wtype)
		var can_afford: bool = balance >= price and gm.reputation.meets_requirement(required_rep)

		var cap_label := Label.new()
		cap_label.text = I18n.t("garage.shop.capacity", [WagonData._get_capacity_for_type(wtype)])
		cap_label.position = Vector2(75, 28)
		cap_label.add_theme_font_size_override("font_size", 12)
		cap_label.add_theme_color_override("font_color", Color("#aaaaaa"))
		item.add_child(cap_label)

		if required_rep > 0.0:
			var req := Label.new()
			req.text = I18n.t("garage.shop.rep_required", [required_rep])
			req.position = Vector2(75, 48)
			req.add_theme_font_size_override("font_size", 10)
			req.add_theme_color_override("font_color", scene.COLOR_RED if not gm.reputation.meets_requirement(required_rep) else Color("#95a5a6"))
			item.add_child(req)

		var buy_btn: Control = scene._create_button("%d DA" % price, Vector2(280, 5), Vector2(110, 45), scene.COLOR_GREEN if can_afford else scene.COLOR_BUTTON_DISABLED)
		buy_btn.name = "BuyBtn_%d" % wtype
		item.add_child(buy_btn)

		container.add_child(item)
		scene._shop_entries.append({"kind": "wagon", "type": wtype, "rect": Rect2(container.position + Vector2(280, i * 90 + 5), Vector2(110, 45))})

	var loco_header := Label.new()
	loco_header.text = I18n.t("garage.shop.locomotives")
	loco_header.position = Vector2(0, wagon_types.size() * 90 + 10)
	loco_header.add_theme_font_size_override("font_size", 16)
	loco_header.add_theme_color_override("font_color", Color("#f1c40f"))
	container.add_child(loco_header)

	var loco_defs := [
		{"id": "demir_yurek", "price": Balance.LOCOMOTIVE_COST_DEMIR_YUREK, "rep": Balance.LOCOMOTIVE_REPUTATION_DEMIR_YUREK},
		{"id": "boz_kaplan", "price": Balance.LOCOMOTIVE_COST_BOZ_KAPLAN, "rep": Balance.LOCOMOTIVE_REPUTATION_BOZ_KAPLAN},
	]
	for j in range(loco_defs.size()):
		var def: Dictionary = loco_defs[j]
		var row_y := wagon_types.size() * 90 + 40 + j * 90
		var loco_item := Control.new()
		loco_item.position = Vector2(0, row_y)
		loco_item.size = Vector2(400, 80)

		var tag := ColorRect.new()
		tag.position = Vector2(0, 5)
		tag.size = Vector2(60, 50)
		tag.color = scene.COLOR_LOCO
		loco_item.add_child(tag)

		var loco_name := Label.new()
		loco_name.text = I18n.t("locomotive.%s" % str(def["id"]))
		loco_name.position = Vector2(75, 5)
		loco_name.add_theme_font_size_override("font_size", 16)
		loco_name.add_theme_color_override("font_color", scene.COLOR_TEXT)
		loco_item.add_child(loco_name)

		var loco_req := Label.new()
		loco_req.text = I18n.t("garage.shop.rep_required", [float(def["rep"])])
		loco_req.position = Vector2(75, 28)
		loco_req.add_theme_font_size_override("font_size", 11)
		loco_req.add_theme_color_override("font_color", scene.COLOR_RED if not gm.reputation.meets_requirement(float(def["rep"])) else Color("#95a5a6"))
		loco_item.add_child(loco_req)

		var owned: bool = gm.inventory.has_locomotive(str(def["id"]))
		var can_buy_loco: bool = (not owned) and balance >= int(def["price"]) and gm.reputation.meets_requirement(float(def["rep"]))
		var loco_buy: Control = scene._create_button(
			I18n.t("garage.shop.owned") if owned else "%d DA" % int(def["price"]),
			Vector2(280, 5),
			Vector2(110, 45),
			scene.COLOR_GREEN if can_buy_loco else scene.COLOR_BUTTON_DISABLED
		)
		loco_item.add_child(loco_buy)
		container.add_child(loco_item)
		scene._shop_entries.append({"kind": "locomotive", "id": str(def["id"]), "rep": float(def["rep"]), "rect": Rect2(container.position + Vector2(280, row_y + 5), Vector2(110, 45))})

static func refresh_upgrade_panel(scene: Node) -> void:
	var content: Control = scene._upgrade_panel.get_node("UpgradeContent")
	for child in content.get_children():
		child.queue_free()
	scene._upgrade_entries.clear()
	scene._upgrade_respec_rect = Rect2()

	var gm: Node = scene._get_game_manager()
	var target_kind: String = str(scene._selected_upgrade_target.get("kind", "locomotive"))
	var target_id: String = str(scene._selected_upgrade_target.get("id", gm.train_config.get_locomotive().id))
	if target_kind == "wagon" and find_wagon_by_id(scene, target_id) == null:
		scene._set_upgrade_target_locomotive(gm.train_config.get_locomotive().id)
		target_kind = "locomotive"
		target_id = gm.train_config.get_locomotive().id

	var target_title := Label.new()
	target_title.text = I18n.t("garage.upgrade.target", [get_upgrade_target_name(scene)])
	target_title.position = Vector2(0, 0)
	target_title.size = Vector2(420, 30)
	target_title.add_theme_font_size_override("font_size", 16)
	target_title.add_theme_color_override("font_color", scene.COLOR_TEXT)
	content.add_child(target_title)

	var info := Label.new()
	info.text = I18n.t("garage.upgrade.select_hint")
	info.position = Vector2(0, 28)
	info.size = Vector2(420, 24)
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color("#95a5a6"))
	content.add_child(info)

	var row_y: int = 70
	if target_kind == "locomotive":
		var types := [Constants.UpgradeType.SPEED, Constants.UpgradeType.CAPACITY, Constants.UpgradeType.FUEL_EFFICIENCY, Constants.UpgradeType.DURABILITY]
		for upgrade_type in types:
			var can_state: Dictionary = gm.upgrade_system.can_upgrade_locomotive(target_id, upgrade_type)
			var level: int = gm.upgrade_system.get_locomotive_level(target_id, upgrade_type)
			var next_level: int = int(can_state.get("next_level", level))
			var cost: int = int(can_state.get("cost", 0))
			var row := create_upgrade_row(scene, I18n.t(loco_upgrade_name_key(upgrade_type)), level, next_level, cost, loco_upgrade_effect_text(upgrade_type), bool(can_state.get("ok", false)))
			row.position = Vector2(0, row_y)
			content.add_child(row)
			scene._upgrade_entries.append({"kind": "locomotive", "id": target_id, "upgrade_type": upgrade_type, "rect": Rect2(content.position + Vector2(300, row_y + 8), Vector2(110, 36))})
			if not bool(can_state.get("ok", false)):
				var reason_label := Label.new()
				reason_label.text = I18n.t(upgrade_reason_key(str(can_state.get("reason", ""))))
				reason_label.position = Vector2(0, row_y + 58)
				reason_label.size = Vector2(420, 18)
				reason_label.add_theme_font_size_override("font_size", 10)
				reason_label.add_theme_color_override("font_color", scene.COLOR_RED)
				content.add_child(reason_label)
			row_y += 88
	else:
		var wagon_data: Variant = find_wagon_by_id(scene, target_id)
		var wagon_type: int = Constants.WagonType.ECONOMY
		if wagon_data != null:
			wagon_type = int((wagon_data as WagonData).type)
		var wtypes := [Constants.WagonUpgradeType.COMFORT, Constants.WagonUpgradeType.CAPACITY, Constants.WagonUpgradeType.MAINTENANCE]
		for upgrade_type in wtypes:
			var can_state: Dictionary = gm.upgrade_system.can_upgrade_wagon(target_id, upgrade_type)
			var level: int = gm.upgrade_system.get_wagon_level(target_id, upgrade_type)
			var next_level: int = int(can_state.get("next_level", level))
			var cost: int = int(can_state.get("cost", 0))
			var row := create_upgrade_row(scene, I18n.t(wagon_upgrade_name_key(upgrade_type)), level, next_level, cost, wagon_upgrade_effect_text(upgrade_type, wagon_type), bool(can_state.get("ok", false)))
			row.position = Vector2(0, row_y)
			content.add_child(row)
			scene._upgrade_entries.append({"kind": "wagon", "id": target_id, "wagon_type": wagon_type, "upgrade_type": upgrade_type, "rect": Rect2(content.position + Vector2(300, row_y + 8), Vector2(110, 36))})
			if not bool(can_state.get("ok", false)):
				var reason_label := Label.new()
				reason_label.text = I18n.t(upgrade_reason_key(str(can_state.get("reason", ""))))
				reason_label.position = Vector2(0, row_y + 58)
				reason_label.size = Vector2(420, 18)
				reason_label.add_theme_font_size_override("font_size", 10)
				reason_label.add_theme_color_override("font_color", scene.COLOR_RED)
				content.add_child(reason_label)
			row_y += 88

	var respec_btn: Control = scene._create_button(I18n.t("garage.upgrade.respec"), Vector2(0, 470), Vector2(180, 42), Color("#16a085"))
	content.add_child(respec_btn)
	scene._upgrade_respec_rect = Rect2(content.position + Vector2(0, 470), Vector2(180, 42))

static func create_upgrade_row(scene: Node, title: String, level: int, next_level: int, cost: int, effect_text: String, can_upgrade: bool) -> Control:
	var row := Control.new()
	row.size = Vector2(420, 80)
	var row_bg := ColorRect.new()
	row_bg.position = Vector2.ZERO
	row_bg.size = row.size
	row_bg.color = Color("#123456")
	row.add_child(row_bg)

	var name_label := Label.new()
	name_label.text = "%s (Lv.%d)" % [title, level]
	name_label.position = Vector2(10, 8)
	name_label.size = Vector2(260, 20)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", scene.COLOR_TEXT)
	row.add_child(name_label)

	var effect_label := Label.new()
	effect_label.text = effect_text
	effect_label.position = Vector2(10, 30)
	effect_label.size = Vector2(280, 18)
	effect_label.add_theme_font_size_override("font_size", 11)
	effect_label.add_theme_color_override("font_color", Color("#95a5a6"))
	row.add_child(effect_label)

	var cost_label := Label.new()
	cost_label.text = I18n.t("garage.upgrade.cost", [next_level, cost])
	cost_label.position = Vector2(10, 52)
	cost_label.size = Vector2(260, 18)
	cost_label.add_theme_font_size_override("font_size", 11)
	cost_label.add_theme_color_override("font_color", Color("#f1c40f"))
	row.add_child(cost_label)

	var upgrade_btn: Control = scene._create_button(I18n.t("garage.upgrade.button"), Vector2(300, 8), Vector2(110, 36), scene.COLOR_GREEN if can_upgrade else scene.COLOR_BUTTON_DISABLED)
	row.add_child(upgrade_btn)
	return row

static func get_upgrade_target_name(scene: Node) -> String:
	var gm: Node = scene._get_game_manager()
	var kind: String = str(scene._selected_upgrade_target.get("kind", "locomotive"))
	var target_id: String = str(scene._selected_upgrade_target.get("id", gm.train_config.get_locomotive().id))
	if kind == "locomotive":
		return I18n.t("locomotive.%s" % target_id)
	var wagon_data: Variant = find_wagon_by_id(scene, target_id)
	if wagon_data == null:
		return I18n.t("garage.upgrade.unknown_target")
	var wagon: WagonData = wagon_data as WagonData
	return "%s #%s" % [scene._get_wagon_type_name(wagon.type), target_id.substr(0, mini(6, target_id.length()))]

static func find_wagon_by_id(scene: Node, wagon_id: String):
	var gm: Node = scene._get_game_manager()
	for wagon in gm.inventory.get_wagons():
		var w: WagonData = wagon
		if w.id == wagon_id:
			return w
	return null

static func loco_upgrade_name_key(upgrade_type: int) -> String:
	match upgrade_type:
		Constants.UpgradeType.SPEED: return "garage.upgrade.loco.speed"
		Constants.UpgradeType.CAPACITY: return "garage.upgrade.loco.capacity"
		Constants.UpgradeType.FUEL_EFFICIENCY: return "garage.upgrade.loco.fuel"
		Constants.UpgradeType.DURABILITY: return "garage.upgrade.loco.durability"
		_: return "garage.upgrade.unknown_target"

static func wagon_upgrade_name_key(upgrade_type: int) -> String:
	match upgrade_type:
		Constants.WagonUpgradeType.COMFORT: return "garage.upgrade.wagon.comfort"
		Constants.WagonUpgradeType.CAPACITY: return "garage.upgrade.wagon.capacity"
		Constants.WagonUpgradeType.MAINTENANCE: return "garage.upgrade.wagon.maintenance"
		_: return "garage.upgrade.unknown_target"

static func upgrade_reason_key(reason: String) -> String:
	match reason:
		"insufficient_money": return "garage.upgrade.reason.money"
		"insufficient_reputation": return "garage.upgrade.reason.reputation"
		"line_not_completed": return "garage.upgrade.reason.line"
		"max_level": return "garage.upgrade.reason.max"
		_: return "garage.upgrade.reason.generic"

static func loco_upgrade_effect_text(upgrade_type: int) -> String:
	match upgrade_type:
		Constants.UpgradeType.SPEED: return I18n.t("garage.upgrade.effect.speed")
		Constants.UpgradeType.CAPACITY: return I18n.t("garage.upgrade.effect.capacity")
		Constants.UpgradeType.FUEL_EFFICIENCY: return I18n.t("garage.upgrade.effect.fuel")
		Constants.UpgradeType.DURABILITY: return I18n.t("garage.upgrade.effect.durability")
		_: return I18n.t("garage.upgrade.reason.generic")

static func wagon_upgrade_effect_text(upgrade_type: int, wagon_type: int) -> String:
	match upgrade_type:
		Constants.WagonUpgradeType.COMFORT:
			return I18n.t("garage.upgrade.effect.wagon.comfort")
		Constants.WagonUpgradeType.CAPACITY:
			var amount: int = Balance.UPGRADE_WAGON_CAPACITY_CARGO_PER_LEVEL if wagon_type == Constants.WagonType.CARGO else Balance.UPGRADE_WAGON_CAPACITY_PASSENGER_PER_LEVEL
			return I18n.t("garage.upgrade.effect.wagon.capacity", [amount])
		Constants.WagonUpgradeType.MAINTENANCE:
			return I18n.t("garage.upgrade.effect.wagon.maintenance")
		_:
			return I18n.t("garage.upgrade.reason.generic")

static func _apply_texture(node: ColorRect, texture_path: String) -> void:
	var texture: Texture2D = PixelTextureLoader.load_texture(texture_path)
	if texture == null:
		return
	var tex := TextureRect.new()
	tex.texture = texture
	tex.position = Vector2.ZERO
	tex.size = node.size
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.modulate = Color(1, 1, 1, 0.88)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(tex)
