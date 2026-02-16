## Vagon veri modeli.
## Kapasite, yolcu kabul/ret mantığı, doluluk takibi.
class_name WagonData
extends RefCounted


var type: Constants.WagonType
var _passengers: Array[Dictionary] = []
var _capacity: int


func _init(wagon_type: Constants.WagonType) -> void:
	type = wagon_type
	_capacity = _get_capacity_for_type(wagon_type)


func get_capacity() -> int:
	return _capacity


func get_passenger_count() -> int:
	return _passengers.size()


func is_full() -> bool:
	return _passengers.size() >= _capacity


func can_accept(passenger: Dictionary) -> bool:
	if is_full():
		return false
	return _is_type_compatible(passenger["type"])


func add_passenger(passenger: Dictionary) -> bool:
	if not can_accept(passenger):
		return false
	_passengers.append(passenger)
	return true


func remove_passenger(passenger_id: String) -> bool:
	for i in _passengers.size():
		if _passengers[i]["id"] == passenger_id:
			_passengers.remove_at(i)
			return true
	return false


func get_passengers_for_destination(destination: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for p in _passengers:
		if p["destination"] == destination:
			result.append(p)
	return result


func get_all_passengers() -> Array[Dictionary]:
	return _passengers.duplicate()


func _is_type_compatible(passenger_type: Constants.PassengerType) -> bool:
	# Kargo ve yemekli vagonlara yolcu binemez
	if type == Constants.WagonType.CARGO or type == Constants.WagonType.DINING:
		return false
	# VIP yolcular sadece VIP veya Business vagona biner
	if passenger_type == Constants.PassengerType.VIP:
		return type == Constants.WagonType.VIP or type == Constants.WagonType.BUSINESS
	# Diğer yolcular Economy, Business veya VIP vagona binebilir
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
