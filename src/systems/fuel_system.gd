## Module: fuel_system.gd
## Restored English comments for maintainability and i18n coding standards.

class_name FuelSystem
extends Node

var _event_bus: Node
var _economy: EconomySystem
var _locomotive: LocomotiveData

var _current_fuel: float = 0.0
var _tank_capacity: float = 0.0
var _consumption_rate: float = 0.0
var _trip_consumed: float = 0.0
var _price_multiplier: float = 1.0

## Handles `setup`.
func setup(event_bus: Node, economy: EconomySystem, locomotive: LocomotiveData) -> void:
	_event_bus = event_bus
	_economy = economy
	_locomotive = locomotive
	_tank_capacity = locomotive.fuel_tank_capacity
	_consumption_rate = locomotive.fuel_consumption
	_current_fuel = _tank_capacity
	_price_multiplier = 1.0

## Handles `get_current_fuel`.
func get_current_fuel() -> float:
	return _current_fuel

## Handles `get_tank_capacity`.
func get_tank_capacity() -> float:
	return _tank_capacity

## Handles `get_consumption_rate`.
func get_consumption_rate() -> float:
	return _consumption_rate

## Handles `get_fuel_percentage`.
func get_fuel_percentage() -> float:
	if _tank_capacity <= 0.0:
		return 0.0
	return (_current_fuel / _tank_capacity) * 100.0

## Handles `is_fuel_low`.
func is_fuel_low() -> bool:
	return get_fuel_percentage() < Balance.FUEL_LOW_THRESHOLD

## Handles `is_fuel_critical`.
func is_fuel_critical() -> bool:
	return get_fuel_percentage() < Balance.FUEL_CRITICAL_THRESHOLD

## Handles `is_fuel_empty`.
func is_fuel_empty() -> bool:
	return _current_fuel <= 0.0

## Handles `begin_trip_tracking`.
func begin_trip_tracking() -> void:
	_trip_consumed = 0.0

## Handles `set_price_multiplier`.
func set_price_multiplier(multiplier: float) -> void:
	_price_multiplier = maxf(0.1, multiplier)

## Handles `reset_price_multiplier`.
func reset_price_multiplier() -> void:
	_price_multiplier = 1.0

## Handles `get_price_multiplier`.
func get_price_multiplier() -> float:
	return _price_multiplier

## Handles `get_trip_consumed`.
func get_trip_consumed() -> float:
	return _trip_consumed

## Handles `get_trip_consumed_cost`.
func get_trip_consumed_cost() -> int:
	return get_refuel_cost(_trip_consumed)

## Handles `calculate_fuel_cost`.
func calculate_fuel_cost(distance_km: float, wagon_count: int) -> float:
	var wagon_multiplier := 1.0 + (wagon_count * Balance.FUEL_PER_WAGON_MULTIPLIER)
	return distance_km * _consumption_rate * wagon_multiplier

## Handles `can_travel`.
func can_travel(distance_km: float, wagon_count: int) -> bool:
	return _current_fuel >= calculate_fuel_cost(distance_km, wagon_count)

## Handles `consume`.
func consume(amount: float) -> void:
	if amount <= 0.0:
		return
	var actual := minf(amount, _current_fuel)
	_current_fuel = maxf(0.0, _current_fuel - amount)
	_trip_consumed += actual

	if _event_bus:
		_event_bus.fuel_changed.emit(get_fuel_percentage())

		if is_fuel_empty():
			_event_bus.fuel_empty.emit(_locomotive.id if _locomotive else "")
		elif is_fuel_low():
			_event_bus.fuel_low.emit(
				_locomotive.id if _locomotive else "",
				get_fuel_percentage()
			)

## Handles `refuel_full`.
func refuel_full() -> void:
	_current_fuel = _tank_capacity

## Handles `refuel_amount`.
func refuel_amount(amount: float) -> void:
	_current_fuel = minf(_tank_capacity, _current_fuel + amount)

## Handles `auto_refuel`.
func auto_refuel() -> bool:
	var needed := _tank_capacity - _current_fuel
	if needed <= 0.0:
		return true

	var cost := get_refuel_cost(needed)
	if not _economy.can_afford(1):
		return false

	var max_spend := mini(cost, _economy.get_balance())
	if max_spend <= 0:
		return false

	var added := minf(needed, float(max_spend) / Balance.FUEL_UNIT_PRICE)
	var spent := mini(max_spend, get_refuel_cost(added))
	if spent <= 0:
		return false

	_economy.spend(spent, "yakit_ikmal")
	refuel_amount(added)
	return true

## Handles `get_refuel_cost`.
func get_refuel_cost(amount: float) -> int:
	if amount <= 0.0:
		return 0
	return ceili(amount * Balance.FUEL_UNIT_PRICE * _price_multiplier)

## Handles `get_full_refuel_cost`.
func get_full_refuel_cost() -> int:
	return get_refuel_cost(_tank_capacity - _current_fuel)

## Handles `buy_refuel`.
func buy_refuel(amount: float) -> bool:
	if amount <= 0.0:
		return true

	var actual_amount := minf(amount, _tank_capacity - _current_fuel)
	if actual_amount <= 0.0:
		return true

	var cost := get_refuel_cost(actual_amount)
	if not _economy.can_afford(cost):
		return false

	_economy.spend(cost, "yakit_ikmal")
	refuel_amount(actual_amount)
	return true

## Handles `ensure_fuel_for_trip`.
func ensure_fuel_for_trip(distance_km: float, wagon_count: int) -> Dictionary:
	var needed := maxf(0.0, calculate_fuel_cost(distance_km, wagon_count) - _current_fuel)
	if needed <= 0.0:
		return {
			"needed": 0.0,
			"added": 0.0,
			"spent": 0,
			"can_travel": true,
		}

	var max_spend := mini(get_refuel_cost(needed), _economy.get_balance())
	var added := minf(needed, float(max_spend) / Balance.FUEL_UNIT_PRICE)
	var spent := 0
	if added > 0.0:
		spent = mini(max_spend, get_refuel_cost(added))
		if _economy.spend(spent, "yakit_ikmal"):
			refuel_amount(added)
		else:
			added = 0.0
			spent = 0

	return {
		"needed": needed,
		"added": added,
		"spent": spent,
		"can_travel": can_travel(distance_km, wagon_count),
	}
