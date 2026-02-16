## Test suite: test_cargo_system.gd
## Validates cargo offer generation, loading, delivery, expiry, and persistence.

class_name TestCargoSystem
extends GdUnitTestSuite

var _event_bus: Node
var _economy: EconomySystem
var _cargo: Node

## Handles `before_test`.
func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	_cargo = auto_free(load("res://src/systems/cargo_system.gd").new())
	_cargo.setup(_event_bus, _economy)
	_cargo.set_cargo_wagon_available(true)
	_cargo.set_cargo_capacity(10)

## Handles `test_LoadCargo_NoCargoWagon_ShouldFail`.
func test_LoadCargo_NoCargoWagon_ShouldFail() -> void:
	_cargo.set_cargo_wagon_available(false)
	var id: String = _cargo.inject_offer({
		"name": "test",
		"origin_station": "AYDIN",
		"destination_station": "IZMIR (BASMANE)",
		"reward": 40,
		"weight": 1,
		"deadline_trips": 2,
	})
	assert_bool(_cargo.load_offer(id)).is_false()

## Handles `test_LoadCargo_CapacityFull_ShouldFail`.
func test_LoadCargo_CapacityFull_ShouldFail() -> void:
	_cargo.set_cargo_capacity(0)
	var id: String = _cargo.inject_offer({
		"name": "test",
		"origin_station": "AYDIN",
		"destination_station": "IZMIR (BASMANE)",
		"reward": 40,
		"weight": 1,
		"deadline_trips": 2,
	})
	assert_bool(_cargo.load_offer(id)).is_false()

## Handles `test_LoadCargo_ValidOffer_ShouldMoveToLoaded`.
func test_LoadCargo_ValidOffer_ShouldMoveToLoaded() -> void:
	var id: String = _cargo.inject_offer({
		"name": "test",
		"origin_station": "AYDIN",
		"destination_station": "IZMIR (BASMANE)",
		"reward": 40,
		"weight": 1,
		"deadline_trips": 2,
	})
	assert_bool(_cargo.load_offer(id)).is_true()
	assert_int(_cargo.get_loaded_cargos().size()).is_equal(1)

## Handles `test_DeliverAtDestination_ShouldEarnMoneyAndEmitDelivery`.
func test_DeliverAtDestination_ShouldEarnMoneyAndEmitDelivery() -> void:
	var delivered: Dictionary = {"count": 0}
	_event_bus.cargo_delivered.connect(func(_cargo_data: Dictionary, _station: String) -> void: delivered["count"] += 1)
	var id: String = _cargo.inject_offer({
		"name": "test",
		"origin_station": "AYDIN",
		"destination_station": "IZMIR (BASMANE)",
		"reward": 60,
		"weight": 1,
		"deadline_trips": 2,
	})
	assert_bool(_cargo.load_offer(id)).is_true()
	var before: int = _economy.get_balance()
	var count: int = _cargo.deliver_for_station("IZMIR (BASMANE)")
	assert_int(count).is_equal(1)
	assert_int(_economy.get_balance()).is_equal(before + 60)
	assert_int(delivered["count"]).is_equal(1)

## Handles `test_EndTrip_ShouldDecreaseDeadlineAndExpire`.
func test_EndTrip_ShouldDecreaseDeadlineAndExpire() -> void:
	var expired: Dictionary = {"count": 0}
	_event_bus.cargo_expired.connect(func(_cargo_data: Dictionary) -> void: expired["count"] += 1)
	var id: String = _cargo.inject_offer({
		"name": "test",
		"origin_station": "AYDIN",
		"destination_station": "IZMIR (BASMANE)",
		"reward": 60,
		"weight": 1,
		"deadline_trips": 1,
	})
	assert_bool(_cargo.load_offer(id)).is_true()
	_cargo.end_trip()
	assert_int(expired["count"]).is_equal(1)
	assert_int(_cargo.get_loaded_cargos().size()).is_equal(0)

## Handles `test_OfferGeneration_ShouldReturnZeroToTwoItems`.
func test_OfferGeneration_ShouldReturnZeroToTwoItems() -> void:
	_cargo.set_roll_provider(func() -> float: return 0.9)
	var offers: Array = _cargo.generate_offers("AYDIN")
	assert_int(offers.size()).is_less_equal(2)

## Handles `test_SaveLoad_ShouldRestoreActiveCargoState`.
func test_SaveLoad_ShouldRestoreActiveCargoState() -> void:
	var id: String = _cargo.inject_offer({
		"name": "test",
		"origin_station": "AYDIN",
		"destination_station": "IZMIR (BASMANE)",
		"reward": 60,
		"weight": 1,
		"deadline_trips": 2,
	})
	assert_bool(_cargo.load_offer(id)).is_true()
	var state: Dictionary = _cargo.get_save_data()

	var other: Node = auto_free(load("res://src/systems/cargo_system.gd").new())
	other.setup(_event_bus, _economy)
	other.load_save_data(state)
	assert_int(other.get_loaded_cargos().size()).is_equal(1)
