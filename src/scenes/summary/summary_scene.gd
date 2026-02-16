## Module: summary_scene.gd
## Restored English comments for maintainability and i18n coding standards.

extends Node2D

const VIEWPORT_W := 540
const VIEWPORT_H := 960

## Lifecycle/helper logic for `_ready`.
func _ready() -> void:
	_build()
	_apply_accessibility()
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.tutorial_manager:
		gm.tutorial_manager.notify("summary_opened")

## Lifecycle/helper logic for `_build`.
func _build() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.color = Color("#111827")
	add_child(bg)

	var panel := ColorRect.new()
	panel.position = Vector2(20, 80)
	panel.size = Vector2(VIEWPORT_W - 40, 760)
	panel.color = Color("#16213e")
	add_child(panel)

	var title := Label.new()
	title.text = I18n.t("summary.title")
	title.position = Vector2(40, 100)
	title.size = Vector2(VIEWPORT_W - 80, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#f1c40f"))
	add_child(title)

	var gm: Node = get_node_or_null("/root/GameManager")
	var report: Dictionary = {}
	if gm:
		report = gm.get_last_trip_report()

	var revenue: Dictionary = report.get("revenue", {})
	var costs: Dictionary = report.get("costs", {})
	var stats: Dictionary = report.get("stats", {})
	var breakdown: Array = revenue.get("by_station", [])

	var lines: Array[String] = []
	lines.append("[color=#2ecc71]%s[/color]" % I18n.t("summary.revenue.title"))
	lines.append("[color=#2ecc71]+ %s[/color]" % I18n.t("summary.revenue.ticket", [int(revenue.get("ticket_total", 0))]))
	lines.append("[color=#2ecc71]+ %s[/color]" % I18n.t("summary.revenue.cargo", [int(revenue.get("cargo_total", 0))]))
	lines.append("[color=#2ecc71]+ %s[/color]" % I18n.t("summary.revenue.shop", [int(revenue.get("shop_total", 0))]))
	lines.append("[color=#2ecc71]+ %s[/color]" % I18n.t("summary.revenue.dining", [int(revenue.get("dining_total", 0))]))
	lines.append("[color=#2ecc71]+ %s[/color]" % I18n.t("summary.revenue.quest", [int(report.get("quest_reward_money", 0))]))
	lines.append("[color=#2ecc71]+ %s[/color]" % I18n.t("summary.revenue.total", [int(revenue.get("total", 0))]))
	lines.append("")
	lines.append(I18n.t("summary.revenue.by_station"))
	for item in breakdown:
		lines.append(
			I18n.t(
				"summary.revenue.by_station_item",
				[item.get("station", I18n.t("summary.station_fallback")), int(item.get("ticket_income", 0))]
			)
		)
	lines.append("")
	lines.append("[color=#e74c3c]%s[/color]" % I18n.t("summary.cost.title"))
	lines.append("[color=#e74c3c]- %s[/color]" % I18n.t("summary.cost.fuel", [int(costs.get("fuel_total", 0))]))
	lines.append("[color=#e74c3c]- %s[/color]" % I18n.t("summary.cost.total", [int(costs.get("total", 0))]))
	lines.append("")
	var net := int(report.get("net_profit", 0))
	lines.append(I18n.t("summary.reputation", [float(report.get("reputation_delta", 0.0))]))
	lines.append("")
	lines.append(I18n.t("summary.stats.title"))
	lines.append(I18n.t("summary.stats.transported", [int(stats.get("passengers_transported", 0))]))
	lines.append(I18n.t("summary.stats.lost", [int(stats.get("passengers_lost", 0))]))
	lines.append(I18n.t("summary.stats.stops", [int(stats.get("stops_visited", 0))]))
	var event_history: Array = report.get("event_history", [])
	if not event_history.is_empty():
		lines.append("")
		lines.append(I18n.t("summary.events.title"))
		for event_id in event_history:
			lines.append(I18n.t("summary.events.item", [I18n.t("event.%s.title" % str(event_id))]))

	var body := RichTextLabel.new()
	body.position = Vector2(40, 150)
	body.size = Vector2(VIEWPORT_W - 80, 620)
	body.fit_content = true
	body.bbcode_enabled = true
	body.scroll_active = false
	body.text = "\n".join(lines)
	add_child(body)

	var net_label := Label.new()
	net_label.name = "NetLabel"
	net_label.position = Vector2(40, 610)
	net_label.size = Vector2(VIEWPORT_W - 80, 34)
	net_label.text = I18n.t("summary.net", [net])
	net_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	net_label.add_theme_font_size_override("font_size", 24)
	net_label.add_theme_constant_override("outline_size", 2)
	net_label.add_theme_color_override("font_outline_color", Color("#111827"))
	if net >= 0:
		net_label.add_theme_color_override("font_color", Color("#2ecc71"))
	else:
		net_label.add_theme_color_override("font_color", Color("#e74c3c"))
	add_child(net_label)

	var reputation_delta: float = float(report.get("reputation_delta", 0.0))
	if absf(reputation_delta) > 0.01:
		var star_label := Label.new()
		star_label.text = "\u2605"
		star_label.position = Vector2(440, 612)
		star_label.add_theme_font_size_override("font_size", 20)
		star_label.add_theme_color_override("font_color", Color("#f1c40f") if reputation_delta > 0.0 else Color("#95a5a6"))
		add_child(star_label)
		var tween := create_tween()
		tween.tween_property(star_label, "scale", Vector2(1.3, 1.3), 0.18)
		tween.tween_property(star_label, "scale", Vector2(1.0, 1.0), 0.18)

	var map_btn := Button.new()
	map_btn.position = Vector2(150, 860)
	map_btn.size = Vector2(240, 56)
	map_btn.text = I18n.t("summary.button.back_map")
	map_btn.pressed.connect(func() -> void:
		SceneTransition.transition_to("res://src/scenes/map/map_scene.tscn")
	)
	add_child(map_btn)

func _apply_accessibility() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.settings_system:
		gm.settings_system.apply_font_scale_recursive(self)
