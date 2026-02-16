## Test suite: test_event_bus.gd
## Restored English comments for maintainability and i18n coding standards.

extends GdUnitTestSuite

var _event_bus: Node

## Handles `before_test`.
func before_test() -> void:
	_event_bus = auto_free(load("res://src/events/event_bus.gd").new())

## Handles `test_EventBus_Load_ShouldCreateInstance`.
func test_EventBus_Load_ShouldCreateInstance() -> void:
	assert_that(_event_bus).is_not_null()

## Handles `test_EventBus_HasSignal_MoneyChanged_ShouldExist`.
func test_EventBus_HasSignal_MoneyChanged_ShouldExist() -> void:
	assert_bool(_event_bus.has_signal("money_changed")).is_true()

## Handles `test_EventBus_HasSignal_PassengerBoarded_ShouldExist`.
func test_EventBus_HasSignal_PassengerBoarded_ShouldExist() -> void:
	assert_bool(_event_bus.has_signal("passenger_boarded")).is_true()

## Handles `test_EventBus_HasSignal_ReputationChanged_ShouldExist`.
func test_EventBus_HasSignal_ReputationChanged_ShouldExist() -> void:
	assert_bool(_event_bus.has_signal("reputation_changed")).is_true()

## Handles `test_EventBus_HasSignal_TripStarted_ShouldExist`.
func test_EventBus_HasSignal_TripStarted_ShouldExist() -> void:
	assert_bool(_event_bus.has_signal("trip_started")).is_true()

## Handles `test_EventBus_HasSignal_StationArrived_ShouldExist`.
func test_EventBus_HasSignal_StationArrived_ShouldExist() -> void:
	assert_bool(_event_bus.has_signal("station_arrived")).is_true()

## Handles `test_EventBus_EmitSignal_MoneyEarned_ShouldBeReceived`.
func test_EventBus_EmitSignal_MoneyEarned_ShouldBeReceived() -> void:

	var result := {"amount": 0, "source": ""}

	_event_bus.money_earned.connect(func(amount: int, source: String) -> void:
		result["amount"] = amount
		result["source"] = source
	)
	_event_bus.money_earned.emit(100, "ticket")

	assert_int(result["amount"]).is_equal(100)
	assert_str(result["source"]).is_equal("ticket")
