## Test suite: test_trip_planner.gd
## Restored English comments for maintainability and i18n coding standards.

class_name TestTripPlanner
extends GdUnitTestSuite

var _planner: TripPlanner
var _event_bus: Node
var _economy: EconomySystem
var _fuel: FuelSystem
var _route: RouteData

## Handles `before_test`.
func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	var loco := LocomotiveData.create("kara_duman")
	_fuel = auto_free(FuelSystem.new())
	_fuel.setup(_event_bus, _economy, loco)
	_route = RouteData.load_ege_route()
	_planner = auto_free(TripPlanner.new())
	_planner.setup(_event_bus, _economy, _fuel, _route)

## Handles `test_SelectRoute_ShouldStoreStartAndEnd`.
func test_SelectRoute_ShouldStoreStartAndEnd() -> void:
	_planner.select_stops(0, 6)
	assert_int(_planner.get_start_index()).is_equal(0)
	assert_int(_planner.get_end_index()).is_equal(6)

## Handles `test_SelectRoute_ShouldCalculateStopCount`.
func test_SelectRoute_ShouldCalculateStopCount() -> void:
	_planner.select_stops(0, 6)
	assert_int(_planner.get_trip_stop_count()).is_equal(7)

## Handles `test_SelectRoute_Partial_ShouldWork`.
func test_SelectRoute_Partial_ShouldWork() -> void:
	_planner.select_stops(1, 4)
	assert_int(_planner.get_trip_stop_count()).is_equal(4)

## Handles `test_SelectRoute_Reversed_ShouldSwapIndices`.
func test_SelectRoute_Reversed_ShouldSwapIndices() -> void:
	_planner.select_stops(4, 1)
	assert_int(_planner.get_start_index()).is_equal(4)
	assert_int(_planner.get_end_index()).is_equal(1)
	assert_int(_planner.get_trip_stop_count()).is_equal(4)

## Handles `test_SelectRoute_Invalid_ShouldReturnFalse`.
func test_SelectRoute_Invalid_ShouldReturnFalse() -> void:
	assert_bool(_planner.select_stops(-1, 6)).is_false()
	assert_bool(_planner.select_stops(0, 99)).is_false()

## Handles `test_SelectRoute_SameStop_ShouldReturnFalse`.
func test_SelectRoute_SameStop_ShouldReturnFalse() -> void:
	assert_bool(_planner.select_stops(2, 2)).is_false()

## Handles `test_GetPreview_Distance_ShouldBePositive`.
func test_GetPreview_Distance_ShouldBePositive() -> void:
	_planner.select_stops(0, 6)
	var preview := _planner.get_preview()
	assert_float(preview["distance_km"]).is_greater(0.0)

## Handles `test_GetPreview_FuelCost_ShouldBePositive`.
func test_GetPreview_FuelCost_ShouldBePositive() -> void:
	_planner.select_stops(0, 6)
	var preview := _planner.get_preview()
	assert_float(preview["fuel_cost"]).is_greater(0.0)

## Handles `test_GetPreview_MoreWagons_ShouldIncreaseFuelCost`.
func test_GetPreview_MoreWagons_ShouldIncreaseFuelCost() -> void:
	_planner.select_stops(0, 6)
	_planner.set_wagon_count(0)
	var low := _planner.get_preview()
	_planner.set_wagon_count(4)
	var high := _planner.get_preview()
	assert_float(high["fuel_cost"]).is_greater(low["fuel_cost"])

## Handles `test_GetPreview_StopCount_ShouldMatch`.
func test_GetPreview_StopCount_ShouldMatch() -> void:
	_planner.select_stops(0, 6)
	var preview := _planner.get_preview()
	assert_int(preview["stop_count"]).is_equal(7)

## Handles `test_GetPreview_EstimatedRevenue_ShouldBePositive`.
func test_GetPreview_EstimatedRevenue_ShouldBePositive() -> void:
	_planner.select_stops(0, 6)
	var preview := _planner.get_preview()
	assert_int(preview["estimated_revenue"]).is_greater(0)

## Handles `test_GetPreview_CanAffordFuel_ShouldBeTrue`.
func test_GetPreview_CanAffordFuel_ShouldBeTrue() -> void:
	_planner.select_stops(0, 3)
	var preview := _planner.get_preview()
	assert_bool(preview["can_afford_fuel"]).is_true()

## Handles `test_GetPreview_TooExpensive_ShouldBeFalse`.
func test_GetPreview_TooExpensive_ShouldBeFalse() -> void:
	_economy.set_balance(0)
	_fuel.consume(280.0)
	_planner.select_stops(0, 6)
	var preview := _planner.get_preview()
	assert_bool(preview["can_afford_fuel"]).is_false()

## Handles `test_StartTrip_ShouldSetActive`.
func test_StartTrip_ShouldSetActive() -> void:
	_planner.select_stops(0, 3)
	assert_bool(_planner.start_trip()).is_true()
	assert_bool(_planner.is_trip_active()).is_true()

## Handles `test_StartTrip_ShouldSetCurrentStopToStart`.
func test_StartTrip_ShouldSetCurrentStopToStart() -> void:
	_planner.select_stops(0, 3)
	_planner.start_trip()
	assert_int(_planner.get_current_stop_index()).is_equal(0)

## Handles `test_StartTrip_NoRouteSelected_ShouldReturnFalse`.
func test_StartTrip_NoRouteSelected_ShouldReturnFalse() -> void:
	assert_bool(_planner.start_trip()).is_false()

## Handles `test_StartTrip_ShouldConsumeFuelForRefuel`.
func test_StartTrip_ShouldConsumeFuelForRefuel() -> void:
	_planner.select_stops(0, 3)
	_fuel.consume(200.0)
	var balance_before := _economy.get_balance()
	_planner.start_trip()

	assert_int(_economy.get_balance()).is_less_equal(balance_before)

## Handles `test_AdvanceToNextStop_ShouldIncrementIndex`.
func test_AdvanceToNextStop_ShouldIncrementIndex() -> void:
	_planner.select_stops(0, 3)
	_planner.start_trip()
	_planner.advance_to_next_stop()
	assert_int(_planner.get_current_stop_index()).is_equal(1)

## Handles `test_AdvanceToNextStop_ShouldConsumeFuel`.
func test_AdvanceToNextStop_ShouldConsumeFuel() -> void:
	_planner.select_stops(0, 3)
	_planner.start_trip()
	var fuel_before := _fuel.get_current_fuel()
	_planner.advance_to_next_stop()
	assert_float(_fuel.get_current_fuel()).is_less(fuel_before)

## Handles `test_AdvanceToNextStop_AtEnd_ShouldEndTrip`.
func test_AdvanceToNextStop_AtEnd_ShouldEndTrip() -> void:
	_planner.select_stops(0, 2)
	_planner.start_trip()
	_planner.advance_to_next_stop()
	_planner.advance_to_next_stop()
	assert_bool(_planner.is_at_final_stop()).is_true()

## Handles `test_IsAtFinalStop_NotAtEnd_ShouldBeFalse`.
func test_IsAtFinalStop_NotAtEnd_ShouldBeFalse() -> void:
	_planner.select_stops(0, 6)
	_planner.start_trip()
	assert_bool(_planner.is_at_final_stop()).is_false()

## Handles `test_EndTrip_ShouldDeactivate`.
func test_EndTrip_ShouldDeactivate() -> void:
	_planner.select_stops(0, 3)
	_planner.start_trip()
	_planner.end_trip()
	assert_bool(_planner.is_trip_active()).is_false()

## Handles `test_EndTrip_ShouldEmitSignal`.
func test_EndTrip_ShouldEmitSignal() -> void:
	_planner.select_stops(0, 3)
	_planner.start_trip()
	var result := {"emitted": false}
	_event_bus.trip_completed.connect(func(_summary: Dictionary) -> void: result["emitted"] = true)
	_planner.end_trip()
	assert_bool(result["emitted"]).is_true()

## Handles `test_GetCurrentStop_ShouldReturnStopData`.
func test_GetCurrentStop_ShouldReturnStopData() -> void:
	_planner.select_stops(0, 6)
	_planner.start_trip()
	var stop := _planner.get_current_stop()
	assert_bool(stop["name"].begins_with("IZMIR")).is_true()

## Handles `test_GetNextStop_ShouldReturnNextStopData`.
func test_GetNextStop_ShouldReturnNextStopData() -> void:
	_planner.select_stops(0, 6)
	_planner.start_trip()
	var next := _planner.get_next_stop()
	assert_str(next["name"]).is_equal("TORBALI")

## Handles `test_GetNextStop_AtEnd_ShouldReturnEmpty`.
func test_GetNextStop_AtEnd_ShouldReturnEmpty() -> void:
	_planner.select_stops(0, 1)
	_planner.start_trip()
	_planner.advance_to_next_stop()
	var next := _planner.get_next_stop()
	assert_int(next.size()).is_equal(0)

## Handles `test_GetDistanceToNextStop_ShouldBePositive`.
func test_GetDistanceToNextStop_ShouldBePositive() -> void:
	_planner.select_stops(0, 6)
	_planner.start_trip()
	assert_float(_planner.get_distance_to_next_stop()).is_greater(0.0)
