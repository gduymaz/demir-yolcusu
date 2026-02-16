## Module: debug_logger.gd
## Restored English comments for maintainability and i18n coding standards.

extends Node

const DEFAULT_LOG_DIR := "res://logs"

var _enabled: bool = false
var _bus_connected: bool = false
var _log_file: FileAccess
var _log_path: String = ""
var _log_dir: String = ""
var _last_scene_path: String = ""

## Lifecycle/helper logic for `_ready`.
func _ready() -> void:
	_enabled = _should_enable()
	if not _enabled:
		return

	if not _open_log_file():
		return

	set_process(true)
	_write_line("logger_started absolute_path=%s" % get_log_path())
	_try_connect_event_bus()

## Lifecycle/helper logic for `_process`.
func _process(_delta: float) -> void:
	if not _enabled:
		return

	if not _bus_connected:
		_try_connect_event_bus()

	var scene := get_tree().current_scene
	if scene == null:
		return

	if scene.scene_file_path != _last_scene_path:
		_last_scene_path = scene.scene_file_path
		_write_line("scene_changed path=%s" % _last_scene_path)

## Lifecycle/helper logic for `_exit_tree`.
func _exit_tree() -> void:
	if _log_file != null:
		_write_line("logger_stopped")
		_log_file.flush()
		_log_file = null

## Handles `is_enabled`.
func is_enabled() -> bool:
	return _enabled

## Handles `get_log_path`.
func get_log_path() -> String:
	if _log_path.is_empty():
		return ""
	return _log_path

## Lifecycle/helper logic for `_should_enable`.
func _should_enable() -> bool:
	var value := OS.get_environment("DEMIR_DEBUG_LOG").strip_edges().to_lower()
	return value == "1" or value == "true" or value == "yes"

## Lifecycle/helper logic for `_open_log_file`.
func _open_log_file() -> bool:
	var explicit_path := OS.get_environment("DEMIR_DEBUG_LOG_PATH").strip_edges()
	if not explicit_path.is_empty():
		_log_path = explicit_path
		var parent := _log_path.get_base_dir()
		var mkdir_parent := DirAccess.make_dir_recursive_absolute(parent)
		if mkdir_parent != OK:
			push_warning("DebugLogger: log parent klasoru olusturulamadi (%s)" % parent)
			_enabled = false
			return false
		if FileAccess.file_exists(_log_path):
			_log_file = FileAccess.open(_log_path, FileAccess.READ_WRITE)
			if _log_file != null:
				_log_file.seek_end()
		else:
			_log_file = FileAccess.open(_log_path, FileAccess.WRITE_READ)
		if _log_file == null:
			push_warning("DebugLogger: log dosyasi acilamadi (%s)" % _log_path)
			_enabled = false
			return false
		print("DebugLogger aktif: %s" % get_log_path())
		return true

	var abs_dir := _resolve_log_dir()
	var mkdir_result := DirAccess.make_dir_recursive_absolute(abs_dir)
	if mkdir_result != OK:
		push_warning("DebugLogger: log directory olusturulamadi (%s)" % abs_dir)
		_enabled = false
		return false

	var now := Time.get_datetime_dict_from_system()
	_log_path = "%s/debug-log-%04d-%02d-%02d_%02d-%02d-%02d.log" % [
		abs_dir,
		int(now.get("year", 0)),
		int(now.get("month", 0)),
		int(now.get("day", 0)),
		int(now.get("hour", 0)),
		int(now.get("minute", 0)),
		int(now.get("second", 0)),
	]
	_log_file = FileAccess.open(_log_path, FileAccess.WRITE)
	if _log_file == null:
		push_warning("DebugLogger: log dosyasi acilamadi (%s)" % _log_path)
		_enabled = false
		return false

	print("DebugLogger aktif: %s" % get_log_path())
	return true

## Lifecycle/helper logic for `_try_connect_event_bus`.
func _try_connect_event_bus() -> void:
	if _bus_connected:
		return

	var bus: Node = get_node_or_null("/root/EventBus")
	if bus == null:
		return

	bus.passenger_boarded.connect(_on_passenger_boarded)
	bus.passenger_lost.connect(_on_passenger_lost)
	bus.passenger_arrived.connect(_on_passenger_arrived)
	bus.money_changed.connect(_on_money_changed)
	bus.money_earned.connect(_on_money_earned)
	bus.money_spent.connect(_on_money_spent)
	bus.reputation_changed.connect(_on_reputation_changed)
	bus.fuel_changed.connect(_on_fuel_changed)
	bus.fuel_low.connect(_on_fuel_low)
	bus.fuel_empty.connect(_on_fuel_empty)
	bus.trip_started.connect(_on_trip_started)
	bus.trip_completed.connect(_on_trip_completed)
	bus.station_arrived.connect(_on_station_arrived)
	bus.hud_update_requested.connect(_on_hud_update_requested)
	bus.dialog_requested.connect(_on_dialog_requested)
	_bus_connected = true
	_write_line("event_bus_connected")

## Lifecycle/helper logic for `_on_passenger_boarded`.
func _on_passenger_boarded(passenger_data: Dictionary, wagon_id: int) -> void:
	_write_line("passenger_boarded wagon_id=%d data=%s" % [wagon_id, _to_json(passenger_data)])

## Lifecycle/helper logic for `_on_passenger_lost`.
func _on_passenger_lost(passenger_data: Dictionary, station_id: String) -> void:
	_write_line("passenger_lost station=%s data=%s" % [station_id, _to_json(passenger_data)])

## Lifecycle/helper logic for `_on_passenger_arrived`.
func _on_passenger_arrived(passenger_data: Dictionary, station_id: String) -> void:
	_write_line("passenger_arrived station=%s data=%s" % [station_id, _to_json(passenger_data)])

## Lifecycle/helper logic for `_on_money_changed`.
func _on_money_changed(old_value: int, new_value: int, reason: String) -> void:
	_write_line("money_changed old=%d new=%d reason=%s" % [old_value, new_value, reason])

## Lifecycle/helper logic for `_on_money_earned`.
func _on_money_earned(amount: int, source: String) -> void:
	_write_line("money_earned amount=%d source=%s" % [amount, source])

## Lifecycle/helper logic for `_on_money_spent`.
func _on_money_spent(amount: int, reason: String) -> void:
	_write_line("money_spent amount=%d reason=%s" % [amount, reason])

## Lifecycle/helper logic for `_on_reputation_changed`.
func _on_reputation_changed(old_value: float, new_value: float) -> void:
	_write_line("reputation_changed old=%.2f new=%.2f" % [old_value, new_value])

## Lifecycle/helper logic for `_on_fuel_changed`.
func _on_fuel_changed(percentage: float) -> void:
	_write_line("fuel_changed percentage=%.2f" % percentage)

## Lifecycle/helper logic for `_on_fuel_low`.
func _on_fuel_low(locomotive_id: String, percentage: float) -> void:
	_write_line("fuel_low locomotive=%s percentage=%.2f" % [locomotive_id, percentage])

## Lifecycle/helper logic for `_on_fuel_empty`.
func _on_fuel_empty(locomotive_id: String) -> void:
	_write_line("fuel_empty locomotive=%s" % locomotive_id)

## Lifecycle/helper logic for `_on_trip_started`.
func _on_trip_started(route_data: Dictionary) -> void:
	_write_line("trip_started data=%s" % _to_json(route_data))

## Lifecycle/helper logic for `_on_trip_completed`.
func _on_trip_completed(trip_summary: Dictionary) -> void:
	_write_line("trip_completed summary=%s" % _to_json(trip_summary))

## Lifecycle/helper logic for `_on_station_arrived`.
func _on_station_arrived(station_id: String) -> void:
	_write_line("station_arrived station=%s" % station_id)

## Lifecycle/helper logic for `_on_hud_update_requested`.
func _on_hud_update_requested() -> void:
	_write_line("hud_update_requested")

## Lifecycle/helper logic for `_on_dialog_requested`.
func _on_dialog_requested(dialog_data: Dictionary) -> void:
	_write_line("dialog_requested data=%s" % _to_json(dialog_data))

## Lifecycle/helper logic for `_write_line`.
func _write_line(message: String) -> void:
	if _log_file == null:
		return
	var prefix := "[%d]" % Time.get_ticks_msec()
	var line := "%s %s" % [prefix, message]
	_log_file.store_line(line)
	_log_file.flush()
	if _should_print_to_stdout():
		print(line)

## Lifecycle/helper logic for `_should_print_to_stdout`.
func _should_print_to_stdout() -> bool:
	var value := OS.get_environment("DEMIR_DEBUG_STDOUT").strip_edges().to_lower()
	return value == "1" or value == "true" or value == "yes"

## Lifecycle/helper logic for `_to_json`.
func _to_json(value: Variant) -> String:
	return JSON.stringify(value)

## Lifecycle/helper logic for `_resolve_log_dir`.
func _resolve_log_dir() -> String:
	if not _log_dir.is_empty():
		return _log_dir

	var dir_setting := OS.get_environment("DEMIR_DEBUG_LOG_DIR").strip_edges()
	if dir_setting.is_empty():
		dir_setting = DEFAULT_LOG_DIR

	if dir_setting.begins_with("res://") or dir_setting.begins_with("user://"):
		_log_dir = ProjectSettings.globalize_path(dir_setting)
	else:
		_log_dir = dir_setting

	return _log_dir
