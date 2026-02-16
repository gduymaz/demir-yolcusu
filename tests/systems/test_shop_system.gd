## Test suite: test_shop_system.gd
## Validates shop opening/upgrading, slot limits, trip income, and modifiers.

class_name TestShopSystem
extends GdUnitTestSuite

var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem
var _shops: Node

func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	_reputation = auto_free(ReputationSystem.new())
	_reputation.setup(_event_bus)
	_shops = auto_free(load("res://src/systems/shop_system.gd").new())
	_shops.setup(_event_bus, _economy, _reputation)

func test_OpenShop_EnoughMoneyAndReputation_ShouldSucceed() -> void:
	_economy.set_balance(1000)
	_reputation.set_reputation(3.0)
	assert_bool(_shops.open_shop("AYDIN", Constants.ShopType.BUFFET)).is_true()
	assert_int(_shops.get_station_shop_level("AYDIN", Constants.ShopType.BUFFET)).is_equal(1)

func test_OpenShop_NotEnoughMoney_ShouldFail() -> void:
	_economy.set_balance(50)
	_reputation.set_reputation(3.0)
	assert_bool(_shops.open_shop("AYDIN", Constants.ShopType.BUFFET)).is_false()

func test_OpenShop_NotEnoughReputation_ShouldFail() -> void:
	_economy.set_balance(1000)
	_reputation.set_reputation(0.5)
	assert_bool(_shops.open_shop("AYDIN", Constants.ShopType.BUFFET)).is_false()

func test_UpgradeShop_ShouldReachMaxLevelAndStopAtThree() -> void:
	_economy.set_balance(3000)
	_reputation.set_reputation(4.0)
	assert_bool(_shops.open_shop("AYDIN", Constants.ShopType.BUFFET)).is_true()
	assert_bool(_shops.upgrade_shop("AYDIN", Constants.ShopType.BUFFET)).is_true()
	assert_bool(_shops.upgrade_shop("AYDIN", Constants.ShopType.BUFFET)).is_true()
	assert_bool(_shops.upgrade_shop("AYDIN", Constants.ShopType.BUFFET)).is_false()
	assert_int(_shops.get_station_shop_level("AYDIN", Constants.ShopType.BUFFET)).is_equal(3)

func test_GetTripIncome_MultipleVisitedStations_ShouldSumIncome() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(4.0)
	assert_bool(_shops.open_shop("AYDIN", Constants.ShopType.BUFFET)).is_true()
	assert_bool(_shops.open_shop("TORBALI", Constants.ShopType.SOUVENIR)).is_true()
	var income: int = _shops.get_trip_income(["AYDIN", "TORBALI", "AYDIN"])
	assert_int(income).is_equal(Balance.SHOP_BUFFET_INCOME_L1 + Balance.SHOP_SOUVENIR_INCOME_L1)

func test_StationSlots_WhenFull_ShouldRejectThirdShop() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(4.0)
	assert_bool(_shops.open_shop("AYDIN", Constants.ShopType.BUFFET)).is_true()
	assert_bool(_shops.open_shop("AYDIN", Constants.ShopType.SOUVENIR)).is_true()
	assert_bool(_shops.open_shop("AYDIN", Constants.ShopType.CARGO_DEPOT)).is_false()

func test_CargoDepot_ShouldIncreaseCargoOfferBonus() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(4.0)
	assert_bool(_shops.open_shop("AYDIN", Constants.ShopType.CARGO_DEPOT)).is_true()
	assert_bool(_shops.upgrade_shop("AYDIN", Constants.ShopType.CARGO_DEPOT)).is_true()
	assert_int(_shops.get_cargo_offer_bonus("AYDIN")).is_equal(2)

func test_Buffet_ShouldReducePatienceDrainMultiplier() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(4.0)
	assert_bool(_shops.open_shop("AYDIN", Constants.ShopType.BUFFET)).is_true()
	assert_bool(_shops.upgrade_shop("AYDIN", Constants.ShopType.BUFFET)).is_true()
	assert_float(_shops.get_patience_multiplier("AYDIN")).is_equal(0.8)
