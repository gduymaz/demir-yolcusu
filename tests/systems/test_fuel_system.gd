## FuelSystem testleri.
## Yakıt deposu, tüketim, ikmal, yakıt bitme sinyalleri.
class_name TestFuelSystem
extends GdUnitTestSuite


var _system: FuelSystem
var _event_bus: Node
var _economy: EconomySystem


func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	_system = auto_free(FuelSystem.new())


# ==========================================================
# KURULUM (Setup)
# ==========================================================

func test_Setup_WithLocomotive_ShouldSetTankCapacity() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_float(_system.get_tank_capacity()).is_equal(Balance.FUEL_TANK_COAL_OLD)


func test_Setup_ShouldStartWithFullTank() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_float(_system.get_current_fuel()).is_equal(Balance.FUEL_TANK_COAL_OLD)


func test_Setup_ShouldSetConsumptionRate() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_float(_system.get_consumption_rate()).is_equal(Balance.FUEL_CONSUMPTION_COAL_OLD)


# ==========================================================
# TÜKETİM HESAPLAMA
# ==========================================================

func test_CalculateConsumption_NoWagons_ShouldBeBaseRate() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var cost := _system.calculate_fuel_cost(100.0, 0)
	# 100 km × 3.0 birim/km = 300
	assert_float(cost).is_equal(300.0)


func test_CalculateConsumption_WithWagons_ShouldAddExtra() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var cost := _system.calculate_fuel_cost(100.0, 2)
	# 100 km × 3.0 × (1 + 2 × 0.1) = 100 × 3.0 × 1.2 = 360
	assert_float(cost).is_equal(360.0)


func test_CalculateConsumption_ElectricLoco_ShouldBeCheaper() -> void:
	var loco := LocomotiveData.create("mavi_simsek")
	_system.setup(_event_bus, _economy, loco)
	var cost := _system.calculate_fuel_cost(100.0, 0)
	# 100 km × 1.0 birim/km = 100
	assert_float(cost).is_equal(100.0)


func test_CalculateConsumption_ZeroDistance_ShouldBeZero() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var cost := _system.calculate_fuel_cost(0.0, 0)
	assert_float(cost).is_equal(0.0)


# ==========================================================
# YAKIT KULLANIMI (Consume)
# ==========================================================

func test_Consume_ValidAmount_ShouldDecreaseFuel() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(100.0)
	assert_float(_system.get_current_fuel()).is_equal(200.0)


func test_Consume_AllFuel_ShouldReachZero() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(300.0)
	assert_float(_system.get_current_fuel()).is_equal(0.0)


func test_Consume_MoreThanAvailable_ShouldClampToZero() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(999.0)
	assert_float(_system.get_current_fuel()).is_equal(0.0)


# ==========================================================
# YÜZDE VE DURUM
# ==========================================================

func test_GetPercentage_FullTank_ShouldBe100() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_float(_system.get_fuel_percentage()).is_equal(100.0)


func test_GetPercentage_HalfTank_ShouldBe50() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(150.0)
	assert_float(_system.get_fuel_percentage()).is_equal(50.0)


func test_IsLow_AboveThreshold_ShouldBeFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_bool(_system.is_fuel_low()).is_false()


func test_IsLow_BelowThreshold_ShouldBeTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	# 300 kapasite, %25 eşik = 75. 230 tüket -> 70 kalan -> dusuk
	_system.consume(230.0)
	assert_bool(_system.is_fuel_low()).is_true()


func test_IsCritical_AboveThreshold_ShouldBeFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(260.0) # 40 kalan -> %13.3
	assert_bool(_system.is_fuel_critical()).is_false()


func test_IsCritical_BelowThreshold_ShouldBeTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(271.0) # 29 kalan -> %9.6
	assert_bool(_system.is_fuel_critical()).is_true()


func test_IsEmpty_WithFuel_ShouldBeFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_bool(_system.is_fuel_empty()).is_false()


func test_IsEmpty_NoFuel_ShouldBeTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(300.0)
	assert_bool(_system.is_fuel_empty()).is_true()


# ==========================================================
# MENZIL KONTROLÜ
# ==========================================================

func test_CanTravel_EnoughFuel_ShouldBeTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	# 300 yakıt / 3.0 oran = 100 km menzil (0 vagonla)
	assert_bool(_system.can_travel(100.0, 0)).is_true()


func test_CanTravel_NotEnoughFuel_ShouldBeFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	# 300 yakıt, 101 km × 3.0 = 303 > 300
	assert_bool(_system.can_travel(101.0, 0)).is_false()


func test_CanTravel_WithWagons_ShouldAccountForExtra() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	# 300 yakıt, 3 vagon: 100km × 3.0 × (1+3×0.1) = 100 × 3.0 × 1.3 = 390 > 300
	assert_bool(_system.can_travel(100.0, 3)).is_false()
	# 70km × 3.0 × 1.3 = 273 < 300
	assert_bool(_system.can_travel(70.0, 3)).is_true()


# ==========================================================
# İKMAL (Refuel)
# ==========================================================

func test_Refuel_Full_ShouldFillTank() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(200.0)
	_system.refuel_full()
	assert_float(_system.get_current_fuel()).is_equal(Balance.FUEL_TANK_COAL_OLD)


func test_RefuelAmount_ShouldAddFuel() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(200.0)  # 100 kalan
	_system.refuel_amount(50.0)
	assert_float(_system.get_current_fuel()).is_equal(150.0)


func test_RefuelAmount_ShouldNotExceedCapacity() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(50.0)   # 250 kalan
	_system.refuel_amount(999.0)
	assert_float(_system.get_current_fuel()).is_equal(Balance.FUEL_TANK_COAL_OLD)


# ==========================================================
# OTOMATİK İKMAL (Auto-refuel)
# ==========================================================

func test_AutoRefuel_ShouldFillTankAndSpendMoney() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(200.0)  # 100 kalan, 200 eksik
	var result := _system.auto_refuel()
	assert_bool(result).is_true()
	assert_float(_system.get_current_fuel()).is_equal(Balance.FUEL_TANK_COAL_OLD)
	# Yakıt maliyeti: 200 birim × 1 DA/birim = 200 DA harcandı
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY - 200)


func test_AutoRefuel_AlreadyFull_ShouldNotSpendMoney() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var result := _system.auto_refuel()
	assert_bool(result).is_true()
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY)


func test_AutoRefuel_NotEnoughMoney_ShouldReturnFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_economy.set_balance(0)
	_system.consume(200.0)  # 200 DA gerekli, 0 DA var
	var result := _system.auto_refuel()
	assert_bool(result).is_false()
	# Para harcanmadı, yakıt değişmedi
	assert_int(_economy.get_balance()).is_equal(0)
	assert_float(_system.get_current_fuel()).is_equal(100.0)


func test_GetRefuelCost_ShouldUseUnitPrice() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_int(_system.get_refuel_cost(12.4)).is_equal(13)


func test_BuyRefuel_EnoughMoney_ShouldIncreaseFuel() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(250.0) # 50 kalan
	assert_bool(_system.buy_refuel(20.0)).is_true()
	assert_float(_system.get_current_fuel()).is_equal(70.0)


func test_BuyRefuel_NotEnoughMoney_ShouldReturnFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_economy.set_balance(5)
	_system.consume(250.0)
	assert_bool(_system.buy_refuel(20.0)).is_false()
	assert_float(_system.get_current_fuel()).is_equal(50.0)


func test_EnsureFuelForTrip_ShouldTopUpMinimum() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(250.0) # 50 kalan
	var result := _system.ensure_fuel_for_trip(30.0, 0) # 90 gerekli
	assert_bool(result["can_travel"]).is_true()
	assert_float(_system.get_current_fuel()).is_equal(90.0)


func test_EnsureFuelForTrip_InsufficientMoney_ShouldFailTravelCheck() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(250.0) # 50 kalan
	_economy.set_balance(10) # +10 yakıt alabilir -> 60
	var result := _system.ensure_fuel_for_trip(30.0, 0) # 90 gerekli
	assert_bool(result["can_travel"]).is_false()
	assert_float(_system.get_current_fuel()).is_equal(60.0)


func test_TripTracking_ShouldTrackOnlyConsumedAmount() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.begin_trip_tracking()
	_system.consume(25.5)
	_system.refuel_amount(10.0)
	_system.consume(4.5)
	assert_float(_system.get_trip_consumed()).is_equal(30.0)
	assert_int(_system.get_trip_consumed_cost()).is_equal(30)


func test_AutoRefuel_PartialMoney_ShouldFillPartially() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_economy.set_balance(50)
	_system.consume(200.0)  # 100 kalan, 200 eksik, 50 DA var
	var result := _system.auto_refuel()
	assert_bool(result).is_true()
	assert_float(_system.get_current_fuel()).is_equal(150.0)  # 100 + 50
	assert_int(_economy.get_balance()).is_equal(0)


# ==========================================================
# SİNYALLER
# ==========================================================

func test_Consume_ShouldEmitFuelChanged() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var result := {"percentage": -1.0}
	_event_bus.fuel_changed.connect(func(pct: float) -> void: result["percentage"] = pct)
	_system.consume(150.0)
	assert_float(result["percentage"]).is_equal(50.0)


func test_Consume_BelowThreshold_ShouldEmitFuelLow() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var result := {"emitted": false}
	_event_bus.fuel_low.connect(func(_id: String, _pct: float) -> void: result["emitted"] = true)
	_system.consume(250.0)  # 50 kalan → %16.7 → düşük
	assert_bool(result["emitted"]).is_true()


func test_Consume_ToZero_ShouldEmitFuelEmpty() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var result := {"emitted": false}
	_event_bus.fuel_empty.connect(func(_id: String) -> void: result["emitted"] = true)
	_system.consume(300.0)
	assert_bool(result["emitted"]).is_true()


func test_Consume_AboveThreshold_ShouldNotEmitFuelLow() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var result := {"emitted": false}
	_event_bus.fuel_low.connect(func(_id: String, _pct: float) -> void: result["emitted"] = true)
	_system.consume(100.0)  # 200 kalan → %66.7 → normal
	assert_bool(result["emitted"]).is_false()
