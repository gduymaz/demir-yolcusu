extends Node2D

const VIEWPORT_W := 540
const VIEWPORT_H := 960

func _ready() -> void:
	_build()


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
	title.text = "SEFER OZETI"
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
	lines.append("GELIR")
	lines.append("- Bilet geliri: %d DA" % int(revenue.get("ticket_total", 0)))
	lines.append("- Kargo geliri: %d DA" % int(revenue.get("cargo_total", 0)))
	lines.append("- Toplam gelir: %d DA" % int(revenue.get("total", 0)))
	lines.append("")
	lines.append("Durak bazli bilet:")
	for item in breakdown:
		lines.append("  %s: %d DA" % [item.get("station", "Durak"), int(item.get("ticket_income", 0))])
	lines.append("")
	lines.append("GIDER")
	lines.append("- Yakit maliyeti: %d DA" % int(costs.get("fuel_total", 0)))
	lines.append("- Toplam gider: %d DA" % int(costs.get("total", 0)))
	lines.append("")
	var net := int(report.get("net_profit", 0))
	lines.append("Itibar degisimi: %.1f" % float(report.get("reputation_delta", 0.0)))
	lines.append("")
	lines.append("ISTATISTIK")
	lines.append("- Tasinan yolcu: %d" % int(stats.get("passengers_transported", 0)))
	lines.append("- Kaybedilen yolcu: %d" % int(stats.get("passengers_lost", 0)))
	lines.append("- Ugranilan durak: %d" % int(stats.get("stops_visited", 0)))

	var body := Label.new()
	body.position = Vector2(40, 150)
	body.size = Vector2(VIEWPORT_W - 80, 620)
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color.WHITE)
	body.text = "\n".join(lines)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(body)

	var net_label := Label.new()
	net_label.position = Vector2(40, 610)
	net_label.size = Vector2(VIEWPORT_W - 80, 34)
	net_label.text = "NET KAZANC: %d DA" % net
	net_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	net_label.add_theme_font_size_override("font_size", 24)
	if net >= 0:
		net_label.add_theme_color_override("font_color", Color("#2ecc71"))
	else:
		net_label.add_theme_color_override("font_color", Color("#e74c3c"))
	add_child(net_label)

	var map_btn := Button.new()
	map_btn.position = Vector2(150, 860)
	map_btn.size = Vector2(240, 56)
	map_btn.text = "Haritaya Don"
	map_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/scenes/map/map_scene.tscn")
	)
	add_child(map_btn)
