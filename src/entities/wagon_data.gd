## Module: wagon_data.gd
## Restored English comments for maintainability and i18n coding standards.

class_name WagonData
extends RefCounted

var type: Constants.WagonType
var _passengers: Array[Dictionary] = []
var _capacity: int

## Lifecycle/helper logic for `_init`.
func _init(wagon_type: Constants.WagonType) -> void:
	type = wagon_type
	_capacity = _get_capacity_for_type(wagon_type)

## Handles `get_capacity`.
func get_capacity() -> int:
	return _capacity

## Handles `get_passenger_count`.
func get_passenger_count() -> int:
	return _passengers.size()

## Handles `is_full`.
func is_full() -> bool:
	return _passengers.size() >= _capacity

## Handles `can_accept`.
func can_accept(passenger: Dictionary) -> bool:
	if is_full():
		return false
	return _is_type_compatible(passenger["type"])

## Handles `add_passenger`.
func add_passenger(passenger: Dictionary) -> bool:
	if not can_accept(passenger):
		return false
	_passengers.append(passenger)
	return true

## Handles `remove_passenger`.
func remove_passenger(passenger_id: String) -> bool:
	for i in _passengers.size():
		if _passengers[i]["id"] == passenger_id:
			_passengers.remove_at(i)
			return true
	return false

## Handles `get_passengers_for_destination`.
func get_passengers_for_destination(destination: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for p in _passengers:
		if p["destination"] == destination:
			result.append(p)
	return result

## Handles `get_all_passengers`.
func get_all_passengers() -> Array[Dictionary]:
	return _passengers.duplicate()

## Lifecycle/helper logic for `_is_type_compatible`.
func _is_type_compatible(passenger_type: Constants.PassengerType) -> bool:

	if type == Constants.WagonType.CARGO or type == Constants.WagonType.DINING:
		return false

	if passenger_type == Constants.PassengerType.VIP:
		return type == Constants.WagonType.VIP or type == Constants.WagonType.BUSINESS

	return true

static func _get_capacity_for_type(wagon_type: Constants.WagonType) -> int:
	match wagon_type:
		Constants.WagonType.ECONOMY:
			return Constants.CAPACITY_ECONOMY
		Constants.WagonType.BUSINESS:
			return Constants.CAPACITY_BUSINESS
		Constants.WagonType.VIP:
			return Constants.CAPACITY_VIP
		Constants.WagonType.CARGO:
			return Constants.CAPACITY_CARGO
		_:
			return 0
