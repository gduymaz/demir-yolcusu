## Test suite: test_boarding_system.gd
## Restored English comments for maintainability and i18n coding standards.

extends GdUnitTestSuite

var _boarding: BoardingSystem
var _economy: EconomySystem
var _reputation: ReputationSystem
var _event_bus: Node

## Handles `before_test`.
func before_test() -> void:
	_event_bus = auto_free(load("res://src/events/event_bus.gd").new())
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	_reputation = auto_free(ReputationSystem.new())
	_reputation.setup(_event_bus)
	_boarding = auto_free(BoardingSystem.new())
	_boarding.setup(_event_bus, _economy, _reputation)

## Handles `test_Board_NormalToEconomy_ShouldReturnTrue`.
func test_Board_NormalToEconomy_ShouldReturnTrue() -> void:
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var passenger := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 100)
	assert_bool(_boarding.board_passenger(passenger, wagon)).is_true()

## Handles `test_Board_ShouldAddPassengerToWagon`.
func test_Board_ShouldAddPassengerToWagon() -> void:
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var passenger := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 100)
	_boarding.board_passenger(passenger, wagon)
	assert_int(wagon.get_passenger_count()).is_equal(1)

## Handles `test_Board_ShouldEarnFare`.
func test_Board_ShouldEarnFare() -> void:
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var passenger := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 100)
	var initial_balance := _economy.get_balance()
	_boarding.board_passenger(passenger, wagon)
	assert_int(_economy.get_balance()).is_equal(initial_balance + passenger["fare"])

## Handles `test_Board_ShouldEmitPassengerBoardedSignal`.
func test_Board_ShouldEmitPassengerBoardedSignal() -> void:
	var result := {"passenger": {}, "wagon_id": -1}
	_event_bus.passenger_boarded.connect(func(p_data: Dictionary, w_id: int) -> void:
		result["passenger"] = p_data
		result["wagon_id"] = w_id
	)
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var passenger := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 100)
	_boarding.board_passenger(passenger, wagon)
	assert_str(result["passenger"]["id"]).is_equal(passenger["id"])

## Handles `test_Board_ShouldAddReputation`.
func test_Board_ShouldAddReputation() -> void:
	var initial_rep := _reputation.get_reputation()
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var passenger := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 100)
	_boarding.board_passenger(passenger, wagon)
	assert_float(_reputation.get_reputation()).is_greater(initial_rep)

## Handles `test_Board_VIPToEconomy_ShouldReturnFalse`.
func test_Board_VIPToEconomy_ShouldReturnFalse() -> void:
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var passenger := PassengerFactory.create(Constants.PassengerType.VIP, "test", 100)
	assert_bool(_boarding.board_passenger(passenger, wagon)).is_false()

## Handles `test_Board_VIPToEconomy_ShouldNotAddPassenger`.
func test_Board_VIPToEconomy_ShouldNotAddPassenger() -> void:
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var passenger := PassengerFactory.create(Constants.PassengerType.VIP, "test", 100)
	_boarding.board_passenger(passenger, wagon)
	assert_int(wagon.get_passenger_count()).is_equal(0)

## Handles `test_Board_VIPToEconomy_ShouldNotEarnMoney`.
func test_Board_VIPToEconomy_ShouldNotEarnMoney() -> void:
	var initial := _economy.get_balance()
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var passenger := PassengerFactory.create(Constants.PassengerType.VIP, "test", 100)
	_boarding.board_passenger(passenger, wagon)
	assert_int(_economy.get_balance()).is_equal(initial)

## Handles `test_Board_FullWagon_ShouldReturnFalse`.
func test_Board_FullWagon_ShouldReturnFalse() -> void:
	var wagon := WagonData.new(Constants.WagonType.VIP)
	for i in Constants.CAPACITY_VIP:
		var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
		wagon.add_passenger(p)
	var extra := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	assert_bool(_boarding.board_passenger(extra, wagon)).is_false()

## Handles `test_Board_ToCargo_ShouldReturnFalse`.
func test_Board_ToCargo_ShouldReturnFalse() -> void:
	var wagon := WagonData.new(Constants.WagonType.CARGO)
	var passenger := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 100)
	assert_bool(_boarding.board_passenger(passenger, wagon)).is_false()

## Handles `test_Alight_AtDestination_ShouldRemovePassengers`.
func test_Alight_AtDestination_ShouldRemovePassengers() -> void:
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var p1 := PassengerFactory.create(Constants.PassengerType.NORMAL, "izmir", 50)
	var p2 := PassengerFactory.create(Constants.PassengerType.NORMAL, "denizli", 80)
	var p3 := PassengerFactory.create(Constants.PassengerType.NORMAL, "izmir", 50)
	wagon.add_passenger(p1)
	wagon.add_passenger(p2)
	wagon.add_passenger(p3)
	var alighted := _boarding.alight_passengers(wagon, "izmir")
	assert_int(alighted.size()).is_equal(2)
	assert_int(wagon.get_passenger_count()).is_equal(1)

## Handles `test_Alight_NoMatchingDestination_ShouldReturnEmpty`.
func test_Alight_NoMatchingDestination_ShouldReturnEmpty() -> void:
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "denizli", 80)
	wagon.add_passenger(p)
	var alighted := _boarding.alight_passengers(wagon, "izmir")
	assert_int(alighted.size()).is_equal(0)
	assert_int(wagon.get_passenger_count()).is_equal(1)
