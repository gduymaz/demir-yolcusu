## Module: economy_system.gd
## Restored English comments for maintainability and i18n coding standards.

class_name EconomySystem
extends Node

var _balance: int = Balance.STARTING_MONEY
var _event_bus: Node

var _trip_earnings: Dictionary = {}
var _trip_spendings: Dictionary = {}
var _ticket_income_multiplier: float = 1.0

## Handles `setup`.
func setup(event_bus: Node) -> void:
	_event_bus = event_bus
	_ticket_income_multiplier = 1.0

## Handles `get_balance`.
func get_balance() -> int:
	return _balance

## Handles `set_balance`.
func set_balance(amount: int) -> void:
	_balance = amount

## Handles `can_afford`.
func can_afford(amount: int) -> bool:
	return amount <= _balance

## Handles `earn`.
func earn(amount: int, source: String) -> void:
	if amount <= 0:
		return
	if source == "ticket":
		amount = int(round(float(amount) * _ticket_income_multiplier))
		if amount <= 0:
			return

	var old_balance := _balance
	_balance += amount

	_trip_earnings[source] = _trip_earnings.get(source, 0) + amount

	if _event_bus:
		_event_bus.money_earned.emit(amount, source)
		_event_bus.money_changed.emit(old_balance, _balance, source)

func set_ticket_income_multiplier(value: float) -> void:
	_ticket_income_multiplier = clampf(value, Balance.DIFFICULTY_CLAMP_MIN, Balance.DIFFICULTY_CLAMP_MAX)

func get_ticket_income_multiplier() -> float:
	return _ticket_income_multiplier

## Handles `spend`.
func spend(amount: int, reason: String) -> bool:
	if amount < 0:
		return false

	if amount == 0:
		return true

	if amount > _balance:
		return false

	var old_balance := _balance
	_balance -= amount

	_trip_spendings[reason] = _trip_spendings.get(reason, 0) + amount

	if _event_bus:
		_event_bus.money_spent.emit(amount, reason)
		_event_bus.money_changed.emit(old_balance, _balance, reason)

	return true

## Handles `calculate_ticket_price`.
func calculate_ticket_price(distance_km: int, passenger_type: Constants.PassengerType) -> int:
	if distance_km <= 0:
		return 0

	var distance_multiplier: float
	if distance_km <= Constants.TICKET_DISTANCE_SHORT:
		distance_multiplier = Balance.TICKET_MULTIPLIER_SHORT
	elif distance_km <= Constants.TICKET_DISTANCE_MEDIUM:
		distance_multiplier = Balance.TICKET_MULTIPLIER_MEDIUM
	else:
		distance_multiplier = Balance.TICKET_MULTIPLIER_LONG

	var fare_multiplier: float
	match passenger_type:
		Constants.PassengerType.VIP:
			fare_multiplier = Balance.FARE_MULTIPLIER_VIP
		Constants.PassengerType.STUDENT:
			fare_multiplier = Balance.FARE_MULTIPLIER_STUDENT
		Constants.PassengerType.ELDERLY:
			fare_multiplier = Balance.FARE_MULTIPLIER_ELDERLY
		_:
			fare_multiplier = Balance.FARE_MULTIPLIER_NORMAL

	var price := float(distance_km) * Balance.TICKET_BASE_PRICE * distance_multiplier * fare_multiplier
	return int(price)

## Handles `get_trip_summary`.
func get_trip_summary() -> Dictionary:
	var total_earned := 0
	for amount in _trip_earnings.values():
		total_earned += amount

	var total_spent := 0
	for amount in _trip_spendings.values():
		total_spent += amount

	return {
		"total_earned": total_earned,
		"total_spent": total_spent,
		"net": total_earned - total_spent,
		"earnings": _trip_earnings.duplicate(),
		"spendings": _trip_spendings.duplicate(),
	}

## Handles `reset_trip_summary`.
func reset_trip_summary() -> void:
	_trip_earnings.clear()
	_trip_spendings.clear()
