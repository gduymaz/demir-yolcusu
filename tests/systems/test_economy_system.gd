## EconomySystem testleri.
## TDD RED aşaması: Sistem davranışını testlerle tanımla.
extends GdUnitTestSuite


var _economy: EconomySystem
var _event_bus: Node


func before_test() -> void:
	_event_bus = auto_free(load("res://src/events/event_bus.gd").new())
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)


# ==========================================================
# BAŞLANGIÇ DURUMU
# ==========================================================

func test_InitialBalance_ShouldBeStartingMoney() -> void:
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY)


# ==========================================================
# EARN (PARA KAZANMA)
# ==========================================================

func test_Earn_ValidAmount_ShouldIncreaseBalance() -> void:
	var initial := _economy.get_balance()
	_economy.earn(100, "ticket")
	assert_int(_economy.get_balance()).is_equal(initial + 100)


func test_Earn_ZeroAmount_ShouldNotChangeBalance() -> void:
	var initial := _economy.get_balance()
	_economy.earn(0, "ticket")
	assert_int(_economy.get_balance()).is_equal(initial)


func test_Earn_NegativeAmount_ShouldNotChangeBalance() -> void:
	var initial := _economy.get_balance()
	_economy.earn(-50, "ticket")
	assert_int(_economy.get_balance()).is_equal(initial)


func test_Earn_ShouldEmitMoneyEarnedSignal() -> void:
	var result := {"amount": 0, "source": ""}
	_event_bus.money_earned.connect(func(amount: int, source: String) -> void:
		result["amount"] = amount
		result["source"] = source
	)
	_economy.earn(75, "cargo")
	assert_int(result["amount"]).is_equal(75)
	assert_str(result["source"]).is_equal("cargo")


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


func test_Earn_MultipleEarns_ShouldAccumulate() -> void:
	_economy.earn(100, "ticket")
	_economy.earn(200, "cargo")
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY + 300)


# ==========================================================
# SPEND (PARA HARCAMA)
# ==========================================================

func test_Spend_SufficientFunds_ShouldReturnTrue() -> void:
	var result := _economy.spend(100, "fuel")
	assert_bool(result).is_true()


func test_Spend_SufficientFunds_ShouldDecreaseBalance() -> void:
	_economy.spend(100, "fuel")
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY - 100)


func test_Spend_InsufficientFunds_ShouldReturnFalse() -> void:
	var result := _economy.spend(Balance.STARTING_MONEY + 1, "fuel")
	assert_bool(result).is_false()


func test_Spend_InsufficientFunds_ShouldNotChangeBalance() -> void:
	_economy.spend(Balance.STARTING_MONEY + 1, "fuel")
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY)


func test_Spend_ExactBalance_ShouldReturnTrue() -> void:
	var result := _economy.spend(Balance.STARTING_MONEY, "fuel")
	assert_bool(result).is_true()
	assert_int(_economy.get_balance()).is_equal(0)


func test_Spend_ZeroAmount_ShouldReturnTrueAndNotChange() -> void:
	var result := _economy.spend(0, "fuel")
	assert_bool(result).is_true()
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY)


func test_Spend_NegativeAmount_ShouldReturnFalse() -> void:
	var result := _economy.spend(-50, "fuel")
	assert_bool(result).is_false()
	assert_int(_economy.get_balance()).is_equal(Balance.STARTING_MONEY)


func test_Spend_ShouldEmitMoneySpentSignal() -> void:
	var result := {"amount": 0, "reason": ""}
	_event_bus.money_spent.connect(func(amount: int, reason: String) -> void:
		result["amount"] = amount
		result["reason"] = reason
	)
	_economy.spend(80, "maintenance")
	assert_int(result["amount"]).is_equal(80)
	assert_str(result["reason"]).is_equal("maintenance")


func test_Spend_ShouldEmitMoneyChangedSignal() -> void:
	var result := {"old": 0, "new": 0}
	_event_bus.money_changed.connect(func(old_val: int, new_val: int, _reason: String) -> void:
		result["old"] = old_val
		result["new"] = new_val
	)
	_economy.spend(200, "fuel")
	assert_int(result["old"]).is_equal(Balance.STARTING_MONEY)
	assert_int(result["new"]).is_equal(Balance.STARTING_MONEY - 200)


# ==========================================================
# CAN_AFFORD
# ==========================================================

func test_CanAfford_LessThanBalance_ShouldReturnTrue() -> void:
	assert_bool(_economy.can_afford(100)).is_true()


func test_CanAfford_ExactBalance_ShouldReturnTrue() -> void:
	assert_bool(_economy.can_afford(Balance.STARTING_MONEY)).is_true()


func test_CanAfford_MoreThanBalance_ShouldReturnFalse() -> void:
	assert_bool(_economy.can_afford(Balance.STARTING_MONEY + 1)).is_false()


func test_CanAfford_Zero_ShouldReturnTrue() -> void:
	assert_bool(_economy.can_afford(0)).is_true()


# ==========================================================
# SET_BALANCE (test yardımcı metodu)
# ==========================================================

func test_SetBalance_ShouldOverrideBalance() -> void:
	_economy.set_balance(1000)
	assert_int(_economy.get_balance()).is_equal(1000)


# ==========================================================
# BİLET FİYATI HESAPLAMA
# ==========================================================

func test_TicketPrice_ShortDistance_Normal_ShouldBeBasePrice() -> void:
	# 50 km, Normal yolcu
	var price := _economy.calculate_ticket_price(50, Constants.PassengerType.NORMAL)
	# 50 km × 2 DA/km × 1.0 (short) × 1.0 (normal) = 100 DA
	assert_int(price).is_equal(100)


func test_TicketPrice_MediumDistance_Normal_ShouldApplyMediumMultiplier() -> void:
	# 200 km, Normal yolcu
	var price := _economy.calculate_ticket_price(200, Constants.PassengerType.NORMAL)
	# 200 km × 2 DA/km × 1.5 (medium) × 1.0 (normal) = 600 DA
	assert_int(price).is_equal(600)


func test_TicketPrice_LongDistance_Normal_ShouldApplyLongMultiplier() -> void:
	# 400 km, Normal yolcu
	var price := _economy.calculate_ticket_price(400, Constants.PassengerType.NORMAL)
	# 400 km × 2 DA/km × 2.0 (long) × 1.0 (normal) = 1600 DA
	assert_int(price).is_equal(1600)


func test_TicketPrice_Student_ShouldApplyHalfPrice() -> void:
	# 50 km, Öğrenci
	var price := _economy.calculate_ticket_price(50, Constants.PassengerType.STUDENT)
	# 50 km × 2 DA/km × 1.0 (short) × 0.5 (student) = 50 DA
	assert_int(price).is_equal(50)


func test_TicketPrice_Elderly_ShouldApply30PercentDiscount() -> void:
	# 50 km, Yaşlı
	var price := _economy.calculate_ticket_price(50, Constants.PassengerType.ELDERLY)
	# 50 km × 2 DA/km × 1.0 (short) × 0.7 (elderly) = 70 DA
	assert_int(price).is_equal(70)


func test_TicketPrice_VIP_ShouldApplyTriplePrice() -> void:
	# 50 km, VIP
	var price := _economy.calculate_ticket_price(50, Constants.PassengerType.VIP)
	# 50 km × 2 DA/km × 1.0 (short) × 3.0 (VIP) = 300 DA
	assert_int(price).is_equal(300)


func test_TicketPrice_BoundaryAt100km_ShouldUseShortMultiplier() -> void:
	# 100 km tam sınır — short kademe
	var price := _economy.calculate_ticket_price(100, Constants.PassengerType.NORMAL)
	# 100 km × 2 DA/km × 1.0 (short) × 1.0 = 200 DA
	assert_int(price).is_equal(200)


func test_TicketPrice_BoundaryAt101km_ShouldUseMediumMultiplier() -> void:
	# 101 km — medium kademeye geçer
	var price := _economy.calculate_ticket_price(101, Constants.PassengerType.NORMAL)
	# 101 km × 2 DA/km × 1.5 (medium) × 1.0 = 303 DA
	assert_int(price).is_equal(303)


func test_TicketPrice_BoundaryAt300km_ShouldUseMediumMultiplier() -> void:
	# 300 km tam sınır — medium kademe
	var price := _economy.calculate_ticket_price(300, Constants.PassengerType.NORMAL)
	# 300 km × 2 DA/km × 1.5 (medium) × 1.0 = 900 DA
	assert_int(price).is_equal(900)


func test_TicketPrice_BoundaryAt301km_ShouldUseLongMultiplier() -> void:
	# 301 km — long kademeye geçer
	var price := _economy.calculate_ticket_price(301, Constants.PassengerType.NORMAL)
	# 301 km × 2 DA/km × 2.0 (long) × 1.0 = 1204 DA
	assert_int(price).is_equal(1204)


func test_TicketPrice_ZeroDistance_ShouldReturnZero() -> void:
	var price := _economy.calculate_ticket_price(0, Constants.PassengerType.NORMAL)
	assert_int(price).is_equal(0)


# ==========================================================
# SEFER ÖZETİ (Trip Summary)
# ==========================================================

func test_TripSummary_Initial_ShouldBeEmpty() -> void:
	var summary := _economy.get_trip_summary()
	assert_int(summary["total_earned"]).is_equal(0)
	assert_int(summary["total_spent"]).is_equal(0)
	assert_int(summary["net"]).is_equal(0)


func test_TripSummary_AfterEarnings_ShouldTrackEarned() -> void:
	_economy.earn(100, "ticket")
	_economy.earn(200, "cargo")
	var summary := _economy.get_trip_summary()
	assert_int(summary["total_earned"]).is_equal(300)


func test_TripSummary_AfterSpending_ShouldTrackSpent() -> void:
	_economy.spend(50, "fuel")
	_economy.spend(30, "maintenance")
	var summary := _economy.get_trip_summary()
	assert_int(summary["total_spent"]).is_equal(80)


func test_TripSummary_Net_ShouldBeEarningsMinusSpending() -> void:
	_economy.earn(300, "ticket")
	_economy.spend(100, "fuel")
	var summary := _economy.get_trip_summary()
	assert_int(summary["net"]).is_equal(200)


func test_TripSummary_ShouldTrackEarningsBySource() -> void:
	_economy.earn(100, "ticket")
	_economy.earn(200, "ticket")
	_economy.earn(50, "cargo")
	var summary := _economy.get_trip_summary()
	var earnings: Dictionary = summary["earnings"]
	assert_int(earnings["ticket"]).is_equal(300)
	assert_int(earnings["cargo"]).is_equal(50)


func test_TripSummary_ShouldTrackSpendingByReason() -> void:
	_economy.spend(80, "fuel")
	_economy.spend(40, "maintenance")
	var summary := _economy.get_trip_summary()
	var spendings: Dictionary = summary["spendings"]
	assert_int(spendings["fuel"]).is_equal(80)
	assert_int(spendings["maintenance"]).is_equal(40)


func test_ResetTripSummary_ShouldClearAll() -> void:
	_economy.earn(100, "ticket")
	_economy.spend(50, "fuel")
	_economy.reset_trip_summary()
	var summary := _economy.get_trip_summary()
	assert_int(summary["total_earned"]).is_equal(0)
	assert_int(summary["total_spent"]).is_equal(0)
