## Test suite: test_settings_system.gd
## Validates accessibility multipliers and persistence.

class_name TestSettingsSystem
extends GdUnitTestSuite

var _settings: Node

func before_test() -> void:
	_settings = auto_free(load("res://src/systems/settings_system.gd").new())

func test_FontMultiplier_ShouldMatchPreset() -> void:
	_settings.set_font_size_key("small")
	assert_float(_settings.get_font_multiplier()).is_equal(1.0)
	_settings.set_font_size_key("medium")
	assert_float(_settings.get_font_multiplier()).is_equal(1.25)
	_settings.set_font_size_key("large")
	assert_float(_settings.get_font_multiplier()).is_equal(1.5)

func test_SlowMode_ShouldDoubleTime() -> void:
	_settings.set_slow_mode_enabled(false)
	assert_float(_settings.get_time_multiplier()).is_equal(1.0)
	_settings.set_slow_mode_enabled(true)
	assert_float(_settings.get_time_multiplier()).is_equal(2.0)

func test_SlowMode_WithDifficulty_ShouldMultiplyTogether() -> void:
	_settings.set_slow_mode_enabled(true)
	assert_float(_settings.compose_time_multiplier(0.85)).is_equal(1.7)

func test_SaveLoad_ShouldPersistPreferences() -> void:
	_settings.set_font_size_key("large")
	_settings.set_slow_mode_enabled(true)
	_settings.set_haptic_enabled(false)
	var data: Dictionary = _settings.get_save_data()
	var clone: Node = auto_free(load("res://src/systems/settings_system.gd").new())
	clone.load_save_data(data)
	assert_str(clone.get_font_size_key()).is_equal("large")
	assert_bool(clone.is_slow_mode_enabled()).is_true()
	assert_bool(clone.is_haptic_enabled()).is_false()
