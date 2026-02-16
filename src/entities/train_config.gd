## Tren konfigürasyonu.
## Bir lokomotif + sıralı vagon listesi. Kapasite/ağırlık hesaplama.
class_name TrainConfig
extends RefCounted


var _locomotive: LocomotiveData
var _wagons: Array = []  # Array[WagonData]


func _init(locomotive: LocomotiveData) -> void:
	_locomotive = locomotive


# ==========================================================
# LOKOMOTİF
# ==========================================================

func get_locomotive() -> LocomotiveData:
	return _locomotive


## Lokomotif değiştirir. Yeni lokomotifin max_wagons'ı daha azsa fazla vagonları keser.
func set_locomotive(locomotive: LocomotiveData) -> void:
	_locomotive = locomotive
	if _wagons.size() > _locomotive.max_wagons:
		_wagons.resize(_locomotive.max_wagons)


# ==========================================================
# VAGON YÖNETİMİ
# ==========================================================

func get_wagons() -> Array:
	return _wagons


func get_wagon_count() -> int:
	return _wagons.size()


func get_max_wagons() -> int:
	return _locomotive.max_wagons


func is_full() -> bool:
	return _wagons.size() >= _locomotive.max_wagons


## Vagon ekler (sona). Max aşılırsa false döner.
func add_wagon(wagon: WagonData) -> bool:
	if is_full():
		return false
	_wagons.append(wagon)
	return true


## Belirtilen indeksteki vagonu çıkarır. Geçersiz indeks → null.
func remove_wagon_at(index: int) -> WagonData:
	if index < 0 or index >= _wagons.size():
		return null
	var wagon: WagonData = _wagons[index]
	_wagons.remove_at(index)
	return wagon


## İki vagonun yerini değiştirir.
func swap_wagons(index_a: int, index_b: int) -> bool:
	if index_a < 0 or index_a >= _wagons.size():
		return false
	if index_b < 0 or index_b >= _wagons.size():
		return false
	var temp: WagonData = _wagons[index_a]
	_wagons[index_a] = _wagons[index_b]
	_wagons[index_b] = temp
	return true


# ==========================================================
# HESAPLAMALAR
# ==========================================================

## Toplam yolcu kapasitesi (CARGO ve DINING hariç).
func get_total_passenger_capacity() -> int:
	var total := 0
	for wagon in _wagons:
		var w: WagonData = wagon
		if w.type != Constants.WagonType.CARGO and w.type != Constants.WagonType.DINING:
			total += w.get_capacity()
	return total


## Toplam ağırlık (basitleştirilmiş: vagon sayısı × sabit ağırlık).
func get_total_weight() -> float:
	return _wagons.size() * Balance.WAGON_WEIGHT
