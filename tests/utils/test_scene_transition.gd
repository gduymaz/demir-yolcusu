## Test suite: test_scene_transition.gd
## Verifies transition state bookkeeping.

class_name TestSceneTransition
extends GdUnitTestSuite

func test_TransitionTo_EmptyPath_ShouldDoNothing() -> void:
	var transition: Node = auto_free(load("res://src/ui/transition/scene_transition.gd").new())
	get_tree().root.add_child(transition)
	transition.transition_to("")
	assert_bool(transition.is_transitioning()).is_false()
	assert_str(transition.get_pending_scene_path()).is_equal("")

func test_TransitionTo_Path_ShouldQueuePendingScene() -> void:
	var transition: Node = auto_free(load("res://src/ui/transition/scene_transition.gd").new())
	get_tree().root.add_child(transition)
	transition.transition_to("res://src/scenes/main_menu/main_menu.tscn")
	assert_str(transition.get_pending_scene_path()).is_equal("res://src/scenes/main_menu/main_menu.tscn")
