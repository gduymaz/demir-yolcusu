## Test suite: test_economy_system.gd
## Restored English comments for maintainability and i18n coding standards.

extends GdUnitTestSuite

var _economy: EconomySystem
var _event_bus: Node

## Handles `before_test`.
func before_test() -> void:
	_event_bus = auto_free(load("res://src/events/event_bus.gd").new())
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)

## Handles `test_InitialBalance_ShouldBeStartingMoney`.
func test_InitialBalance_ShouldBeStartingMoney() -> void:
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY)

## Handles `test_Earn_ValidAmount_ShouldIncreaseBalance`.
func test_Earn_ValidAmount_ShouldIncreaseBalance() -> void:
	var initial := _economy.get_balance()
	_economy.earn(100, "ticket")
	assert_int(_economy.get_balance()).is_equal(initial + 100)

## Handles `test_Earn_ZeroAmount_ShouldNotChangeBalance`.
func test_Earn_ZeroAmount_ShouldNotChangeBalance() -> void:
	var initial := _economy.get_balance()
	_economy.earn(0, "ticket")
	assert_int(_economy.get_balance()).is_equal(initial)

## Handles `test_Earn_NegativeAmount_ShouldNotChangeBalance`.
func test_Earn_NegativeAmount_ShouldNotChangeBalance() -> void:
	var initial := _economy.get_balance()
	_economy.earn(-50, "ticket")
	assert_int(_economy.get_balance()).is_equal(initial)

## Handles `test_Earn_ShouldEmitMoneyEarnedSignal`.
func test_Earn_ShouldEmitMoneyEarnedSignal() -> void:
	var result := {"amount": 0, "source": ""}
	_event_bus.money_earned.connect(func(amount: int, source: String) -> void:
		result["amount"] = amount
		result["source"] = source
	)
	_economy.earn(75, "cargo")
	assert_int(result["amount"]).is_equal(75)
	assert_str(result["source"]).is_equal("cargo")

## Handles `test_Earn_ShouldEmitMoneyChangedSignal`.
func test_Earn_ShouldEmitMoneyChangedSignal() -> void:
	var result := {"old": 0, "new": 0, "reason": ""}
	_event_bus.money_changed.connect(func(old_val: int, new_val: int, reason: String) -> void:
		result["old"] = old_val
		result["new"] = new_val
		result["reason"] = reason
	)
	_economy.earn(100, "ticket")
	assert_int(result["old"]).is_equal(Balance.STARTING_MONEY)
	assert_int(result["new"]).is_equal(Balance.STARTING_MONEY + 100)

## Handles `test_Earn_MultipleEarns_ShouldAccumulate`.
func test_Earn_MultipleEarns_ShouldAccumulate() -> void:
	_economy.earn(100, "ticket")
	_economy.earn(200, "cargo")
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY + 300)

## Handles `test_Spend_SufficientFunds_ShouldReturnTrue`.
func test_Spend_SufficientFunds_ShouldReturnTrue() -> void:
	var result := _economy.spend(100, "fuel")
	assert_bool(result).is_true()

## Handles `test_Spend_SufficientFunds_ShouldDecreaseBalance`.
func test_Spend_SufficientFunds_ShouldDecreaseBalance() -> void:
	_economy.spend(100, "fuel")
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY - 100)

## Handles `test_Spend_InsufficientFunds_ShouldReturnFalse`.
func test_Spend_InsufficientFunds_ShouldReturnFalse() -> void:
	var result := _economy.spend(Balance.STARTING_MONEY + 1, "fuel")
	assert_bool(result).is_false()

## Handles `test_Spend_InsufficientFunds_ShouldNotChangeBalance`.
func test_Spend_InsufficientFunds_ShouldNotChangeBalance() -> void:
	_economy.spend(Balance.STARTING_MONEY + 1, "fuel")
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY)

## Handles `test_Spend_ExactBalance_ShouldReturnTrue`.
func test_Spend_ExactBalance_ShouldReturnTrue() -> void:
	var result := _economy.spend(Balance.STARTING_MONEY, "fuel")
	assert_bool(result).is_true()
	assert_int(_economy.get_balance()).is_equal(0)

## Handles `test_Spend_ZeroAmount_ShouldReturnTrueAndNotChange`.
func test_Spend_ZeroAmount_ShouldReturnTrueAndNotChange() -> void:
	var result := _economy.spend(0, "fuel")
	assert_bool(result).is_true()
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY)

## Handles `test_Spend_NegativeAmount_ShouldReturnFalse`.
func test_Spend_NegativeAmount_ShouldReturnFalse() -> void:
	var result := _economy.spend(-50, "fuel")
	assert_bool(result).is_false()
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY)

## Handles `test_Spend_ShouldEmitMoneySpentSignal`.
func test_Spend_ShouldEmitMoneySpentSignal() -> void:
	var result := {"amount": 0, "reason": ""}
	_event_bus.money_spent.connect(func(amount: int, reason: String) -> void:
		result["amount"] = amount
		result["reason"] = reason
	)
	_economy.spend(80, "maintenance")
	assert_int(result["amount"]).is_equal(80)
	assert_str(result["reason"]).is_equal("maintenance")

## Handles `test_Spend_ShouldEmitMoneyChangedSignal`.
func test_Spend_ShouldEmitMoneyChangedSignal() -> void:
	var result := {"old": 0, "new": 0}
	_event_bus.money_changed.connect(func(old_val: int, new_val: int, _reason: String) -> void:
		result["old"] = old_val
		result["new"] = new_val
	)
	_economy.spend(200, "fuel")
	assert_int(result["old"]).is_equal(Balance.STARTING_MONEY)
	assert_int(result["new"]).is_equal(Balance.STARTING_MONEY - 200)

## Handles `test_CanAfford_LessThanBalance_ShouldReturnTrue`.
func test_CanAfford_LessThanBalance_ShouldReturnTrue() -> void:
	assert_bool(_economy.can_afford(100)).is_true()

## Handles `test_CanAfford_ExactBalance_ShouldReturnTrue`.
func test_CanAfford_ExactBalance_ShouldReturnTrue() -> void:
	assert_bool(_economy.can_afford(Balance.STARTING_MONEY)).is_true()

## Handles `test_CanAfford_MoreThanBalance_ShouldReturnFalse`.
func test_CanAfford_MoreThanBalance_ShouldReturnFalse() -> void:
	assert_bool(_economy.can_afford(Balance.STARTING_MONEY + 1)).is_false()

## Handles `test_CanAfford_Zero_ShouldReturnTrue`.
func test_CanAfford_Zero_ShouldReturnTrue() -> void:
	assert_bool(_economy.can_afford(0)).is_true()

## Handles `test_SetBalance_ShouldOverrideBalance`.
func test_SetBalance_ShouldOverrideBalance() -> void:
	_economy.set_balance(1000)
	assert_int(_economy.get_balance()).is_equal(1000)

## Handles `test_TicketPrice_ShortDistance_Normal_ShouldBeBasePrice`.
func test_TicketPrice_ShortDistance_Normal_ShouldBeBasePrice() -> void:

	var price := _economy.calculate_ticket_price(50, Constants.PassengerType.NORMAL)

	assert_int(price).is_equal(100)

## Handles `test_TicketPrice_MediumDistance_Normal_ShouldApplyMediumMultiplier`.
func test_TicketPrice_MediumDistance_Normal_ShouldApplyMediumMultiplier() -> void:

	var price := _economy.calculate_ticket_price(200, Constants.PassengerType.NORMAL)

	assert_int(price).is_equal(600)

## Handles `test_TicketPrice_LongDistance_Normal_ShouldApplyLongMultiplier`.
func test_TicketPrice_LongDistance_Normal_ShouldApplyLongMultiplier() -> void:

	var price := _economy.calculate_ticket_price(400, Constants.PassengerType.NORMAL)

	assert_int(price).is_equal(1600)

## Handles `test_TicketPrice_Student_ShouldApplyHalfPrice`.
func test_TicketPrice_Student_ShouldApplyHalfPrice() -> void:

	var price := _economy.calculate_ticket_price(50, Constants.PassengerType.STUDENT)

	assert_int(price).is_equal(50)

## Handles `test_TicketPrice_Elderly_ShouldApply30PercentDiscount`.
func test_TicketPrice_Elderly_ShouldApply30PercentDiscount() -> void:

	var price := _economy.calculate_ticket_price(50, Constants.PassengerType.ELDERLY)

	assert_int(price).is_equal(70)

## Handles `test_TicketPrice_VIP_ShouldApplyTriplePrice`.
func test_TicketPrice_VIP_ShouldApplyTriplePrice() -> void:

	var price := _economy.calculate_ticket_price(50, Constants.PassengerType.VIP)

	assert_int(price).is_equal(300)

## Handles `test_TicketPrice_BoundaryAt100km_ShouldUseShortMultiplier`.
func test_TicketPrice_BoundaryAt100km_ShouldUseShortMultiplier() -> void:

	var price := _economy.calculate_ticket_price(100, Constants.PassengerType.NORMAL)

	assert_int(price).is_equal(200)

## Handles `test_TicketPrice_BoundaryAt101km_ShouldUseMediumMultiplier`.
func test_TicketPrice_BoundaryAt101km_ShouldUseMediumMultiplier() -> void:

	var price := _economy.calculate_ticket_price(101, Constants.PassengerType.NORMAL)

	assert_int(price).is_equal(303)

## Handles `test_TicketPrice_BoundaryAt300km_ShouldUseMediumMultiplier`.
func test_TicketPrice_BoundaryAt300km_ShouldUseMediumMultiplier() -> void:

	var price := _economy.calculate_ticket_price(300, Constants.PassengerType.NORMAL)

	assert_int(price).is_equal(900)

## Handles `test_TicketPrice_BoundaryAt301km_ShouldUseLongMultiplier`.
func test_TicketPrice_BoundaryAt301km_ShouldUseLongMultiplier() -> void:

	var price := _economy.calculate_ticket_price(301, Constants.PassengerType.NORMAL)

	assert_int(price).is_equal(1204)

## Handles `test_TicketPrice_ZeroDistance_ShouldReturnZero`.
func test_TicketPrice_ZeroDistance_ShouldReturnZero() -> void:
	var price := _economy.calculate_ticket_price(0, Constants.PassengerType.NORMAL)
	assert_int(price).is_equal(0)

## Handles `test_TripSummary_Initial_ShouldBeEmpty`.
func test_TripSummary_Initial_ShouldBeEmpty() -> void:
	var summary := _economy.get_trip_summary()
	assert_int(summary["total_earned"]).is_equal(0)
	assert_int(summary["total_spent"]).is_equal(0)
	assert_int(summary["net"]).is_equal(0)

## Handles `test_TripSummary_AfterEarnings_ShouldTrackEarned`.
func test_TripSummary_AfterEarnings_ShouldTrackEarned() -> void:
	_economy.earn(100, "ticket")
	_economy.earn(200, "cargo")
	var summary := _economy.get_trip_summary()
	assert_int(summary["total_earned"]).is_equal(300)

## Handles `test_TripSummary_AfterSpending_ShouldTrackSpent`.
func test_TripSummary_AfterSpending_ShouldTrackSpent() -> void:
	_economy.spend(50, "fuel")
	_economy.spend(30, "maintenance")
	var summary := _economy.get_trip_summary()
	assert_int(summary["total_spent"]).is_equal(80)

## Handles `test_TripSummary_Net_ShouldBeEarningsMinusSpending`.
func test_TripSummary_Net_ShouldBeEarningsMinusSpending() -> void:
	_economy.earn(300, "ticket")
	_economy.spend(100, "fuel")
	var summary := _economy.get_trip_summary()
	assert_int(summary["net"]).is_equal(200)

## Handles `test_TripSummary_ShouldTrackEarningsBySource`.
func test_TripSummary_ShouldTrackEarningsBySource() -> void:
	_economy.earn(100, "ticket")
	_economy.earn(200, "ticket")
	_economy.earn(50, "cargo")
	var summary := _economy.get_trip_summary()
	var earnings: Dictionary = summary["earnings"]
	assert_int(earnings["ticket"]).is_equal(300)
	assert_int(earnings["cargo"]).is_equal(50)

## Handles `test_TripSummary_ShouldTrackSpendingByReason`.
func test_TripSummary_ShouldTrackSpendingByReason() -> void:
	_economy.spend(80, "fuel")
	_economy.spend(40, "maintenance")
	var summary := _economy.get_trip_summary()
	var spendings: Dictionary = summary["spendings"]
	assert_int(spendings["fuel"]).is_equal(80)
	assert_int(spendings["maintenance"]).is_equal(40)

## Handles `test_ResetTripSummary_ShouldClearAll`.
func test_ResetTripSummary_ShouldClearAll() -> void:
	_economy.earn(100, "ticket")
	_economy.spend(50, "fuel")
	_economy.reset_trip_summary()
	var summary := _economy.get_trip_summary()
	assert_int(summary["total_earned"]).is_equal(0)
	assert_int(summary["total_spent"]).is_equal(0)
