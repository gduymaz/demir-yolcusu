## Module: settings_scene.gd
## Presents gameplay/audio/accessibility settings and save reset.

extends Node2D

const VIEWPORT_W := 540
const VIEWPORT_H := 960

var _music_slider: HSlider
var _sfx_slider: HSlider
var _haptic_toggle: Button
var _slow_toggle: Button
var _font_small_btn: Button
var _font_medium_btn: Button
var _font_large_btn: Button
var _delete_btn: Button
var _delete_armed: bool = false

func _ready() -> void:
	_build_scene()
	_load_values()
	_apply_accessibility_preview()

func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = Color("#0b1220")
	add_child(bg)

	var panel := ColorRect.new()
	panel.position = Vector2(20, 80)
	panel.size = Vector2(VIEWPORT_W - 40, VIEWPORT_H - 120)
	panel.color = Color("#16213e")
	add_child(panel)

	var title := Label.new()
	title.text = I18n.t("settings.title")
	title.position = Vector2(40, 100)
	title.size = Vector2(VIEWPORT_W - 80, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#f1c40f"))
	add_child(title)

	var y: float = 150.0
	_add_section_label(I18n.t("settings.section.audio"), y)
	y += 28
	_music_slider = _add_slider_row(I18n.t("settings.music"), y)
	y += 54
	_sfx_slider = _add_slider_row(I18n.t("settings.sfx"), y)
	y += 66

	_add_section_label(I18n.t("settings.section.gameplay"), y)
	y += 30
	_haptic_toggle = _add_toggle_row(I18n.t("settings.haptic"), y, _on_haptic_toggled)
	y += 48
	_slow_toggle = _add_toggle_row(I18n.t("settings.slow_mode"), y, _on_slow_mode_toggled)
	y += 62

	_add_section_label(I18n.t("settings.section.visual"), y)
	y += 30
	var font_label := Label.new()
	font_label.text = I18n.t("settings.font_size")
	font_label.position = Vector2(44, y)
	font_label.size = Vector2(180, 30)
	font_label.add_theme_font_size_override("font_size", 14)
	font_label.add_theme_color_override("font_color", Color("#ecf0f1"))
	add_child(font_label)
	_font_small_btn = _add_font_button(I18n.t("settings.font.small"), Vector2(220, y), Balance.ACCESSIBILITY_FONT_SMALL)
	_font_medium_btn = _add_font_button(I18n.t("settings.font.medium"), Vector2(314, y), Balance.ACCESSIBILITY_FONT_MEDIUM)
	_font_large_btn = _add_font_button(I18n.t("settings.font.large"), Vector2(410, y), Balance.ACCESSIBILITY_FONT_LARGE)
	y += 72

	_add_section_label(I18n.t("settings.section.data"), y)
	y += 34
	_delete_btn = Button.new()
	_delete_btn.position = Vector2(44, y)
	_delete_btn.size = Vector2(452, 44)
	_delete_btn.text = I18n.t("settings.delete_save")
	_delete_btn.pressed.connect(_on_delete_save_pressed)
	add_child(_delete_btn)
	y += 74

	var back_btn := Button.new()
	back_btn.position = Vector2(170, y)
	back_btn.size = Vector2(200, 44)
	back_btn.text = I18n.t("settings.button.back")
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)

func _add_section_label(text: String, y: float) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(40, y)
	label.size = Vector2(300, 24)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#f7dc6f"))
	add_child(label)

func _add_slider_row(text: String, y: float) -> HSlider:
	var label := Label.new()
	label.text = text
	label.position = Vector2(44, y)
	label.size = Vector2(140, 30)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("#ecf0f1"))
	add_child(label)
	var slider := HSlider.new()
	slider.position = Vector2(190, y + 5)
	slider.size = Vector2(300, 24)
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value_changed.connect(_on_slider_changed)
	add_child(slider)
	return slider

func _add_toggle_row(text: String, y: float, callback: Callable) -> Button:
	var label := Label.new()
	label.text = text
	label.position = Vector2(44, y)
	label.size = Vector2(220, 30)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("#ecf0f1"))
	add_child(label)
	var button := Button.new()
	button.position = Vector2(370, y)
	button.size = Vector2(120, 34)
	button.pressed.connect(callback)
	add_child(button)
	return button

func _add_font_button(text: String, pos: Vector2, key: String) -> Button:
	var button := Button.new()
	button.position = pos
	button.size = Vector2(88, 32)
	button.text = text
	button.pressed.connect(_on_font_selected.bind(key))
	add_child(button)
	return button

func _load_values() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.settings_system == null:
		return
	_music_slider.value = gm.settings_system.get_music_volume()
	_sfx_slider.value = gm.settings_system.get_sfx_volume()
	_update_toggle_labels(gm.settings_system)
	_update_font_button_state(gm.settings_system.get_font_size_key())
	_delete_armed = false
	_delete_btn.text = I18n.t("settings.delete_save")

func _on_slider_changed(_value: float) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.settings_system == null:
		return
	gm.settings_system.set_music_volume(int(_music_slider.value))
	gm.settings_system.set_sfx_volume(int(_sfx_slider.value))
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio:
		audio.set_bgm_volume(gm.settings_system.get_music_volume())
		audio.set_sfx_volume(gm.settings_system.get_sfx_volume())
	gm.save_game()

func _on_haptic_toggled() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.settings_system == null:
		return
	gm.settings_system.set_haptic_enabled(not gm.settings_system.is_haptic_enabled())
	_update_toggle_labels(gm.settings_system)
	gm.save_game()

func _on_slow_mode_toggled() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.settings_system == null:
		return
	var new_value: bool = not gm.settings_system.is_slow_mode_enabled()
	gm.settings_system.set_slow_mode_enabled(new_value)
	_update_toggle_labels(gm.settings_system)
	if new_value:
		var conductor: Node = get_node_or_null("/root/ConductorManager")
		if conductor:
			conductor.show_runtime_tip("tip_slow_mode", I18n.t("conductor.tip.slow_mode"))
	gm.save_game()

func _on_font_selected(key: String) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.settings_system == null:
		return
	gm.settings_system.set_font_size_key(key)
	_update_font_button_state(key)
	gm.settings_system.apply_font_scale_recursive(get_tree().root)
	gm.save_game()

func _update_toggle_labels(settings_system: Node) -> void:
	_haptic_toggle.text = I18n.t("settings.toggle.on") if settings_system.is_haptic_enabled() else I18n.t("settings.toggle.off")
	_slow_toggle.text = I18n.t("settings.toggle.on") if settings_system.is_slow_mode_enabled() else I18n.t("settings.toggle.off")

func _update_font_button_state(key: String) -> void:
	_font_small_btn.disabled = key == Balance.ACCESSIBILITY_FONT_SMALL
	_font_medium_btn.disabled = key == Balance.ACCESSIBILITY_FONT_MEDIUM
	_font_large_btn.disabled = key == Balance.ACCESSIBILITY_FONT_LARGE

func _on_delete_save_pressed() -> void:
	if not _delete_armed:
		_delete_armed = true
		_delete_btn.text = I18n.t("settings.delete_save_confirm")
		return
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		gm.delete_save_slot(gm.get_active_save_slot())
	_delete_armed = false
	_delete_btn.text = I18n.t("settings.delete_save_done")

func _on_back_pressed() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.trip_planner and gm.trip_planner.is_trip_active():
		SceneTransition.transition_to("res://src/scenes/map/map_scene.tscn")
		return
	if SceneTransition.get_last_scene_path().contains("main_menu"):
		SceneTransition.transition_to("res://src/scenes/main_menu/main_menu.tscn")
		return
	SceneTransition.transition_to("res://src/scenes/garage/garage_scene.tscn")

func _apply_accessibility_preview() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.settings_system:
		gm.settings_system.apply_font_scale_recursive(self)
