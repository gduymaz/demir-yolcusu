## Test suite: test_difficulty_system.gd
## Validates dynamic difficulty multipliers, defaults, clamp, and persistence.

class_name TestDifficultySystem
extends GdUnitTestSuite

var _difficulty: Node

func before_test() -> void:
	_difficulty = auto_free(load("res://src/systems/difficulty_system.gd").new())

func test_FirstTrips_NoEnoughData_ShouldReturnDefaultMultipliers() -> void:
	_difficulty.record_trip(95.0)
	_difficulty.record_trip(90.0)
	assert_float(_difficulty.get_time_multiplier()).is_equal(1.0)
	assert_float(_difficulty.get_patience_multiplier()).is_equal(1.0)
	assert_float(_difficulty.get_breakdown_multiplier()).is_equal(1.0)
	assert_float(_difficulty.get_income_multiplier()).is_equal(1.0)

func test_HighPerformance_ShouldApplyHarderMultipliers() -> void:
	_difficulty.record_trip(90.0)
	_difficulty.record_trip(90.0)
	_difficulty.record_trip(90.0)
	assert_float(_difficulty.get_time_multiplier()).is_equal(0.85)
	assert_float(_difficulty.get_patience_multiplier()).is_equal(0.85)
	assert_float(_difficulty.get_breakdown_multiplier()).is_equal(1.3)
	assert_float(_difficulty.get_income_multiplier()).is_equal(0.95)

func test_LowPerformance_ShouldApplyEasierMultipliers() -> void:
	_difficulty.record_trip(20.0)
	_difficulty.record_trip(20.0)
	_difficulty.record_trip(20.0)
	assert_float(_difficulty.get_time_multiplier()).is_equal(1.3)
	assert_float(_difficulty.get_patience_multiplier()).is_equal(1.3)
	assert_float(_difficulty.get_breakdown_multiplier()).is_equal(0.7)
	assert_float(_difficulty.get_income_multiplier()).is_equal(1.15)

func test_MixedPerformance_ShouldApplyNormalMultipliers() -> void:
	_difficulty.record_trip(20.0)
	_difficulty.record_trip(70.0)
	_difficulty.record_trip(90.0)
	assert_float(_difficulty.get_average_performance()).is_equal(60.0)
	assert_float(_difficulty.get_time_multiplier()).is_equal(1.0)
	assert_float(_difficulty.get_income_multiplier()).is_equal(1.0)

func test_Clamp_ShouldKeepCustomOverridesInBounds() -> void:
	_difficulty.set_profile_multipliers(10.0, 10.0, 10.0, 10.0)
	_difficulty.record_trip(95.0)
	_difficulty.record_trip(95.0)
	_difficulty.record_trip(95.0)
	assert_float(_difficulty.get_time_multiplier()).is_equal(1.5)
	assert_float(_difficulty.get_patience_multiplier()).is_equal(1.5)
	assert_float(_difficulty.get_breakdown_multiplier()).is_equal(1.5)
	assert_float(_difficulty.get_income_multiplier()).is_equal(1.5)

func test_SaveLoad_ShouldPersistLastScores() -> void:
	_difficulty.record_trip(10.0)
	_difficulty.record_trip(50.0)
	_difficulty.record_trip(90.0)
	var data: Dictionary = _difficulty.get_save_data()
	var clone: Node = auto_free(load("res://src/systems/difficulty_system.gd").new())
	clone.load_save_data(data)
	assert_float(clone.get_average_performance()).is_equal(50.0)
