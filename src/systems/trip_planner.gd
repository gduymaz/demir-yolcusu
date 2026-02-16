## Sefer planlama sistemi.
## Rota üzerinde başlangıç/bitiş seçimi, ön izleme, sefer yönetimi.
class_name TripPlanner
extends Node


var _event_bus: Node
var _economy: EconomySystem
var _fuel: FuelSystem
var _route: RouteData

# -- Seçim --
var _start_index: int = -1
var _end_index: int = -1

# -- Aktif sefer --
var _trip_active: bool = false
var _trip_stops: Array = []  # Seferdeki duraklar (sıralı)
var _current_trip_stop: int = 0  # _trip_stops içindeki mevcut indeks
var _direction: int = 1  # 1 = ileri, -1 = geri


func setup(event_bus: Node, economy: EconomySystem, fuel: FuelSystem, route: RouteData) -> void:
	_event_bus = event_bus
	_economy = economy
	_fuel = fuel
	_route = route


# ==========================================================
# ROTA SEÇİMİ
# ==========================================================

## Başlangıç ve bitiş duraklarını seçer. Aynı durak seçilemez.
func select_stops(from_index: int, to_index: int) -> bool:
	if from_index < 0 or to_index < 0:
		return false
	if from_index >= _route.get_stop_count() or to_index >= _route.get_stop_count():
		return false
	if from_index == to_index:
		return false

	_start_index = from_index
	_end_index = to_index

	# Trip stops'u hazırla
	_trip_stops = _route.get_sub_route(from_index, to_index)
	_direction = 1 if to_index > from_index else -1
	return true


func get_start_index() -> int:
	return _start_index


func get_end_index() -> int:
	return _end_index


func get_trip_stop_count() -> int:
	return _trip_stops.size()


# ==========================================================
# ÖN İZLEME
# ==========================================================

## Sefer ön izlemesi: mesafe, yakıt maliyeti, tahmini gelir vb.
func get_preview() -> Dictionary:
	if _trip_stops.is_empty():
		return {}

	var distance := _route.get_distance_between(_start_index, _end_index)
	var wagon_count := 2  # Varsayılan — GameManager'dan alınacak
	var fuel_cost := _fuel.calculate_fuel_cost(distance, wagon_count)
	var fuel_needed := maxf(0.0, fuel_cost - _fuel.get_current_fuel())
	var refuel_cost := ceili(fuel_needed)
	var can_afford := _economy.can_afford(refuel_cost) or fuel_needed <= 0.0

	# Tahmini gelir: durak başına ortalama 5 yolcu × ortalama bilet
	var avg_ticket := Balance.TICKET_BASE_PRICE * (distance / float(_trip_stops.size()))
	var estimated_revenue := int(avg_ticket * 5 * _trip_stops.size() * 0.4)

	return {
		"distance_km": distance,
		"stop_count": _trip_stops.size(),
		"fuel_cost": fuel_cost,
		"refuel_cost": refuel_cost,
		"can_afford_fuel": can_afford,
		"estimated_revenue": estimated_revenue,
	}


# ==========================================================
# SEFER YÖNETİMİ
# ==========================================================

## Seferi başlatır. Otomatik yakıt ikmali yapar.
func start_trip() -> bool:
	if _trip_stops.is_empty():
		return false

	# Otomatik ikmal
	_fuel.auto_refuel()

	_trip_active = true
	_current_trip_stop = 0
	_economy.reset_trip_summary()

	if _event_bus:
		_event_bus.trip_started.emit({
			"route_id": _route.id,
			"start": _trip_stops[0]["name"],
			"end": _trip_stops[_trip_stops.size() - 1]["name"],
			"stop_count": _trip_stops.size(),
		})

	return true


func is_trip_active() -> bool:
	return _trip_active


func get_current_stop_index() -> int:
	return _current_trip_stop


## Mevcut durağın verisini döner.
func get_current_stop() -> Dictionary:
	if _current_trip_stop < 0 or _current_trip_stop >= _trip_stops.size():
		return {}
	return _trip_stops[_current_trip_stop]


## Sonraki durağın verisini döner. Son duraktaysa boş döner.
func get_next_stop() -> Dictionary:
	var next := _current_trip_stop + 1
	if next >= _trip_stops.size():
		return {}
	return _trip_stops[next]


## Sonraki durağa mesafe (km).
func get_distance_to_next_stop() -> float:
	var current: Dictionary = get_current_stop()
	var next: Dictionary = get_next_stop()
	if current.is_empty() or next.is_empty():
		return 0.0
	return RouteData.haversine(current["lat"], current["lng"], next["lat"], next["lng"])


## Son durağa ulaşıldı mı?
func is_at_final_stop() -> bool:
	return _current_trip_stop >= _trip_stops.size() - 1


## Sonraki durağa ilerler. Yakıt tüketir.
func advance_to_next_stop() -> void:
	if is_at_final_stop():
		return

	var distance := get_distance_to_next_stop()
	var fuel_cost := _fuel.calculate_fuel_cost(distance, 2)  # TODO: gerçek vagon sayısı
	_fuel.consume(fuel_cost)

	_current_trip_stop += 1


## Seferi bitirir. Sinyal gönderir.
func end_trip() -> void:
	_trip_active = false
	var summary := _economy.get_trip_summary()

	if _event_bus:
		_event_bus.trip_completed.emit(summary)

	_current_trip_stop = 0


## Tüm trip duraklarını döner.
func get_trip_stops() -> Array:
	return _trip_stops
