## Module: station_interaction_manager.gd
## Handles StationScene interactions, drag-drop boarding, and service panels.

extends RefCounted

static func handle_input(scene: Node, event: InputEvent) -> void:
	if not scene._is_active:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pos := scene._get_event_position(event)
		var pressed := scene._is_pressed(event)
		if pressed:
			if scene._shop_panel and scene._shop_panel.visible and scene._is_in_rect(pos, scene._shop_panel.position, scene._shop_panel.size):
				return
			if scene._shop_button and scene._is_in_rect(pos, scene._shop_button.position, scene._shop_button.size):
				scene._toggle_shop_panel()
				return
			if scene._is_in_rect(pos, scene._fuel_button.position, scene._fuel_button.size):
				scene._try_refuel()
				return
			if scene._cargo_panel and scene._is_in_rect(pos, scene._cargo_panel.position, scene._cargo_panel.size):
				return
			scene._try_start_drag(pos)
		else:
			scene._try_end_drag(pos)
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if scene._dragged_passenger_index >= 0 and scene._dragged_passenger_index < scene._passenger_nodes.size():
			var drag_pos := scene._get_event_position(event)
			var pnode: Control = scene._passenger_nodes[scene._dragged_passenger_index]
			pnode.position = drag_pos - scene._drag_offset

static func rebuild_passenger_nodes(scene: Node) -> void:
	for node in scene._passenger_nodes:
		node.queue_free()
	scene._passenger_nodes.clear()
	for i in range(scene._waiting_passengers.size()):
		var passenger := scene._waiting_passengers[i]
		var pnode := scene._create_passenger_node(passenger)
		pnode.position = scene._get_passenger_position(i)
		scene.add_child(pnode)
		scene._passenger_nodes.append(pnode)

static func update_patience_bars(scene: Node) -> void:
	for i in scene._passenger_nodes.size():
		if i >= scene._waiting_passengers.size():
			break
		var passenger: Dictionary = scene._waiting_passengers[i]
		var percent := PatienceSystem.get_patience_percent(passenger)
		var pnode: Control = scene._passenger_nodes[i]
		var bar: ColorRect = pnode.get_node("PatienceBarFill")
		bar.size.x = (scene.PASSENGER_SIZE.x - 4) * (percent / 100.0)
		if percent > 60:
			bar.color = scene.COLOR_SUCCESS
		elif percent > 30:
			bar.color = Color("#F39C12")
		else:
			bar.color = scene.COLOR_FAIL

static func update_refuel_controls(scene: Node) -> void:
	if scene._fuel_button == null:
		return
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm == null:
		scene._fuel_button.disabled = true
		return
	var fuel: FuelSystem = gm.fuel_system
	var missing := maxf(0.0, fuel.get_tank_capacity() - fuel.get_current_fuel())
	var cost: int = fuel.get_refuel_cost(missing)
	if missing <= 0.0:
		scene._fuel_button.disabled = true
		scene._fuel_button.text = I18n.t("station.button.refuel_full")
	else:
		scene._fuel_button.disabled = not scene._economy.can_afford(cost)
		scene._fuel_button.text = I18n.t("station.button.refuel_with_cost", [cost])

static func try_refuel(scene: Node) -> void:
	if scene._refuel_in_progress:
		return
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var fuel: FuelSystem = gm.fuel_system
	var missing := maxf(0.0, fuel.get_tank_capacity() - fuel.get_current_fuel())
	var cost: int = fuel.get_refuel_cost(missing)
	if missing <= 0.0 or not scene._economy.can_afford(cost):
		return
	scene._refuel_in_progress = true
	scene._refuel_progress = 0.0
	scene._fuel_progress_fill.size.x = 0

static func process_refuel(scene: Node, delta: float) -> void:
	if not scene._refuel_in_progress:
		return
	scene._refuel_progress += delta / 1.5
	var p := clampf(scene._refuel_progress, 0.0, 1.0)
	scene._fuel_progress_fill.size.x = 160.0 * p
	if p >= 1.0:
		var gm: Node = scene.get_node_or_null("/root/GameManager")
		if gm:
			var fuel: FuelSystem = gm.fuel_system
			var missing := maxf(0.0, fuel.get_tank_capacity() - fuel.get_current_fuel())
			fuel.buy_refuel(missing)
		scene._refuel_in_progress = false
		scene._refuel_progress = 0.0
		scene._fuel_progress_fill.size.x = 0
		scene._update_hud()

static func update_wagon_labels(scene: Node) -> void:
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	var cargo_loaded: int = 0
	if gm and gm.cargo_system:
		cargo_loaded = gm.cargo_system.get_loaded_weight()
	for i in scene._wagon_nodes.size():
		if i >= scene._wagons.size():
			break
		var wagon: WagonData = scene._wagons[i]
		var wnode: ColorRect = scene._wagon_nodes[i]
		var label := wnode.get_node_or_null("WagonLabel") as Label
		if label == null:
			continue
		if wagon.type == Constants.WagonType.CARGO:
			label.text = "%s\n%s %d/%d" % [scene._get_wagon_short_name(wagon.type), I18n.t("station.cargo.boxes_icon"), cargo_loaded, wagon.get_capacity()]
		else:
			label.text = "%s\n%d/%d" % [scene._get_wagon_short_name(wagon.type), wagon.get_passenger_count(), wagon.get_capacity()]
