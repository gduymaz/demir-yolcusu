## PlayerInventory testleri.
## Envanter yönetimi: lokomotif/vagon sahipliği, satın alma, başlangıç envanteri.
class_name TestPlayerInventory
extends GdUnitTestSuite


var _inventory: PlayerInventory
var _event_bus: Node
var _economy: EconomySystem


func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	_inventory = auto_free(PlayerInventory.new())
	_inventory.setup(_event_bus, _economy)


# ==========================================================
# BAŞLANGIÇ ENVANTERİ
# ==========================================================

func test_Setup_ShouldHaveOneLocomotive() -> void:
	assert_int(_inventory.get_locomotives().size()).is_equal(1)


func test_Setup_FirstLocomotive_ShouldBeKaraDuman() -> void:
	var locos := _inventory.get_locomotives()
	assert_str(locos[0].id).is_equal("kara_duman")


func test_Setup_ShouldHaveTwoWagons() -> void:
	assert_int(_inventory.get_wagons().size()).is_equal(2)


func test_Setup_ShouldHaveOneEconomyWagon() -> void:
	var wagons := _inventory.get_wagons()
	var economy_count := 0
	for w in wagons:
		var wagon: WagonData = w
		if wagon.type == Constants.WagonType.ECONOMY:
			economy_count += 1
	assert_int(economy_count).is_equal(1)


func test_Setup_ShouldHaveOneCargoWagon() -> void:
	var wagons := _inventory.get_wagons()
	var cargo_count := 0
	for w in wagons:
		var wagon: WagonData = w
		if wagon.type == Constants.WagonType.CARGO:
			cargo_count += 1
	assert_int(cargo_count).is_equal(1)


# ==========================================================
# LOKOMOTİF YÖNETİMİ
# ==========================================================

func test_AddLocomotive_ShouldIncreaseCount() -> void:
	var loco := LocomotiveData.create("demir_yildizi")
	_inventory.add_locomotive(loco)
	assert_int(_inventory.get_locomotives().size()).is_equal(2)


func test_HasLocomotive_Existing_ShouldReturnTrue() -> void:
	assert_bool(_inventory.has_locomotive("kara_duman")).is_true()


func test_HasLocomotive_NotOwned_ShouldReturnFalse() -> void:
	assert_bool(_inventory.has_locomotive("mavi_simsek")).is_false()


# ==========================================================
# VAGON YÖNETİMİ
# ==========================================================

func test_AddWagon_ShouldIncreaseCount() -> void:
	var wagon := WagonData.new(Constants.WagonType.BUSINESS)
	_inventory.add_wagon(wagon)
	assert_int(_inventory.get_wagons().size()).is_equal(3)


func test_RemoveWagon_ValidIndex_ShouldDecreaseCount() -> void:
	var removed := _inventory.remove_wagon(0)
	assert_object(removed).is_not_null()
	assert_int(_inventory.get_wagons().size()).is_equal(1)


func test_RemoveWagon_InvalidIndex_ShouldReturnNull() -> void:
	var removed := _inventory.remove_wagon(99)
	assert_object(removed).is_null()
	assert_int(_inventory.get_wagons().size()).is_equal(2)


# ==========================================================
# VAGON SATIN ALMA
# ==========================================================

func test_BuyWagon_EnoughMoney_ShouldSucceed() -> void:
	var result := _inventory.buy_wagon(Constants.WagonType.ECONOMY)
	assert_bool(result).is_true()
	assert_int(_inventory.get_wagons().size()).is_equal(3)


func test_BuyWagon_ShouldDeductMoney() -> void:
	_inventory.buy_wagon(Constants.WagonType.ECONOMY)
	# 500 - 100 (economy cost) = 400
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY - Balance.WAGON_COST_ECONOMY)


func test_BuyWagon_Business_ShouldDeductCorrectAmount() -> void:
	_inventory.buy_wagon(Constants.WagonType.BUSINESS)
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY - Balance.WAGON_COST_BUSINESS)


func test_BuyWagon_NotEnoughMoney_ShouldReturnFalse() -> void:
	_economy.set_balance(10)
	var result := _inventory.buy_wagon(Constants.WagonType.ECONOMY)  # 100 DA
	assert_bool(result).is_false()
	assert_int(_inventory.get_wagons().size()).is_equal(2)
	assert_int(_economy.get_balance()).is_equal(10)


func test_BuyWagon_VIP_ShouldAddVIPWagon() -> void:
	_inventory.buy_wagon(Constants.WagonType.VIP)
	var wagons := _inventory.get_wagons()
	var last_wagon: WagonData = wagons[wagons.size() - 1]
	assert_int(last_wagon.type).is_equal(Constants.WagonType.VIP)


func test_BuyWagon_Cargo_ShouldDeductCorrectAmount() -> void:
	_inventory.buy_wagon(Constants.WagonType.CARGO)
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY - Balance.WAGON_COST_CARGO)


# ==========================================================
# FİYAT SORGULAMA
# ==========================================================

func test_GetWagonPrice_Economy_ShouldReturnCorrectPrice() -> void:
	assert_int(PlayerInventory.get_wagon_price(Constants.WagonType.ECONOMY)).is_equal(Balance.WAGON_COST_ECONOMY)


func test_GetWagonPrice_Business_ShouldReturnCorrectPrice() -> void:
	assert_int(PlayerInventory.get_wagon_price(Constants.WagonType.BUSINESS)).is_equal(Balance.WAGON_COST_BUSINESS)


func test_GetWagonPrice_VIP_ShouldReturnCorrectPrice() -> void:
	assert_int(PlayerInventory.get_wagon_price(Constants.WagonType.VIP)).is_equal(Balance.WAGON_COST_VIP)


func test_GetWagonPrice_Cargo_ShouldReturnCorrectPrice() -> void:
	assert_int(PlayerInventory.get_wagon_price(Constants.WagonType.CARGO)).is_equal(Balance.WAGON_COST_CARGO)


# ==========================================================
# KULLANILABILIR VAGONLAR (trene takılı olmayanlar)
# ==========================================================

func test_GetAvailableWagons_Initially_ShouldReturnAll() -> void:
	assert_int(_inventory.get_available_wagons().size()).is_equal(2)


func test_MarkWagonInUse_ShouldRemoveFromAvailable() -> void:
	var wagons := _inventory.get_wagons()
	_inventory.mark_wagon_in_use(wagons[0])
	assert_int(_inventory.get_available_wagons().size()).is_equal(1)


func test_UnmarkWagonInUse_ShouldReturnToAvailable() -> void:
	var wagons := _inventory.get_wagons()
	_inventory.mark_wagon_in_use(wagons[0])
	_inventory.unmark_wagon_in_use(wagons[0])
	assert_int(_inventory.get_available_wagons().size()).is_equal(2)
