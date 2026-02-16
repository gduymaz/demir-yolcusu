## Test suite: test_audio_manager.gd
## Validates safe audio behavior without requiring real assets.

class_name TestAudioManager
extends GdUnitTestSuite

func before_test() -> void:
	_ensure_event_bus()
	_clear_runtime_audio()

func after_test() -> void:
	_clear_runtime_audio()
	_clear_runtime_event_bus()

func test_SetVolume_ShouldClampBetweenZeroAndHundred() -> void:
	var manager := _create_manager()
	manager.set_bgm_volume(150)
	manager.set_sfx_volume(-10)
	assert_int(manager.get_bgm_volume()).is_equal(100)
	assert_int(manager.get_sfx_volume()).is_equal(0)

func test_PlaySfx_UnknownName_ShouldNotCrashAndStoreWarning() -> void:
	var manager := _create_manager()
	manager.play_sfx("unknown_clip")
	assert_str(manager.get_last_warning()).contains("unknown SFX")

func test_PlaySfx_Muted_ShouldSkipPlaybackAndWarnings() -> void:
	var manager := _create_manager()
	manager.set_sfx_muted(true)
	manager.play_sfx("unknown_clip")
	assert_str(manager.get_last_warning()).is_equal("")

func test_PlaySfx_KnownClip_ShouldLoadNonNullStream() -> void:
	var manager := _create_manager()
	manager.play_sfx("button_click")
	assert_object(manager._sfx_player.stream).is_not_null()

func test_EventBus_StationArrived_ShouldTriggerAnnouncementCue() -> void:
	var manager := _create_manager()
	var bus := get_tree().root.get_node_or_null("EventBus")
	bus.station_arrived.emit("manisa")
	assert_object(manager._sfx_player.stream).is_not_null()

func _create_manager() -> Node:
	var manager: Node = auto_free(load("res://src/managers/audio_manager.gd").new())
	manager.name = "AudioManager"
	get_tree().root.add_child(manager)
	return manager

func _ensure_event_bus() -> void:
	if get_tree().root.get_node_or_null("EventBus") != null:
		return
	var bus: Node = auto_free(load("res://src/events/event_bus.gd").new())
	bus.name = "EventBus"
	get_tree().root.add_child(bus)

func _clear_runtime_audio() -> void:
	var manager := get_tree().root.get_node_or_null("AudioManager")
	if manager:
		manager.free()

func _clear_runtime_event_bus() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus:
		bus.free()
