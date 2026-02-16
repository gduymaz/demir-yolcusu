## İtibar sistemi.
## Asimetrik: artar hızlı, düşer yavaş (×0.5 çarpan).
## 0.0 - 5.0 arası, yarım yıldız dahil.
class_name ReputationSystem
extends Node


var _reputation: float = Balance.REPUTATION_STARTING
var _event_bus: Node


func setup(event_bus: Node) -> void:
	_event_bus = event_bus


# ==========================================================
# OKUMA
# ==========================================================

func get_reputation() -> float:
	return _reputation


func get_stars() -> float:
	return _reputation


func meets_requirement(min_stars: float) -> bool:
	return _reputation >= min_stars


# ==========================================================
# DEĞİŞTİRME
# ==========================================================

func set_reputation(value: float) -> void:
	_reputation = clampf(value, Balance.REPUTATION_MIN, Balance.REPUTATION_MAX)


func add(points: float, _reason: String) -> void:
	if points <= 0.0:
		return

	var old_rep := _reputation
	_reputation = minf(_reputation + points, Balance.REPUTATION_MAX)

	if _event_bus:
		_event_bus.reputation_changed.emit(old_rep, _reputation)


func remove(points: float, _reason: String) -> void:
	if points <= 0.0:
		return

	var old_rep := _reputation
	var actual_loss := points * Balance.REPUTATION_LOSS_MULTIPLIER
	_reputation = maxf(_reputation - actual_loss, Balance.REPUTATION_MIN)

	if _event_bus:
		_event_bus.reputation_changed.emit(old_rep, _reputation)
