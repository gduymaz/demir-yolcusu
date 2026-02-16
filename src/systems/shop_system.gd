## Module: shop_system.gd
## Handles station shop opening, upgrades, passive income, and station modifiers.

class_name ShopSystem
extends Node

var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem
var _shops_by_station: Dictionary = {}

func setup(event_bus: Node, economy: EconomySystem, reputation: ReputationSystem) -> void:
	_event_bus = event_bus
	_economy = economy
	_reputation = reputation

func open_shop(station_id: String, shop_type: int) -> bool:
	var station_key: String = _normalize_station(station_id)
	var station_shops: Dictionary = _shops_by_station.get(station_key, {})
	if station_shops.has(str(shop_type)):
		return false
	if station_shops.size() >= _get_slot_limit_for_station(station_key):
		return false
	if not _can_afford_shop_level(1):
		return false
	if not _reputation.meets_requirement(_get_shop_rep_requirement(1)):
		return false

	if not _economy.spend(_get_shop_cost(1), "shop_open"):
		return false

	station_shops[str(shop_type)] = 1
	_shops_by_station[station_key] = station_shops
	if _event_bus:
		_event_bus.shop_opened.emit(station_key, shop_type)
	return true

func upgrade_shop(station_id: String, shop_type: int) -> bool:
	var station_key: String = _normalize_station(station_id)
	var station_shops: Dictionary = _shops_by_station.get(station_key, {})
	var key: String = str(shop_type)
	if not station_shops.has(key):
		return false
	var current_level: int = int(station_shops.get(key, 0))
	if current_level >= Balance.SHOP_MAX_LEVEL:
		return false

	var next_level: int = current_level + 1
	if not _can_afford_shop_level(next_level):
		return false
	if not _reputation.meets_requirement(_get_shop_rep_requirement(next_level)):
		return false
	if not _economy.spend(_get_shop_cost(next_level), "shop_upgrade"):
		return false

	station_shops[key] = next_level
	_shops_by_station[station_key] = station_shops
	if _event_bus:
		_event_bus.shop_upgraded.emit(station_key, shop_type, next_level)
	return true

func get_trip_income(visited_stations: Array) -> int:
	var income: int = 0
	var seen: Dictionary = {}
	for station in visited_stations:
		var key: String = _normalize_station(str(station))
		if seen.get(key, false):
			continue
		seen[key] = true
		var station_shops: Dictionary = _shops_by_station.get(key, {})
		for shop_type_key in station_shops.keys():
			var shop_type: int = int(shop_type_key)
			var level: int = int(station_shops.get(shop_type_key, 0))
			income += _get_income_for_shop(shop_type, level)
	if income > 0 and _event_bus:
		_event_bus.shop_income_earned.emit(income, visited_stations)
	return income

func get_station_shops(station_id: String) -> Array:
	var station_key: String = _normalize_station(station_id)
	var out: Array = []
	var station_shops: Dictionary = _shops_by_station.get(station_key, {})
	for shop_type_key in station_shops.keys():
		out.append({
			"shop_type": int(shop_type_key),
			"level": int(station_shops.get(shop_type_key, 0)),
			"income_per_trip": _get_income_for_shop(int(shop_type_key), int(station_shops.get(shop_type_key, 0))),
		})
	return out

func get_station_shop_level(station_id: String, shop_type: int) -> int:
	var station_key: String = _normalize_station(station_id)
	var station_shops: Dictionary = _shops_by_station.get(station_key, {})
	return int(station_shops.get(str(shop_type), 0))

func get_cargo_offer_bonus(station_id: String) -> int:
	var level: int = get_station_shop_level(station_id, Constants.ShopType.CARGO_DEPOT)
	return level

func get_patience_multiplier(station_id: String) -> float:
	var level: int = get_station_shop_level(station_id, Constants.ShopType.BUFFET)
	var reduce: float = Balance.SHOP_BUFFET_PATIENCE_REDUCTION_PER_LEVEL * float(level)
	return maxf(0.5, 1.0 - reduce)

func get_save_data() -> Dictionary:
	return {
		"shops": _shops_by_station.duplicate(true),
	}

func load_save_data(data: Dictionary) -> void:
	var shops: Variant = data.get("shops", {})
	if typeof(shops) == TYPE_DICTIONARY:
		_shops_by_station = (shops as Dictionary).duplicate(true)
	else:
		_shops_by_station = {}

func _get_income_for_shop(shop_type: int, level: int) -> int:
	if level <= 0:
		return 0
	match shop_type:
		Constants.ShopType.BUFFET:
			match level:
				1:
					return Balance.SHOP_BUFFET_INCOME_L1
				2:
					return Balance.SHOP_BUFFET_INCOME_L2
				3:
					return Balance.SHOP_BUFFET_INCOME_L3
		Constants.ShopType.SOUVENIR:
			match level:
				1:
					return Balance.SHOP_SOUVENIR_INCOME_L1
				2:
					return Balance.SHOP_SOUVENIR_INCOME_L2
				3:
					return Balance.SHOP_SOUVENIR_INCOME_L3
		Constants.ShopType.CARGO_DEPOT:
			return 0
		_:
			return 0
	return 0

func _get_shop_cost(level: int) -> int:
	match level:
		1:
			return Balance.SHOP_COST_L1
		2:
			return Balance.SHOP_COST_L2
		3:
			return Balance.SHOP_COST_L3
		_:
			return Balance.SHOP_COST_L3

func _get_shop_rep_requirement(level: int) -> float:
	match level:
		1:
			return Balance.SHOP_REPUTATION_L1
		2:
			return Balance.SHOP_REPUTATION_L2
		3:
			return Balance.SHOP_REPUTATION_L3
		_:
			return Balance.SHOP_REPUTATION_L3

func _can_afford_shop_level(level: int) -> bool:
	return _economy.can_afford(_get_shop_cost(level))

func _get_slot_limit_for_station(station_id: String) -> int:
	if Balance.SHOP_BIG_STATION_IDS.has(station_id):
		return Balance.SHOP_SLOT_BIG_STATION
	return Balance.SHOP_SLOT_SMALL_STATION

func _normalize_station(name: String) -> String:
	return name.to_upper().replace("(", " ").replace(")", " ").replace("  ", " ").strip_edges()
