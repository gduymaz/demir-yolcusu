## Yakıt yönetim sistemi.
## Yakıt deposu takibi, tüketim hesaplama, ikmal, düşük yakıt uyarıları.
class_name FuelSystem
extends Node


var _event_bus: Node
var _economy: EconomySystem
var _locomotive: LocomotiveData

var _current_fuel: float = 0.0
var _tank_capacity: float = 0.0
var _consumption_rate: float = 0.0
var _trip_consumed: float = 0.0


## Sistemi lokomotif ile başlatır. Depo dolu başlar.
func setup(event_bus: Node, economy: EconomySystem, locomotive: LocomotiveData) -> void:
	_event_bus = event_bus
	_economy = economy
	_locomotive = locomotive
	_tank_capacity = locomotive.fuel_tank_capacity
	_consumption_rate = locomotive.fuel_consumption
	_current_fuel = _tank_capacity


# ==========================================================
# DURUM SORGULAMA
# ==========================================================

func get_current_fuel() -> float:
	return _current_fuel


func get_tank_capacity() -> float:
	return _tank_capacity


func get_consumption_rate() -> float:
	return _consumption_rate


func get_fuel_percentage() -> float:
	if _tank_capacity <= 0.0:
		return 0.0
	return (_current_fuel / _tank_capacity) * 100.0


func is_fuel_low() -> bool:
	return get_fuel_percentage() < Balance.FUEL_LOW_THRESHOLD


func is_fuel_critical() -> bool:
	return get_fuel_percentage() < Balance.FUEL_CRITICAL_THRESHOLD


func is_fuel_empty() -> bool:
	return _current_fuel <= 0.0


func begin_trip_tracking() -> void:
	_trip_consumed = 0.0


func get_trip_consumed() -> float:
	return _trip_consumed


func get_trip_consumed_cost() -> int:
	return get_refuel_cost(_trip_consumed)


# ==========================================================
# TÜKETİM
# ==========================================================

## Belirli mesafe + vagon sayısı için yakıt maliyeti hesaplar.
func calculate_fuel_cost(distance_km: float, wagon_count: int) -> float:
	var wagon_multiplier := 1.0 + (wagon_count * Balance.FUEL_PER_WAGON_MULTIPLIER)
	return distance_km * _consumption_rate * wagon_multiplier


## Belirli mesafe ve vagon sayısı ile yolculuk yapılabilir mi?
func can_travel(distance_km: float, wagon_count: int) -> bool:
	return _current_fuel >= calculate_fuel_cost(distance_km, wagon_count)


## Yakıt tüketir. Sinyaller gönderir.
func consume(amount: float) -> void:
	if amount <= 0.0:
		return
	var actual := minf(amount, _current_fuel)
	_current_fuel = maxf(0.0, _current_fuel - amount)
	_trip_consumed += actual

	if _event_bus:
		_event_bus.fuel_changed.emit(get_fuel_percentage())

		if is_fuel_empty():
			_event_bus.fuel_empty.emit(_locomotive.id if _locomotive else "")
		elif is_fuel_low():
			_event_bus.fuel_low.emit(
				_locomotive.id if _locomotive else "",
				get_fuel_percentage()
			)


# ==========================================================
# İKMAL
# ==========================================================

## Depoyu tamamen doldurur (para harcamaz).
func refuel_full() -> void:
	_current_fuel = _tank_capacity


## Belirli miktar yakıt ekler (kapasiteyi aşmaz).
func refuel_amount(amount: float) -> void:
	_current_fuel = minf(_tank_capacity, _current_fuel + amount)


## Depoyu otomatik doldurur, maliyeti EconomySystem'den düşer.
## Yetersiz para varsa mümkün olduğunca doldurur.
## 1 birim yakıt = 1 DA (basitleştirilmiş).
## Dönüş: ikmal yapılabildi mi (en az kısmen).
func auto_refuel() -> bool:
	var needed := _tank_capacity - _current_fuel
	if needed <= 0.0:
		return true  # Zaten dolu

	var cost := get_refuel_cost(needed)
	if not _economy.can_afford(1):
		return false  # Hiç parası yok

	var affordable := mini(cost, _economy.get_balance())
	if affordable <= 0:
		return false

	_economy.spend(affordable, "yakit_ikmal")
	refuel_amount(float(affordable))
	return true


## Belirli miktar yakıtın maliyetini döner.
func get_refuel_cost(amount: float) -> int:
	if amount <= 0.0:
		return 0
	return ceili(amount * Balance.FUEL_UNIT_PRICE)


## Tankı tam doldurmanın maliyetini döner.
func get_full_refuel_cost() -> int:
	return get_refuel_cost(_tank_capacity - _current_fuel)


## Belirli yakıt miktarını satın alıp depoya ekler.
func buy_refuel(amount: float) -> bool:
	if amount <= 0.0:
		return true

	var actual_amount := minf(amount, _tank_capacity - _current_fuel)
	if actual_amount <= 0.0:
		return true

	var cost := get_refuel_cost(actual_amount)
	if not _economy.can_afford(cost):
		return false

	_economy.spend(cost, "yakit_ikmal")
	refuel_amount(actual_amount)
	return true


## Planlanan sefer için minimum yakıtı otomatik ikmal eder.
## Dönüş: {"needed": float, "added": float, "spent": int, "can_travel": bool}
func ensure_fuel_for_trip(distance_km: float, wagon_count: int) -> Dictionary:
	var needed := maxf(0.0, calculate_fuel_cost(distance_km, wagon_count) - _current_fuel)
	if needed <= 0.0:
		return {
			"needed": 0.0,
			"added": 0.0,
			"spent": 0,
			"can_travel": true,
		}

	var affordable_cost := mini(get_refuel_cost(needed), _economy.get_balance())
	var added := minf(needed, float(affordable_cost) / Balance.FUEL_UNIT_PRICE)
	var spent := 0
	if added > 0.0:
		spent = get_refuel_cost(added)
		if _economy.spend(spent, "yakit_ikmal"):
			refuel_amount(added)
		else:
			added = 0.0
			spent = 0

	return {
		"needed": needed,
		"added": added,
		"spent": spent,
		"can_travel": can_travel(distance_km, wagon_count),
	}
