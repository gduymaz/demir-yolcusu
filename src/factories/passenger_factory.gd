## Module: passenger_factory.gd
## Restored English comments for maintainability and i18n coding standards.

class_name PassengerFactory
extends RefCounted

static var _next_id: int = 0

static func create(type: Constants.PassengerType, destination: String, distance_km: int) -> Dictionary:
	_next_id += 1
	return {
		"id": "passenger_%d" % _next_id,
		"type": type,
		"destination": destination,
		"fare": _calculate_fare(type, distance_km),
		"patience": _calculate_patience(type),
		"patience_max": _calculate_patience(type),
		"state": Constants.PassengerState.WAITING,
	}

static func create_random(destinations: Array, distance_km: int) -> Dictionary:
	var type := _random_type()
	var dest: String = destinations[randi() % destinations.size()]
	return create(type, dest, distance_km)

static func create_batch(count: int, destinations: Array, distance_km: int) -> Array[Dictionary]:
	var batch: Array[Dictionary] = []
	for i in count:
		batch.append(create_random(destinations, distance_km))
	return batch

static func _calculate_fare(type: Constants.PassengerType, distance_km: int) -> int:
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
	match type:
		Constants.PassengerType.VIP:
			fare_multiplier = Balance.FARE_MULTIPLIER_VIP
		Constants.PassengerType.STUDENT:
			fare_multiplier = Balance.FARE_MULTIPLIER_STUDENT
		Constants.PassengerType.ELDERLY:
			fare_multiplier = Balance.FARE_MULTIPLIER_ELDERLY
		_:
			fare_multiplier = Balance.FARE_MULTIPLIER_NORMAL

	return int(float(distance_km) * Balance.TICKET_BASE_PRICE * distance_multiplier * fare_multiplier)

static func _calculate_patience(type: Constants.PassengerType) -> float:
	var multiplier: float
	match type:
		Constants.PassengerType.VIP:
			multiplier = Balance.PATIENCE_MULTIPLIER_VIP
		Constants.PassengerType.STUDENT:
			multiplier = Balance.PATIENCE_MULTIPLIER_STUDENT
		Constants.PassengerType.ELDERLY:
			multiplier = Balance.PATIENCE_MULTIPLIER_ELDERLY
		_:
			multiplier = Balance.PATIENCE_MULTIPLIER_NORMAL
	return Balance.PATIENCE_BASE * multiplier

static func _random_type() -> Constants.PassengerType:
	var roll := randf()
	if roll < 0.6:
		return Constants.PassengerType.NORMAL
	elif roll < 0.75:
		return Constants.PassengerType.STUDENT
	elif roll < 0.9:
		return Constants.PassengerType.ELDERLY
	else:
		return Constants.PassengerType.VIP
