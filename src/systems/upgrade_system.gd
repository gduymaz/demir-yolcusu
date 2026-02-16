## Module: upgrade_system.gd
## Handles locomotive and wagon upgrades with levels, costs, effects, and respec.

class_name UpgradeSystem
extends Node

var _event_bus: Node
var _economy: EconomySystem
var _reputation: ReputationSystem

var _locomotive_levels: Dictionary = {}
var _wagon_levels: Dictionary = {}
var _loco_upgrade_history: Dictionary = {}
var _wagon_upgrade_history: Dictionary = {}
var _line_completion_checker: Callable = Callable()
var _last_failure_reason: String = ""

func setup(event_bus: Node, economy: EconomySystem, reputation: ReputationSystem) -> void:
	_event_bus = event_bus
	_economy = economy
	_reputation = reputation

func upgrade_locomotive(loco_id: String, upgrade_type: int) -> bool:
	var state: Dictionary = can_upgrade_locomotive(loco_id, upgrade_type)
	if not bool(state.get("ok", false)):
		_last_failure_reason = str(state.get("reason", "unknown"))
		return false
	var levels: Dictionary = _locomotive_levels.get(loco_id, _new_locomotive_levels())
	var key: String = str(upgrade_type)
	var current_level: int = int(levels.get(key, 0))
	var next_level: int = current_level + 1
	var cost: int = int(state.get("cost", _get_loco_upgrade_cost(upgrade_type, next_level)))
	if not _economy.spend(cost, "locomotive_upgrade"):
		_last_failure_reason = "spend_failed"
		return false

	levels[key] = next_level
	_locomotive_levels[loco_id] = levels
	var history: Array = _loco_upgrade_history.get(loco_id, [])
	history.append({"upgrade_type": upgrade_type, "cost": cost})
	_loco_upgrade_history[loco_id] = history
	if _event_bus:
		_event_bus.locomotive_upgraded.emit(loco_id, upgrade_type, next_level)
	_last_failure_reason = ""
	return true

func respec_locomotive(loco_id: String) -> bool:
	var history: Array = _loco_upgrade_history.get(loco_id, [])
	if history.is_empty():
		return false
	var last: Dictionary = history.pop_back()
	_loco_upgrade_history[loco_id] = history
	var upgrade_type: int = int(last.get("upgrade_type", -1))
	if upgrade_type < 0:
		return false
	var levels: Dictionary = _locomotive_levels.get(loco_id, _new_locomotive_levels())
	var key: String = str(upgrade_type)
	var current_level: int = int(levels.get(key, 0))
	if current_level <= 0:
		return false
	levels[key] = current_level - 1
	_locomotive_levels[loco_id] = levels

	var paid: int = int(last.get("cost", 0))
	var refund: int = int(round(float(paid) * Balance.UPGRADE_RESPEC_REFUND_RATIO))
	if refund > 0:
		_economy.earn(refund, "upgrade_respec")
	return true

func get_locomotive_level(loco_id: String, upgrade_type: int) -> int:
	var levels: Dictionary = _locomotive_levels.get(loco_id, _new_locomotive_levels())
	return int(levels.get(str(upgrade_type), 0))

func get_locomotive_modifiers(loco_id: String) -> Dictionary:
	var speed_level: int = get_locomotive_level(loco_id, Constants.UpgradeType.SPEED)
	var capacity_level: int = get_locomotive_level(loco_id, Constants.UpgradeType.CAPACITY)
	var fuel_level: int = get_locomotive_level(loco_id, Constants.UpgradeType.FUEL_EFFICIENCY)
	var durability_level: int = get_locomotive_level(loco_id, Constants.UpgradeType.DURABILITY)
	return {
		"speed_multiplier": pow(Balance.UPGRADE_SPEED_MULTIPLIER_PER_LEVEL, speed_level),
		"capacity_bonus": capacity_level,
		"fuel_efficiency_multiplier": pow(Balance.UPGRADE_FUEL_MULTIPLIER_PER_LEVEL, fuel_level),
		"durability_multiplier": pow(Balance.UPGRADE_DURABILITY_MULTIPLIER_PER_LEVEL, durability_level),
	}

func upgrade_wagon(wagon_id: String, wagon_type: int, upgrade_type: int) -> bool:
	var state: Dictionary = can_upgrade_wagon(wagon_id, upgrade_type)
	if not bool(state.get("ok", false)):
		_last_failure_reason = str(state.get("reason", "unknown"))
		return false
	var levels: Dictionary = _wagon_levels.get(wagon_id, _new_wagon_levels())
	var key: String = str(upgrade_type)
	var current_level: int = int(levels.get(key, 0))
	var next_level: int = current_level + 1
	var cost: int = int(state.get("cost", _get_wagon_upgrade_cost(upgrade_type, next_level)))
	if not _economy.spend(cost, "wagon_upgrade"):
		_last_failure_reason = "spend_failed"
		return false
	levels[key] = next_level
	_wagon_levels[wagon_id] = levels
	var history: Array = _wagon_upgrade_history.get(wagon_id, [])
	history.append({"upgrade_type": upgrade_type, "cost": cost, "wagon_type": wagon_type})
	_wagon_upgrade_history[wagon_id] = history
	if _event_bus:
		_event_bus.wagon_upgraded.emit(wagon_id, upgrade_type, next_level)
	_last_failure_reason = ""
	return true

func respec_wagon(wagon_id: String) -> bool:
	var history: Array = _wagon_upgrade_history.get(wagon_id, [])
	if history.is_empty():
		return false
	var last: Dictionary = history.pop_back()
	_wagon_upgrade_history[wagon_id] = history
	var upgrade_type: int = int(last.get("upgrade_type", -1))
	if upgrade_type < 0:
		return false
	var levels: Dictionary = _wagon_levels.get(wagon_id, _new_wagon_levels())
	var key: String = str(upgrade_type)
	var current_level: int = int(levels.get(key, 0))
	if current_level <= 0:
		return false
	levels[key] = current_level - 1
	_wagon_levels[wagon_id] = levels
	var paid: int = int(last.get("cost", 0))
	var refund: int = int(round(float(paid) * Balance.UPGRADE_RESPEC_REFUND_RATIO))
	if refund > 0:
		_economy.earn(refund, "upgrade_respec")
	return true

func get_wagon_level(wagon_id: String, upgrade_type: int) -> int:
	var levels: Dictionary = _wagon_levels.get(wagon_id, _new_wagon_levels())
	return int(levels.get(str(upgrade_type), 0))

func get_wagon_capacity_bonus(wagon_id: String, wagon_type: int) -> int:
	var level: int = get_wagon_level(wagon_id, Constants.WagonUpgradeType.CAPACITY)
	if wagon_type == Constants.WagonType.CARGO:
		return level * Balance.UPGRADE_WAGON_CAPACITY_CARGO_PER_LEVEL
	return level * Balance.UPGRADE_WAGON_CAPACITY_PASSENGER_PER_LEVEL

func get_wagon_comfort_bonus_per_passenger(wagon_id: String) -> float:
	var level: int = get_wagon_level(wagon_id, Constants.WagonUpgradeType.COMFORT)
	return float(level) * Balance.UPGRADE_WAGON_COMFORT_REPUTATION_PER_LEVEL

func get_wagon_maintenance_multiplier(wagon_id: String) -> float:
	var level: int = get_wagon_level(wagon_id, Constants.WagonUpgradeType.MAINTENANCE)
	return pow(Balance.UPGRADE_WAGON_MAINTENANCE_MULTIPLIER_PER_LEVEL, level)

func get_save_data() -> Dictionary:
	return {
		"locomotive_upgrades": _locomotive_levels.duplicate(true),
		"wagon_upgrades": _wagon_levels.duplicate(true),
		"locomotive_history": _loco_upgrade_history.duplicate(true),
		"wagon_history": _wagon_upgrade_history.duplicate(true),
	}

func load_save_data(data: Dictionary) -> void:
	_locomotive_levels = data.get("locomotive_upgrades", {}).duplicate(true)
	_wagon_levels = data.get("wagon_upgrades", {}).duplicate(true)
	_loco_upgrade_history = data.get("locomotive_history", {}).duplicate(true)
	_wagon_upgrade_history = data.get("wagon_history", {}).duplicate(true)

func set_line_completion_checker(checker: Callable) -> void:
	_line_completion_checker = checker

func get_last_failure_reason() -> String:
	return _last_failure_reason

func can_upgrade_locomotive(loco_id: String, upgrade_type: int) -> Dictionary:
	var levels: Dictionary = _locomotive_levels.get(loco_id, _new_locomotive_levels())
	var key: String = str(upgrade_type)
	var current_level: int = int(levels.get(key, 0))
	if current_level >= Balance.UPGRADE_MAX_LEVEL:
		return {"ok": false, "reason": "max_level", "cost": 0, "next_level": current_level}
	var next_level: int = current_level + 1
	var cost: int = _get_loco_upgrade_cost(upgrade_type, next_level)
	if not _economy.can_afford(cost):
		return {"ok": false, "reason": "insufficient_money", "cost": cost, "next_level": next_level}
	var required_rep: float = _get_upgrade_rep_requirement(next_level)
	if not _reputation.meets_requirement(required_rep):
		return {"ok": false, "reason": "insufficient_reputation", "cost": cost, "next_level": next_level}
	if _requires_line_completion(next_level) and not _is_required_line_completed():
		return {"ok": false, "reason": "line_not_completed", "cost": cost, "next_level": next_level}
	return {"ok": true, "reason": "", "cost": cost, "next_level": next_level}

func can_upgrade_wagon(wagon_id: String, upgrade_type: int) -> Dictionary:
	var levels: Dictionary = _wagon_levels.get(wagon_id, _new_wagon_levels())
	var key: String = str(upgrade_type)
	var current_level: int = int(levels.get(key, 0))
	if current_level >= Balance.UPGRADE_MAX_LEVEL:
		return {"ok": false, "reason": "max_level", "cost": 0, "next_level": current_level}
	var next_level: int = current_level + 1
	var cost: int = _get_wagon_upgrade_cost(upgrade_type, next_level)
	if not _economy.can_afford(cost):
		return {"ok": false, "reason": "insufficient_money", "cost": cost, "next_level": next_level}
	var required_rep: float = _get_upgrade_rep_requirement(next_level)
	if not _reputation.meets_requirement(required_rep):
		return {"ok": false, "reason": "insufficient_reputation", "cost": cost, "next_level": next_level}
	if _requires_line_completion(next_level) and not _is_required_line_completed():
		return {"ok": false, "reason": "line_not_completed", "cost": cost, "next_level": next_level}
	return {"ok": true, "reason": "", "cost": cost, "next_level": next_level}

func _new_locomotive_levels() -> Dictionary:
	return {
		str(Constants.UpgradeType.SPEED): 0,
		str(Constants.UpgradeType.CAPACITY): 0,
		str(Constants.UpgradeType.FUEL_EFFICIENCY): 0,
		str(Constants.UpgradeType.DURABILITY): 0,
	}

func _new_wagon_levels() -> Dictionary:
	return {
		str(Constants.WagonUpgradeType.COMFORT): 0,
		str(Constants.WagonUpgradeType.CAPACITY): 0,
		str(Constants.WagonUpgradeType.MAINTENANCE): 0,
	}

func _get_upgrade_rep_requirement(level: int) -> float:
	match level:
		1:
			return Balance.UPGRADE_REPUTATION_L1
		2:
			return Balance.UPGRADE_REPUTATION_L2
		3:
			return Balance.UPGRADE_REPUTATION_L3
		_:
			return Balance.UPGRADE_REPUTATION_L3

func _get_loco_upgrade_cost(upgrade_type: int, level: int) -> int:
	match upgrade_type:
		Constants.UpgradeType.SPEED:
			match level:
				1:
					return Balance.UPGRADE_LOCO_SPEED_COST_L1
				2:
					return Balance.UPGRADE_LOCO_SPEED_COST_L2
				3:
					return Balance.UPGRADE_LOCO_SPEED_COST_L3
		Constants.UpgradeType.CAPACITY:
			match level:
				1:
					return Balance.UPGRADE_LOCO_CAPACITY_COST_L1
				2:
					return Balance.UPGRADE_LOCO_CAPACITY_COST_L2
				3:
					return Balance.UPGRADE_LOCO_CAPACITY_COST_L3
		Constants.UpgradeType.FUEL_EFFICIENCY:
			match level:
				1:
					return Balance.UPGRADE_LOCO_FUEL_COST_L1
				2:
					return Balance.UPGRADE_LOCO_FUEL_COST_L2
				3:
					return Balance.UPGRADE_LOCO_FUEL_COST_L3
		Constants.UpgradeType.DURABILITY:
			match level:
				1:
					return Balance.UPGRADE_LOCO_DURABILITY_COST_L1
				2:
					return Balance.UPGRADE_LOCO_DURABILITY_COST_L2
				3:
					return Balance.UPGRADE_LOCO_DURABILITY_COST_L3
		_:
			return 0
	return 0

func _get_wagon_upgrade_cost(upgrade_type: int, level: int) -> int:
	match upgrade_type:
		Constants.WagonUpgradeType.COMFORT:
			match level:
				1:
					return Balance.UPGRADE_WAGON_COMFORT_COST_L1
				2:
					return Balance.UPGRADE_WAGON_COMFORT_COST_L2
				3:
					return Balance.UPGRADE_WAGON_COMFORT_COST_L3
		Constants.WagonUpgradeType.CAPACITY:
			match level:
				1:
					return Balance.UPGRADE_WAGON_CAPACITY_COST_L1
				2:
					return Balance.UPGRADE_WAGON_CAPACITY_COST_L2
				3:
					return Balance.UPGRADE_WAGON_CAPACITY_COST_L3
		Constants.WagonUpgradeType.MAINTENANCE:
			match level:
				1:
					return Balance.UPGRADE_WAGON_MAINTENANCE_COST_L1
				2:
					return Balance.UPGRADE_WAGON_MAINTENANCE_COST_L2
				3:
					return Balance.UPGRADE_WAGON_MAINTENANCE_COST_L3
		_:
			return 0
	return 0

func _requires_line_completion(level: int) -> bool:
	return level >= Balance.UPGRADE_LINE_LOCK_MIN_LEVEL

func _is_required_line_completed() -> bool:
	if not _line_completion_checker.is_valid():
		return true
	return bool(_line_completion_checker.call(Balance.UPGRADE_LINE_LOCK_REQUIRED))
