## Merkezi oyun yöneticisi (Autoload).
## Sahneler arasında paylaşılan verileri tutar: envanter, ekonomi, itibar, tren.
extends Node


var event_bus: Node
var economy: EconomySystem
var reputation: ReputationSystem
var inventory: PlayerInventory
var train_config: TrainConfig
var fuel_system: FuelSystem
var route: RouteData
var trip_planner: TripPlanner
var current_stop_index: int = 0  # Mevcut durak (haritada konum)


func _ready() -> void:
	# EventBus'ı bul (diğer autoload)
	event_bus = get_node("/root/EventBus")

	# Ekonomi sistemi
	economy = EconomySystem.new()
	economy.setup(event_bus)
	add_child(economy)

	# İtibar sistemi
	reputation = ReputationSystem.new()
	reputation.setup(event_bus)
	add_child(reputation)

	# Oyuncu envanteri
	inventory = PlayerInventory.new()
	inventory.setup(event_bus, economy)
	add_child(inventory)

	# Varsayılan tren konfigürasyonu (ilk lokomotif + başlangıç vagonları)
	_setup_default_train()

	# Yakıt sistemi
	fuel_system = FuelSystem.new()
	fuel_system.setup(event_bus, economy, train_config.get_locomotive())
	add_child(fuel_system)

	# Ege rotası
	route = RouteData.load_ege_route()

	# Sefer planlayıcı
	trip_planner = TripPlanner.new()
	trip_planner.setup(event_bus, economy, fuel_system, route)
	add_child(trip_planner)


func _setup_default_train() -> void:
	var locos := inventory.get_locomotives()
	if locos.size() > 0:
		var loco: LocomotiveData = locos[0]
		train_config = TrainConfig.new(loco)
		# Başlangıç vagonlarını trene ekle
		for wagon in inventory.get_available_wagons():
			if train_config.is_full():
				break
			train_config.add_wagon(wagon)
			inventory.mark_wagon_in_use(wagon)
