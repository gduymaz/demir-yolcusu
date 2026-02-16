## Test suite: test_tutorial_manager.gd
## Validates tutorial progression, skip behavior, slot handling, and persistence.

class_name TestTutorialManager
extends GdUnitTestSuite

var _tutorial: Node

func before_test() -> void:
	_tutorial = auto_free(load("res://src/systems/tutorial_manager.gd").new())
	_tutorial.setup(1)

func test_StepProgression_ShouldAdvanceOnTrigger() -> void:
	assert_int(_tutorial.get_current_step()).is_equal(1)
	_tutorial.notify("wagon_added")
	assert_int(_tutorial.get_current_step()).is_equal(2)

func test_Skip_ShouldCompleteTutorial() -> void:
	_tutorial.skip_tutorial()
	assert_bool(_tutorial.is_tutorial_complete()).is_true()
	assert_int(_tutorial.get_current_step()).is_equal(-1)

func test_SecondSlot_ShouldStartAsCompleted() -> void:
	var slot_two: Node = auto_free(load("res://src/systems/tutorial_manager.gd").new())
	slot_two.setup(2)
	assert_bool(slot_two.is_tutorial_complete()).is_true()
	assert_int(slot_two.get_current_step()).is_equal(-1)

func test_CompletedTutorial_ShouldNotRestart() -> void:
	_tutorial.skip_tutorial()
	_tutorial.setup(1)
	assert_bool(_tutorial.is_tutorial_complete()).is_true()
	assert_int(_tutorial.get_current_step()).is_equal(-1)

func test_SaveLoad_ShouldPersistTutorialState() -> void:
	_tutorial.notify("wagon_added")
	var data: Dictionary = _tutorial.get_save_data()
	var clone: Node = auto_free(load("res://src/systems/tutorial_manager.gd").new())
	clone.setup(1)
	clone.load_save_data(data)
	assert_int(clone.get_current_step()).is_equal(2)
	assert_bool(clone.is_tutorial_complete()).is_false()
