## Module: difficulty_system.gd
## Handles hidden dynamic difficulty adaptation based on last trip performance.

class_name DifficultySystem
extends Node

var _last_scores: Array = []
var _override_time: float = 1.0
var _override_patience: float = 1.0
var _override_breakdown: float = 1.0
var _override_income: float = 1.0

func record_trip(performance_score: float) -> void:
	_last_scores.append(clampf(performance_score, 0.0, 100.0))
	while _last_scores.size() > Balance.DIFFICULTY_HISTORY_SIZE:
		_last_scores.remove_at(0)

func get_average_performance() -> float:
	if _last_scores.is_empty():
		return 0.0
	var total: float = 0.0
	for score in _last_scores:
		total += float(score)
	return total / float(_last_scores.size())

func get_time_multiplier() -> float:
	return _resolve_multiplier("time")

func get_patience_multiplier() -> float:
	return _resolve_multiplier("patience")

func get_breakdown_multiplier() -> float:
	return _resolve_multiplier("breakdown")

func get_income_multiplier() -> float:
	return _resolve_multiplier("income")

func set_profile_multipliers(time_mul: float, patience_mul: float, breakdown_mul: float, income_mul: float) -> void:
	_override_time = time_mul
	_override_patience = patience_mul
	_override_breakdown = breakdown_mul
	_override_income = income_mul

func get_save_data() -> Dictionary:
	return {
		"last_scores": _last_scores.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	_last_scores = data.get("last_scores", []).duplicate()
	while _last_scores.size() > Balance.DIFFICULTY_HISTORY_SIZE:
		_last_scores.remove_at(0)

func _resolve_multiplier(kind: String) -> float:
	if _last_scores.size() < Balance.DIFFICULTY_HISTORY_SIZE:
		return 1.0
	var avg: float = get_average_performance()
	var base: float = 1.0
	match kind:
		"time":
			base = _resolve_triplet(Balance.DIFFICULTY_TIME_LOW, Balance.DIFFICULTY_TIME_MID, Balance.DIFFICULTY_TIME_HIGH, avg)
			base *= _override_time
		"patience":
			base = _resolve_triplet(Balance.DIFFICULTY_PATIENCE_LOW, Balance.DIFFICULTY_PATIENCE_MID, Balance.DIFFICULTY_PATIENCE_HIGH, avg)
			base *= _override_patience
		"breakdown":
			base = _resolve_triplet(Balance.DIFFICULTY_BREAKDOWN_LOW, Balance.DIFFICULTY_BREAKDOWN_MID, Balance.DIFFICULTY_BREAKDOWN_HIGH, avg)
			base *= _override_breakdown
		"income":
			base = _resolve_triplet(Balance.DIFFICULTY_INCOME_LOW, Balance.DIFFICULTY_INCOME_MID, Balance.DIFFICULTY_INCOME_HIGH, avg)
			base *= _override_income
	return clampf(base, Balance.DIFFICULTY_CLAMP_MIN, Balance.DIFFICULTY_CLAMP_MAX)

func _resolve_triplet(low_value: float, mid_value: float, high_value: float, avg: float) -> float:
	if avg < Balance.DIFFICULTY_PERF_LOW:
		return low_value
	if avg >= Balance.DIFFICULTY_PERF_HIGH:
		return high_value
	return mid_value
