## Kondüktör ipucu secim mantigi testleri.
class_name TestConductorManager
extends GdUnitTestSuite


func test_GetContextHint_Garage_ShouldReturnGarageTip() -> void:
	var conductor: CanvasLayer = auto_free(load("res://src/ui/dialogs/conductor_manager.gd").new())
	var hint: Dictionary = conductor.get_context_hint("res://src/scenes/garage/garage_scene.tscn")
	assert_str(hint.get("key", "")).is_equal("tip_garage")
	assert_str(hint.get("text", "")).contains("Vagonlari surukleyerek")


func test_GetContextHint_Map_ShouldReturnMapTip() -> void:
	var conductor: CanvasLayer = auto_free(load("res://src/ui/dialogs/conductor_manager.gd").new())
	var hint: Dictionary = conductor.get_context_hint("res://src/scenes/map/map_scene.tscn")
	assert_str(hint.get("key", "")).is_equal("tip_map")


func test_GetContextHint_Travel_ShouldInjectNextStopName() -> void:
	var conductor: CanvasLayer = auto_free(load("res://src/ui/dialogs/conductor_manager.gd").new())
	var hint: Dictionary = conductor.get_context_hint("res://src/scenes/travel/travel_scene.tscn", "NAZILLI")
	assert_str(hint.get("key", "")).is_equal("tip_travel")
	assert_str(hint.get("text", "")).contains("NAZILLI")


func test_GetContextHint_UnknownScene_ShouldReturnEmpty() -> void:
	var conductor: CanvasLayer = auto_free(load("res://src/ui/dialogs/conductor_manager.gd").new())
	var hint: Dictionary = conductor.get_context_hint("res://src/scenes/unknown/other.tscn")
	assert_int(hint.size()).is_equal(0)
