## Test suite: test_random_event_system.gd
## Validates random event probability, limits, and effect state.

class_name TestRandomEventSystem
extends GdUnitTestSuite

var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem
var _events: Node

## Handles `before_test`.
func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	_reputation = auto_free(ReputationSystem.new())
	_reputation.setup(_event_bus)
	_events = auto_free(load("res://src/systems/random_event_system.gd").new())
	_events.setup(_event_bus, _economy, _reputation)

## Handles `test_ProbabilityZero_ShouldNotTrigger`.
func test_ProbabilityZero_ShouldNotTrigger() -> void:
	_events.start_trip()
	_events.set_event_probability("evt_motor", 0.0)
	_events.set_roll_provider(func() -> float: return 0.0)
	var triggered: Dictionary = _events.try_trigger(Constants.RandomEventTrigger.ON_TRAVEL)
	assert_int(triggered.size()).is_equal(0)

## Handles `test_ProbabilityOne_ShouldTrigger`.
func test_ProbabilityOne_ShouldTrigger() -> void:
	_events.start_trip()
	_events.set_event_probability("evt_motor", 1.0)
	_events.set_roll_provider(func() -> float: return 0.0)
	var triggered: Dictionary = _events.try_trigger(Constants.RandomEventTrigger.ON_TRAVEL)
	assert_int(triggered.size()).is_greater(0)

## Handles `test_MaxTwoEventsPerTrip_ShouldEnforceLimit`.
func test_MaxTwoEventsPerTrip_ShouldEnforceLimit() -> void:
	_events.start_trip()
	_events.force_trigger("evt_motor")
	_events.force_trigger("evt_vip")
	var third: Dictionary = _events.force_trigger("evt_fuel_hike")
	assert_int(third.size()).is_equal(0)

## Handles `test_SameEventType_ShouldNotRepeatInTrip`.
func test_SameEventType_ShouldNotRepeatInTrip() -> void:
	_events.start_trip()
	var first: Dictionary = _events.force_trigger("evt_motor")
	var second: Dictionary = _events.force_trigger("evt_door")
	assert_str(first.get("id", "")).is_equal("evt_motor")
	assert_int(second.size()).is_equal(0)

## Handles `test_MotorFailure_ShouldApplySpeedMultiplier`.
func test_MotorFailure_ShouldApplySpeedMultiplier() -> void:
	_events.start_trip()
	_events.force_trigger("evt_motor")
	assert_float(_events.get_active_effect("speed_multiplier", 1.0)).is_equal(0.5)

## Handles `test_Festival_ShouldDoublePassengerMultiplier`.
func test_Festival_ShouldDoublePassengerMultiplier() -> void:
	_events.start_trip()
	_events.force_trigger("evt_festival")
	assert_float(_events.get_active_effect("passenger_multiplier", 1.0)).is_equal(2.0)

## Handles `test_DoorFailure_ShouldApplyStationTimeDelta`.
func test_DoorFailure_ShouldApplyStationTimeDelta() -> void:
	_events.start_trip()
	_events.force_trigger("evt_door")
	assert_float(_events.get_active_effect("station_time_delta", 0.0)).is_equal(-5.0)

## Handles `test_SickPassenger_ShouldGrantReputationBonus`.
func test_SickPassenger_ShouldGrantReputationBonus() -> void:
	_events.start_trip()
	_events.force_trigger("evt_sick")
	assert_float(_events.consume_reputation_bonus()).is_equal(0.5)

## Handles `test_FuelHike_ShouldSetFuelPriceMultiplier`.
func test_FuelHike_ShouldSetFuelPriceMultiplier() -> void:
	_events.start_trip()
	_events.force_trigger("evt_fuel_hike")
	assert_float(_events.get_trip_fuel_multiplier()).is_equal(1.5)
