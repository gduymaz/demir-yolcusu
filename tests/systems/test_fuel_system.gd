## Test suite: test_fuel_system.gd
## Restored English comments for maintainability and i18n coding standards.

class_name TestFuelSystem
extends GdUnitTestSuite

var _system: FuelSystem
var _event_bus: Node
var _economy: EconomySystem

## Handles `before_test`.
func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	_system = auto_free(FuelSystem.new())

## Handles `test_Setup_WithLocomotive_ShouldSetTankCapacity`.
func test_Setup_WithLocomotive_ShouldSetTankCapacity() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_float(_system.get_tank_capacity()).is_equal(Balance.FUEL_TANK_COAL_OLD)

## Handles `test_Setup_ShouldStartWithFullTank`.
func test_Setup_ShouldStartWithFullTank() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_float(_system.get_current_fuel()).is_equal(Balance.FUEL_TANK_COAL_OLD)

## Handles `test_Setup_ShouldSetConsumptionRate`.
func test_Setup_ShouldSetConsumptionRate() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_float(_system.get_consumption_rate()).is_equal(Balance.FUEL_CONSUMPTION_COAL_OLD)

## Handles `test_CalculateConsumption_NoWagons_ShouldBeBaseRate`.
func test_CalculateConsumption_NoWagons_ShouldBeBaseRate() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var cost := _system.calculate_fuel_cost(100.0, 0)

	assert_float(cost).is_equal(300.0)

## Handles `test_CalculateConsumption_WithWagons_ShouldAddExtra`.
func test_CalculateConsumption_WithWagons_ShouldAddExtra() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var cost := _system.calculate_fuel_cost(100.0, 2)

	assert_float(cost).is_equal(360.0)

## Handles `test_CalculateConsumption_ElectricLoco_ShouldBeCheaper`.
func test_CalculateConsumption_ElectricLoco_ShouldBeCheaper() -> void:
	var loco := LocomotiveData.create("mavi_simsek")
	_system.setup(_event_bus, _economy, loco)
	var cost := _system.calculate_fuel_cost(100.0, 0)

	assert_float(cost).is_equal(100.0)

## Handles `test_CalculateConsumption_ZeroDistance_ShouldBeZero`.
func test_CalculateConsumption_ZeroDistance_ShouldBeZero() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var cost := _system.calculate_fuel_cost(0.0, 0)
	assert_float(cost).is_equal(0.0)

## Handles `test_Consume_ValidAmount_ShouldDecreaseFuel`.
func test_Consume_ValidAmount_ShouldDecreaseFuel() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(100.0)
	assert_float(_system.get_current_fuel()).is_equal(200.0)

## Handles `test_Consume_AllFuel_ShouldReachZero`.
func test_Consume_AllFuel_ShouldReachZero() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(300.0)
	assert_float(_system.get_current_fuel()).is_equal(0.0)

## Handles `test_Consume_MoreThanAvailable_ShouldClampToZero`.
func test_Consume_MoreThanAvailable_ShouldClampToZero() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(999.0)
	assert_float(_system.get_current_fuel()).is_equal(0.0)

## Handles `test_GetPercentage_FullTank_ShouldBe100`.
func test_GetPercentage_FullTank_ShouldBe100() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_float(_system.get_fuel_percentage()).is_equal(100.0)

## Handles `test_GetPercentage_HalfTank_ShouldBe50`.
func test_GetPercentage_HalfTank_ShouldBe50() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(150.0)
	assert_float(_system.get_fuel_percentage()).is_equal(50.0)

## Handles `test_IsLow_AboveThreshold_ShouldBeFalse`.
func test_IsLow_AboveThreshold_ShouldBeFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_bool(_system.is_fuel_low()).is_false()

## Handles `test_IsLow_BelowThreshold_ShouldBeTrue`.
func test_IsLow_BelowThreshold_ShouldBeTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)

	_system.consume(230.0)
	assert_bool(_system.is_fuel_low()).is_true()

## Handles `test_IsCritical_AboveThreshold_ShouldBeFalse`.
func test_IsCritical_AboveThreshold_ShouldBeFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(260.0)
	assert_bool(_system.is_fuel_critical()).is_false()

## Handles `test_IsCritical_BelowThreshold_ShouldBeTrue`.
func test_IsCritical_BelowThreshold_ShouldBeTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(271.0)
	assert_bool(_system.is_fuel_critical()).is_true()

## Handles `test_IsEmpty_WithFuel_ShouldBeFalse`.
func test_IsEmpty_WithFuel_ShouldBeFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_bool(_system.is_fuel_empty()).is_false()

## Handles `test_IsEmpty_NoFuel_ShouldBeTrue`.
func test_IsEmpty_NoFuel_ShouldBeTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(300.0)
	assert_bool(_system.is_fuel_empty()).is_true()

## Handles `test_CanTravel_EnoughFuel_ShouldBeTrue`.
func test_CanTravel_EnoughFuel_ShouldBeTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)

	assert_bool(_system.can_travel(100.0, 0)).is_true()

## Handles `test_CanTravel_NotEnoughFuel_ShouldBeFalse`.
func test_CanTravel_NotEnoughFuel_ShouldBeFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)

	assert_bool(_system.can_travel(101.0, 0)).is_false()

## Handles `test_CanTravel_WithWagons_ShouldAccountForExtra`.
func test_CanTravel_WithWagons_ShouldAccountForExtra() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)

	assert_bool(_system.can_travel(100.0, 3)).is_false()

	assert_bool(_system.can_travel(70.0, 3)).is_true()

## Handles `test_Refuel_Full_ShouldFillTank`.
func test_Refuel_Full_ShouldFillTank() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(200.0)
	_system.refuel_full()
	assert_float(_system.get_current_fuel()).is_equal(Balance.FUEL_TANK_COAL_OLD)

## Handles `test_RefuelAmount_ShouldAddFuel`.
func test_RefuelAmount_ShouldAddFuel() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(200.0)
	_system.refuel_amount(50.0)
	assert_float(_system.get_current_fuel()).is_equal(150.0)

## Handles `test_RefuelAmount_ShouldNotExceedCapacity`.
func test_RefuelAmount_ShouldNotExceedCapacity() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(50.0)
	_system.refuel_amount(999.0)
	assert_float(_system.get_current_fuel()).is_equal(Balance.FUEL_TANK_COAL_OLD)

## Handles `test_AutoRefuel_ShouldFillTankAndSpendMoney`.
func test_AutoRefuel_ShouldFillTankAndSpendMoney() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(200.0)
	var result := _system.auto_refuel()
	assert_bool(result).is_true()
	assert_float(_system.get_current_fuel()).is_equal(Balance.FUEL_TANK_COAL_OLD)

	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY - 200)

## Handles `test_AutoRefuel_AlreadyFull_ShouldNotSpendMoney`.
func test_AutoRefuel_AlreadyFull_ShouldNotSpendMoney() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var result := _system.auto_refuel()
	assert_bool(result).is_true()
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY)

## Handles `test_AutoRefuel_NotEnoughMoney_ShouldReturnFalse`.
func test_AutoRefuel_NotEnoughMoney_ShouldReturnFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_economy.set_balance(0)
	_system.consume(200.0)
	var result := _system.auto_refuel()
	assert_bool(result).is_false()

	assert_int(_economy.get_balance()).is_equal(0)
	assert_float(_system.get_current_fuel()).is_equal(100.0)

## Handles `test_GetRefuelCost_ShouldUseUnitPrice`.
func test_GetRefuelCost_ShouldUseUnitPrice() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	assert_int(_system.get_refuel_cost(12.4)).is_equal(13)

## Handles `test_BuyRefuel_EnoughMoney_ShouldIncreaseFuel`.
func test_BuyRefuel_EnoughMoney_ShouldIncreaseFuel() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(250.0)
	assert_bool(_system.buy_refuel(20.0)).is_true()
	assert_float(_system.get_current_fuel()).is_equal(70.0)

## Handles `test_BuyRefuel_NotEnoughMoney_ShouldReturnFalse`.
func test_BuyRefuel_NotEnoughMoney_ShouldReturnFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_economy.set_balance(5)
	_system.consume(250.0)
	assert_bool(_system.buy_refuel(20.0)).is_false()
	assert_float(_system.get_current_fuel()).is_equal(50.0)

## Handles `test_EnsureFuelForTrip_ShouldTopUpMinimum`.
func test_EnsureFuelForTrip_ShouldTopUpMinimum() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(250.0)
	var result := _system.ensure_fuel_for_trip(30.0, 0)
	assert_bool(result["can_travel"]).is_true()
	assert_float(_system.get_current_fuel()).is_equal(90.0)

## Handles `test_EnsureFuelForTrip_InsufficientMoney_ShouldFailTravelCheck`.
func test_EnsureFuelForTrip_InsufficientMoney_ShouldFailTravelCheck() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.consume(250.0)
	_economy.set_balance(10)
	var result := _system.ensure_fuel_for_trip(30.0, 0)
	assert_bool(result["can_travel"]).is_false()
	assert_float(_system.get_current_fuel()).is_equal(60.0)

## Handles `test_TripTracking_ShouldTrackOnlyConsumedAmount`.
func test_TripTracking_ShouldTrackOnlyConsumedAmount() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_system.begin_trip_tracking()
	_system.consume(25.5)
	_system.refuel_amount(10.0)
	_system.consume(4.5)
	assert_float(_system.get_trip_consumed()).is_equal(30.0)
	assert_int(_system.get_trip_consumed_cost()).is_equal(30)

## Handles `test_AutoRefuel_PartialMoney_ShouldFillPartially`.
func test_AutoRefuel_PartialMoney_ShouldFillPartially() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	_economy.set_balance(50)
	_system.consume(200.0)
	var result := _system.auto_refuel()
	assert_bool(result).is_true()
	assert_float(_system.get_current_fuel()).is_equal(150.0)
	assert_int(_economy.get_balance()).is_equal(0)

## Handles `test_Consume_ShouldEmitFuelChanged`.
func test_Consume_ShouldEmitFuelChanged() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var result := {"percentage": -1.0}
	_event_bus.fuel_changed.connect(func(pct: float) -> void: result["percentage"] = pct)
	_system.consume(150.0)
	assert_float(result["percentage"]).is_equal(50.0)

## Handles `test_Consume_BelowThreshold_ShouldEmitFuelLow`.
func test_Consume_BelowThreshold_ShouldEmitFuelLow() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var result := {"emitted": false}
	_event_bus.fuel_low.connect(func(_id: String, _pct: float) -> void: result["emitted"] = true)
	_system.consume(250.0)
	assert_bool(result["emitted"]).is_true()

## Handles `test_Consume_ToZero_ShouldEmitFuelEmpty`.
func test_Consume_ToZero_ShouldEmitFuelEmpty() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var result := {"emitted": false}
	_event_bus.fuel_empty.connect(func(_id: String) -> void: result["emitted"] = true)
	_system.consume(300.0)
	assert_bool(result["emitted"]).is_true()

## Handles `test_Consume_AboveThreshold_ShouldNotEmitFuelLow`.
func test_Consume_AboveThreshold_ShouldNotEmitFuelLow() -> void:
	var loco := LocomotiveData.create("kara_duman")
	_system.setup(_event_bus, _economy, loco)
	var result := {"emitted": false}
	_event_bus.fuel_low.connect(func(_id: String, _pct: float) -> void: result["emitted"] = true)
	_system.consume(100.0)
	assert_bool(result["emitted"]).is_false()
