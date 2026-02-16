## Module: random_event_system.gd
## Handles random trip events with per-trip limits and temporary effects.

class_name RandomEventSystem
extends Node

var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem
var _events: Dictionary = {}
var _active_effects: Dictionary = {}
var _event_history: Array = []
var _triggered_types: Dictionary = {}
var _trip_event_count: int = 0
var _trip_fuel_multiplier: float = 1.0
var _roll_provider: Callable
var _durability_multiplier: float = 1.0
var _difficulty_breakdown_multiplier: float = 1.0

## Handles `setup`.
func setup(event_bus: Node, economy: EconomySystem, reputation: ReputationSystem) -> void:
	_event_bus = event_bus
	_economy = economy
	_reputation = reputation
	_setup_default_events()
	_roll_provider = func() -> float:
		return randf()
	_durability_multiplier = 1.0
	_difficulty_breakdown_multiplier = 1.0

func set_durability_multiplier(multiplier: float) -> void:
	_durability_multiplier = clampf(multiplier, 0.1, 1.0)

func set_difficulty_breakdown_multiplier(multiplier: float) -> void:
	_difficulty_breakdown_multiplier = clampf(multiplier, Balance.DIFFICULTY_CLAMP_MIN, Balance.DIFFICULTY_CLAMP_MAX)

## Lifecycle/helper logic for `_setup_default_events`.
func _setup_default_events() -> void:
	_events = {
		"evt_motor": {
			"id": "evt_motor",
			"type": Constants.RandomEventType.TECHNICAL,
			"title_key": "event.evt_motor.title",
			"description_key": "event.evt_motor.description",
			"trigger": Constants.RandomEventTrigger.ON_TRAVEL,
			"probability": Balance.RANDOM_EVENT_MOTOR_PROBABILITY,
			"effect": {"speed_multiplier": Balance.EVENT_SPEED_MULTIPLIER_MOTOR},
		},
		"evt_door": {
			"id": "evt_door",
			"type": Constants.RandomEventType.TECHNICAL,
			"title_key": "event.evt_door.title",
			"description_key": "event.evt_door.description",
			"trigger": Constants.RandomEventTrigger.ON_STATION_ARRIVE,
			"probability": Balance.RANDOM_EVENT_DOOR_PROBABILITY,
			"effect": {"station_time_delta": Balance.EVENT_STATION_TIME_DELTA_DOOR},
		},
		"evt_vip": {
			"id": "evt_vip",
			"type": Constants.RandomEventType.PASSENGER,
			"title_key": "event.evt_vip.title",
			"description_key": "event.evt_vip.description",
			"trigger": Constants.RandomEventTrigger.ON_STATION_ARRIVE,
			"probability": Balance.RANDOM_EVENT_VIP_PROBABILITY,
			"effect": {"extra_vip": Balance.EVENT_VIP_EXTRA_COUNT},
		},
		"evt_sick": {
			"id": "evt_sick",
			"type": Constants.RandomEventType.PASSENGER,
			"title_key": "event.evt_sick.title",
			"description_key": "event.evt_sick.description",
			"trigger": Constants.RandomEventTrigger.ON_STATION_ARRIVE,
			"probability": Balance.RANDOM_EVENT_SICK_PROBABILITY,
			"effect": {"reputation_bonus": Balance.EVENT_REPUTATION_SICK_BONUS},
		},
		"evt_fuel_hike": {
			"id": "evt_fuel_hike",
			"type": Constants.RandomEventType.ECONOMIC,
			"title_key": "event.evt_fuel_hike.title",
			"description_key": "event.evt_fuel_hike.description",
			"trigger": Constants.RandomEventTrigger.ON_TRIP_START,
			"probability": Balance.RANDOM_EVENT_FUEL_HIKE_PROBABILITY,
			"effect": {"fuel_price_multiplier": Balance.EVENT_FUEL_PRICE_MULTIPLIER_HIKE},
		},
		"evt_festival": {
			"id": "evt_festival",
			"type": Constants.RandomEventType.PASSENGER,
			"title_key": "event.evt_festival.title",
			"description_key": "event.evt_festival.description",
			"trigger": Constants.RandomEventTrigger.ON_STATION_ARRIVE,
			"probability": Balance.RANDOM_EVENT_FESTIVAL_PROBABILITY,
			"effect": {"passenger_multiplier": Balance.EVENT_PASSENGER_MULTIPLIER_FESTIVAL},
		},
	}

## Handles `start_trip`.
func start_trip() -> void:
	_trip_event_count = 0
	_event_history.clear()
	_active_effects.clear()
	_triggered_types.clear()
	_trip_fuel_multiplier = 1.0

## Handles `try_trigger`.
func try_trigger(trigger: int) -> Dictionary:
	if _trip_event_count >= Balance.RANDOM_EVENT_MAX_PER_TRIP:
		return {}

	var candidates: Array = _candidate_ids_for_trigger(trigger)
	for event_id in candidates:
		if not _events.has(event_id):
			continue
		var event_data: Dictionary = _events[event_id]
		if not _can_trigger_event(event_data):
			continue
		var probability: float = float(event_data.get("probability", 0.0))
		if int(event_data.get("type", -1)) == Constants.RandomEventType.TECHNICAL:
			probability *= _durability_multiplier
			probability *= _difficulty_breakdown_multiplier
			probability = clampf(probability, 0.0, 1.0)
		if _roll() < probability:
			return _apply_event(event_data)
	return {}

## Handles `force_trigger`.
func force_trigger(event_id: String) -> Dictionary:
	if not _events.has(event_id):
		return {}
	if _trip_event_count >= Balance.RANDOM_EVENT_MAX_PER_TRIP:
		return {}
	var event_data: Dictionary = _events[event_id]
	if not _can_trigger_event(event_data):
		return {}
	return _apply_event(event_data)

## Handles `set_event_probability`.
func set_event_probability(event_id: String, probability: float) -> void:
	if not _events.has(event_id):
		return
	var event_data: Dictionary = _events[event_id]
	event_data["probability"] = clampf(probability, 0.0, 1.0)
	_events[event_id] = event_data

## Handles `set_roll_provider`.
func set_roll_provider(provider: Callable) -> void:
	_roll_provider = provider

## Handles `get_active_effect`.
func get_active_effect(key: String, default_value: Variant) -> Variant:
	return _active_effects.get(key, default_value)

## Handles `consume_station_time_delta`.
func consume_station_time_delta() -> float:
	var value: float = float(_active_effects.get("station_time_delta", 0.0))
	_active_effects.erase("station_time_delta")
	return value

## Handles `consume_extra_vip`.
func consume_extra_vip() -> int:
	var value: int = int(_active_effects.get("extra_vip", 0))
	_active_effects.erase("extra_vip")
	return value

## Handles `consume_passenger_multiplier`.
func consume_passenger_multiplier() -> float:
	var value: float = float(_active_effects.get("passenger_multiplier", 1.0))
	_active_effects.erase("passenger_multiplier")
	return value

## Handles `consume_reputation_bonus`.
func consume_reputation_bonus() -> float:
	var value: float = float(_active_effects.get("reputation_bonus", 0.0))
	_active_effects.erase("reputation_bonus")
	return value

## Handles `consume_speed_multiplier`.
func consume_speed_multiplier() -> float:
	var value: float = float(_active_effects.get("speed_multiplier", 1.0))
	_active_effects.erase("speed_multiplier")
	return value

## Handles `get_trip_fuel_multiplier`.
func get_trip_fuel_multiplier() -> float:
	return _trip_fuel_multiplier

## Handles `get_event_history`.
func get_event_history() -> Array:
	return _event_history.duplicate(true)

## Handles `get_save_data`.
func get_save_data() -> Dictionary:
	return {
		"event_history": _event_history.duplicate(true),
	}

## Handles `load_save_data`.
func load_save_data(data: Dictionary) -> void:
	_event_history = data.get("event_history", []).duplicate(true)

## Lifecycle/helper logic for `_can_trigger_event`.
func _can_trigger_event(event_data: Dictionary) -> bool:
	var type_id: int = int(event_data.get("type", -1))
	return not _triggered_types.has(type_id)

## Lifecycle/helper logic for `_apply_event`.
func _apply_event(event_data: Dictionary) -> Dictionary:
	_trip_event_count += 1
	var event_id: String = str(event_data.get("id", ""))
	var type_id: int = int(event_data.get("type", -1))
	_triggered_types[type_id] = true
	_event_history.append(event_id)

	var effect: Dictionary = event_data.get("effect", {})
	for key in effect.keys():
		_active_effects[key] = effect[key]

	if effect.has("fuel_price_multiplier"):
		_trip_fuel_multiplier = float(effect.get("fuel_price_multiplier", 1.0))

	if _event_bus:
		_event_bus.random_event_triggered.emit(event_data.duplicate(true))

	return event_data.duplicate(true)

## Lifecycle/helper logic for `_roll`.
func _roll() -> float:
	if _roll_provider.is_valid():
		return clampf(float(_roll_provider.call()), 0.0, 1.0)
	return randf()

## Lifecycle/helper logic for `_candidate_ids_for_trigger`.
func _candidate_ids_for_trigger(trigger: int) -> Array:
	match trigger:
		Constants.RandomEventTrigger.ON_TRAVEL:
			return ["evt_motor"]
		Constants.RandomEventTrigger.ON_STATION_ARRIVE:
			return ["evt_door", "evt_vip", "evt_sick", "evt_festival"]
		Constants.RandomEventTrigger.ON_TRIP_START:
			return ["evt_fuel_hike"]
		_:
			return []
