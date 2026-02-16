## Module: main_menu.gd
## Main entry menu with slot-based load/new game actions.

extends Node2D

const VIEWPORT_W := 540
const VIEWPORT_H := 960

enum SlotMode {
	LOAD,
	NEW_GAME,
}

var _start_button: Button
var _continue_button: Button
var _slot_panel: PanelContainer
var _slot_mode: int = SlotMode.LOAD
var _slot_rows: Array = []
var _pending_overwrite_slot: int = -1
var _has_any_save: bool = false
var _train: ColorRect
var _train_base_x: float = 100.0
var _train_elapsed: float = 0.0

func _ready() -> void:
	_build_scene()
	_refresh()

func _process(delta: float) -> void:
	if _train == null:
		return
	_train_elapsed += delta
	_train.position.x = _train_base_x + sin(_train_elapsed * 1.25) * 32.0

func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = Color("#1b263b")
	add_child(bg)

	var logo := Label.new()
	logo.text = I18n.t("menu.title")
	logo.position = Vector2(30, 110)
	logo.size = Vector2(VIEWPORT_W - 60, 60)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 42)
	logo.add_theme_color_override("font_color", Color("#e74c3c"))
	add_child(logo)

	_train = ColorRect.new()
	_train.position = Vector2(_train_base_x, 200)
	_train.size = Vector2(340, 40)
	_train.color = Color("#c0392b")
	add_child(_train)

	var cabin := ColorRect.new()
	cabin.position = Vector2(250, -18)
	cabin.size = Vector2(80, 18)
	cabin.color = Color("#922b21")
	_train.add_child(cabin)

	for i in range(4):
		var window := ColorRect.new()
		window.position = Vector2(20 + i * 75, 8)
		window.size = Vector2(32, 16)
		window.color = Color(1.0, 1.0, 1.0, 0.45)
		_train.add_child(window)

	for wheel_x in [20.0, 95.0, 170.0, 245.0, 310.0]:
		var wheel := ColorRect.new()
		wheel.position = Vector2(wheel_x, 34)
		wheel.size = Vector2(16, 16)
		wheel.color = Color("#2c3e50")
		_train.add_child(wheel)

	_start_button = _make_menu_button(I18n.t("menu.start"), Vector2(120, 420))
	_start_button.pressed.connect(_on_start_pressed)
	add_child(_start_button)

	_continue_button = _make_menu_button(I18n.t("menu.continue"), Vector2(120, 490))
	_continue_button.pressed.connect(_on_continue_pressed)
	add_child(_continue_button)

	var settings_button := _make_menu_button(I18n.t("menu.settings"), Vector2(120, 560))
	settings_button.pressed.connect(func() -> void:
		_play_click()
		SceneTransition.transition_to("res://src/scenes/settings/settings_scene.tscn")
	)
	add_child(settings_button)

	var achievements_button := _make_menu_button(I18n.t("menu.achievements"), Vector2(120, 630))
	achievements_button.pressed.connect(func() -> void:
		_play_click()
		SceneTransition.transition_to("res://src/scenes/achievements/achievements_scene.tscn")
	)
	add_child(achievements_button)

	var version_label := Label.new()
	version_label.text = I18n.t("menu.version")
	version_label.position = Vector2(20, 920)
	version_label.size = Vector2(VIEWPORT_W - 40, 24)
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.add_theme_color_override("font_color", Color("#95a5a6"))
	add_child(version_label)

	_slot_panel = PanelContainer.new()
	_slot_panel.visible = false
	_slot_panel.position = Vector2(28, 300)
	_slot_panel.size = Vector2(484, 520)
	add_child(_slot_panel)

	var panel_bg := ColorRect.new()
	panel_bg.size = _slot_panel.size
	panel_bg.color = Color(0.07, 0.08, 0.15, 0.95)
	_slot_panel.add_child(panel_bg)

	var close_button := Button.new()
	close_button.text = I18n.t("menu.slot.close")
	close_button.position = Vector2(344, 14)
	close_button.size = Vector2(120, 36)
	close_button.pressed.connect(func() -> void:
		_play_click()
		_slot_panel.visible = false
	)
	_slot_panel.add_child(close_button)

	for i in range(3):
		var row := _build_slot_row(i + 1, 62 + i * 145)
		_slot_rows.append(row)

func _build_slot_row(slot_id: int, y: int) -> Dictionary:
	var card := ColorRect.new()
	card.position = Vector2(18, y)
	card.size = Vector2(448, 130)
	card.color = Color("#243b55")
	_slot_panel.add_child(card)

	var title := Label.new()
	title.position = Vector2(14, 10)
	title.size = Vector2(420, 24)
	title.add_theme_font_size_override("font_size", 18)
	card.add_child(title)

	var summary := Label.new()
	summary.position = Vector2(14, 38)
	summary.size = Vector2(420, 46)
	summary.add_theme_font_size_override("font_size", 13)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(summary)

	var action := Button.new()
	action.position = Vector2(14, 88)
	action.size = Vector2(190, 32)
	action.pressed.connect(func() -> void:
		_handle_slot_action(slot_id)
	)
	card.add_child(action)

	var delete_button := Button.new()
	delete_button.position = Vector2(214, 88)
	delete_button.size = Vector2(220, 32)
	delete_button.text = I18n.t("menu.slot.delete")
	delete_button.pressed.connect(func() -> void:
		_play_click()
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm and gm.delete_save_slot(slot_id):
			_refresh()
	)
	card.add_child(delete_button)

	return {
		"slot_id": slot_id,
		"title": title,
		"summary": summary,
		"action": action,
		"delete": delete_button,
	}

func _make_menu_button(text: String, pos: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = Vector2(300, 54)
	return button

func _refresh() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var summaries: Array = gm.get_save_slot_summaries()
	_has_any_save = false
	for summary in summaries:
		if bool((summary as Dictionary).get("has_save", false)):
			_has_any_save = true
			break

	_continue_button.disabled = not _has_any_save
	_start_button.text = I18n.t("menu.new_game") if _has_any_save else I18n.t("menu.start")
	_refresh_slot_rows(summaries)

func _refresh_slot_rows(summaries: Array) -> void:
	for row_data in _slot_rows:
		var row: Dictionary = row_data
		var slot_id: int = int(row.get("slot_id", 1))
		var summary: Dictionary = summaries[slot_id - 1] if slot_id - 1 < summaries.size() else {}
		var has_save: bool = bool(summary.get("has_save", false))

		var title: Label = row.get("title")
		var body: Label = row.get("summary")
		var action_btn: Button = row.get("action")
		var delete_btn: Button = row.get("delete")

		title.text = I18n.t("menu.slot.title", [slot_id])
		if has_save:
			body.text = I18n.t(
				"menu.slot.summary",
				[
					int(summary.get("balance", Balance.STARTING_MONEY)),
					float(summary.get("reputation", Balance.REPUTATION_STARTING)),
					int(summary.get("total_trips", 0)),
				]
			)
		else:
			body.text = I18n.t("menu.slot.empty")

		delete_btn.visible = has_save
		if _slot_mode == SlotMode.LOAD:
			action_btn.text = I18n.t("menu.slot.load")
			action_btn.disabled = not has_save
		else:
			action_btn.text = I18n.t("menu.slot.overwrite") if has_save else I18n.t("menu.slot.new")
			action_btn.disabled = false

func _on_start_pressed() -> void:
	_play_click()
	_slot_mode = SlotMode.NEW_GAME
	_pending_overwrite_slot = -1
	_slot_panel.visible = true
	_refresh()

func _on_continue_pressed() -> void:
	_play_click()
	_slot_mode = SlotMode.LOAD
	_pending_overwrite_slot = -1
	_slot_panel.visible = true
	_refresh()

func _handle_slot_action(slot_id: int) -> void:
	_play_click()
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	if _slot_mode == SlotMode.LOAD:
		if gm.has_save_data(slot_id):
			gm.load_slot(slot_id)
			SceneTransition.transition_to("res://src/scenes/garage/garage_scene.tscn")
		return

	if gm.has_save_data(slot_id) and _pending_overwrite_slot != slot_id:
		_pending_overwrite_slot = slot_id
		_show_overwrite_warning(slot_id)
		return
	gm.start_new_game(slot_id)
	SceneTransition.transition_to("res://src/scenes/garage/garage_scene.tscn")

func _show_overwrite_warning(slot_id: int) -> void:
	for row_data in _slot_rows:
		var row: Dictionary = row_data
		var row_slot: int = int(row.get("slot_id", 0))
		var summary_label: Label = row.get("summary")
		if row_slot == slot_id:
			summary_label.text = I18n.t("menu.slot.confirm_overwrite")
		else:
			var gm: Node = get_node_or_null("/root/GameManager")
			if gm:
				_refresh_slot_rows(gm.get_save_slot_summaries())

func _play_click() -> void:
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("button_click")
