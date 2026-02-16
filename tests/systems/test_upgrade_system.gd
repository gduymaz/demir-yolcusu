## Test suite: test_upgrade_system.gd
## Validates locomotive/wagon upgrades, effects, caps, and respec.

class_name TestUpgradeSystem
extends GdUnitTestSuite

var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem
var _upgrades: Node

func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	_reputation = auto_free(ReputationSystem.new())
	_reputation.setup(_event_bus)
	_upgrades = auto_free(load("res://src/systems/upgrade_system.gd").new())
	_upgrades.setup(_event_bus, _economy, _reputation)

func test_UpgradeLocomotive_EnoughMoneyAndReputation_ShouldSucceed() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(5.0)
	assert_bool(_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.SPEED)).is_true()
	assert_int(_upgrades.get_locomotive_level("kara_duman", Constants.UpgradeType.SPEED)).is_equal(1)

func test_UpgradeLocomotive_NotEnoughMoneyOrReputation_ShouldFail() -> void:
	_economy.set_balance(10)
	_reputation.set_reputation(0.5)
	assert_bool(_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.SPEED)).is_false()

func test_UpgradeLocomotive_MaxLevel_ShouldNotExceedThree() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(5.0)
	assert_bool(_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.FUEL_EFFICIENCY)).is_true()
	assert_bool(_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.FUEL_EFFICIENCY)).is_true()
	assert_bool(_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.FUEL_EFFICIENCY)).is_true()
	assert_bool(_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.FUEL_EFFICIENCY)).is_false()

func test_SpeedModifier_LevelTwo_ShouldReduceDurationMultiplier() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(5.0)
	_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.SPEED)
	_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.SPEED)
	var mods: Dictionary = _upgrades.get_locomotive_modifiers("kara_duman")
	assert_float(mods.get("speed_multiplier", 1.0)).is_equal(0.81)

func test_CapacityModifier_LevelOne_ShouldIncreaseMaxWagonsByOne() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(5.0)
	_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.CAPACITY)
	var mods: Dictionary = _upgrades.get_locomotive_modifiers("kara_duman")
	assert_int(mods.get("capacity_bonus", 0)).is_equal(1)

func test_FuelModifier_LevelOne_ShouldReduceConsumption() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(5.0)
	_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.FUEL_EFFICIENCY)
	var mods: Dictionary = _upgrades.get_locomotive_modifiers("kara_duman")
	assert_float(mods.get("fuel_efficiency_multiplier", 1.0)).is_equal(0.85)

func test_DurabilityModifier_LevelOne_ShouldReduceFailureChance() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(5.0)
	_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.DURABILITY)
	var mods: Dictionary = _upgrades.get_locomotive_modifiers("kara_duman")
	assert_float(mods.get("durability_multiplier", 1.0)).is_equal(0.75)

func test_RespecLocomotive_ShouldRefundHalfAndDecreaseLevel() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(5.0)
	_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.SPEED)
	var after_buy: int = _economy.get_balance()
	assert_bool(_upgrades.respec_locomotive("kara_duman")).is_true()
	assert_int(_upgrades.get_locomotive_level("kara_duman", Constants.UpgradeType.SPEED)).is_equal(0)
	assert_int(_economy.get_balance()).is_equal(after_buy + int(round(Balance.UPGRADE_LOCO_SPEED_COST_L1 * Balance.UPGRADE_RESPEC_REFUND_RATIO)))

func test_WagonCapacityUpgrade_ShouldIncreaseByType() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(5.0)
	var passenger_wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var cargo_wagon := WagonData.new(Constants.WagonType.CARGO)
	assert_bool(_upgrades.upgrade_wagon(passenger_wagon.id, passenger_wagon.type, Constants.WagonUpgradeType.CAPACITY)).is_true()
	assert_bool(_upgrades.upgrade_wagon(cargo_wagon.id, cargo_wagon.type, Constants.WagonUpgradeType.CAPACITY)).is_true()
	assert_int(_upgrades.get_wagon_capacity_bonus(passenger_wagon.id, passenger_wagon.type)).is_equal(3)
	assert_int(_upgrades.get_wagon_capacity_bonus(cargo_wagon.id, cargo_wagon.type)).is_equal(2)

func test_WagonComfortUpgrade_ShouldExposeReputationBonus() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(5.0)
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	assert_bool(_upgrades.upgrade_wagon(wagon.id, wagon.type, Constants.WagonUpgradeType.COMFORT)).is_true()
	assert_float(_upgrades.get_wagon_comfort_bonus_per_passenger(wagon.id)).is_equal(0.1)

func test_UpgradeLocomotive_LevelTwo_LineNotCompleted_ShouldFailWithReason() -> void:
	_economy.set_balance(5000)
	_reputation.set_reputation(5.0)
	_upgrades.set_line_completion_checker(func(_line_id: String) -> bool: return false)
	assert_bool(_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.SPEED)).is_true()
	assert_bool(_upgrades.upgrade_locomotive("kara_duman", Constants.UpgradeType.SPEED)).is_false()
	assert_str(_upgrades.get_last_failure_reason()).is_equal("line_not_completed")
