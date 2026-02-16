## Module: garage_interaction_manager.gd
## Handles GarageScene input, drag-and-drop, and purchase/upgrade interactions.

extends RefCounted

static func handle_input(scene: Node, event: InputEvent) -> void:
	if scene._should_ignore_mouse_event(event):
		return
	if scene._shop_visible:
		_handle_shop_input(scene, event)
		return
	if scene._upgrade_visible:
		_handle_upgrade_input(scene, event)
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pos := scene._get_event_position(event)
		var pressed := scene._is_pressed(event)
		if pressed:
			_on_press(scene, pos)
		else:
			_on_release(scene, pos)
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and scene._dragging:
		var pos := scene._get_event_position(event)
		_on_drag(scene, pos)

static func _handle_shop_input(scene: Node, event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if not scene._is_pressed(event):
		return
	var pos := scene._get_event_position(event)
	var close_btn: Control = scene._shop_panel.get_node("ShopCloseButton")
	if scene._is_in_rect(pos, close_btn.position, close_btn.size):
		scene._shop_visible = false
		scene._shop_panel.visible = false
		scene._refresh_all()
		return
	for entry in scene._shop_entries:
		var rect: Rect2 = entry.get("rect", Rect2())
		if rect.has_point(pos):
			if str(entry.get("kind", "")) == "wagon":
				scene._try_buy_wagon(int(entry.get("type", 0)))
			else:
				scene._try_buy_locomotive(str(entry.get("id", "")), float(entry.get("rep", 0.0)))
			return

static func _handle_upgrade_input(scene: Node, event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if not scene._is_pressed(event):
		return
	var pos := scene._get_event_position(event)
	var close_btn: Control = scene._upgrade_panel.get_node("UpgradeCloseButton")
	if scene._is_in_rect(pos, close_btn.position, close_btn.size):
		scene._upgrade_visible = false
		scene._upgrade_panel.visible = false
		scene._refresh_all()
		return
	if scene._upgrade_respec_rect.has_point(pos):
		scene._try_respec_selected_target()
		return
	for entry in scene._upgrade_entries:
		var rect: Rect2 = entry.get("rect", Rect2())
		if rect.has_point(pos):
			scene._try_upgrade_entry(entry)
			return

static func _on_press(scene: Node, pos: Vector2) -> void:
	if scene._dragging:
		return
	var shop_btn: Control = scene.get_node("ShopButton")
	if scene._is_in_rect(pos, shop_btn.position, shop_btn.size):
		scene._open_shop()
		return
	var achievements_btn: Control = scene.get_node("AchievementsButton")
	if scene._is_in_rect(pos, achievements_btn.position, achievements_btn.size):
		SceneTransition.transition_to("res://src/scenes/achievements/achievements_scene.tscn")
		return
	var settings_btn: Control = scene.get_node("SettingsButton")
	if scene._is_in_rect(pos, settings_btn.position, settings_btn.size):
		SceneTransition.transition_to("res://src/scenes/settings/settings_scene.tscn")
		return
	var upgrade_btn: Control = scene.get_node("UpgradeButton")
	if scene._is_in_rect(pos, upgrade_btn.position, upgrade_btn.size):
		scene._open_upgrade()
		return
	var go_btn: Control = scene.get_node("GoButton")
	if scene._is_in_rect(pos, go_btn.position, go_btn.size):
		scene._go_to_station()
		return
	var gm: Node = scene._get_game_manager()
	for i in range(scene._train_wagon_nodes.size()):
		var node: Control = scene._train_wagon_nodes[i]
		var node_global := node.position + scene._train_container.position
		if scene._is_in_rect(pos, node_global, node.size):
			_start_drag_from_train(scene, i, pos)
			return
	for i in range(scene._pool_wagon_nodes.size()):
		var pool_node: Control = scene._pool_wagon_nodes[i]
		var node_global_pool := pool_node.position + scene._wagon_pool_container.position
		if scene._is_in_rect(pos, node_global_pool, pool_node.size):
			_start_drag_from_pool(scene, i, pos)
			return
	var loco_container: Control = scene.get_node("LocoContainer")
	for i in range(scene._loco_buttons.size()):
		var btn: Control = scene._loco_buttons[i]
		var btn_global := btn.position + loco_container.position
		if scene._is_in_rect(pos, btn_global, btn.size):
			_select_locomotive(scene, i)
			return

static func _on_drag(scene: Node, pos: Vector2) -> void:
	if scene._drag_node:
		scene._drag_node.position = pos - scene._drag_offset

static func _on_release(scene: Node, pos: Vector2) -> void:
	if not scene._dragging:
		return
	scene._dragging = false
	var in_train_area := pos.y >= scene.TRAIN_AREA_Y and pos.y <= scene.TRAIN_AREA_Y + scene.TRAIN_AREA_H
	if scene._drag_source == "pool" and in_train_area:
		_add_wagon_to_train_from_pool(scene)
	elif scene._drag_source == "train" and not in_train_area:
		_remove_wagon_from_train(scene)
	if scene._drag_node:
		scene._drag_node.queue_free()
		scene._drag_node = null
	scene._refresh_all()

static func _start_drag_from_pool(scene: Node, index: int, pos: Vector2) -> void:
	var gm: Node = scene._get_game_manager()
	var available: Array = gm.inventory.get_available_wagons()
	if index >= available.size():
		return
	scene._dragging = true
	scene._drag_source = "pool"
	scene._drag_index = index
	scene._drag_wagon = available[index]
	scene._set_upgrade_target_wagon(scene._drag_wagon)
	scene._drag_node = ColorRect.new()
	scene._drag_node.size = Vector2(scene.WAGON_SPRITE_W, scene.WAGON_SPRITE_H)
	scene._drag_node.color = scene._get_wagon_color(scene._drag_wagon.type)
	scene._drag_node.modulate = Color(1, 1, 1, 0.7)
	scene._drag_node.z_index = 100
	scene._drag_offset = Vector2(scene.WAGON_SPRITE_W / 2.0, scene.WAGON_SPRITE_H / 2.0)
	scene._drag_node.position = pos - scene._drag_offset
	scene.add_child(scene._drag_node)

static func _start_drag_from_train(scene: Node, index: int, pos: Vector2) -> void:
	var gm: Node = scene._get_game_manager()
	var wagons: Array = gm.train_config.get_wagons()
	if index >= wagons.size():
		return
	scene._dragging = true
	scene._drag_source = "train"
	scene._drag_index = index
	scene._drag_wagon = wagons[index]
	scene._set_upgrade_target_wagon(scene._drag_wagon)
	scene._drag_node = ColorRect.new()
	scene._drag_node.size = Vector2(scene.WAGON_SPRITE_W, scene.WAGON_SPRITE_H)
	scene._drag_node.color = scene._get_wagon_color(scene._drag_wagon.type)
	scene._drag_node.modulate = Color(1, 1, 1, 0.7)
	scene._drag_node.z_index = 100
	scene._drag_offset = Vector2(scene.WAGON_SPRITE_W / 2.0, scene.WAGON_SPRITE_H / 2.0)
	scene._drag_node.position = pos - scene._drag_offset
	scene.add_child(scene._drag_node)

static func _add_wagon_to_train_from_pool(scene: Node) -> void:
	var gm: Node = scene._get_game_manager()
	var config: TrainConfig = gm.train_config
	if config.is_full() or scene._drag_wagon == null:
		return
	if config.add_wagon(scene._drag_wagon):
		gm.inventory.mark_wagon_in_use(scene._drag_wagon)
		gm.sync_trip_wagon_count()
		if gm.tutorial_manager:
			gm.tutorial_manager.notify("wagon_added")

static func _remove_wagon_from_train(scene: Node) -> void:
	var gm: Node = scene._get_game_manager()
	var config: TrainConfig = gm.train_config
	var removed := config.remove_wagon_at(scene._drag_index)
	if removed:
		gm.inventory.unmark_wagon_in_use(removed)
		gm.sync_trip_wagon_count()

static func _select_locomotive(scene: Node, index: int) -> void:
	var gm: Node = scene._get_game_manager()
	var locos: Array = gm.inventory.get_locomotives()
	if index >= locos.size():
		return
	var loco: LocomotiveData = locos[index]
	scene._set_upgrade_target_locomotive(loco.id)
	var old_config: TrainConfig = gm.train_config
	for wagon in old_config.get_wagons():
		gm.inventory.unmark_wagon_in_use(wagon)
	gm.train_config = TrainConfig.new(loco)
	for old_wagon in old_config.get_wagons():
		if gm.train_config.is_full():
			break
		gm.train_config.add_wagon(old_wagon)
		gm.inventory.mark_wagon_in_use(old_wagon)
	gm.sync_trip_wagon_count()
	scene._refresh_all()
