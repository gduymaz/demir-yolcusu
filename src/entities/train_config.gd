## Module: train_config.gd
## Restored English comments for maintainability and i18n coding standards.

class_name TrainConfig
extends RefCounted

var _locomotive: LocomotiveData
var _wagons: Array = []

## Lifecycle/helper logic for `_init`.
func _init(locomotive: LocomotiveData) -> void:
	_locomotive = locomotive

## Handles `get_locomotive`.
func get_locomotive() -> LocomotiveData:
	return _locomotive

## Handles `set_locomotive`.
func set_locomotive(locomotive: LocomotiveData) -> void:
	_locomotive = locomotive
	if _wagons.size() > _locomotive.max_wagons:
		_wagons.resize(_locomotive.max_wagons)

## Handles `get_wagons`.
func get_wagons() -> Array:
	return _wagons

## Handles `get_wagon_count`.
func get_wagon_count() -> int:
	return _wagons.size()

## Handles `get_max_wagons`.
func get_max_wagons() -> int:
	return _locomotive.max_wagons

## Handles `is_full`.
func is_full() -> bool:
	return _wagons.size() >= _locomotive.max_wagons

## Handles `add_wagon`.
func add_wagon(wagon: WagonData) -> bool:
	if is_full():
		return false
	_wagons.append(wagon)
	return true

## Handles `remove_wagon_at`.
func remove_wagon_at(index: int) -> WagonData:
	if index < 0 or index >= _wagons.size():
		return null
	var wagon: WagonData = _wagons[index]
	_wagons.remove_at(index)
	return wagon

## Handles `swap_wagons`.
func swap_wagons(index_a: int, index_b: int) -> bool:
	if index_a < 0 or index_a >= _wagons.size():
		return false
	if index_b < 0 or index_b >= _wagons.size():
		return false
	var temp: WagonData = _wagons[index_a]
	_wagons[index_a] = _wagons[index_b]
	_wagons[index_b] = temp
	return true

## Handles `get_total_passenger_capacity`.
func get_total_passenger_capacity() -> int:
	var total := 0
	for wagon in _wagons:
		var w: WagonData = wagon
		if w.type != Constants.WagonType.CARGO and w.type != Constants.WagonType.DINING:
			total += w.get_capacity()
	return total

## Handles `get_total_weight`.
func get_total_weight() -> float:
	return _wagons.size() * Balance.WAGON_WEIGHT
