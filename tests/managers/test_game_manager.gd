## GameManager testleri.
## Faz 6: save/load, varsayilan acilis, sefer ozeti ve tip kaliciligi.
class_name TestGameManager
extends GdUnitTestSuite


const SAVE_PATH := "user://save_slot_1.json"


func before_test() -> void:
	_clear_runtime_nodes()
	_remove_save_file()


func after_test() -> void:
	_clear_runtime_nodes()
	_remove_save_file()


func test_Load_NoSave_ShouldUseDefaultsAndShowIntro() -> void:
	var gm := _create_manager()
	assert_int(gm.economy.get_balance()).is_equal(Balance.STARTING_MONEY)
	assert_float(gm.reputation.get_stars()).is_equal(Balance.REPUTATION_STARTING)
	assert_bool(gm.should_show_intro()).is_true()
	assert_int(gm.inventory.get_locomotives().size()).is_equal(1)
	assert_int(gm.inventory.get_wagons().size()).is_equal(2)


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


func test_Load_InvalidSave_ShouldKeepDefaults() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string("not-json")
	_clear_runtime_nodes()
	var gm := _create_manager()
	assert_int(gm.economy.get_balance()).is_equal(Balance.STARTING_MONEY)
	assert_float(gm.reputation.get_stars()).is_equal(Balance.REPUTATION_STARTING)
	assert_bool(gm.should_show_intro()).is_true()


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


func _create_manager() -> Node:
	var bus: Node = load("res://src/events/event_bus.gd").new()
	bus.name = "EventBus"
	get_tree().root.add_child(bus)

	var gm: Node = load("res://src/managers/game_manager.gd").new()
	gm.name = "GameManager"
	get_tree().root.add_child(gm)
	return gm


func _remove_save_file() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _clear_runtime_nodes() -> void:
	var gm := get_tree().root.get_node_or_null("GameManager")
	if gm:
		gm.free()
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus:
		bus.free()
