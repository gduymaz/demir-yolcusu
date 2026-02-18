## Test suite: test_splash_scene.gd
## Verifies splash scene layout and train pass animation.

class_name TestSplashScene
extends GdUnitTestSuite

func test_Ready_ShouldRenderGameTitleNearTop() -> void:
	var splash := _create_splash_scene()
	var title := _find_label_by_text(splash, I18n.t("menu.title"))
	assert_object(title).is_not_null()
	assert_float(title.position.y).is_less(220.0)

func test_Ready_ShouldBuildStationLayerAndTrain() -> void:
	var splash := _create_splash_scene()
	var station := splash.get_node_or_null("StationPlatform")
	var tile_background := splash.get_node_or_null("StationTileBackground")
	var rail := splash.get_node_or_null("RailLayer")
	var train := splash.get_node_or_null("TrainRoot")
	assert_object(station).is_not_null()
	assert_object(tile_background).is_not_null()
	assert_int(_count_tile_sprites(tile_background)).is_greater_equal(40)
	assert_object(rail).is_not_null()
	assert_object(train).is_not_null()
	assert_int(_count_tile_sprites(train)).is_greater_equal(3)
	assert_int(train.z_index).is_greater(rail.z_index)

func test_Process_ShouldMoveTrainAcrossStation() -> void:
	var splash := _create_splash_scene()
	var train: Node2D = splash.get_node_or_null("TrainRoot")
	assert_object(train).is_not_null()
	var start_x := train.position.x
	splash._process(0.5)
	assert_float(train.position.x).is_greater(start_x)

func _create_splash_scene() -> Node2D:
	var splash: Node2D = auto_free(load("res://src/scenes/splash/splash_scene.tscn").instantiate())
	get_tree().root.add_child(splash)
	return splash

func _find_label_by_text(root: Node, text: String) -> Label:
	var labels := root.find_children("*", "Label", true, false)
	for label_node in labels:
		var label: Label = label_node
		if label.text == text:
			return label
	return null

func _count_tile_sprites(root: Node) -> int:
	var sprites := root.find_children("*", "Sprite2D", true, false)
	var count := 0
	for sprite_node in sprites:
		var sprite: Sprite2D = sprite_node
		if sprite.texture != null:
			count += 1
	return count
