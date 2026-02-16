## Module: settings_system.gd
## Stores and applies gameplay/accessibility preferences.

class_name SettingsSystem
extends Node

var _music_volume: int = 80
var _sfx_volume: int = 80
var _haptic_enabled: bool = true
var _slow_mode_enabled: bool = false
var _font_size_key: String = Balance.ACCESSIBILITY_FONT_SMALL

func set_music_volume(value: int) -> void:
	_music_volume = clampi(value, 0, 100)

func get_music_volume() -> int:
	return _music_volume

func set_sfx_volume(value: int) -> void:
	_sfx_volume = clampi(value, 0, 100)

func get_sfx_volume() -> int:
	return _sfx_volume

func set_haptic_enabled(value: bool) -> void:
	_haptic_enabled = value

func is_haptic_enabled() -> bool:
	return _haptic_enabled

func set_slow_mode_enabled(value: bool) -> void:
	_slow_mode_enabled = value

func is_slow_mode_enabled() -> bool:
	return _slow_mode_enabled

func set_font_size_key(value: String) -> void:
	match value:
		Balance.ACCESSIBILITY_FONT_SMALL, Balance.ACCESSIBILITY_FONT_MEDIUM, Balance.ACCESSIBILITY_FONT_LARGE:
			_font_size_key = value
		_:
			_font_size_key = Balance.ACCESSIBILITY_FONT_SMALL

func get_font_size_key() -> String:
	return _font_size_key

func get_font_multiplier() -> float:
	match _font_size_key:
		Balance.ACCESSIBILITY_FONT_MEDIUM:
			return Balance.ACCESSIBILITY_FONT_MULTIPLIER_MEDIUM
		Balance.ACCESSIBILITY_FONT_LARGE:
			return Balance.ACCESSIBILITY_FONT_MULTIPLIER_LARGE
		_:
			return Balance.ACCESSIBILITY_FONT_MULTIPLIER_SMALL

func get_time_multiplier() -> float:
	return Balance.ACCESSIBILITY_SLOW_MODE_MULTIPLIER if _slow_mode_enabled else 1.0

func compose_time_multiplier(difficulty_multiplier: float) -> float:
	return get_time_multiplier() * difficulty_multiplier

func apply_font_scale_recursive(root: Node) -> void:
	var mul: float = get_font_multiplier()
	_apply_font_scale(root, mul)

func get_save_data() -> Dictionary:
	return {
		"music_volume": _music_volume,
		"sfx_volume": _sfx_volume,
		"haptic_enabled": _haptic_enabled,
		"slow_mode_enabled": _slow_mode_enabled,
		"font_size_key": _font_size_key,
	}

func load_save_data(data: Dictionary) -> void:
	set_music_volume(int(data.get("music_volume", 80)))
	set_sfx_volume(int(data.get("sfx_volume", 80)))
	set_haptic_enabled(bool(data.get("haptic_enabled", true)))
	set_slow_mode_enabled(bool(data.get("slow_mode_enabled", false)))
	set_font_size_key(str(data.get("font_size_key", Balance.ACCESSIBILITY_FONT_SMALL)))

func _apply_font_scale(node: Node, multiplier: float) -> void:
	if node is Label:
		var label: Label = node
		var current_size: int = label.get_theme_font_size("font_size")
		if current_size > 0:
			var base_size: int = current_size
			if label.has_meta("base_font_size"):
				base_size = int(label.get_meta("base_font_size"))
			else:
				label.set_meta("base_font_size", current_size)
			label.add_theme_font_size_override("font_size", int(round(float(base_size) * multiplier)))
	if node is Button:
		var button: Button = node
		var button_size: int = button.get_theme_font_size("font_size")
		if button_size > 0:
			var base_button_size: int = button_size
			if button.has_meta("base_font_size"):
				base_button_size = int(button.get_meta("base_font_size"))
			else:
				button.set_meta("base_font_size", button_size)
			button.add_theme_font_size_override("font_size", int(round(float(base_button_size) * multiplier)))
	for child in node.get_children():
		_apply_font_scale(child, multiplier)
