## Module: player_inventory.gd
## Restored English comments for maintainability and i18n coding standards.

class_name PlayerInventory
extends Node

var _event_bus: Node
var _economy: EconomySystem
var _locomotives: Array = []
var _wagons: Array = []
var _wagons_in_use: Array = []

## Handles `setup`.
func setup(event_bus: Node, economy: EconomySystem) -> void:
	_event_bus = event_bus
	_economy = economy
	_create_starting_inventory()

## Lifecycle/helper logic for `_create_starting_inventory`.
func _create_starting_inventory() -> void:

	_locomotives.append(LocomotiveData.create("kara_duman"))

	_wagons.append(WagonData.new(Constants.WagonType.ECONOMY))
	_wagons.append(WagonData.new(Constants.WagonType.CARGO))

## Handles `get_locomotives`.
func get_locomotives() -> Array:
	return _locomotives

## Handles `add_locomotive`.
func add_locomotive(locomotive: LocomotiveData) -> void:
	_locomotives.append(locomotive)

func buy_locomotive(loco_id: String, required_reputation: float, reputation: ReputationSystem) -> bool:
	if has_locomotive(loco_id):
		return false
	if reputation != null and not reputation.meets_requirement(required_reputation):
		return false
	var loco := LocomotiveData.create(loco_id)
	if loco == null:
		return false
	if not _economy.can_afford(loco.base_cost):
		return false
	if not _economy.spend(loco.base_cost, "locomotive_purchase"):
		return false
	_locomotives.append(loco)
	return true

## Handles `has_locomotive`.
func has_locomotive(loco_id: String) -> bool:
	for loco in _locomotives:
		var l: LocomotiveData = loco
		if l.id == loco_id:
			return true
	return false

## Handles `get_wagons`.
func get_wagons() -> Array:
	return _wagons

## Handles `add_wagon`.
func add_wagon(wagon: WagonData) -> void:
	_wagons.append(wagon)

## Handles `remove_wagon`.
func remove_wagon(index: int) -> WagonData:
	if index < 0 or index >= _wagons.size():
		return null
	var wagon: WagonData = _wagons[index]
	_wagons.remove_at(index)
	return wagon

## Handles `buy_wagon`.
func buy_wagon(wagon_type: Constants.WagonType) -> bool:
	return buy_wagon_with_requirement(wagon_type, 0.0, null)

func buy_wagon_with_requirement(wagon_type: Constants.WagonType, required_reputation: float, reputation: ReputationSystem) -> bool:
	if reputation != null and not reputation.meets_requirement(required_reputation):
		return false
	var price := get_wagon_price(wagon_type)
	if not _economy.can_afford(price):
		return false
	_economy.spend(price, "wagon_purchase")
	_wagons.append(WagonData.new(wagon_type))
	return true

static func get_wagon_price(wagon_type: Constants.WagonType) -> int:
	match wagon_type:
		Constants.WagonType.ECONOMY:
			return Balance.WAGON_COST_ECONOMY
		Constants.WagonType.BUSINESS:
			return Balance.WAGON_COST_BUSINESS
		Constants.WagonType.VIP:
			return Balance.WAGON_COST_VIP
		Constants.WagonType.DINING:
			return Balance.WAGON_COST_DINING
		Constants.WagonType.CARGO:
			return Balance.WAGON_COST_CARGO
		_:
			return 0

## Handles `get_available_wagons`.
func get_available_wagons() -> Array:
	var available: Array = []
	for wagon in _wagons:
		if not _wagons_in_use.has(wagon):
			available.append(wagon)
	return available

## Handles `mark_wagon_in_use`.
func mark_wagon_in_use(wagon: WagonData) -> void:
	if not _wagons_in_use.has(wagon):
		_wagons_in_use.append(wagon)

## Handles `unmark_wagon_in_use`.
func unmark_wagon_in_use(wagon: WagonData) -> void:
	_wagons_in_use.erase(wagon)

## Handles `get_locomotive_ids`.
func get_locomotive_ids() -> Array:
	var result: Array = []
	for loco in _locomotives:
		result.append((loco as LocomotiveData).id)
	return result

## Handles `get_wagon_types`.
func get_wagon_types() -> Array:
	var result: Array = []
	for wagon in _wagons:
		result.append((wagon as WagonData).type)
	return result

## Handles `get_wagons_in_use_indices`.
func get_wagons_in_use_indices() -> Array:
	var indices: Array = []
	for wagon in _wagons_in_use:
		var idx := _wagons.find(wagon)
		if idx >= 0:
			indices.append(idx)
	return indices

## Handles `restore_inventory`.
func restore_inventory(locomotive_ids: Array, wagon_types: Array, in_use_indices: Array) -> void:
	restore_inventory_with_ids(locomotive_ids, wagon_types, in_use_indices, [])

func restore_inventory_with_ids(locomotive_ids: Array, wagon_types: Array, in_use_indices: Array, wagon_ids: Array) -> void:
	_locomotives.clear()
	_wagons.clear()
	_wagons_in_use.clear()

	for loco_id in locomotive_ids:
		var loco := LocomotiveData.create(str(loco_id))
		if loco != null:
			_locomotives.append(loco)

	for i in range(wagon_types.size()):
		var wagon := WagonData.new(int(wagon_types[i]))
		if i < wagon_ids.size():
			wagon.set_persistent_id(str(wagon_ids[i]))
		_wagons.append(wagon)

	for idx in in_use_indices:
		var i := int(idx)
		if i >= 0 and i < _wagons.size():
			_wagons_in_use.append(_wagons[i])
