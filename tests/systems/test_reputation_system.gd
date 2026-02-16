## Test suite: test_reputation_system.gd
## Restored English comments for maintainability and i18n coding standards.

extends GdUnitTestSuite

var _reputation: ReputationSystem
var _event_bus: Node

## Handles `before_test`.
func before_test() -> void:
	_event_bus = auto_free(load("res://src/events/event_bus.gd").new())
	_reputation = auto_free(ReputationSystem.new())
	_reputation.setup(_event_bus)

## Handles `test_InitialReputation_ShouldBeStartingValue`.
func test_InitialReputation_ShouldBeStartingValue() -> void:
	assert_float(_reputation.get_reputation()).is_equal(Balance.REPUTATION_STARTING)

## Handles `test_InitialStars_ShouldMatchStartingValue`.
func test_InitialStars_ShouldMatchStartingValue() -> void:

	assert_float(_reputation.get_stars()).is_equal(Balance.REPUTATION_STARTING)

## Handles `test_Add_ValidPoints_ShouldIncrease`.
func test_Add_ValidPoints_ShouldIncrease() -> void:
	var initial := _reputation.get_reputation()
	_reputation.add(0.5, "passenger_delivered")
	assert_float(_reputation.get_reputation()).is_equal(initial + 0.5)

## Handles `test_Add_ZeroPoints_ShouldNotChange`.
func test_Add_ZeroPoints_ShouldNotChange() -> void:
	var initial := _reputation.get_reputation()
	_reputation.add(0.0, "test")
	assert_float(_reputation.get_reputation()).is_equal(initial)

## Handles `test_Add_NegativePoints_ShouldNotChange`.
func test_Add_NegativePoints_ShouldNotChange() -> void:
	var initial := _reputation.get_reputation()
	_reputation.add(-0.5, "test")
	assert_float(_reputation.get_reputation()).is_equal(initial)

## Handles `test_Add_ShouldNotExceedMaximum`.
func test_Add_ShouldNotExceedMaximum() -> void:
	_reputation.add(100.0, "test")
	assert_float(_reputation.get_reputation()).is_equal(Balance.REPUTATION_MAX)

## Handles `test_Add_ShouldEmitReputationChangedSignal`.
func test_Add_ShouldEmitReputationChangedSignal() -> void:
	var result := {"old": 0.0, "new": 0.0}
	_event_bus.reputation_changed.connect(func(old_val: float, new_val: float) -> void:
		result["old"] = old_val
		result["new"] = new_val
	)
	_reputation.add(0.5, "passenger_delivered")
	assert_float(result["old"]).is_equal(Balance.REPUTATION_STARTING)
	assert_float(result["new"]).is_equal(Balance.REPUTATION_STARTING + 0.5)

## Handles `test_Add_MultipleAdds_ShouldAccumulate`.
func test_Add_MultipleAdds_ShouldAccumulate() -> void:
	_reputation.add(0.3, "a")
	_reputation.add(0.2, "b")
	assert_float(_reputation.get_reputation()).is_equal(Balance.REPUTATION_STARTING + 0.5)

## Handles `test_Remove_ShouldApplyLossMultiplier`.
func test_Remove_ShouldApplyLossMultiplier() -> void:

	var initial := _reputation.get_reputation()
	_reputation.remove(1.0, "passenger_lost")
	var expected := initial - (1.0 * Balance.REPUTATION_LOSS_MULTIPLIER)
	assert_float(_reputation.get_reputation()).is_equal(expected)

## Handles `test_Remove_ZeroPoints_ShouldNotChange`.
func test_Remove_ZeroPoints_ShouldNotChange() -> void:
	var initial := _reputation.get_reputation()
	_reputation.remove(0.0, "test")
	assert_float(_reputation.get_reputation()).is_equal(initial)

## Handles `test_Remove_NegativePoints_ShouldNotChange`.
func test_Remove_NegativePoints_ShouldNotChange() -> void:
	var initial := _reputation.get_reputation()
	_reputation.remove(-0.5, "test")
	assert_float(_reputation.get_reputation()).is_equal(initial)

## Handles `test_Remove_ShouldNotGoBelowMinimum`.
func test_Remove_ShouldNotGoBelowMinimum() -> void:
	_reputation.remove(100.0, "test")
	assert_float(_reputation.get_reputation()).is_equal(Balance.REPUTATION_MIN)

## Handles `test_Remove_ShouldEmitReputationChangedSignal`.
func test_Remove_ShouldEmitReputationChangedSignal() -> void:
	var result := {"old": 0.0, "new": 0.0}
	_event_bus.reputation_changed.connect(func(old_val: float, new_val: float) -> void:
		result["old"] = old_val
		result["new"] = new_val
	)
	_reputation.remove(1.0, "passenger_lost")
	var expected_new := Balance.REPUTATION_STARTING - (1.0 * Balance.REPUTATION_LOSS_MULTIPLIER)
	assert_float(result["old"]).is_equal(Balance.REPUTATION_STARTING)
	assert_float(result["new"]).is_equal(expected_new)

## Handles `test_Remove_AsymmetricBehavior_LossShouldBeHalfOfGain`.
func test_Remove_AsymmetricBehavior_LossShouldBeHalfOfGain() -> void:

	var initial := _reputation.get_reputation()
	_reputation.add(1.0, "gain")
	_reputation.remove(1.0, "loss")

	assert_float(_reputation.get_reputation()).is_equal(initial + 0.5)

## Handles `test_Stars_AtMinimum_ShouldBeZero`.
func test_Stars_AtMinimum_ShouldBeZero() -> void:
	_reputation.set_reputation(0.0)
	assert_float(_reputation.get_stars()).is_equal(0.0)

## Handles `test_Stars_AtMaximum_ShouldBeFive`.
func test_Stars_AtMaximum_ShouldBeFive() -> void:
	_reputation.set_reputation(5.0)
	assert_float(_reputation.get_stars()).is_equal(5.0)

## Handles `test_Stars_AtHalf_ShouldBeTwoPointFive`.
func test_Stars_AtHalf_ShouldBeTwoPointFive() -> void:
	_reputation.set_reputation(2.5)
	assert_float(_reputation.get_stars()).is_equal(2.5)

## Handles `test_Stars_ShouldSupportHalfStars`.
func test_Stars_ShouldSupportHalfStars() -> void:
	_reputation.set_reputation(3.5)
	assert_float(_reputation.get_stars()).is_equal(3.5)

## Handles `test_MeetsRequirement_ExactStars_ShouldReturnTrue`.
func test_MeetsRequirement_ExactStars_ShouldReturnTrue() -> void:
	_reputation.set_reputation(3.0)
	assert_bool(_reputation.meets_requirement(3.0)).is_true()

## Handles `test_MeetsRequirement_HigherStars_ShouldReturnTrue`.
func test_MeetsRequirement_HigherStars_ShouldReturnTrue() -> void:
	_reputation.set_reputation(4.0)
	assert_bool(_reputation.meets_requirement(3.0)).is_true()

## Handles `test_MeetsRequirement_LowerStars_ShouldReturnFalse`.
func test_MeetsRequirement_LowerStars_ShouldReturnFalse() -> void:
	_reputation.set_reputation(2.0)
	assert_bool(_reputation.meets_requirement(3.0)).is_false()

## Handles `test_MeetsRequirement_ZeroRequired_ShouldAlwaysReturnTrue`.
func test_MeetsRequirement_ZeroRequired_ShouldAlwaysReturnTrue() -> void:
	_reputation.set_reputation(0.0)
	assert_bool(_reputation.meets_requirement(0.0)).is_true()

## Handles `test_MeetsRequirement_MaxRequired_OnlyMaxMeets`.
func test_MeetsRequirement_MaxRequired_OnlyMaxMeets() -> void:
	_reputation.set_reputation(4.9)
	assert_bool(_reputation.meets_requirement(5.0)).is_false()
	_reputation.set_reputation(5.0)
	assert_bool(_reputation.meets_requirement(5.0)).is_true()

## Handles `test_SetReputation_ShouldOverride`.
func test_SetReputation_ShouldOverride() -> void:
	_reputation.set_reputation(4.2)
	assert_float(_reputation.get_reputation()).is_equal(4.2)

## Handles `test_SetReputation_AboveMax_ShouldClampToMax`.
func test_SetReputation_AboveMax_ShouldClampToMax() -> void:
	_reputation.set_reputation(10.0)
	assert_float(_reputation.get_reputation()).is_equal(Balance.REPUTATION_MAX)

## Handles `test_SetReputation_BelowMin_ShouldClampToMin`.
func test_SetReputation_BelowMin_ShouldClampToMin() -> void:
	_reputation.set_reputation(-5.0)
	assert_float(_reputation.get_reputation()).is_equal(Balance.REPUTATION_MIN)
