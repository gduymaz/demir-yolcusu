## Module: reputation_system.gd
## Restored English comments for maintainability and i18n coding standards.

class_name ReputationSystem
extends Node

var _reputation: float = Balance.REPUTATION_STARTING
var _event_bus: Node

## Handles `setup`.
func setup(event_bus: Node) -> void:
	_event_bus = event_bus

## Handles `get_reputation`.
func get_reputation() -> float:
	return _reputation

## Handles `get_stars`.
func get_stars() -> float:
	return _reputation

## Handles `meets_requirement`.
func meets_requirement(min_stars: float) -> bool:
	return _reputation >= min_stars

## Handles `set_reputation`.
func set_reputation(value: float) -> void:
	_reputation = clampf(value, Balance.REPUTATION_MIN, Balance.REPUTATION_MAX)

## Handles `add`.
func add(points: float, _reason: String) -> void:
	if points <= 0.0:
		return

	var old_rep := _reputation
	_reputation = minf(_reputation + points, Balance.REPUTATION_MAX)

	if _event_bus:
		_event_bus.reputation_changed.emit(old_rep, _reputation)

## Handles `remove`.
func remove(points: float, _reason: String) -> void:
	if points <= 0.0:
		return

	var old_rep := _reputation
	var actual_loss := points * Balance.REPUTATION_LOSS_MULTIPLIER
	_reputation = maxf(_reputation - actual_loss, Balance.REPUTATION_MIN)

	if _event_bus:
		_event_bus.reputation_changed.emit(old_rep, _reputation)
