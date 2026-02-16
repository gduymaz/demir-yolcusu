## Module: tutorial_manager.gd
## Handles first-session guided steps and lightweight state progression.

class_name TutorialManager
extends Node

var _slot_index: int = 1
var _current_step: int = 1
var _is_complete: bool = false

var _step_map: Dictionary = {
	1: {"trigger": "wagon_added", "key": "tutorial.step.1", "highlight": "garage_wagon_pool"},
	2: {"trigger": "map_selected", "key": "tutorial.step.2", "highlight": "map_select_stop"},
	3: {"trigger": "first_boarded", "key": "tutorial.step.3", "highlight": "station_passenger"},
	4: {"trigger": "timer_half", "key": "tutorial.step.4", "highlight": "station_timer"},
	5: {"trigger": "travel_started", "key": "tutorial.step.5", "highlight": "travel_speed_button"},
	6: {"trigger": "summary_opened", "key": "tutorial.step.6", "highlight": "summary_net"},
}

func setup(slot_index: int) -> void:
	_slot_index = max(1, slot_index)
	if _slot_index >= 2:
		_is_complete = true
		_current_step = -1
		return
	if _is_complete:
		_current_step = -1
		return
	if _current_step <= 0:
		_current_step = 1

func notify(trigger: String) -> bool:
	if _is_complete or _current_step < 0:
		return false
	var step_data: Dictionary = _step_map.get(_current_step, {})
	if step_data.is_empty():
		complete_tutorial()
		return false
	if str(step_data.get("trigger", "")) != trigger:
		return false
	_current_step += 1
	if not _step_map.has(_current_step):
		complete_tutorial()
	return true

func get_current_step() -> int:
	return _current_step

func is_tutorial_complete() -> bool:
	return _is_complete

func get_current_message_key() -> String:
	if _is_complete or _current_step < 0:
		return ""
	var step_data: Dictionary = _step_map.get(_current_step, {})
	return str(step_data.get("key", ""))

func get_current_highlight_id() -> String:
	if _is_complete or _current_step < 0:
		return ""
	var step_data: Dictionary = _step_map.get(_current_step, {})
	return str(step_data.get("highlight", ""))

func skip_tutorial() -> void:
	complete_tutorial()

func complete_tutorial() -> void:
	_is_complete = true
	_current_step = -1

func get_save_data() -> Dictionary:
	return {
		"slot_index": _slot_index,
		"current_step": _current_step,
		"is_complete": _is_complete,
	}

func load_save_data(data: Dictionary) -> void:
	_slot_index = int(data.get("slot_index", 1))
	_current_step = int(data.get("current_step", 1))
	_is_complete = bool(data.get("is_complete", false))
	if _slot_index >= 2:
		complete_tutorial()
