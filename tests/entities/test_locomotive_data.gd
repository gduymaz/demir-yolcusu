## LocomotiveData testleri.
## Lokomotif veri modeli: oluşturma, özellikler, katalog.
class_name TestLocomotiveData
extends GdUnitTestSuite


# ==========================================================
# OLUŞTURMA (Factory)
# ==========================================================

func test_Create_KaraDuman_ShouldHaveCorrectId() -> void:
	var loco := LocomotiveData.create("kara_duman")
	assert_str(loco.id).is_equal("kara_duman")


func test_Create_KaraDuman_ShouldHaveCorrectName() -> void:
	var loco := LocomotiveData.create("kara_duman")
	assert_str(loco.loco_name).is_equal("Kara Duman")


func test_Create_KaraDuman_ShouldHaveCoalOldFuelType() -> void:
	var loco := LocomotiveData.create("kara_duman")
	assert_int(loco.fuel_type).is_equal(Constants.FuelType.COAL_OLD)


func test_Create_KaraDuman_ShouldHaveCorrectSpeed() -> void:
	var loco := LocomotiveData.create("kara_duman")
	assert_float(loco.base_speed).is_equal(Balance.LOCOMOTIVE_SPEED_COAL_OLD)


func test_Create_KaraDuman_ShouldHaveCorrectMaxWagons() -> void:
	var loco := LocomotiveData.create("kara_duman")
	assert_int(loco.max_wagons).is_equal(Constants.MAX_WAGONS_COAL_OLD)


func test_Create_KaraDuman_ShouldHaveCorrectFuelConsumption() -> void:
	var loco := LocomotiveData.create("kara_duman")
	assert_float(loco.fuel_consumption).is_equal(Balance.FUEL_CONSUMPTION_COAL_OLD)


func test_Create_KaraDuman_ShouldHaveCorrectTankCapacity() -> void:
	var loco := LocomotiveData.create("kara_duman")
	assert_float(loco.fuel_tank_capacity).is_equal(Balance.FUEL_TANK_COAL_OLD)


func test_Create_KaraDuman_ShouldHaveCorrectCost() -> void:
	var loco := LocomotiveData.create("kara_duman")
	assert_int(loco.base_cost).is_equal(Balance.LOCOMOTIVE_COST_COAL_OLD)


# ==========================================================
# DİĞER LOKOMOTİFLER
# ==========================================================

func test_Create_DemirYildizi_ShouldBeDieselOld() -> void:
	var loco := LocomotiveData.create("demir_yildizi")
	assert_str(loco.loco_name).is_equal("Demir Yıldızı")
	assert_int(loco.fuel_type).is_equal(Constants.FuelType.DIESEL_OLD)
	assert_int(loco.max_wagons).is_equal(Constants.MAX_WAGONS_DIESEL_OLD)


func test_Create_MaviSimsek_ShouldBeElectric() -> void:
	var loco := LocomotiveData.create("mavi_simsek")
	assert_str(loco.loco_name).is_equal("Mavi Şimşek")
	assert_int(loco.fuel_type).is_equal(Constants.FuelType.ELECTRIC)
	assert_int(loco.max_wagons).is_equal(Constants.MAX_WAGONS_ELECTRIC)


# ==========================================================
# GEÇERSİZ OLUŞTURMA
# ==========================================================

func test_Create_UnknownId_ShouldReturnNull() -> void:
	var loco := LocomotiveData.create("nonexistent")
	assert_object(loco).is_null()


func test_Create_EmptyId_ShouldReturnNull() -> void:
	var loco := LocomotiveData.create("")
	assert_object(loco).is_null()


# ==========================================================
# KATALOG
# ==========================================================

func test_GetCatalog_ShouldContainKaraDuman() -> void:
	var catalog := LocomotiveData.get_catalog()
	assert_bool(catalog.has("kara_duman")).is_true()


func test_GetCatalog_ShouldContainMultipleEntries() -> void:
	var catalog := LocomotiveData.get_catalog()
	assert_int(catalog.size()).is_greater_equal(3)


func test_GetCatalog_AllEntries_ShouldBeCreatable() -> void:
	var catalog := LocomotiveData.get_catalog()
	for loco_id in catalog:
		var loco := LocomotiveData.create(loco_id)
		assert_object(loco).is_not_null()
		assert_str(loco.id).is_equal(loco_id)


func test_GetCatalog_AllEntries_ShouldHaveValidProperties() -> void:
	var catalog := LocomotiveData.get_catalog()
	for loco_id in catalog:
		var loco := LocomotiveData.create(loco_id)
		assert_str(loco.loco_name).is_not_empty()
		assert_int(loco.max_wagons).is_greater(0)
		assert_float(loco.base_speed).is_greater(0.0)
		assert_float(loco.fuel_consumption).is_greater(0.0)
		assert_float(loco.fuel_tank_capacity).is_greater(0.0)
		assert_int(loco.base_cost).is_greater(0)


# ==========================================================
# HIZ SIRASI
# ==========================================================

func test_Speed_ElectricShouldBeFasterThanDiesel() -> void:
	var electric := LocomotiveData.create("mavi_simsek")
	var diesel := LocomotiveData.create("demir_yildizi")
	assert_float(electric.base_speed).is_greater(diesel.base_speed)


func test_Speed_DieselShouldBeFasterThanCoal() -> void:
	var diesel := LocomotiveData.create("demir_yildizi")
	var coal := LocomotiveData.create("kara_duman")
	assert_float(diesel.base_speed).is_greater(coal.base_speed)
