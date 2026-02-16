## Module: game_manager.gd
## Restored English comments for maintainability and i18n coding standards.

extends Node

const SAVE_PATH := "user://save_slot_1.json"

var event_bus: Node
var economy: EconomySystem
var reputation: ReputationSystem
var inventory: PlayerInventory
var train_config: TrainConfig
var fuel_system: FuelSystem
var route: RouteData
var trip_planner: TripPlanner
var quest_system: Node
var random_event_system: Node
var cargo_system: Node
var current_stop_index: int = 0

var total_trips: int = 0
var total_passengers: int = 0
var total_lost_passengers: int = 0
var total_km: float = 0.0
var total_net_earnings: int = 0

var _trip_station_breakdown: Array = []
var _trip_passenger_count: int = 0
var _trip_lost_count: int = 0
var _trip_start_reputation: float = 0.0

var last_trip_report: Dictionary = {}

var shown_tips: Dictionary = {}
var intro_completed: bool = false
var _pending_station_event: Dictionary = {}
var _pending_cargo_delivery_summary: Dictionary = {"count": 0, "total_reward": 0}

## Lifecycle/helper logic for `_ready`.
func _ready() -> void:
	event_bus = get_node("/root/EventBus")

	economy = EconomySystem.new()
	economy.setup(event_bus)
	add_child(economy)

	reputation = ReputationSystem.new()
	reputation.setup(event_bus)
	add_child(reputation)

	inventory = PlayerInventory.new()
	inventory.setup(event_bus, economy)
	add_child(inventory)

	_setup_default_train()

	fuel_system = FuelSystem.new()
	fuel_system.setup(event_bus, economy, train_config.get_locomotive())
	add_child(fuel_system)

	route = RouteData.load_ege_route()

	trip_planner = TripPlanner.new()
	trip_planner.setup(event_bus, economy, fuel_system, route)
	trip_planner.set_wagon_count(train_config.get_wagon_count())
	add_child(trip_planner)

	quest_system = load("res://src/systems/quest_system.gd").new()
	quest_system.setup(event_bus, economy, reputation)
	add_child(quest_system)

	random_event_system = load("res://src/systems/random_event_system.gd").new()
	random_event_system.setup(event_bus, economy, reputation)
	add_child(random_event_system)

	cargo_system = load("res://src/systems/cargo_system.gd").new()
	cargo_system.setup(event_bus, economy)
	add_child(cargo_system)

	_bind_events()
	_sync_cargo_capacity()
	_load_game_if_exists()

## Lifecycle/helper logic for `_bind_events`.
func _bind_events() -> void:
	if event_bus == null:
		return
	if not event_bus.trip_started.is_connected(_on_trip_started):
		event_bus.trip_started.connect(_on_trip_started)
	if not event_bus.trip_completed.is_connected(_on_trip_completed):
		event_bus.trip_completed.connect(_on_trip_completed)
	if not event_bus.station_arrived.is_connected(_on_station_arrived):
		event_bus.station_arrived.connect(_on_station_arrived)

## Lifecycle/helper logic for `_setup_default_train`.
func _setup_default_train() -> void:
	var locos := inventory.get_locomotives()
	if locos.size() > 0:
		var loco: LocomotiveData = locos[0]
		train_config = TrainConfig.new(loco)
		for wagon in inventory.get_available_wagons():
			if train_config.is_full():
				break
			train_config.add_wagon(wagon)
			inventory.mark_wagon_in_use(wagon)

## Handles `sync_trip_wagon_count`.
func sync_trip_wagon_count() -> void:
	if trip_planner != null and train_config != null:
		trip_planner.set_wagon_count(train_config.get_wagon_count())
	_sync_cargo_capacity()

## Lifecycle/helper logic for `_sync_cargo_capacity`.
func _sync_cargo_capacity() -> void:
	if cargo_system == null or train_config == null:
		return
	var cargo_capacity: int = 0
	for wagon in train_config.get_wagons():
		var w: WagonData = wagon
		if w.type == Constants.WagonType.CARGO:
			cargo_capacity += w.get_capacity()
	cargo_system.set_cargo_wagon_available(cargo_capacity > 0)
	cargo_system.set_cargo_capacity(cargo_capacity)

## Handles `record_station_result`.
func record_station_result(station_name: String, ticket_income: int, boarded: int, lost: int) -> void:
	_trip_station_breakdown.append({
		"station": station_name,
		"ticket_income": ticket_income,
		"boarded": boarded,
		"lost": lost,
	})
	_trip_passenger_count += boarded
	_trip_lost_count += maxi(0, lost)

## Lifecycle/helper logic for `_on_trip_started`.
func _on_trip_started(route_data: Dictionary) -> void:
	_trip_station_breakdown.clear()
	_trip_passenger_count = 0
	_trip_lost_count = 0
	_trip_start_reputation = reputation.get_stars()
	if random_event_system and bool(route_data.get("enable_random_events", false)):
		random_event_system.start_trip()
		var trip_event: Dictionary = random_event_system.try_trigger(Constants.RandomEventTrigger.ON_TRIP_START)
		if not trip_event.is_empty():
			fuel_system.set_price_multiplier(random_event_system.get_trip_fuel_multiplier())

## Lifecycle/helper logic for `_on_trip_completed`.
func _on_trip_completed(summary: Dictionary) -> void:
	var rep_delta := reputation.get_stars() - _trip_start_reputation
	var total_earned := int(summary.get("total_earned", 0))
	var earnings: Dictionary = summary.get("earnings", {})
	var fuel_cost: int = fuel_system.get_trip_consumed_cost()
	var total_spent: int = fuel_cost
	var net: int = total_earned - total_spent
	var quest_reward_money: int = 0
	var events: Array = []
	if quest_system:
		quest_reward_money = quest_system.consume_trip_reward_money()
	if random_event_system:
		events = random_event_system.get_event_history()
	if cargo_system:
		cargo_system.end_trip()

	last_trip_report = {
		"revenue": {
			"ticket_total": int(earnings.get("ticket", 0)),
			"cargo_total": int(earnings.get("cargo", 0)),
			"total": total_earned,
			"by_station": _trip_station_breakdown.duplicate(true),
		},
		"costs": {
			"fuel_total": fuel_cost,
			"total": total_spent,
		},
		"net_profit": net,
		"reputation_delta": rep_delta,
		"quest_reward_money": quest_reward_money,
		"event_history": events.duplicate(true),
		"stats": {
			"passengers_transported": _trip_passenger_count,
			"passengers_lost": _trip_lost_count,
			"stops_visited": _trip_station_breakdown.size(),
		},
	}

	total_trips += 1
	total_passengers += _trip_passenger_count
	total_lost_passengers += _trip_lost_count
	total_km += route.get_distance_between(trip_planner.get_start_index(), trip_planner.get_end_index())
	total_net_earnings += net

	fuel_system.reset_price_multiplier()
	save_game()

## Lifecycle/helper logic for `_on_station_arrived`.
func _on_station_arrived(station_id: String) -> void:
	if cargo_system:
		cargo_system.deliver_for_station(station_id)
		_pending_cargo_delivery_summary = cargo_system.consume_last_delivery_summary()
	if random_event_system:
		_pending_station_event = random_event_system.try_trigger(Constants.RandomEventTrigger.ON_STATION_ARRIVE)

## Handles `consume_pending_station_event`.
func consume_pending_station_event() -> Dictionary:
	var event_data: Dictionary = _pending_station_event.duplicate(true)
	_pending_station_event.clear()
	return event_data

## Handles `consume_pending_cargo_delivery_summary`.
func consume_pending_cargo_delivery_summary() -> Dictionary:
	var summary: Dictionary = _pending_cargo_delivery_summary.duplicate(true)
	_pending_cargo_delivery_summary = {"count": 0, "total_reward": 0}
	return summary

## Handles `get_last_trip_report`.
func get_last_trip_report() -> Dictionary:
	return last_trip_report.duplicate(true)

## Handles `has_tip_been_shown`.
func has_tip_been_shown(key: String) -> bool:
	return bool(shown_tips.get(key, false))

## Handles `mark_tip_shown`.
func mark_tip_shown(key: String) -> void:
	shown_tips[key] = true

## Handles `should_show_intro`.
func should_show_intro() -> bool:
	return not intro_completed

## Handles `mark_intro_completed`.
func mark_intro_completed() -> void:
	intro_completed = true
	save_game()

## Handles `save_game`.
func save_game() -> bool:
	var train_wagon_indices: Array = []
	for wagon in train_config.get_wagons():
		var idx := inventory.get_wagons().find(wagon)
		if idx >= 0:
			train_wagon_indices.append(idx)

	var data := {
		"version": 1,
		"economy": {
			"balance": economy.get_balance(),
		},
		"reputation": {
			"stars": reputation.get_stars(),
		},
		"inventory": {
			"locomotives": inventory.get_locomotive_ids(),
			"wagons": inventory.get_wagon_types(),
			"wagons_in_use": inventory.get_wagons_in_use_indices(),
		},
		"train": {
			"locomotive_id": train_config.get_locomotive().id,
			"wagon_indices": train_wagon_indices,
		},
		"fuel": {
			"current": fuel_system.get_current_fuel(),
		},
		"stats": {
			"total_trips": total_trips,
			"total_passengers": total_passengers,
			"total_lost_passengers": total_lost_passengers,
			"total_km": total_km,
			"total_net_earnings": total_net_earnings,
		},
		"tutorial": {
			"shown_tips": shown_tips,
			"intro_completed": intro_completed,
		},
		"quest_progress": quest_system.get_save_data() if quest_system else {},
		"active_cargos": cargo_system.get_save_data() if cargo_system else {},
		"event_history": random_event_system.get_save_data() if random_event_system else {},
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return true

## Lifecycle/helper logic for `_load_game_if_exists`.
func _load_game_if_exists() -> void:
	if not FileAccess.file_exists(SAVE_PATH):

		intro_completed = false
		shown_tips.clear()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var text := file.get_as_text()
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data: Dictionary = parsed
	economy.set_balance(int(data.get("economy", {}).get("balance", Balance.STARTING_MONEY)))
	reputation.set_reputation(float(data.get("reputation", {}).get("stars", Balance.REPUTATION_STARTING)))

	var inv_data: Dictionary = data.get("inventory", {})
	inventory.restore_inventory(
		inv_data.get("locomotives", ["kara_duman"]),
		inv_data.get("wagons", [Constants.WagonType.ECONOMY, Constants.WagonType.CARGO]),
		inv_data.get("wagons_in_use", [])
	)

	var train_data: Dictionary = data.get("train", {})
	var loco_id := str(train_data.get("locomotive_id", "kara_duman"))
	var loco := LocomotiveData.create(loco_id)
	if loco == null:
		var locos := inventory.get_locomotives()
		if locos.size() > 0:
			loco = locos[0]
		else:
			loco = LocomotiveData.create("kara_duman")

	train_config = TrainConfig.new(loco)
	inventory.restore_inventory(
		inventory.get_locomotive_ids(),
		inventory.get_wagon_types(),
		[]
	)
	for idx in train_data.get("wagon_indices", []):
		var i := int(idx)
		if i >= 0 and i < inventory.get_wagons().size():
			var wagon: WagonData = inventory.get_wagons()[i]
			if train_config.add_wagon(wagon):
				inventory.mark_wagon_in_use(wagon)

	fuel_system.setup(event_bus, economy, train_config.get_locomotive())
	var target_fuel := float(data.get("fuel", {}).get("current", fuel_system.get_tank_capacity()))
	target_fuel = clampf(target_fuel, 0.0, fuel_system.get_tank_capacity())
	fuel_system.consume(fuel_system.get_tank_capacity() - target_fuel)

	sync_trip_wagon_count()

	var stats: Dictionary = data.get("stats", {})
	total_trips = int(stats.get("total_trips", 0))
	total_passengers = int(stats.get("total_passengers", 0))
	total_lost_passengers = int(stats.get("total_lost_passengers", 0))
	total_km = float(stats.get("total_km", 0.0))
	total_net_earnings = int(stats.get("total_net_earnings", 0))

	var tutorial: Dictionary = data.get("tutorial", {})
	shown_tips = tutorial.get("shown_tips", {}).duplicate(true)
	intro_completed = bool(tutorial.get("intro_completed", true))

	var quest_data: Dictionary = data.get("quest_progress", {})
	if quest_system:
		quest_system.load_save_data(quest_data)

	var cargo_data: Dictionary = data.get("active_cargos", {})
	if cargo_system:
		cargo_system.load_save_data(cargo_data)

	var event_data: Dictionary = data.get("event_history", {})
	if random_event_system:
		random_event_system.load_save_data(event_data)
