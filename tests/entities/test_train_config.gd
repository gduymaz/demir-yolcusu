## Test suite: test_train_config.gd
## Restored English comments for maintainability and i18n coding standards.

class_name TestTrainConfig
extends GdUnitTestSuite

## Handles `test_Create_WithLocomotive_ShouldStoreIt`.
func test_Create_WithLocomotive_ShouldStoreIt() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	assert_str(config.get_locomotive().id).is_equal("kara_duman")

## Handles `test_Create_ShouldStartWithNoWagons`.
func test_Create_ShouldStartWithNoWagons() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	assert_int(config.get_wagon_count()).is_equal(0)

## Handles `test_AddWagon_SingleWagon_ShouldIncreaseCount`.
func test_AddWagon_SingleWagon_ShouldIncreaseCount() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var result := config.add_wagon(wagon)
	assert_bool(result).is_true()
	assert_int(config.get_wagon_count()).is_equal(1)

## Handles `test_AddWagon_UpToMax_ShouldSucceed`.
func test_AddWagon_UpToMax_ShouldSucceed() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	for i in range(3):
		var wagon := WagonData.new(Constants.WagonType.ECONOMY)
		assert_bool(config.add_wagon(wagon)).is_true()
	assert_int(config.get_wagon_count()).is_equal(3)

## Handles `test_AddWagon_ExceedMax_ShouldReturnFalse`.
func test_AddWagon_ExceedMax_ShouldReturnFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	for i in range(3):
		config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	var extra := WagonData.new(Constants.WagonType.BUSINESS)
	assert_bool(config.add_wagon(extra)).is_false()
	assert_int(config.get_wagon_count()).is_equal(3)

## Handles `test_AddWagon_ShouldAppendToEnd`.
func test_AddWagon_ShouldAppendToEnd() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	var w1 := WagonData.new(Constants.WagonType.ECONOMY)
	var w2 := WagonData.new(Constants.WagonType.BUSINESS)
	config.add_wagon(w1)
	config.add_wagon(w2)
	var wagons := config.get_wagons()
	assert_int(wagons[0].type).is_equal(Constants.WagonType.ECONOMY)
	assert_int(wagons[1].type).is_equal(Constants.WagonType.BUSINESS)

## Handles `test_RemoveWagonAt_ValidIndex_ShouldRemove`.
func test_RemoveWagonAt_ValidIndex_ShouldRemove() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	config.add_wagon(WagonData.new(Constants.WagonType.BUSINESS))
	var removed := config.remove_wagon_at(0)
	assert_object(removed).is_not_null()
	assert_int(removed.type).is_equal(Constants.WagonType.ECONOMY)
	assert_int(config.get_wagon_count()).is_equal(1)

## Handles `test_RemoveWagonAt_InvalidIndex_ShouldReturnNull`.
func test_RemoveWagonAt_InvalidIndex_ShouldReturnNull() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	var removed := config.remove_wagon_at(0)
	assert_object(removed).is_null()

## Handles `test_RemoveWagonAt_NegativeIndex_ShouldReturnNull`.
func test_RemoveWagonAt_NegativeIndex_ShouldReturnNull() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	var removed := config.remove_wagon_at(-1)
	assert_object(removed).is_null()

## Handles `test_SwapWagons_ValidIndices_ShouldSwap`.
func test_SwapWagons_ValidIndices_ShouldSwap() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	config.add_wagon(WagonData.new(Constants.WagonType.BUSINESS))
	config.add_wagon(WagonData.new(Constants.WagonType.CARGO))
	var result := config.swap_wagons(0, 2)
	assert_bool(result).is_true()
	var wagons := config.get_wagons()
	assert_int(wagons[0].type).is_equal(Constants.WagonType.CARGO)
	assert_int(wagons[2].type).is_equal(Constants.WagonType.ECONOMY)

## Handles `test_SwapWagons_InvalidIndex_ShouldReturnFalse`.
func test_SwapWagons_InvalidIndex_ShouldReturnFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	assert_bool(config.swap_wagons(0, 5)).is_false()

## Handles `test_SwapWagons_SameIndex_ShouldReturnTrue`.
func test_SwapWagons_SameIndex_ShouldReturnTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	assert_bool(config.swap_wagons(0, 0)).is_true()

## Handles `test_GetTotalPassengerCapacity_NoWagons_ShouldBeZero`.
func test_GetTotalPassengerCapacity_NoWagons_ShouldBeZero() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	assert_int(config.get_total_passenger_capacity()).is_equal(0)

## Handles `test_GetTotalPassengerCapacity_WithWagons_ShouldSumAll`.
func test_GetTotalPassengerCapacity_WithWagons_ShouldSumAll() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	config.add_wagon(WagonData.new(Constants.WagonType.BUSINESS))
	assert_int(config.get_total_passenger_capacity()).is_equal(32)

## Handles `test_GetTotalPassengerCapacity_CargoShouldNotCount`.
func test_GetTotalPassengerCapacity_CargoShouldNotCount() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	config.add_wagon(WagonData.new(Constants.WagonType.CARGO))

	assert_int(config.get_total_passenger_capacity()).is_equal(20)

## Handles `test_GetTotalWeight_NoWagons_ShouldBeZero`.
func test_GetTotalWeight_NoWagons_ShouldBeZero() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	assert_float(config.get_total_weight()).is_equal(0.0)

## Handles `test_GetTotalWeight_WithWagons_ShouldMultiplyByConstant`.
func test_GetTotalWeight_WithWagons_ShouldMultiplyByConstant() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	config.add_wagon(WagonData.new(Constants.WagonType.BUSINESS))

	assert_float(config.get_total_weight()).is_equal(2 * Balance.WAGON_WEIGHT)

## Handles `test_GetMaxWagons_ShouldMatchLocomotive`.
func test_GetMaxWagons_ShouldMatchLocomotive() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	assert_int(config.get_max_wagons()).is_equal(Constants.MAX_WAGONS_COAL_OLD)

## Handles `test_IsFull_NotFull_ShouldBeFalse`.
func test_IsFull_NotFull_ShouldBeFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	assert_bool(config.is_full()).is_false()

## Handles `test_IsFull_AtMax_ShouldBeTrue`.
func test_IsFull_AtMax_ShouldBeTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	for i in range(3):
		config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	assert_bool(config.is_full()).is_true()

## Handles `test_SetLocomotive_ShouldChangeLocomotive`.
func test_SetLocomotive_ShouldChangeLocomotive() -> void:
	var loco1 := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco1)
	var loco2 := LocomotiveData.create("mavi_simsek")
	config.set_locomotive(loco2)
	assert_str(config.get_locomotive().id).is_equal("mavi_simsek")

## Handles `test_SetLocomotive_WithTooManyWagons_ShouldTrimExcess`.
func test_SetLocomotive_WithTooManyWagons_ShouldTrimExcess() -> void:
	var loco_big := LocomotiveData.create("mavi_simsek")
	var config := TrainConfig.new(loco_big)
	for i in range(5):
		config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	assert_int(config.get_wagon_count()).is_equal(5)
	var loco_small := LocomotiveData.create("kara_duman")
	config.set_locomotive(loco_small)
	assert_int(config.get_wagon_count()).is_equal(3)
