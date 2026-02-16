## Oyuncu envanteri.
## Sahip olunan lokomotif ve vagonların yönetimi.
## Sahneler arası kalıcı (Autoload olarak kullanılabilir).
class_name PlayerInventory
extends Node


var _event_bus: Node
var _economy: EconomySystem
var _locomotives: Array = []   # Array[LocomotiveData]
var _wagons: Array = []        # Array[WagonData]
var _wagons_in_use: Array = [] # Array[WagonData] — trene takılı olanlar


## Sistemi başlatır ve başlangıç envanterini oluşturur.
func setup(event_bus: Node, economy: EconomySystem) -> void:
	_event_bus = event_bus
	_economy = economy
	_create_starting_inventory()


func _create_starting_inventory() -> void:
	# 1 Kara Duman lokomotif
	_locomotives.append(LocomotiveData.create("kara_duman"))
	# 1 Ekonomi vagon + 1 Kargo vagon
	_wagons.append(WagonData.new(Constants.WagonType.ECONOMY))
	_wagons.append(WagonData.new(Constants.WagonType.CARGO))


# ==========================================================
# LOKOMOTİF
# ==========================================================

func get_locomotives() -> Array:
	return _locomotives


func add_locomotive(locomotive: LocomotiveData) -> void:
	_locomotives.append(locomotive)


func has_locomotive(loco_id: String) -> bool:
	for loco in _locomotives:
		var l: LocomotiveData = loco
		if l.id == loco_id:
			return true
	return false


# ==========================================================
# VAGON
# ==========================================================

func get_wagons() -> Array:
	return _wagons


func add_wagon(wagon: WagonData) -> void:
	_wagons.append(wagon)


func remove_wagon(index: int) -> WagonData:
	if index < 0 or index >= _wagons.size():
		return null
	var wagon: WagonData = _wagons[index]
	_wagons.remove_at(index)
	return wagon


# ==========================================================
# SATIN ALMA
# ==========================================================

## Vagon satın alır. Yeterli bakiye yoksa false döner.
func buy_wagon(wagon_type: Constants.WagonType) -> bool:
	var price := get_wagon_price(wagon_type)
	if not _economy.can_afford(price):
		return false
	_economy.spend(price, "vagon_satin_alma")
	_wagons.append(WagonData.new(wagon_type))
	return true


## Vagon tipi için fiyat döner.
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


# ==========================================================
# KULLANIM DURUMU (trene takılı / boşta)
# ==========================================================

## Kullanılabilir (trene takılı olmayan) vagonları döner.
func get_available_wagons() -> Array:
	var available: Array = []
	for wagon in _wagons:
		if not _wagons_in_use.has(wagon):
			available.append(wagon)
	return available


## Vagonu "trende kullanılıyor" olarak işaretler.
func mark_wagon_in_use(wagon: WagonData) -> void:
	if not _wagons_in_use.has(wagon):
		_wagons_in_use.append(wagon)


## Vagonu "boşta" olarak işaretler.
func unmark_wagon_in_use(wagon: WagonData) -> void:
	_wagons_in_use.erase(wagon)
