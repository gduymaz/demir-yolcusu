---
name: godot-basics
description: "Godot 4 motor bilgisi. GDScript sözdizimi, Node/Scene sistemi, Signal kullanımı, TileMap, AnimatedSprite2D, isometrik kurulum."
---

# Godot 4 Temelleri — Demir Yolcusu İçin

## Godot Konseptleri
- **Node**: Her şeyin temel yapı taşı
- **Scene**: Node'ların bir araya geldiği dosya (.tscn)
- **Signal**: Node'lar arası mesajlaşma (observer pattern)
- **Autoload**: Oyun boyunca aktif tekil script (singleton)
- **GDScript**: Godot'un kendi dili, Python'a benzer

## project.godot Ayarları
```ini
[display]
window/size/viewport_width=540
window/size/viewport_height=960
window/handheld/orientation="portrait"
window/stretch/mode="canvas_items"
window/stretch/aspect="keep_width"

[rendering]
textures/canvas_textures/default_texture_filter=0

[autoload]
EventBus="*res://src/events/event_bus.gd"
```

## İsometrik TileMap
- Tile boyutu: 32x32
- Layout: Isometric, Cell size: Vector2i(32, 16)

## GDScript Temel Syntax
```gdscript
class_name MyClass
extends Node2D

@export var speed: float = 100.0
signal health_changed(new_value: int)

func _ready() -> void:
    pass
```

## Signal Kullanımı
```gdscript
signal passenger_boarded(passenger, wagon)
passenger_boarded.emit(passenger, wagon)
some_node.passenger_boarded.connect(_on_passenger_boarded)
```
