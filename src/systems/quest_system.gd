## Module: quest_system.gd
## Tracks quest lifecycle, progress, rewards, and persistence.

class_name QuestSystem
extends Node

var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem

var _quests: Dictionary = {}
var _progress: Dictionary = {}
var _active_quest_id: String = ""
var _trip_passenger_arrived: int = 0
var _trip_quest_reward_money: int = 0

## Handles `setup`.
func setup(event_bus: Node, economy: EconomySystem, reputation: ReputationSystem) -> void:
	_event_bus = event_bus
	_economy = economy
	_reputation = reputation
	_setup_default_quests()
	_bind_events()

## Lifecycle/helper logic for `_setup_default_quests`.
func _setup_default_quests() -> void:
	_quests.clear()
	_progress.clear()
	_active_quest_id = ""
	_trip_passenger_arrived = 0
	_trip_quest_reward_money = 0

	_add_quest({
		"id": "ege_01",
		"title_key": "quest.ege_01.title",
		"description_key": "quest.ege_01.description",
		"type": Constants.QuestType.EXPLORE,
		"conditions": {"destination": "torbali"},
		"rewards": {"money": Balance.QUEST_REWARD_EGE_01_MONEY, "reputation": Balance.QUEST_REWARD_EGE_01_REPUTATION},
		"next_quest_id": "ege_02",
		"status": Constants.QuestState.AVAILABLE,
	})
	_add_quest({
		"id": "ege_02",
		"title_key": "quest.ege_02.title",
		"description_key": "quest.ege_02.description",
		"type": Constants.QuestType.TRANSPORT,
		"conditions": {"destination": "selcuk", "passenger_count": Balance.QUEST_TARGET_EGE_02_PASSENGERS},
		"rewards": {"money": Balance.QUEST_REWARD_EGE_02_MONEY, "reputation": Balance.QUEST_REWARD_EGE_02_REPUTATION},
		"next_quest_id": "ege_03",
		"status": Constants.QuestState.LOCKED,
	})
	_add_quest({
		"id": "ege_03",
		"title_key": "quest.ege_03.title",
		"description_key": "quest.ege_03.description",
		"type": Constants.QuestType.CARGO_DELIVERY,
		"conditions": {"origin": "aydin", "destination": "izmir", "cargo_name": "zeytin_yagi"},
		"rewards": {"money": Balance.QUEST_REWARD_EGE_03_MONEY, "reputation": Balance.QUEST_REWARD_EGE_03_REPUTATION},
		"next_quest_id": "ege_04",
		"status": Constants.QuestState.LOCKED,
	})
	_add_quest({
		"id": "ege_04",
		"title_key": "quest.ege_04.title",
		"description_key": "quest.ege_04.description",
		"type": Constants.QuestType.TRANSPORT,
		"conditions": {"passenger_count": Balance.QUEST_TARGET_EGE_04_PASSENGERS, "single_trip": true},
		"rewards": {"money": Balance.QUEST_REWARD_EGE_04_MONEY, "reputation": Balance.QUEST_REWARD_EGE_04_REPUTATION},
		"next_quest_id": "ege_05",
		"status": Constants.QuestState.LOCKED,
	})
	_add_quest({
		"id": "ege_05",
		"title_key": "quest.ege_05.title",
		"description_key": "quest.ege_05.description",
		"type": Constants.QuestType.EXPLORE,
		"conditions": {"trip_start": "izmir", "trip_end": "denizli"},
		"rewards": {"money": Balance.QUEST_REWARD_EGE_05_MONEY, "reputation": Balance.QUEST_REWARD_EGE_05_REPUTATION},
		"next_quest_id": "",
		"status": Constants.QuestState.LOCKED,
	})

## Lifecycle/helper logic for `_add_quest`.
func _add_quest(quest: Dictionary) -> void:
	var quest_id: String = str(quest.get("id", ""))
	_quests[quest_id] = quest.duplicate(true)
	var target: int = _resolve_target(quest)
	_progress[quest_id] = {"current": 0, "target": target}

## Lifecycle/helper logic for `_bind_events`.
func _bind_events() -> void:
	if _event_bus == null:
		return
	if _event_bus.passenger_arrived and not _event_bus.passenger_arrived.is_connected(process_passenger_arrived):
		_event_bus.passenger_arrived.connect(process_passenger_arrived)
	if _event_bus.station_arrived and not _event_bus.station_arrived.is_connected(process_station_arrived):
		_event_bus.station_arrived.connect(process_station_arrived)
	if _event_bus.cargo_delivered and not _event_bus.cargo_delivered.is_connected(_on_cargo_delivered):
		_event_bus.cargo_delivered.connect(_on_cargo_delivered)
	if _event_bus.trip_started and not _event_bus.trip_started.is_connected(_on_trip_started):
		_event_bus.trip_started.connect(_on_trip_started)
	if _event_bus.trip_completed and not _event_bus.trip_completed.is_connected(_on_trip_completed):
		_event_bus.trip_completed.connect(_on_trip_completed)

## Handles `activate_available_quest`.
func activate_available_quest() -> bool:
	if not _active_quest_id.is_empty() and _get_status(_active_quest_id) == Constants.QuestState.ACTIVE:
		return true

	for quest_id in _quests.keys():
		if _get_status(quest_id) == Constants.QuestState.AVAILABLE:
			_set_status(quest_id, Constants.QuestState.ACTIVE)
			_active_quest_id = quest_id
			if _event_bus:
				_event_bus.quest_started.emit(quest_id)
			_emit_progress(quest_id)
			return true
	return false

## Handles `get_active_quest_id`.
func get_active_quest_id() -> String:
	return _active_quest_id

## Handles `get_active_quest`.
func get_active_quest() -> Dictionary:
	if _active_quest_id.is_empty():
		return {}
	return get_quest(_active_quest_id)

## Handles `get_quest`.
func get_quest(quest_id: String) -> Dictionary:
	if not _quests.has(quest_id):
		return {}
	return _quests[quest_id].duplicate(true)

## Handles `get_quest_progress`.
func get_quest_progress(quest_id: String) -> Dictionary:
	if not _progress.has(quest_id):
		return {}
	return _progress[quest_id].duplicate(true)

## Handles `get_active_progress`.
func get_active_progress() -> Dictionary:
	if _active_quest_id.is_empty():
		return {}
	return get_quest_progress(_active_quest_id)

## Handles `process_station_arrived`.
func process_station_arrived(station_id: String) -> void:
	if _active_quest_id.is_empty():
		return
	var quest: Dictionary = _quests.get(_active_quest_id, {})
	if int(quest.get("type", -1)) != Constants.QuestType.EXPLORE:
		return

	var conditions: Dictionary = quest.get("conditions", {})
	var destination: String = str(conditions.get("destination", ""))
	if destination.is_empty():
		return
	if _normalize_station(station_id).find(destination) >= 0:
		_set_progress(_active_quest_id, 1)
		_complete_active_quest()

## Handles `process_passenger_arrived`.
func process_passenger_arrived(_passenger_data: Dictionary, station_id: String) -> void:
	_trip_passenger_arrived += 1
	if _active_quest_id.is_empty():
		return

	var quest: Dictionary = _quests.get(_active_quest_id, {})
	if int(quest.get("type", -1)) != Constants.QuestType.TRANSPORT:
		return

	var conditions: Dictionary = quest.get("conditions", {})
	var target_station: String = str(conditions.get("destination", ""))
	if not target_station.is_empty() and _normalize_station(station_id).find(target_station) < 0:
		return

	var p: Dictionary = _progress.get(_active_quest_id, {"current": 0, "target": 1})
	var next_value: int = int(p.get("current", 0)) + 1
	_set_progress(_active_quest_id, next_value)
	_emit_progress(_active_quest_id)

	if next_value >= int(p.get("target", 1)) and not bool(conditions.get("single_trip", false)):
		_complete_active_quest()

## Lifecycle/helper logic for `_on_cargo_delivered`.
func _on_cargo_delivered(cargo_data: Dictionary, _station_id: String) -> void:
	process_cargo_delivered(cargo_data)

## Handles `process_cargo_delivered`.
func process_cargo_delivered(cargo_data: Dictionary) -> void:
	if _active_quest_id.is_empty():
		return
	var quest: Dictionary = _quests.get(_active_quest_id, {})
	if int(quest.get("type", -1)) != Constants.QuestType.CARGO_DELIVERY:
		return

	var conditions: Dictionary = quest.get("conditions", {})
	var required_origin: String = str(conditions.get("origin", ""))
	var required_destination: String = str(conditions.get("destination", ""))
	var required_name: String = str(conditions.get("cargo_name", ""))

	var origin_ok: bool = _normalize_station(str(cargo_data.get("origin_station", ""))).find(required_origin) >= 0
	var destination_ok: bool = _normalize_station(str(cargo_data.get("destination_station", ""))).find(required_destination) >= 0
	var name_ok: bool = str(cargo_data.get("name", "")) == required_name
	if origin_ok and destination_ok and name_ok:
		_set_progress(_active_quest_id, 1)
		_complete_active_quest()

## Lifecycle/helper logic for `_on_trip_started`.
func _on_trip_started(_route_data: Dictionary) -> void:
	_trip_passenger_arrived = 0
	_trip_quest_reward_money = 0
	activate_available_quest()

## Lifecycle/helper logic for `_on_trip_completed`.
func _on_trip_completed(summary: Dictionary) -> void:
	if _active_quest_id.is_empty():
		return
	var quest: Dictionary = _quests.get(_active_quest_id, {})
	var conditions: Dictionary = quest.get("conditions", {})

	if _active_quest_id == "ege_04":
		var target: int = int(conditions.get("passenger_count", 1))
		_set_progress(_active_quest_id, _trip_passenger_arrived)
		_emit_progress(_active_quest_id)
		if _trip_passenger_arrived >= target:
			_complete_active_quest()
		return

	if _active_quest_id == "ege_05":
		var route_data: Dictionary = summary.get("route_data", {})
		var start_name: String = _normalize_station(str(route_data.get("start", "")))
		var end_name: String = _normalize_station(str(route_data.get("end", "")))
		if start_name.find(str(conditions.get("trip_start", ""))) >= 0 and end_name.find(str(conditions.get("trip_end", ""))) >= 0:
			_set_progress(_active_quest_id, 1)
			_complete_active_quest()

## Handles `get_trip_reward_money`.
func get_trip_reward_money() -> int:
	return _trip_quest_reward_money

## Handles `consume_trip_reward_money`.
func consume_trip_reward_money() -> int:
	var value: int = _trip_quest_reward_money
	_trip_quest_reward_money = 0
	return value

## Handles `get_save_data`.
func get_save_data() -> Dictionary:
	var statuses: Dictionary = {}
	for quest_id in _quests.keys():
		statuses[quest_id] = _get_status(quest_id)
	return {
		"statuses": statuses,
		"progress": _progress.duplicate(true),
		"active_quest_id": _active_quest_id,
	}

## Handles `load_save_data`.
func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	var statuses: Dictionary = data.get("statuses", {})
	for quest_id in statuses.keys():
		if _quests.has(quest_id):
			_set_status(quest_id, int(statuses[quest_id]))

	var loaded_progress: Dictionary = data.get("progress", {})
	for quest_id in loaded_progress.keys():
		if _progress.has(quest_id):
			_progress[quest_id] = loaded_progress[quest_id].duplicate(true)

	_active_quest_id = str(data.get("active_quest_id", ""))

## Handles `force_set_status`.
func force_set_status(quest_id: String, status: int) -> void:
	if not _quests.has(quest_id):
		return
	_set_status(quest_id, status)
	if status == Constants.QuestState.ACTIVE:
		_active_quest_id = quest_id
	elif _active_quest_id == quest_id and status != Constants.QuestState.ACTIVE:
		_active_quest_id = ""

## Lifecycle/helper logic for `_complete_active_quest`.
func _complete_active_quest() -> void:
	if _active_quest_id.is_empty():
		return
	var quest_id: String = _active_quest_id
	if _get_status(quest_id) == Constants.QuestState.COMPLETED:
		return

	_set_status(quest_id, Constants.QuestState.COMPLETED)
	_apply_rewards(quest_id)
	if _event_bus:
		_event_bus.quest_completed.emit(quest_id)

	var next_quest_id: String = str(_quests[quest_id].get("next_quest_id", ""))
	_active_quest_id = ""
	if not next_quest_id.is_empty() and _quests.has(next_quest_id) and _get_status(next_quest_id) == Constants.QuestState.LOCKED:
		_set_status(next_quest_id, Constants.QuestState.AVAILABLE)

## Lifecycle/helper logic for `_apply_rewards`.
func _apply_rewards(quest_id: String) -> void:
	var rewards: Dictionary = _quests[quest_id].get("rewards", {})
	var money: int = int(rewards.get("money", 0))
	var reputation_points: float = float(rewards.get("reputation", 0.0))

	if money > 0:
		_economy.earn(money, "quest")
		_trip_quest_reward_money += money
	if reputation_points > 0.0:
		_reputation.add(reputation_points, "quest")

## Lifecycle/helper logic for `_resolve_target`.
func _resolve_target(quest: Dictionary) -> int:
	var conditions: Dictionary = quest.get("conditions", {})
	if conditions.has("passenger_count"):
		return int(conditions.get("passenger_count", 1))
	return 1

## Lifecycle/helper logic for `_emit_progress`.
func _emit_progress(quest_id: String) -> void:
	if _event_bus == null:
		return
	var p: Dictionary = _progress.get(quest_id, {"current": 0, "target": 1})
	_event_bus.quest_progress.emit(quest_id, int(p.get("current", 0)), int(p.get("target", 1)))

## Lifecycle/helper logic for `_set_progress`.
func _set_progress(quest_id: String, value: int) -> void:
	if not _progress.has(quest_id):
		return
	var p: Dictionary = _progress[quest_id]
	var target: int = int(p.get("target", 1))
	p["current"] = clampi(value, 0, maxi(target, 1))
	_progress[quest_id] = p

## Lifecycle/helper logic for `_set_status`.
func _set_status(quest_id: String, status: int) -> void:
	if not _quests.has(quest_id):
		return
	var q: Dictionary = _quests[quest_id]
	q["status"] = status
	_quests[quest_id] = q

## Lifecycle/helper logic for `_get_status`.
func _get_status(quest_id: String) -> int:
	if not _quests.has(quest_id):
		return Constants.QuestState.LOCKED
	return int(_quests[quest_id].get("status", Constants.QuestState.LOCKED))

## Lifecycle/helper logic for `_normalize_station`.
func _normalize_station(station_name: String) -> String:
	return station_name.to_lower().replace("(", " ").replace(")", " ").replace("-", " ")
