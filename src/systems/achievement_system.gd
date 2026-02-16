## Module: achievement_system.gd
## Tracks and unlocks achievements from gameplay events.

class_name AchievementSystem
extends Node

var _event_bus: Node
var _economy: EconomySystem
var _achievements: Dictionary = {}
var _counters: Dictionary = {}
var _current_trip_passengers: int = 0
var _current_trip_lost: int = 0
var _inventory_snapshot_provider: Callable = Callable()
var _completed_quest_count_provider: Callable = Callable()

func setup(event_bus: Node, economy: EconomySystem) -> void:
	_event_bus = event_bus
	_economy = economy
	_setup_defaults()
	_bind_events()

func set_inventory_snapshot_provider(provider: Callable) -> void:
	_inventory_snapshot_provider = provider

func set_completed_quest_count_provider(provider: Callable) -> void:
	_completed_quest_count_provider = provider

func is_unlocked(achievement_id: String) -> bool:
	if not _achievements.has(achievement_id):
		return false
	return bool((_achievements[achievement_id] as Dictionary).get("is_unlocked", false))

func is_visible(achievement_id: String) -> bool:
	if not _achievements.has(achievement_id):
		return false
	return bool((_achievements[achievement_id] as Dictionary).get("is_visible", false))

func get_achievement(achievement_id: String) -> Dictionary:
	return (_achievements.get(achievement_id, {}) as Dictionary).duplicate(true)

func get_all_achievements() -> Array:
	var result: Array = []
	for achievement in _achievements.values():
		result.append((achievement as Dictionary).duplicate(true))
	return result

func get_counter(key: String) -> int:
	return int(_counters.get(key, 0))

func get_unlocked_count() -> int:
	var count: int = 0
	for id in _achievements.keys():
		if is_unlocked(str(id)):
			count += 1
	return count

func get_total_count() -> int:
	return _achievements.size()

func get_progress(achievement_id: String) -> Dictionary:
	var current: int = 0
	var target: int = 1
	match achievement_id:
		"trip_first":
			current = int(_counters.get("trips_completed", 0))
			target = Balance.ACH_TARGET_TRIPS_FIRST
		"trip_10":
			current = int(_counters.get("trips_completed", 0))
			target = Balance.ACH_TARGET_TRIPS_10
		"trip_100km":
			current = int(_counters.get("distance_km", 0))
			target = Balance.ACH_TARGET_KM_100
		"trip_500km":
			current = int(_counters.get("distance_km", 0))
			target = Balance.ACH_TARGET_KM_500
		"pax_100":
			current = int(_counters.get("passengers_total", 0))
			target = Balance.ACH_TARGET_PAX_100
		"pax_vip_first":
			current = int(_counters.get("vip_arrived", 0))
			target = 1
		"pax_zero_loss":
			current = _current_trip_passengers if _current_trip_lost <= 0 else 0
			target = Balance.ACH_TARGET_PERFECT_MIN_PASSENGERS
		"pax_500":
			current = int(_counters.get("passengers_total", 0))
			target = Balance.ACH_TARGET_PAX_500
		"col_upgrade":
			current = int(_counters.get("upgrades_done", 0))
			target = 1
		"col_loco2":
			current = int(_get_inventory_snapshot().get("locomotive_count", 0))
			target = 2
		"col_all_wagons":
			var owned_types: Array = _get_inventory_snapshot().get("wagon_types", [])
			current = owned_types.size()
			target = 5
		"col_shop":
			current = int(_counters.get("shops_opened", 0))
			target = 1
		"disc_all_ege":
			current = int(_counters.get("visited_stop_count", 0))
			target = Balance.ACH_TARGET_ALL_EGE_STOPS
		"disc_cargo_first":
			current = int(_counters.get("cargo_deliveries", 0))
			target = 1
		"disc_event":
			current = int(_counters.get("random_events", 0))
			target = 1
		"disc_quest_all":
			current = _get_completed_quest_count()
			target = Balance.ACH_TARGET_ALL_QUESTS
		_:
			current = 0
			target = 1
	return {"current": current, "target": target}

func check_all() -> void:
	for achievement_id in _achievements.keys():
		_check_unlock(str(achievement_id))

func get_save_data() -> Dictionary:
	return {
		"achievements": _achievements.duplicate(true),
		"counters": _counters.duplicate(true),
	}

func load_save_data(data: Dictionary) -> void:
	var loaded_achievements: Dictionary = data.get("achievements", {})
	for id in _achievements.keys():
		var key: String = str(id)
		if loaded_achievements.has(key):
			var base: Dictionary = _achievements[key]
			var loaded: Dictionary = loaded_achievements[key]
			base["is_unlocked"] = bool(loaded.get("is_unlocked", false))
			base["is_visible"] = bool(loaded.get("is_visible", base.get("is_visible", false)))
			_achievements[key] = base
	_counters = data.get("counters", {}).duplicate(true)
	check_all()

func _setup_defaults() -> void:
	_counters = {
		"trips_completed": 0,
		"distance_km": 0,
		"passengers_total": 0,
		"vip_arrived": 0,
		"cargo_deliveries": 0,
		"random_events": 0,
		"shops_opened": 0,
		"upgrades_done": 0,
		"visited_stop_count": 0,
	}
	_achievements = {
		"trip_first": _mk_achievement(Constants.AchievementCategory.TRIP, "achievement.trip_first.title", "achievement.trip_first.desc", Balance.ACH_REWARD_TRIP_FIRST, true, ""),
		"trip_10": _mk_achievement(Constants.AchievementCategory.TRIP, "achievement.trip_10.title", "achievement.trip_10.desc", Balance.ACH_REWARD_TRIP_10, false, "trip_first"),
		"trip_100km": _mk_achievement(Constants.AchievementCategory.TRIP, "achievement.trip_100km.title", "achievement.trip_100km.desc", Balance.ACH_REWARD_TRIP_100KM, true, ""),
		"trip_500km": _mk_achievement(Constants.AchievementCategory.TRIP, "achievement.trip_500km.title", "achievement.trip_500km.desc", Balance.ACH_REWARD_TRIP_500KM, false, "trip_100km"),
		"pax_100": _mk_achievement(Constants.AchievementCategory.PASSENGER, "achievement.pax_100.title", "achievement.pax_100.desc", Balance.ACH_REWARD_PAX_100, true, ""),
		"pax_vip_first": _mk_achievement(Constants.AchievementCategory.PASSENGER, "achievement.pax_vip_first.title", "achievement.pax_vip_first.desc", Balance.ACH_REWARD_PAX_VIP_FIRST, true, ""),
		"pax_zero_loss": _mk_achievement(Constants.AchievementCategory.PASSENGER, "achievement.pax_zero_loss.title", "achievement.pax_zero_loss.desc", Balance.ACH_REWARD_PAX_ZERO_LOSS, false, "pax_100"),
		"pax_500": _mk_achievement(Constants.AchievementCategory.PASSENGER, "achievement.pax_500.title", "achievement.pax_500.desc", Balance.ACH_REWARD_PAX_500, false, "pax_100"),
		"col_upgrade": _mk_achievement(Constants.AchievementCategory.COLLECTION, "achievement.col_upgrade.title", "achievement.col_upgrade.desc", Balance.ACH_REWARD_COL_UPGRADE, true, ""),
		"col_loco2": _mk_achievement(Constants.AchievementCategory.COLLECTION, "achievement.col_loco2.title", "achievement.col_loco2.desc", Balance.ACH_REWARD_COL_LOCO2, true, ""),
		"col_all_wagons": _mk_achievement(Constants.AchievementCategory.COLLECTION, "achievement.col_all_wagons.title", "achievement.col_all_wagons.desc", Balance.ACH_REWARD_COL_ALL_WAGONS, false, "col_upgrade"),
		"col_shop": _mk_achievement(Constants.AchievementCategory.COLLECTION, "achievement.col_shop.title", "achievement.col_shop.desc", Balance.ACH_REWARD_COL_SHOP, true, ""),
		"disc_all_ege": _mk_achievement(Constants.AchievementCategory.DISCOVERY, "achievement.disc_all_ege.title", "achievement.disc_all_ege.desc", Balance.ACH_REWARD_DISC_ALL_EGE, true, ""),
		"disc_cargo_first": _mk_achievement(Constants.AchievementCategory.DISCOVERY, "achievement.disc_cargo_first.title", "achievement.disc_cargo_first.desc", Balance.ACH_REWARD_DISC_CARGO_FIRST, true, ""),
		"disc_event": _mk_achievement(Constants.AchievementCategory.DISCOVERY, "achievement.disc_event.title", "achievement.disc_event.desc", Balance.ACH_REWARD_DISC_EVENT, true, ""),
		"disc_quest_all": _mk_achievement(Constants.AchievementCategory.DISCOVERY, "achievement.disc_quest_all.title", "achievement.disc_quest_all.desc", Balance.ACH_REWARD_DISC_QUEST_ALL, false, "disc_all_ege"),
	}

func _mk_achievement(category: int, title_key: String, description_key: String, reward_money: int, visible: bool, visible_after: String) -> Dictionary:
	return {
		"id": title_key.trim_suffix(".title"),
		"category": category,
		"title_key": title_key,
		"description_key": description_key,
		"reward_money": reward_money,
		"is_unlocked": false,
		"is_visible": visible,
		"visible_after": visible_after,
	}

func _bind_events() -> void:
	if _event_bus == null:
		return
	if not _event_bus.trip_started.is_connected(_on_trip_started):
		_event_bus.trip_started.connect(_on_trip_started)
	if not _event_bus.trip_completed.is_connected(_on_trip_completed):
		_event_bus.trip_completed.connect(_on_trip_completed)
	if not _event_bus.passenger_arrived.is_connected(_on_passenger_arrived):
		_event_bus.passenger_arrived.connect(_on_passenger_arrived)
	if not _event_bus.passenger_lost.is_connected(_on_passenger_lost):
		_event_bus.passenger_lost.connect(_on_passenger_lost)
	if not _event_bus.station_arrived.is_connected(_on_station_arrived):
		_event_bus.station_arrived.connect(_on_station_arrived)
	if not _event_bus.shop_opened.is_connected(_on_shop_opened):
		_event_bus.shop_opened.connect(_on_shop_opened)
	if not _event_bus.money_spent.is_connected(_on_money_spent):
		_event_bus.money_spent.connect(_on_money_spent)
	if not _event_bus.cargo_delivered.is_connected(_on_cargo_delivered):
		_event_bus.cargo_delivered.connect(_on_cargo_delivered)
	if not _event_bus.random_event_triggered.is_connected(_on_random_event):
		_event_bus.random_event_triggered.connect(_on_random_event)
	if not _event_bus.quest_completed.is_connected(_on_quest_completed):
		_event_bus.quest_completed.connect(_on_quest_completed)

func _on_trip_started(_data: Dictionary) -> void:
	_current_trip_passengers = 0
	_current_trip_lost = 0

func _on_trip_completed(summary: Dictionary) -> void:
	_counters["trips_completed"] = int(_counters.get("trips_completed", 0)) + 1
	_counters["distance_km"] = int(_counters.get("distance_km", 0)) + int(round(float(summary.get("distance_km", 0.0))))
	_check_unlock("trip_first")
	_check_unlock("trip_10")
	_check_unlock("trip_100km")
	_check_unlock("trip_500km")
	_check_unlock("pax_zero_loss")

func _on_passenger_arrived(passenger_data: Dictionary, _station_id: String) -> void:
	_counters["passengers_total"] = int(_counters.get("passengers_total", 0)) + 1
	_current_trip_passengers += 1
	if int(passenger_data.get("type", Constants.PassengerType.NORMAL)) == Constants.PassengerType.VIP:
		_counters["vip_arrived"] = int(_counters.get("vip_arrived", 0)) + 1
	_check_unlock("pax_100")
	_check_unlock("pax_500")
	_check_unlock("pax_vip_first")

func _on_passenger_lost(_passenger_data: Dictionary, _station_id: String) -> void:
	_current_trip_lost += 1

func _on_station_arrived(station_id: String) -> void:
	var visited: Dictionary = _counters.get("visited_stations", {})
	visited[station_id] = true
	_counters["visited_stations"] = visited
	_counters["visited_stop_count"] = visited.size()
	_check_unlock("disc_all_ege")

func _on_shop_opened(_station_id: String, _shop_type: int) -> void:
	_counters["shops_opened"] = int(_counters.get("shops_opened", 0)) + 1
	_check_unlock("col_shop")

func _on_money_spent(_amount: int, reason: String) -> void:
	if reason.find("upgrade") >= 0:
		_counters["upgrades_done"] = int(_counters.get("upgrades_done", 0)) + 1
		_check_unlock("col_upgrade")
	if reason == "locomotive_purchase":
		_check_unlock("col_loco2")
	if reason == "wagon_purchase":
		_check_unlock("col_all_wagons")

func _on_cargo_delivered(_cargo_data: Dictionary, _station_id: String) -> void:
	_counters["cargo_deliveries"] = int(_counters.get("cargo_deliveries", 0)) + 1
	_check_unlock("disc_cargo_first")

func _on_random_event(_event_data: Dictionary) -> void:
	_counters["random_events"] = int(_counters.get("random_events", 0)) + 1
	_check_unlock("disc_event")

func _on_quest_completed(_quest_id: String) -> void:
	_check_unlock("disc_quest_all")

func _check_unlock(achievement_id: String) -> void:
	if not _achievements.has(achievement_id):
		return
	var achievement: Dictionary = _achievements[achievement_id]
	if bool(achievement.get("is_unlocked", false)):
		return
	if not bool(achievement.get("is_visible", false)):
		return
	if not _is_condition_met(achievement_id):
		return
	achievement["is_unlocked"] = true
	_achievements[achievement_id] = achievement
	var reward_money: int = int(achievement.get("reward_money", 0))
	if reward_money > 0 and _economy != null:
		_economy.earn(reward_money, "achievement")
	_unlock_visibility_chain(achievement_id)
	if _event_bus:
		_event_bus.achievement_unlocked.emit(get_achievement(achievement_id))

func _unlock_visibility_chain(unlocked_id: String) -> void:
	for id in _achievements.keys():
		var key: String = str(id)
		var achievement: Dictionary = _achievements[key]
		if str(achievement.get("visible_after", "")) == unlocked_id:
			achievement["is_visible"] = true
			_achievements[key] = achievement

func _is_condition_met(achievement_id: String) -> bool:
	match achievement_id:
		"trip_first":
			return int(_counters.get("trips_completed", 0)) >= Balance.ACH_TARGET_TRIPS_FIRST
		"trip_10":
			return int(_counters.get("trips_completed", 0)) >= Balance.ACH_TARGET_TRIPS_10
		"trip_100km":
			return int(_counters.get("distance_km", 0)) >= Balance.ACH_TARGET_KM_100
		"trip_500km":
			return int(_counters.get("distance_km", 0)) >= Balance.ACH_TARGET_KM_500
		"pax_100":
			return int(_counters.get("passengers_total", 0)) >= Balance.ACH_TARGET_PAX_100
		"pax_vip_first":
			return int(_counters.get("vip_arrived", 0)) >= 1
		"pax_zero_loss":
			return _current_trip_lost <= 0 and _current_trip_passengers >= Balance.ACH_TARGET_PERFECT_MIN_PASSENGERS
		"pax_500":
			return int(_counters.get("passengers_total", 0)) >= Balance.ACH_TARGET_PAX_500
		"col_upgrade":
			return int(_counters.get("upgrades_done", 0)) >= 1
		"col_loco2":
			var inventory: Dictionary = _get_inventory_snapshot()
			return int(inventory.get("locomotive_count", 0)) >= 2
		"col_all_wagons":
			var inv: Dictionary = _get_inventory_snapshot()
			var wagon_types: Array = inv.get("wagon_types", [])
			var required := [
				Constants.WagonType.ECONOMY,
				Constants.WagonType.BUSINESS,
				Constants.WagonType.VIP,
				Constants.WagonType.DINING,
				Constants.WagonType.CARGO,
			]
			for t in required:
				if not wagon_types.has(t):
					return false
			return true
		"col_shop":
			return int(_counters.get("shops_opened", 0)) >= 1
		"disc_all_ege":
			return int(_counters.get("visited_stop_count", 0)) >= Balance.ACH_TARGET_ALL_EGE_STOPS
		"disc_cargo_first":
			return int(_counters.get("cargo_deliveries", 0)) >= 1
		"disc_event":
			return int(_counters.get("random_events", 0)) >= 1
		"disc_quest_all":
			return _get_completed_quest_count() >= Balance.ACH_TARGET_ALL_QUESTS
		_:
			return false

func _get_inventory_snapshot() -> Dictionary:
	if _inventory_snapshot_provider.is_valid():
		var value: Variant = _inventory_snapshot_provider.call()
		if typeof(value) == TYPE_DICTIONARY:
			return value
	return {"locomotive_count": 0, "wagon_types": []}

func _get_completed_quest_count() -> int:
	if _completed_quest_count_provider.is_valid():
		return int(_completed_quest_count_provider.call())
	return 0
