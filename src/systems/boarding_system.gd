## Yolcu bindirme/indirme orkestratörü.
## Vagon uyumluluğu kontrol eder, parayı kazandırır, sinyalleri gönderir.
class_name BoardingSystem
extends Node


var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem


func setup(event_bus: Node, economy: EconomySystem, reputation: ReputationSystem) -> void:
	_event_bus = event_bus
	_economy = economy
	_reputation = reputation


## Yolcuyu vagona bindir. Başarılıysa true döner.
func board_passenger(passenger: Dictionary, wagon: WagonData) -> bool:
	if not wagon.can_accept(passenger):
		return false

	wagon.add_passenger(passenger)

	# Para kazan
	_economy.earn(passenger["fare"], "ticket")

	# İtibar kazan
	_reputation.add(Balance.REPUTATION_PER_PASSENGER_DELIVERED, "passenger_boarded")

	# EventBus bildir
	if _event_bus:
		_event_bus.passenger_boarded.emit(passenger, wagon.type)

	return true


## Hedefe varan yolcuları indir. İndirilen yolcuların listesini döner.
func alight_passengers(wagon: WagonData, station_id: String) -> Array[Dictionary]:
	var alighting := wagon.get_passengers_for_destination(station_id)
	for p in alighting:
		wagon.remove_passenger(p["id"])
		if _event_bus:
			_event_bus.passenger_arrived.emit(p, station_id)
	return alighting
