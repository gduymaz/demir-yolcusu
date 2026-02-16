## Module: station_flow_manager.gd
## Encapsulates StationScene flow, UI state updates, and content generation.

extends RefCounted

const StationUiBuilder := preload("res://src/scenes/station/station_ui_builder.gd")

static func setup_systems(scene: Node) -> void:
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm:
		scene._event_bus = gm.event_bus
		scene._economy = gm.economy
		scene._reputation = gm.reputation
		scene._wagons = []
		for wagon in gm.train_config.get_wagons():
			scene._wagons.append(wagon)
	else:
		scene._event_bus = scene.get_node_or_null("/root/EventBus")
		if not scene._event_bus:
			scene._event_bus = load("res://src/events/event_bus.gd").new()
			scene.add_child(scene._event_bus)
		scene._economy = EconomySystem.new()
		scene._economy.setup(scene._event_bus)
		scene.add_child(scene._economy)
		scene._reputation = ReputationSystem.new()
		scene._reputation.setup(scene._event_bus)
		scene.add_child(scene._reputation)
		scene._wagons = [
			WagonData.new(Constants.WagonType.ECONOMY),
			WagonData.new(Constants.WagonType.BUSINESS),
		]
	scene._boarding = BoardingSystem.new()
	scene._boarding.setup(scene._event_bus, scene._economy, scene._reputation)
	scene.add_child(scene._boarding)
	scene._patience = PatienceSystem.new()
	scene._patience.setup(scene._event_bus, scene._reputation)
	scene.add_child(scene._patience)

static func build_scene(scene: Node) -> void:
	var refs: Dictionary = StationUiBuilder.build(scene)
	scene._hud_timer = refs.get("hud_timer")
	scene._hud_station = refs.get("hud_station")
	scene._event_icon_label = refs.get("event_icon_label")
	scene._wagon_nodes = refs.get("wagon_nodes", [])
	scene._fuel_button = refs.get("fuel_button")
	scene._fuel_progress_bg = refs.get("fuel_progress_bg")
	scene._fuel_progress_fill = refs.get("fuel_progress_fill")
	scene._cargo_panel = refs.get("cargo_panel")
	scene._cargo_list = refs.get("cargo_list")
	scene._cargo_note_label = refs.get("cargo_note_label")
	scene._cargo_info_label = refs.get("cargo_info_label")
	scene._event_banner = refs.get("event_banner")
	scene._summary_panel = refs.get("summary_panel")
	scene._summary_label = refs.get("summary_label")

static func process(scene: Node, delta: float) -> void:
	scene._process_refuel(delta)
	scene._update_refuel_controls()
	update_event_banner(scene, delta)
	if not scene._is_active:
		return
	scene._time_remaining -= delta
	scene._hud_timer.text = I18n.t("station.hud.time", [ceili(scene._time_remaining)])
	if scene._time_remaining <= 0.0:
		scene._end_station()
		return
	if not scene._timer_half_notified and scene._time_remaining <= (scene._station_time * 0.5):
		scene._timer_half_notified = true
		var gm_notify: Node = scene.get_node_or_null("/root/GameManager")
		if gm_notify and gm_notify.tutorial_manager:
			gm_notify.tutorial_manager.notify("timer_half")
	var patience_delta: float = delta
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm and gm.has_method("get_station_patience_multiplier"):
		patience_delta *= gm.get_station_patience_multiplier(get_current_station_name(scene))
	var lost := scene._patience.update(scene._waiting_passengers, patience_delta)
	if lost.size() > 0:
		var conductor: Node = scene.get_node_or_null("/root/ConductorManager")
		if conductor:
			conductor.show_runtime_tip("tip_passenger_lost", I18n.t("conductor.tip.passenger_lost"))
		scene._rebuild_passenger_nodes()
	scene._update_patience_bars()

static func update_event_banner(scene: Node, delta: float) -> void:
	if scene._event_banner == null or scene._event_banner_timer <= 0.0:
		return
	scene._event_banner_timer = maxf(0.0, scene._event_banner_timer - delta)
	if scene._event_banner_timer <= 0.0:
		scene._event_banner.visible = false

static func start_station(scene: Node) -> void:
	scene._is_active = true
	scene._station_time = Constants.STATION_TIME_LARGE
	scene._time_remaining = scene._station_time
	scene._timer_half_notified = false
	scene._first_boarded_notified = false
	scene._summary_panel.visible = false
	scene._event_banner.visible = false
	if scene._event_icon_label:
		scene._event_icon_label.visible = false
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm and gm.has_method("get_station_time_multiplier"):
		scene._station_time *= gm.get_station_time_multiplier()
		scene._time_remaining = scene._station_time
	if gm and gm.tutorial_manager:
		gm.tutorial_manager.notify("station_opened")
	var passenger_multiplier: float = 1.0
	var extra_vip: int = 0
	if gm and gm.random_event_system:
		scene._time_remaining = maxf(5.0, scene._time_remaining + gm.random_event_system.consume_station_time_delta())
		passenger_multiplier = gm.random_event_system.consume_passenger_multiplier()
		extra_vip = gm.random_event_system.consume_extra_vip()
		var station_event: Dictionary = gm.consume_pending_station_event()
		if not station_event.is_empty():
			show_event_banner(scene, station_event)
			show_event_icon(scene, str(station_event.get("id", "")))
			show_conductor_event_tip(scene, station_event)
	setup_special_action(scene, gm)
	var destinations := get_destination_names(scene)
	var distance: int = get_current_distance(scene)
	scene._waiting_passengers = []
	var batch_count: int = max(1, int(round(5.0 * passenger_multiplier)))
	for p in PassengerFactory.create_batch(batch_count, destinations, distance):
		scene._waiting_passengers.append(p)
	for i in range(extra_vip):
		scene._waiting_passengers.append(PassengerFactory.create(Constants.PassengerType.VIP, destinations[randi() % destinations.size()], distance))
	scene._hud_station.text = get_current_station_name(scene)
	scene._station_ticket_start = int(scene._economy.get_trip_summary().get("earnings", {}).get("ticket", 0))
	apply_dining_income(scene, gm)
	refresh_cargo_offers(scene, gm)
	refresh_shop_panel(scene, gm)
	show_cargo_delivery_popup(scene, gm)
	show_second_trip_station_reminders(scene, gm)
	scene._rebuild_passenger_nodes()
	scene._update_hud()
	scene._update_wagon_labels()

static func end_station(scene: Node) -> void:
	scene._is_active = false
	scene._time_remaining = 0.0
	scene._hud_timer.text = I18n.t("station.hud.time", [0])
	var summary := scene._economy.get_trip_summary()
	var boarded_count := 0
	for w in scene._wagons:
		boarded_count += (w as WagonData).get_passenger_count()
	var lost_count := 5 - scene._waiting_passengers.size() - boarded_count
	var ticket_end := int(summary.get("earnings", {}).get("ticket", 0))
	var station_ticket := maxi(0, ticket_end - scene._station_ticket_start)
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm:
		gm.record_station_result(get_current_station_name(scene), station_ticket, boarded_count, lost_count)
	scene._summary_label.text = I18n.t("station.summary.text", [boarded_count, scene._waiting_passengers.size(), lost_count, summary["total_earned"], scene._economy.get_balance(), scene._reputation.get_stars()])
	scene._summary_panel.visible = true
	if boarded_count >= 4 and lost_count <= 0:
		var conductor: Node = scene.get_node_or_null("/root/ConductorManager")
		if conductor:
			conductor.show_runtime_tip("tip_station_good", I18n.t("conductor.tip.station_good"))

static func refresh_cargo_offers(scene: Node, gm: Node) -> void:
	clear_cargo_buttons(scene)
	if gm == null or gm.cargo_system == null:
		scene._cargo_note_label.text = I18n.t("station.cargo.none")
		scene._cargo_info_label.text = ""
		return
	var active_quest_id: String = ""
	if gm.quest_system:
		active_quest_id = gm.quest_system.get_active_quest_id()
	var guaranteed_offer: Dictionary = {}
	if active_quest_id == "ege_03" and get_current_station_name(scene).to_lower().find("aydin") >= 0:
		guaranteed_offer = gm.cargo_system.get_forced_offer_for_quest(active_quest_id)
	var offers: Array = gm.cargo_system.generate_offers(get_current_station_name(scene), guaranteed_offer)
	scene._cargo_note_label.text = I18n.t("station.cargo.available", [offers.size()]) if not offers.is_empty() else I18n.t("station.cargo.none")
	var has_cargo_wagon: bool = gm.cargo_system.is_cargo_wagon_available()
	var capacity: int = gm.cargo_system.get_available_capacity()
	scene._cargo_info_label.text = I18n.t("station.cargo.no_wagon") if not has_cargo_wagon else I18n.t("station.cargo.capacity", [capacity])
	for offer in offers:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 11)
		label.text = I18n.t("station.cargo.offer", [I18n.t("cargo.%s" % str(offer.get("name", ""))), str(offer.get("destination_station", "")), int(offer.get("reward", 0)), int(offer.get("remaining_trips", 0))])
		row.add_child(label)
		var load_btn := Button.new()
		load_btn.text = I18n.t("station.cargo.load")
		load_btn.disabled = (not has_cargo_wagon) or (capacity < int(offer.get("weight", 1)))
		if load_btn.disabled and not has_cargo_wagon:
			load_btn.tooltip_text = I18n.t("station.cargo.no_wagon")
		load_btn.pressed.connect(scene._on_cargo_load_pressed.bind(str(offer.get("id", ""))))
		row.add_child(load_btn)
		scene._cargo_button_map[str(offer.get("id", ""))] = load_btn
		scene._cargo_list.add_child(row)

static func apply_dining_income(scene: Node, gm: Node) -> void:
	if gm == null or not gm.has_method("get_dining_income_per_station"):
		return
	var dining_income: int = gm.get_dining_income_per_station()
	if dining_income <= 0:
		return
	scene._economy.earn(dining_income, "dining")
	show_event_text(scene, I18n.t("station.dining.income", [dining_income]))

static func toggle_shop_panel(scene: Node) -> void:
	if scene._shop_panel == null:
		return
	scene._shop_panel.visible = not scene._shop_panel.visible
	if scene._shop_panel.visible:
		refresh_shop_panel(scene, scene.get_node_or_null("/root/GameManager"))

static func refresh_shop_panel(scene: Node, gm: Node) -> void:
	if scene._shop_rows.is_empty():
		return
	var station_name: String = get_current_station_name(scene)
	for i in range(scene._shop_rows.size()):
		var row: HBoxContainer = scene._shop_rows[i]
		var shop_type: int = [Constants.ShopType.BUFFET, Constants.ShopType.SOUVENIR, Constants.ShopType.CARGO_DEPOT][i]
		var level: int = gm.shop_system.get_station_shop_level(station_name, shop_type) if gm and gm.shop_system else 0
		(row.get_node("Label") as Label).text = "%s  Lv.%d" % [shop_type_name(shop_type), level]
		var btn: Button = row.get_node("Action")
		if level <= 0:
			btn.text = I18n.t("station.shop.open")
			btn.disabled = gm == null or gm.shop_system == null
		elif level < Balance.SHOP_MAX_LEVEL:
			btn.text = I18n.t("station.shop.upgrade")
			btn.disabled = gm == null or gm.shop_system == null
		else:
			btn.text = I18n.t("station.shop.max")
			btn.disabled = true

static func on_shop_action_pressed(scene: Node, shop_type: int) -> void:
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm == null or gm.shop_system == null:
		return
	var station_name: String = get_current_station_name(scene)
	var level: int = gm.shop_system.get_station_shop_level(station_name, shop_type)
	var ok: bool = gm.shop_system.open_shop(station_name, shop_type) if level <= 0 else gm.shop_system.upgrade_shop(station_name, shop_type)
	show_event_text(scene, I18n.t("station.shop.success") if ok else I18n.t("station.shop.failed"))
	refresh_shop_panel(scene, gm)
	scene._update_hud()

static func shop_type_name(shop_type: int) -> String:
	match shop_type:
		Constants.ShopType.BUFFET:
			return I18n.t("shop.type.buffet")
		Constants.ShopType.SOUVENIR:
			return I18n.t("shop.type.souvenir")
		Constants.ShopType.CARGO_DEPOT:
			return I18n.t("shop.type.cargo_depot")
		_:
			return "?"

static func show_cargo_delivery_popup(scene: Node, gm: Node) -> void:
	if gm == null:
		return
	var summary: Dictionary = gm.consume_pending_cargo_delivery_summary()
	var total_reward: int = int(summary.get("total_reward", 0))
	if total_reward > 0:
		show_event_text(scene, I18n.t("station.cargo.delivered", [total_reward]))

static func setup_special_action(scene: Node, gm: Node) -> void:
	if scene._special_action_button != null:
		scene._special_action_button.queue_free()
		scene._special_action_button = null
	if gm == null or gm.random_event_system == null:
		return
	var reputation_bonus: float = gm.random_event_system.consume_reputation_bonus()
	if reputation_bonus <= 0.0:
		return
	scene._special_action_button = Button.new()
	scene._special_action_button.position = Vector2(20, 112)
	scene._special_action_button.size = Vector2(180, 30)
	scene._special_action_button.text = I18n.t("station.button.help_sick")
	scene._special_action_button.pressed.connect(func() -> void:
		scene._reputation.add(reputation_bonus, "event")
		show_event_text(scene, I18n.t("station.sick.reward", [reputation_bonus]))
		scene._special_action_button.disabled = true
	)
	scene.add_child(scene._special_action_button)

static func show_conductor_event_tip(scene: Node, event_data: Dictionary) -> void:
	var description_key: String = str(event_data.get("description_key", ""))
	if description_key.is_empty():
		return
	var conductor: Node = scene.get_node_or_null("/root/ConductorManager")
	if conductor:
		conductor.show_runtime_tip("tip_event_%s" % str(event_data.get("id", "")), I18n.t(description_key))

static func show_event_banner(scene: Node, event_data: Dictionary) -> void:
	var title_key: String = str(event_data.get("title_key", ""))
	if not title_key.is_empty():
		show_event_text(scene, I18n.t("station.event.banner", [I18n.t(title_key)]))

static func show_event_icon(scene: Node, event_id: String) -> void:
	if scene._event_icon_label == null:
		return
	var icon_key: String = "travel.event.icon.%s" % event_id
	var icon_text: String = I18n.t(icon_key)
	scene._event_icon_label.visible = icon_text != icon_key
	if scene._event_icon_label.visible:
		scene._event_icon_label.text = icon_text

static func show_event_text(scene: Node, text: String) -> void:
	if scene._event_banner == null:
		return
	scene._event_banner.text = text
	scene._event_banner.visible = true
	scene._event_banner_timer = 3.0

static func clear_cargo_buttons(scene: Node) -> void:
	scene._cargo_button_map.clear()
	if scene._cargo_list == null:
		return
	for child in scene._cargo_list.get_children():
		child.queue_free()

static func on_restart_pressed(scene: Node) -> void:
	start_station(scene)

static func on_garage_pressed(_scene: Node) -> void:
	SceneTransition.transition_to("res://src/scenes/garage/garage_scene.tscn")

static func on_continue_pressed(_scene: Node) -> void:
	SceneTransition.transition_to("res://src/scenes/travel/travel_scene.tscn")

static func on_finish_trip_pressed(scene: Node) -> void:
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm:
		gm.trip_planner.end_trip()
	SceneTransition.transition_to("res://src/scenes/summary/summary_scene.tscn")

static func on_cargo_load_pressed(scene: Node, cargo_id: String) -> void:
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm == null or gm.cargo_system == null:
		return
	if not gm.cargo_system.is_cargo_wagon_available():
		var conductor: Node = scene.get_node_or_null("/root/ConductorManager")
		if conductor:
			conductor.show_runtime_tip("tip_cargo_need_wagon", I18n.t("conductor.tip.cargo_no_wagon"))
		return
	if gm.cargo_system.load_offer(cargo_id):
		show_event_text(scene, I18n.t("station.cargo.loaded"))
		refresh_cargo_offers(scene, gm)
		scene._update_wagon_labels()

static func get_destination_names(scene: Node) -> Array:
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if not gm or not gm.trip_planner.is_trip_active():
		return ["denizli", "torbali", "selcuk", "nazilli"]
	var destinations: Array = []
	var trip_stops: Array = gm.trip_planner.get_trip_stops()
	var current: int = gm.trip_planner.get_current_stop_index()
	for i in range(current + 1, trip_stops.size()):
		destinations.append(trip_stops[i]["name"].to_lower())
	if destinations.is_empty():
		destinations.append(I18n.t("station.destination.final"))
	return destinations

static func get_current_distance(scene: Node) -> int:
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if not gm or not gm.trip_planner.is_trip_active():
		return 120
	return int(gm.trip_planner.get_current_stop().get("km_from_start", 120))

static func get_current_station_name(scene: Node) -> String:
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if not gm or not gm.trip_planner.is_trip_active():
		return I18n.t("station.name.fallback")
	return gm.trip_planner.get_current_stop().get("name", I18n.t("station.name.fallback"))

static func create_passenger_node(scene: Node, passenger: Dictionary) -> Control:
	var root := Control.new()
	root.size = scene.PASSENGER_SIZE
	var shadow := ColorRect.new()
	shadow.size = Vector2(scene.PASSENGER_SIZE.x - 8, 8)
	shadow.position = Vector2(4, scene.PASSENGER_SIZE.y - 6)
	shadow.color = Color(0, 0, 0, 0.22)
	root.add_child(shadow)
	var torso := ColorRect.new()
	torso.size = Vector2(22, 26)
	torso.position = Vector2(9, 20)
	torso.color = get_passenger_color(scene, passenger["type"])
	root.add_child(torso)
	var head := ColorRect.new()
	head.size = Vector2(16, 16)
	head.position = Vector2(12, 2)
	head.color = Color("#f5d7b2")
	root.add_child(head)
	var type_label := Label.new()
	type_label.text = get_passenger_type_letter(passenger["type"])
	type_label.position = Vector2(12, 22)
	type_label.add_theme_font_size_override("font_size", 14)
	type_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(type_label)
	var fare_label := Label.new()
	fare_label.text = "%d DA" % passenger["fare"]
	fare_label.position = Vector2(2, 30)
	fare_label.add_theme_font_size_override("font_size", 10)
	fare_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(fare_label)
	var dest_label := Label.new()
	dest_label.text = passenger["destination"].substr(0, 3).to_upper()
	dest_label.position = Vector2(2, 45)
	dest_label.add_theme_font_size_override("font_size", 9)
	dest_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	root.add_child(dest_label)
	var bar_bg := ColorRect.new()
	bar_bg.size = Vector2(scene.PASSENGER_SIZE.x - 4, 5)
	bar_bg.position = Vector2(2, -8)
	bar_bg.color = Color(0, 0, 0, 0.5)
	bar_bg.name = "PatienceBarBG"
	root.add_child(bar_bg)
	var bar_fill := ColorRect.new()
	bar_fill.size = Vector2(scene.PASSENGER_SIZE.x - 4, 5)
	bar_fill.position = Vector2(2, -8)
	bar_fill.color = scene.COLOR_SUCCESS
	bar_fill.name = "PatienceBarFill"
	root.add_child(bar_fill)
	if is_quest_target_passenger(scene, passenger):
		var highlight := PanelContainer.new()
		highlight.name = "QuestHighlight"
		highlight.position = Vector2(-2, -2)
		highlight.size = scene.PASSENGER_SIZE + Vector2(4, 4)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight.add_theme_stylebox_override("panel", make_quest_highlight_style(scene))
		root.add_child(highlight)
	return root

static func get_passenger_position(scene: Node, index: int) -> Vector2:
	return Vector2(scene.WAITING_START_X + index * scene.WAITING_SPACING, scene.WAITING_Y)

static func is_quest_target_passenger(scene: Node, passenger: Dictionary) -> bool:
	var target_station: String = get_active_transport_target_station(scene)
	if target_station.is_empty():
		return false
	return str(passenger.get("destination", "")).to_lower().find(target_station) >= 0

static func get_active_transport_target_station(scene: Node) -> String:
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm == null or gm.quest_system == null:
		return ""
	var active_quest: Dictionary = gm.quest_system.get_active_quest()
	if active_quest.is_empty() or int(active_quest.get("type", -1)) != Constants.QuestType.TRANSPORT:
		return ""
	return str(active_quest.get("conditions", {}).get("destination", "")).to_lower()

static func make_quest_highlight_style(scene: Node) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = scene.COLOR_QUEST_TARGET
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

static func get_passenger_color(scene: Node, passenger_type: Constants.PassengerType) -> Color:
	match passenger_type:
		Constants.PassengerType.VIP: return scene.COLOR_PASSENGER_VIP
		Constants.PassengerType.STUDENT: return scene.COLOR_PASSENGER_STUDENT
		Constants.PassengerType.ELDERLY: return scene.COLOR_PASSENGER_ELDERLY
		_: return scene.COLOR_PASSENGER_NORMAL

static func get_passenger_type_letter(_scene: Node, passenger_type: Constants.PassengerType) -> String:
	match passenger_type:
		Constants.PassengerType.VIP: return "V"
		Constants.PassengerType.STUDENT: return "O"
		Constants.PassengerType.ELDERLY: return "Y"
		_: return "N"

static func flash_wagon(scene: Node, wagon_index: int, color: Color) -> void:
	var node: ColorRect = scene._wagon_nodes[wagon_index]
	var tween := scene.create_tween()
	node.modulate = color
	tween.tween_property(node, "modulate", Color.WHITE, 0.3)

static func get_wagon_color(scene: Node, wtype: Constants.WagonType) -> Color:
	match wtype:
		Constants.WagonType.ECONOMY: return scene.COLOR_WAGON_ECONOMY
		Constants.WagonType.BUSINESS: return scene.COLOR_WAGON_BUSINESS
		Constants.WagonType.VIP: return scene.COLOR_WAGON_VIP
		Constants.WagonType.DINING: return scene.COLOR_WAGON_DINING
		Constants.WagonType.CARGO: return scene.COLOR_WAGON_CARGO
		_: return Color.WHITE

static func get_wagon_short_name(_scene: Node, wtype: Constants.WagonType) -> String:
	match wtype:
		Constants.WagonType.ECONOMY: return I18n.t("wagon.short.economy")
		Constants.WagonType.BUSINESS: return I18n.t("wagon.short.business")
		Constants.WagonType.VIP: return I18n.t("wagon.short.vip")
		Constants.WagonType.DINING: return I18n.t("wagon.short.dining")
		Constants.WagonType.CARGO: return I18n.t("wagon.short.cargo")
		_: return "?"

static func apply_accessibility(scene: Node) -> void:
	var gm: Node = scene.get_node_or_null("/root/GameManager")
	if gm and gm.settings_system:
		gm.settings_system.apply_font_scale_recursive(scene)

static func show_second_trip_station_reminders(scene: Node, gm: Node) -> void:
	if gm == null or gm.total_trips != 1:
		return
	var conductor: Node = scene.get_node_or_null("/root/ConductorManager")
	if conductor == null:
		return
	if gm.fuel_system and gm.fuel_system.is_fuel_low():
		conductor.show_runtime_tip("tip_tutorial_trip2_fuel", I18n.t("tutorial.trip2.fuel_low"))
	if gm.cargo_system:
		var offers_exist: bool = scene._cargo_list != null and scene._cargo_list.get_child_count() > 0
		if offers_exist and gm.cargo_system.is_cargo_wagon_available():
			conductor.show_runtime_tip("tip_tutorial_trip2_cargo", I18n.t("tutorial.trip2.cargo"))
