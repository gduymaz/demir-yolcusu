## Test suite: test_quest_system.gd
## Validates quest progression, rewards, chaining, and persistence.

class_name TestQuestSystem
extends GdUnitTestSuite

var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem
var _quests: Node

## Handles `before_test`.
func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	_reputation = auto_free(ReputationSystem.new())
	_reputation.setup(_event_bus)
	_quests = auto_free(load("res://src/systems/quest_system.gd").new())
	_quests.setup(_event_bus, _economy, _reputation)

## Handles `test_InitialState_ShouldExposeFirstQuestAsAvailable`.
func test_InitialState_ShouldExposeFirstQuestAsAvailable() -> void:
	var q1: Dictionary = _quests.get_quest("ege_01")
	var q2: Dictionary = _quests.get_quest("ege_02")
	assert_int(q1.get("status", -1)).is_equal(Constants.QuestState.AVAILABLE)
	assert_int(q2.get("status", -1)).is_equal(Constants.QuestState.LOCKED)

## Handles `test_ActivateAvailableQuest_ShouldSetActiveAndEmitStarted`.
func test_ActivateAvailableQuest_ShouldSetActiveAndEmitStarted() -> void:
	var started: Dictionary = {"id": ""}
	_event_bus.quest_started.connect(func(quest_id: String) -> void: started["id"] = quest_id)
	assert_bool(_quests.activate_available_quest()).is_true()
	assert_str(_quests.get_active_quest_id()).is_equal("ege_01")
	assert_str(started["id"]).is_equal("ege_01")

## Handles `test_ExploreQuestCompletion_ShouldUnlockNextQuest`.
func test_ExploreQuestCompletion_ShouldUnlockNextQuest() -> void:
	_quests.activate_available_quest()
	_quests.process_station_arrived("TORBALI")
	var q1: Dictionary = _quests.get_quest("ege_01")
	var q2: Dictionary = _quests.get_quest("ege_02")
	assert_int(q1.get("status", -1)).is_equal(Constants.QuestState.COMPLETED)
	assert_int(q2.get("status", -1)).is_equal(Constants.QuestState.AVAILABLE)

## Handles `test_TransportQuestProgress_ShouldRequireTargetPassengerCount`.
func test_TransportQuestProgress_ShouldRequireTargetPassengerCount() -> void:
	_quests.force_set_status("ege_01", Constants.QuestState.COMPLETED)
	_quests.force_set_status("ege_02", Constants.QuestState.AVAILABLE)
	_quests.activate_available_quest()
	for i in 5:
		_quests.process_passenger_arrived({"id": "p_%d" % i}, "SELCUK")
	assert_int(_quests.get_active_progress().get("current", -1)).is_equal(5)
	assert_int(_quests.get_quest("ege_02").get("status", -1)).is_equal(Constants.QuestState.ACTIVE)
	for i in range(5, 10):
		_quests.process_passenger_arrived({"id": "p_%d" % i}, "SELCUK")
	assert_int(_quests.get_quest("ege_02").get("status", -1)).is_equal(Constants.QuestState.COMPLETED)

## Handles `test_RewardDistribution_ShouldIncreaseMoneyAndReputation`.
func test_RewardDistribution_ShouldIncreaseMoneyAndReputation() -> void:
	var money_before: int = _economy.get_balance()
	var rep_before: float = _reputation.get_stars()
	_quests.activate_available_quest()
	_quests.process_station_arrived("TORBALI")
	assert_int(_economy.get_balance()).is_equal(money_before + 100)
	assert_float(_reputation.get_stars()).is_equal(rep_before + 0.2)

## Handles `test_CompletedQuest_ShouldNotCompleteTwice`.
func test_CompletedQuest_ShouldNotCompleteTwice() -> void:
	_quests.activate_available_quest()
	_quests.process_station_arrived("TORBALI")
	var money_after_first: int = _economy.get_balance()
	_quests.process_station_arrived("TORBALI")
	assert_int(_economy.get_balance()).is_equal(money_after_first)

## Handles `test_SaveLoadState_ShouldPreserveStatusesAndProgress`.
func test_SaveLoadState_ShouldPreserveStatusesAndProgress() -> void:
	_quests.activate_available_quest()
	_quests.process_station_arrived("TORBALI")
	_quests.activate_available_quest()
	_quests.process_passenger_arrived({"id": "p_a"}, "SELCUK")
	_quests.process_passenger_arrived({"id": "p_b"}, "SELCUK")
	var saved: Dictionary = _quests.get_save_data()

	var other: Node = auto_free(load("res://src/systems/quest_system.gd").new())
	other.setup(_event_bus, _economy, _reputation)
	other.load_save_data(saved)
	assert_int(other.get_quest("ege_01").get("status", -1)).is_equal(Constants.QuestState.COMPLETED)
	assert_int(other.get_quest("ege_02").get("status", -1)).is_equal(Constants.QuestState.ACTIVE)
	assert_int(other.get_quest_progress("ege_02").get("current", -1)).is_equal(2)
