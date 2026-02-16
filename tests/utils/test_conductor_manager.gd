## Test suite: test_conductor_manager.gd
## Restored English comments for maintainability and i18n coding standards.

class_name TestConductorManager
extends GdUnitTestSuite

## Handles `test_GetContextHint_Garage_ShouldReturnGarageTip`.
func test_GetContextHint_Garage_ShouldReturnGarageTip() -> void:
	var conductor: CanvasLayer = auto_free(load("res://src/ui/dialogs/conductor_manager.gd").new())
	var hint: Dictionary = conductor.get_context_hint("res://src/scenes/garage/garage_scene.tscn")
	assert_str(hint.get("key", "")).is_equal("tip_garage")
	assert_str(hint.get("text", "")).contains("Vagonlari surukleyerek")

## Handles `test_GetContextHint_Map_ShouldReturnMapTip`.
func test_GetContextHint_Map_ShouldReturnMapTip() -> void:
	var conductor: CanvasLayer = auto_free(load("res://src/ui/dialogs/conductor_manager.gd").new())
	var hint: Dictionary = conductor.get_context_hint("res://src/scenes/map/map_scene.tscn")
	assert_str(hint.get("key", "")).is_equal("tip_map")

## Handles `test_GetContextHint_Travel_ShouldInjectNextStopName`.
func test_GetContextHint_Travel_ShouldInjectNextStopName() -> void:
	var conductor: CanvasLayer = auto_free(load("res://src/ui/dialogs/conductor_manager.gd").new())
	var hint: Dictionary = conductor.get_context_hint("res://src/scenes/travel/travel_scene.tscn", "NAZILLI")
	assert_str(hint.get("key", "")).is_equal("tip_travel")
	assert_str(hint.get("text", "")).contains("NAZILLI")

## Handles `test_GetContextHint_UnknownScene_ShouldReturnEmpty`.
func test_GetContextHint_UnknownScene_ShouldReturnEmpty() -> void:
	var conductor: CanvasLayer = auto_free(load("res://src/ui/dialogs/conductor_manager.gd").new())
	var hint: Dictionary = conductor.get_context_hint("res://src/scenes/unknown/other.tscn")
	assert_int(hint.size()).is_equal(0)

## Handles `test_GetIntroMessages_ShouldIncludeWelcomeAndStory`.
func test_GetIntroMessages_ShouldIncludeWelcomeAndStory() -> void:
	var conductor: CanvasLayer = auto_free(load("res://src/ui/dialogs/conductor_manager.gd").new())
	var intro: Array = conductor.get_intro_messages()
	assert_int(intro.size()).is_equal(4)
	assert_str(str(intro[0])).is_equal(I18n.t("conductor.intro.1"))
