## Sabır sistemi.
## Her frame'de yolcuların sabrını azaltır, sabırsız yolcuları kaybeder.
class_name PatienceSystem
extends Node


var _event_bus: Node
var _reputation: ReputationSystem


func setup(event_bus: Node, reputation: ReputationSystem) -> void:
	_event_bus = event_bus
	_reputation = reputation


## Yolcuların sabrını güncelle. Kaybedilen yolcuları döner.
## passengers listesi doğrudan değiştirilir (kaybolanlar çıkarılır).
func update(passengers: Array[Dictionary], delta: float) -> Array[Dictionary]:
	var lost: Array[Dictionary] = []

	# Ters iterasyon — silme sırasında index kaymasını önler
	for i in range(passengers.size() - 1, -1, -1):
		passengers[i]["patience"] = maxf(passengers[i]["patience"] - delta, 0.0)

		if passengers[i]["patience"] <= 0.0:
			var lost_passenger := passengers[i]
			lost.append(lost_passenger)
			passengers.remove_at(i)

			# İtibar düşür
			_reputation.remove(
				absf(Balance.REPUTATION_PER_PASSENGER_LOST),
				"passenger_lost"
			)

			# EventBus bildir
			if _event_bus:
				_event_bus.passenger_lost.emit(lost_passenger, "")

	return lost


## Yolcunun sabır yüzdesini hesapla (0-100).
static func get_patience_percent(passenger: Dictionary) -> float:
	if passenger["patience_max"] <= 0.0:
		return 0.0
	return (passenger["patience"] / passenger["patience_max"]) * 100.0
