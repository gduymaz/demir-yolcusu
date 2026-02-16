## Module: wagon_data.gd
## Restored English comments for maintainability and i18n coding standards.

class_name WagonData
extends RefCounted

static var _next_id: int = 1

var id: String
var type: Constants.WagonType
var _passengers: Array[Dictionary] = []
var _base_capacity: int
var _extra_capacity: int = 0

## Lifecycle/helper logic for `_init`.
func _init(wagon_type: Constants.WagonType) -> void:
	id = "wagon_%d" % _next_id
	_next_id += 1
	type = wagon_type
	_base_capacity = _get_capacity_for_type(wagon_type)

func set_persistent_id(value: String) -> void:
	id = value
	if value.begins_with("wagon_"):
		var suffix: String = value.trim_prefix("wagon_")
		if suffix.is_valid_int():
			_next_id = maxi(_next_id, int(suffix) + 1)

## Handles `get_capacity`.
func get_capacity() -> int:
	return _base_capacity + _extra_capacity

func set_extra_capacity(value: int) -> void:
	_extra_capacity = maxi(0, value)

func get_extra_capacity() -> int:
	return _extra_capacity

func get_base_capacity() -> int:
	return _base_capacity

## Handles `get_passenger_count`.
func get_passenger_count() -> int:
	return _passengers.size()

## Handles `is_full`.
func is_full() -> bool:
	return _passengers.size() >= get_capacity()

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
