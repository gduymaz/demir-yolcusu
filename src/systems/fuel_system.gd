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


func is_fuel_empty() -> bool:
	return _current_fuel <= 0.0


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
	_current_fuel = maxf(0.0, _current_fuel - amount)

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

	var cost := ceili(needed)  # 1 birim = 1 DA, yukarı yuvarla
	if not _economy.can_afford(1):
		return false  # Hiç parası yok

	var affordable := mini(cost, _economy.get_balance())
	if affordable <= 0:
		return false

	_economy.spend(affordable, "yakit_ikmal")
	refuel_amount(float(affordable))
	return true
