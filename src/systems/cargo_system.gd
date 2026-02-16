## Module: cargo_system.gd
## Handles cargo offers, loading, delivery, deadlines, and persistence.

class_name CargoSystem
extends Node

var _event_bus: Node
var _economy: EconomySystem

var _cargo_wagon_available: bool = false
var _cargo_capacity: int = 0
var _offer_seq: int = 0

var _offer_pool: Array = []
var _current_offers: Array = []
var _loaded_cargos: Array = []
var _last_delivery_summary: Dictionary = {"count": 0, "total_reward": 0}

var _roll_provider: Callable

## Handles `setup`.
func setup(event_bus: Node, economy: EconomySystem) -> void:
	_event_bus = event_bus
	_economy = economy
	_setup_default_pool()
	_roll_provider = func() -> float:
		return randf()

## Lifecycle/helper logic for `_setup_default_pool`.
func _setup_default_pool() -> void:
	_offer_pool = [
		{"name": "elektronik_parca", "origin_station": "IZMIR", "destination_station": "DENIZLI", "reward": 80, "weight": 1, "deadline_trips": 3},
		{"name": "zeytin_yagi", "origin_station": "SELCUK", "destination_station": "IZMIR (BASMANE)", "reward": 60, "weight": 1, "deadline_trips": 2},
		{"name": "incir_kutusu", "origin_station": "AYDIN", "destination_station": "IZMIR (BASMANE)", "reward": 50, "weight": 1, "deadline_trips": 2},
		{"name": "tekstil_balya", "origin_station": "DENIZLI", "destination_station": "AYDIN", "reward": 70, "weight": 1, "deadline_trips": 2},
		{"name": "tarim_malzeme", "origin_station": "TORBALI", "destination_station": "NAZILLI", "reward": 40, "weight": 1, "deadline_trips": 3},
		{"name": "pamuk_balya", "origin_station": "NAZILLI", "destination_station": "SELCUK", "reward": 45, "weight": 1, "deadline_trips": 2},
		{"name": "makine_yedek_parca", "origin_station": "IZMIR", "destination_station": "AYDIN", "reward": 55, "weight": 1, "deadline_trips": 2},
	]

## Handles `set_roll_provider`.
func set_roll_provider(provider: Callable) -> void:
	_roll_provider = provider

## Handles `set_cargo_wagon_available`.
func set_cargo_wagon_available(value: bool) -> void:
	_cargo_wagon_available = value

## Handles `set_cargo_capacity`.
func set_cargo_capacity(value: int) -> void:
	_cargo_capacity = maxi(0, value)

## Handles `get_current_offers`.
func get_current_offers() -> Array:
	return _current_offers.duplicate(true)

## Handles `get_loaded_cargos`.
func get_loaded_cargos() -> Array:
	return _loaded_cargos.duplicate(true)

## Handles `get_loaded_weight`.
func get_loaded_weight() -> int:
	var total: int = 0
	for cargo in _loaded_cargos:
		total += int(cargo.get("weight", 0))
	return total

## Handles `get_available_capacity`.
func get_available_capacity() -> int:
	return maxi(0, _cargo_capacity - get_loaded_weight())

## Handles `has_capacity_for`.
func has_capacity_for(weight: int) -> bool:
	return get_available_capacity() >= weight

## Handles `is_cargo_wagon_available`.
func is_cargo_wagon_available() -> bool:
	return _cargo_wagon_available

## Handles `has_offers_for_station`.
func has_offers_for_station(station_name: String) -> bool:
	var origin_key: String = _normalize_station(station_name)
	for item in _offer_pool:
		var offer_data: Dictionary = item
		if _normalize_station(str(offer_data.get("origin_station", ""))).find(origin_key) >= 0:
			return true
	return false

## Handles `get_forced_offer_for_quest`.
func get_forced_offer_for_quest(quest_id: String) -> Dictionary:
	if quest_id != "ege_03":
		return {}
	return {
		"name": "zeytin_yagi",
		"origin_station": "AYDIN",
		"destination_station": "IZMIR (BASMANE)",
		"reward": 60,
		"weight": 1,
		"deadline_trips": 2,
	}

## Handles `generate_offers`.
func generate_offers(station_name: String, guaranteed_offer: Dictionary = {}) -> Array:
	_current_offers.clear()
	var origin_key: String = _normalize_station(station_name)
	var candidates: Array = []
	for item in _offer_pool:
		var offer_data: Dictionary = item
		if _normalize_station(str(offer_data.get("origin_station", ""))).find(origin_key) >= 0:
			candidates.append(offer_data)

	if not guaranteed_offer.is_empty():
		_current_offers.append(_build_offer(guaranteed_offer))

	var target_count: int = Balance.CARGO_OFFERS_MIN_PER_STATION + int(floor(_roll() * float(Balance.CARGO_OFFERS_MAX_PER_STATION + 1)))
	target_count = clampi(target_count, Balance.CARGO_OFFERS_MIN_PER_STATION, Balance.CARGO_OFFERS_MAX_PER_STATION)

	while _current_offers.size() < target_count and not candidates.is_empty():
		var index: int = int(floor(_roll() * candidates.size()))
		index = clampi(index, 0, candidates.size() - 1)
		var next_offer: Dictionary = candidates[index]
		candidates.remove_at(index)
		_current_offers.append(_build_offer(next_offer))

	return get_current_offers()

## Handles `inject_offer`.
func inject_offer(cargo_data: Dictionary) -> String:
	var offer: Dictionary = _build_offer(cargo_data)
	_current_offers.append(offer)
	return str(offer.get("id", ""))

## Handles `load_offer`.
func load_offer(cargo_id: String) -> bool:
	if not _cargo_wagon_available:
		return false
	var index: int = _find_offer_index(cargo_id)
	if index < 0:
		return false
	var offer: Dictionary = _current_offers[index]
	var weight: int = int(offer.get("weight", 1))
	if not has_capacity_for(weight):
		return false

	offer["status"] = Constants.CargoStatus.LOADED
	offer["remaining_trips"] = int(offer.get("deadline_trips", 1))
	_current_offers.remove_at(index)
	_loaded_cargos.append(offer)
	if _event_bus:
		_event_bus.cargo_loaded.emit(offer.duplicate(true))
	return true

## Handles `deliver_for_station`.
func deliver_for_station(station_id: String) -> int:
	var delivered_count: int = 0
	var total_reward: int = 0
	for i in range(_loaded_cargos.size() - 1, -1, -1):
		var cargo: Dictionary = _loaded_cargos[i]
		if _normalize_station(station_id).find(_normalize_station(str(cargo.get("destination_station", "")))) < 0:
			continue
		_loaded_cargos.remove_at(i)
		cargo["status"] = Constants.CargoStatus.DELIVERED
		delivered_count += 1
		var reward: int = int(cargo.get("reward", 0))
		total_reward += reward
		_economy.earn(reward, "cargo")
		if _event_bus:
			_event_bus.cargo_delivered.emit(cargo.duplicate(true), station_id)
	_last_delivery_summary = {
		"count": delivered_count,
		"total_reward": total_reward,
	}
	return delivered_count

## Handles `end_trip`.
func end_trip() -> void:
	for i in range(_loaded_cargos.size() - 1, -1, -1):
		var cargo: Dictionary = _loaded_cargos[i]
		var remaining: int = int(cargo.get("remaining_trips", cargo.get("deadline_trips", 1))) - 1
		cargo["remaining_trips"] = remaining
		if remaining <= 0:
			_loaded_cargos.remove_at(i)
			cargo["status"] = Constants.CargoStatus.EXPIRED
			if _event_bus:
				_event_bus.cargo_expired.emit(cargo.duplicate(true))
		else:
			_loaded_cargos[i] = cargo

## Handles `get_save_data`.
func get_save_data() -> Dictionary:
	return {
		"offer_seq": _offer_seq,
		"current_offers": _current_offers.duplicate(true),
		"loaded_cargos": _loaded_cargos.duplicate(true),
	}

## Handles `load_save_data`.
func load_save_data(data: Dictionary) -> void:
	_offer_seq = int(data.get("offer_seq", 0))
	_current_offers = data.get("current_offers", []).duplicate(true)
	_loaded_cargos = data.get("loaded_cargos", []).duplicate(true)
	_last_delivery_summary = {"count": 0, "total_reward": 0}

## Handles `consume_last_delivery_summary`.
func consume_last_delivery_summary() -> Dictionary:
	var summary: Dictionary = _last_delivery_summary.duplicate(true)
	_last_delivery_summary = {"count": 0, "total_reward": 0}
	return summary

## Lifecycle/helper logic for `_build_offer`.
func _build_offer(cargo_data: Dictionary) -> Dictionary:
	_offer_seq += 1
	var offer: Dictionary = cargo_data.duplicate(true)
	offer["id"] = "cargo_%d" % _offer_seq
	offer["status"] = Constants.CargoStatus.AVAILABLE
	offer["remaining_trips"] = int(offer.get("deadline_trips", 1))
	return offer

## Lifecycle/helper logic for `_find_offer_index`.
func _find_offer_index(cargo_id: String) -> int:
	for i in _current_offers.size():
		if str(_current_offers[i].get("id", "")) == cargo_id:
			return i
	return -1

## Lifecycle/helper logic for `_normalize_station`.
func _normalize_station(name: String) -> String:
	return name.to_lower().replace("(", " ").replace(")", " ").replace("-", " ")

## Lifecycle/helper logic for `_roll`.
func _roll() -> float:
	if _roll_provider.is_valid():
		return clampf(float(_roll_provider.call()), 0.0, 0.9999)
	return randf()
