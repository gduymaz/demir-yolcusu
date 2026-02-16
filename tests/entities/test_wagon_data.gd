## Test suite: test_wagon_data.gd
## Restored English comments for maintainability and i18n coding standards.

extends GdUnitTestSuite

## Handles `test_Create_Economy_ShouldHaveCorrectCapacity`.
func test_Create_Economy_ShouldHaveCorrectCapacity() -> void:
	var w := WagonData.new(Constants.WagonType.ECONOMY)
	assert_int(w.get_capacity()).is_equal(Constants.CAPACITY_ECONOMY)

## Handles `test_Create_Business_ShouldHaveCorrectCapacity`.
func test_Create_Business_ShouldHaveCorrectCapacity() -> void:
	var w := WagonData.new(Constants.WagonType.BUSINESS)
	assert_int(w.get_capacity()).is_equal(Constants.CAPACITY_BUSINESS)

## Handles `test_Create_VIP_ShouldHaveCorrectCapacity`.
func test_Create_VIP_ShouldHaveCorrectCapacity() -> void:
	var w := WagonData.new(Constants.WagonType.VIP)
	assert_int(w.get_capacity()).is_equal(Constants.CAPACITY_VIP)

## Handles `test_Create_ShouldStartEmpty`.
func test_Create_ShouldStartEmpty() -> void:
	var w := WagonData.new(Constants.WagonType.ECONOMY)
	assert_int(w.get_passenger_count()).is_equal(0)
	assert_bool(w.is_full()).is_false()

## Handles `test_AddPassenger_Normal_ToEconomy_ShouldReturnTrue`.
func test_AddPassenger_Normal_ToEconomy_ShouldReturnTrue() -> void:
	var w := WagonData.new(Constants.WagonType.ECONOMY)
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	assert_bool(w.add_passenger(p)).is_true()
	assert_int(w.get_passenger_count()).is_equal(1)

## Handles `test_AddPassenger_Full_ShouldReturnFalse`.
func test_AddPassenger_Full_ShouldReturnFalse() -> void:
	var w := WagonData.new(Constants.WagonType.VIP)
	for i in Constants.CAPACITY_VIP:
		var p := PassengerFactory.create(Constants.PassengerType.VIP, "test", 50)
		w.add_passenger(p)
	var extra := PassengerFactory.create(Constants.PassengerType.VIP, "test", 50)
	assert_bool(w.add_passenger(extra)).is_false()
	assert_int(w.get_passenger_count()).is_equal(Constants.CAPACITY_VIP)

## Handles `test_AddPassenger_VIP_ToEconomy_ShouldReturnFalse`.
func test_AddPassenger_VIP_ToEconomy_ShouldReturnFalse() -> void:
	var w := WagonData.new(Constants.WagonType.ECONOMY)
	var p := PassengerFactory.create(Constants.PassengerType.VIP, "test", 50)
	assert_bool(w.add_passenger(p)).is_false()

## Handles `test_AddPassenger_VIP_ToBusiness_ShouldReturnTrue`.
func test_AddPassenger_VIP_ToBusiness_ShouldReturnTrue() -> void:
	var w := WagonData.new(Constants.WagonType.BUSINESS)
	var p := PassengerFactory.create(Constants.PassengerType.VIP, "test", 50)
	assert_bool(w.add_passenger(p)).is_true()

## Handles `test_AddPassenger_VIP_ToVIP_ShouldReturnTrue`.
func test_AddPassenger_VIP_ToVIP_ShouldReturnTrue() -> void:
	var w := WagonData.new(Constants.WagonType.VIP)
	var p := PassengerFactory.create(Constants.PassengerType.VIP, "test", 50)
	assert_bool(w.add_passenger(p)).is_true()

## Handles `test_AddPassenger_Normal_ToCargo_ShouldReturnFalse`.
func test_AddPassenger_Normal_ToCargo_ShouldReturnFalse() -> void:
	var w := WagonData.new(Constants.WagonType.CARGO)
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	assert_bool(w.add_passenger(p)).is_false()

## Handles `test_AddPassenger_Normal_ToDining_ShouldReturnFalse`.
func test_AddPassenger_Normal_ToDining_ShouldReturnFalse() -> void:
	var w := WagonData.new(Constants.WagonType.DINING)
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	assert_bool(w.add_passenger(p)).is_false()

## Handles `test_AddPassenger_Normal_ToBusiness_ShouldReturnTrue`.
func test_AddPassenger_Normal_ToBusiness_ShouldReturnTrue() -> void:
	var w := WagonData.new(Constants.WagonType.BUSINESS)
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	assert_bool(w.add_passenger(p)).is_true()

## Handles `test_CanAccept_ShouldReflectTypeAndCapacity`.
func test_CanAccept_ShouldReflectTypeAndCapacity() -> void:
	var w := WagonData.new(Constants.WagonType.ECONOMY)
	var normal := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	var vip := PassengerFactory.create(Constants.PassengerType.VIP, "test", 50)
	assert_bool(w.can_accept(normal)).is_true()
	assert_bool(w.can_accept(vip)).is_false()

## Handles `test_RemovePassenger_Existing_ShouldReturnTrue`.
func test_RemovePassenger_Existing_ShouldReturnTrue() -> void:
	var w := WagonData.new(Constants.WagonType.ECONOMY)
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	w.add_passenger(p)
	assert_bool(w.remove_passenger(p["id"])).is_true()
	assert_int(w.get_passenger_count()).is_equal(0)

## Handles `test_RemovePassenger_NonExisting_ShouldReturnFalse`.
func test_RemovePassenger_NonExisting_ShouldReturnFalse() -> void:
	var w := WagonData.new(Constants.WagonType.ECONOMY)
	assert_bool(w.remove_passenger("fake_id")).is_false()

## Handles `test_GetPassengersForDestination_ShouldFilterCorrectly`.
func test_GetPassengersForDestination_ShouldFilterCorrectly() -> void:
	var w := WagonData.new(Constants.WagonType.ECONOMY)
	var p1 := PassengerFactory.create(Constants.PassengerType.NORMAL, "izmir", 50)
	var p2 := PassengerFactory.create(Constants.PassengerType.NORMAL, "denizli", 80)
	var p3 := PassengerFactory.create(Constants.PassengerType.NORMAL, "izmir", 50)
	w.add_passenger(p1)
	w.add_passenger(p2)
	w.add_passenger(p3)
	var izmir_passengers := w.get_passengers_for_destination("izmir")
	assert_int(izmir_passengers.size()).is_equal(2)
