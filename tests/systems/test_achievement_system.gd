## Test suite: test_achievement_system.gd
## Validates achievement progression, visibility, rewards, and persistence.

class_name TestAchievementSystem
extends GdUnitTestSuite

var _event_bus: Node
var _economy: EconomySystem
var _achievements: Node

func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	_achievements = auto_free(load("res://src/systems/achievement_system.gd").new())
	_achievements.setup(_event_bus, _economy)
	_achievements.set_inventory_snapshot_provider(func() -> Dictionary:
		return {"locomotive_count": 1, "wagon_types": [Constants.WagonType.ECONOMY]}
	)
	_achievements.set_completed_quest_count_provider(func() -> int:
		return 0
	)

func test_TripAchievement_FirstTrip_ShouldUnlock() -> void:
	_event_bus.trip_started.emit({})
	_event_bus.trip_completed.emit({"route_data": {}, "distance_km": 20.0})
	assert_bool(_achievements.is_unlocked("trip_first")).is_true()

func test_PassengerAchievement_100Passengers_ShouldUnlockAtThreshold() -> void:
	for i in range(99):
		_event_bus.passenger_arrived.emit({"type": Constants.PassengerType.NORMAL}, "AYDIN")
	assert_bool(_achievements.is_unlocked("pax_100")).is_false()
	_event_bus.passenger_arrived.emit({"type": Constants.PassengerType.NORMAL}, "AYDIN")
	assert_bool(_achievements.is_unlocked("pax_100")).is_true()

func test_PassengerAchievement_FirstVip_ShouldUnlock() -> void:
	_event_bus.passenger_arrived.emit({"type": Constants.PassengerType.VIP}, "SELCUK")
	assert_bool(_achievements.is_unlocked("pax_vip_first")).is_true()

func test_PerfectTripAchievement_Min10AndZeroLoss_ShouldUnlock() -> void:
	for i in range(100):
		_event_bus.passenger_arrived.emit({"type": Constants.PassengerType.NORMAL}, "AYDIN")
	_event_bus.trip_started.emit({})
	for i in range(10):
		_event_bus.passenger_arrived.emit({"type": Constants.PassengerType.NORMAL}, "AYDIN")
	_event_bus.trip_completed.emit({"route_data": {}, "distance_km": 35.0})
	assert_bool(_achievements.is_unlocked("pax_zero_loss")).is_true()

func test_VisibilityChain_Trip10_ShouldBeHiddenUntilTripFirstUnlocked() -> void:
	assert_bool(_achievements.is_visible("trip_10")).is_false()
	_event_bus.trip_started.emit({})
	_event_bus.trip_completed.emit({"route_data": {}, "distance_km": 10.0})
	assert_bool(_achievements.is_visible("trip_10")).is_true()

func test_RepeatUnlock_ShouldNotRewardTwice() -> void:
	var before: int = _economy.get_balance()
	_event_bus.trip_started.emit({})
	_event_bus.trip_completed.emit({"route_data": {}, "distance_km": 10.0})
	var after_first: int = _economy.get_balance()
	_event_bus.trip_started.emit({})
	_event_bus.trip_completed.emit({"route_data": {}, "distance_km": 10.0})
	assert_int(after_first - before).is_equal(50)
	assert_int(_economy.get_balance()).is_equal(after_first)

func test_SaveLoad_ShouldPersistStatesAndCounters() -> void:
	_event_bus.trip_started.emit({})
	_event_bus.trip_completed.emit({"route_data": {}, "distance_km": 100.0})
	for i in range(5):
		_event_bus.passenger_arrived.emit({"type": Constants.PassengerType.NORMAL}, "TORBALI")
	var data: Dictionary = _achievements.get_save_data()
	var clone: Node = auto_free(load("res://src/systems/achievement_system.gd").new())
	clone.setup(_event_bus, _economy)
	clone.load_save_data(data)
	assert_bool(clone.is_unlocked("trip_first")).is_true()
	assert_int(clone.get_counter("trips_completed")).is_equal(1)
	assert_int(clone.get_counter("passengers_total")).is_equal(5)
