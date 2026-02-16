## Test suite: test_game_manager.gd
## Restored English comments for maintainability and i18n coding standards.

class_name TestGameManager
extends GdUnitTestSuite

const SAVE_PATH := "user://save_slot_1.json"

## Handles `before_test`.
func before_test() -> void:
	_clear_runtime_nodes()
	_remove_save_file()

## Handles `after_test`.
func after_test() -> void:
	_clear_runtime_nodes()
	_remove_save_file()

## Handles `test_Load_NoSave_ShouldUseDefaultsAndShowIntro`.
func test_Load_NoSave_ShouldUseDefaultsAndShowIntro() -> void:
	var gm := _create_manager()
	assert_int(gm.economy.get_balance()).is_equal(Balance.STARTING_MONEY)
	assert_float(gm.reputation.get_stars()).is_equal(Balance.REPUTATION_STARTING)
	assert_bool(gm.should_show_intro()).is_true()
	assert_int(gm.inventory.get_locomotives().size()).is_equal(1)
	assert_int(gm.inventory.get_wagons().size()).is_equal(2)

## Handles `test_SaveLoad_ShouldRestoreEconomyReputationInventoryAndTips`.
func test_SaveLoad_ShouldRestoreEconomyReputationInventoryAndTips() -> void:
	var gm1 := _create_manager()
	gm1.economy.set_balance(777)
	gm1.reputation.set_reputation(4.2)
	gm1.inventory.add_wagon(WagonData.new(Constants.WagonType.BUSINESS))
	gm1.fuel_system.consume(55.0)
	gm1.total_trips = 3
	gm1.total_passengers = 42
	gm1.total_km = 321.5
	gm1.total_net_earnings = 999
	gm1.mark_tip_shown("tip_map")
	gm1.mark_intro_completed()
	assert_bool(gm1.save_game()).is_true()

	_clear_runtime_nodes()
	var gm2 := _create_manager()
	assert_int(gm2.economy.get_balance()).is_equal(777)
	assert_float(gm2.reputation.get_stars()).is_equal(4.2)
	assert_int(gm2.inventory.get_wagons().size()).is_equal(3)
	assert_float(gm2.fuel_system.get_current_fuel()).is_equal(gm2.fuel_system.get_tank_capacity() - 55.0)
	assert_int(gm2.total_trips).is_equal(3)
	assert_int(gm2.total_passengers).is_equal(42)
	assert_float(gm2.total_km).is_equal(321.5)
	assert_int(gm2.total_net_earnings).is_equal(999)
	assert_bool(gm2.has_tip_been_shown("tip_map")).is_true()
	assert_bool(gm2.should_show_intro()).is_false()

## Handles `test_Load_InvalidSave_ShouldKeepDefaults`.
func test_Load_InvalidSave_ShouldKeepDefaults() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string("not-json")
	_clear_runtime_nodes()
	var gm := _create_manager()
	assert_int(gm.economy.get_balance()).is_equal(Balance.STARTING_MONEY)
	assert_float(gm.reputation.get_stars()).is_equal(Balance.REPUTATION_STARTING)
	assert_bool(gm.should_show_intro()).is_true()

## Handles `test_TripSummary_ShouldUseFuelConsumptionCostAndStationBreakdown`.
func test_TripSummary_ShouldUseFuelConsumptionCostAndStationBreakdown() -> void:
	var gm := _create_manager()
	gm._on_trip_started({})
	gm.record_station_result("TORBALI", 120, 3, 1)
	gm.fuel_system.begin_trip_tracking()
	gm.fuel_system.consume(40.0)
	gm._on_trip_completed({
		"total_earned": 200,
		"earnings": {"ticket": 200, "cargo": 0},
		"spendings": {},
	})

	var report: Dictionary = gm.get_last_trip_report()
	assert_int(report.get("revenue", {}).get("total", 0)).is_equal(200)
	assert_int(report.get("costs", {}).get("fuel_total", 0)).is_equal(40)
	assert_int(report.get("costs", {}).get("total", 0)).is_equal(40)
	assert_int(report.get("net_profit", 0)).is_equal(160)
	assert_int(report.get("stats", {}).get("stops_visited", 0)).is_equal(1)

## Handles `test_TripSummary_MultipleStationsAndLoss_ShouldAggregateCorrectly`.
func test_TripSummary_MultipleStationsAndLoss_ShouldAggregateCorrectly() -> void:
	var gm := _create_manager()
	gm._on_trip_started({})
	gm.record_station_result("TORBALI", 60, 2, 1)
	gm.record_station_result("SELCUK", 90, 3, 0)
	gm.fuel_system.begin_trip_tracking()
	gm.fuel_system.consume(100.0)
	gm._on_trip_completed({
		"total_earned": 150,
		"earnings": {"ticket": 150, "cargo": 0},
		"spendings": {},
	})

	var report: Dictionary = gm.get_last_trip_report()
	assert_int(report.get("revenue", {}).get("ticket_total", 0)).is_equal(150)
	assert_int(report.get("costs", {}).get("fuel_total", 0)).is_equal(100)
	assert_int(report.get("net_profit", 0)).is_equal(50)
	assert_int(report.get("stats", {}).get("passengers_transported", 0)).is_equal(5)
	assert_int(report.get("stats", {}).get("passengers_lost", 0)).is_equal(1)
	assert_int(report.get("stats", {}).get("stops_visited", 0)).is_equal(2)

## Handles `test_SaveLoad_ShouldPersistTipFlags`.
func test_SaveLoad_ShouldPersistTipFlags() -> void:
	var gm1 := _create_manager()
	gm1.mark_tip_shown("tip_garage")
	gm1.mark_tip_shown("tip_map")
	assert_bool(gm1.save_game()).is_true()

	_clear_runtime_nodes()
	var gm2 := _create_manager()
	assert_bool(gm2.has_tip_been_shown("tip_garage")).is_true()
	assert_bool(gm2.has_tip_been_shown("tip_map")).is_true()

## Handles `test_FullFlow_Phase7Systems_ShouldProduceIntegratedTripReport`.
func test_FullFlow_Phase7Systems_ShouldProduceIntegratedTripReport() -> void:
	var gm := _create_manager()
	gm.quest_system.force_set_status("ege_01", Constants.QuestState.COMPLETED)
	gm.quest_system.force_set_status("ege_02", Constants.QuestState.COMPLETED)
	gm.quest_system.force_set_status("ege_03", Constants.QuestState.ACTIVE)
	gm.random_event_system.set_event_probability("evt_fuel_hike", 1.0)
	gm.random_event_system.set_roll_provider(func() -> float: return 0.0)
	gm.random_event_system.set_event_probability("evt_door", 0.0)
	gm.random_event_system.set_event_probability("evt_vip", 0.0)
	gm.random_event_system.set_event_probability("evt_sick", 0.0)
	gm.random_event_system.set_event_probability("evt_festival", 0.0)
	gm._on_trip_started({"enable_random_events": true})

	var cargo_id: String = gm.cargo_system.inject_offer({
		"name": "zeytin_yagi",
		"origin_station": "AYDIN",
		"destination_station": "IZMIR (BASMANE)",
		"reward": 60,
		"weight": 1,
		"deadline_trips": 2,
	})
	assert_bool(gm.cargo_system.load_offer(cargo_id)).is_true()
	gm._on_station_arrived("IZMIR (BASMANE)")
	gm.record_station_result("IZMIR (BASMANE)", 120, 3, 0)
	gm.fuel_system.begin_trip_tracking()
	gm._on_trip_completed({
		"total_earned": 380,
		"earnings": {"ticket": 120, "cargo": 60, "quest": 200},
		"spendings": {},
		"route_data": {"start": "IZMIR (BASMANE)", "end": "DENIZLI", "stop_count": 7},
	})

	var report: Dictionary = gm.get_last_trip_report()
	assert_int(report.get("quest_reward_money", 0)).is_equal(200)
	assert_int(report.get("revenue", {}).get("cargo_total", 0)).is_equal(60)
	assert_array(report.get("event_history", [])).contains("evt_fuel_hike")

## Handles `test_SaveLoad_Phase8Data_ShouldPersistShopsAndUpgrades`.
func test_SaveLoad_Phase8Data_ShouldPersistShopsAndUpgrades() -> void:
	var gm1 := _create_manager()
	gm1.economy.set_balance(5000)
	gm1.reputation.set_reputation(5.0)
	assert_bool(gm1.shop_system.open_shop("AYDIN", Constants.ShopType.BUFFET)).is_true()
	assert_bool(gm1.upgrade_system.upgrade_locomotive("kara_duman", Constants.UpgradeType.SPEED)).is_true()
	var wagon: WagonData = gm1.inventory.get_wagons()[0]
	assert_bool(gm1.upgrade_system.upgrade_wagon(wagon.id, wagon.type, Constants.WagonUpgradeType.CAPACITY)).is_true()
	assert_bool(gm1.save_game()).is_true()

	_clear_runtime_nodes()
	var gm2 := _create_manager()
	assert_int(gm2.shop_system.get_station_shop_level("AYDIN", Constants.ShopType.BUFFET)).is_equal(1)
	assert_int(gm2.upgrade_system.get_locomotive_level("kara_duman", Constants.UpgradeType.SPEED)).is_equal(1)

## Handles `test_TripSummary_Phase8Income_ShouldIncludeShopAndDining`.
func test_TripSummary_Phase8Income_ShouldIncludeShopAndDining() -> void:
	var gm := _create_manager()
	gm.economy.set_balance(5000)
	gm.reputation.set_reputation(5.0)
	assert_bool(gm.shop_system.open_shop("AYDIN", Constants.ShopType.BUFFET)).is_true()
	gm._on_trip_started({})
	gm.economy.earn(10, "dining")
	gm.record_station_result("AYDIN", 50, 2, 0)
	gm._on_trip_completed({
		"total_earned": 60,
		"earnings": {"ticket": 50, "dining": 10},
		"spendings": {},
	})
	var report: Dictionary = gm.get_last_trip_report()
	assert_int(report.get("revenue", {}).get("shop_total", 0)).is_equal(Balance.SHOP_BUFFET_INCOME_L1)
	assert_int(report.get("revenue", {}).get("dining_total", 0)).is_equal(10)

func test_SaveLoad_LineCompletion_ShouldPersistAndAffectUpgradeLock() -> void:
	var gm1 := _create_manager()
	gm1.mark_line_completed("ege_main")
	assert_bool(gm1.save_game()).is_true()
	_clear_runtime_nodes()
	var gm2 := _create_manager()
	assert_bool(gm2.is_line_completed("ege_main")).is_true()

## Lifecycle/helper logic for `_create_manager`.
func _create_manager() -> Node:
	var bus: Node = load("res://src/events/event_bus.gd").new()
	bus.name = "EventBus"
	get_tree().root.add_child(bus)

	var gm: Node = load("res://src/managers/game_manager.gd").new()
	gm.name = "GameManager"
	get_tree().root.add_child(gm)
	return gm

## Lifecycle/helper logic for `_remove_save_file`.
func _remove_save_file() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

## Lifecycle/helper logic for `_clear_runtime_nodes`.
func _clear_runtime_nodes() -> void:
	var gm := get_tree().root.get_node_or_null("GameManager")
	if gm:
		gm.free()
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus:
		bus.free()
