---
name: tile-character-placer
description: "Place animated characters (NPCs, passengers, animals), trains, and other moving entities into Godot scenes with proper y-sort occlusion. Reads character data from manifest, generates AnimatedSprite2D nodes, walk paths, and train animation code. Characters walk behind buildings, under canopies, and alongside trains. Use for NPC spawning, passenger flows, train animations, and any moving entity placement."
---

# 🚶 Tile Character Placer

## Purpose
Manifest'teki karakter sprite'larını Godot sahnesine yerleştir. Yürüme animasyonları, y-sort sıralaması, ve tren/NPC etkileşimlerini yönet. Karakterler binaların arkasından, sundurmaların altından geçer.

---

## When To Use
- "İstasyona NPC/yolcu ekle"
- "Tren animasyonu oluştur"
- "Platformda yürüyen insanlar ekle"
- "Tren istasyona yanaşsın, yolcular insin"
- Herhangi bir hareketli entity yerleştirme

## DATA SOURCE
```
MANIFEST:   assets/tilemaps/manifest.json
TILE ROOT:  assets/tilemaps/
CHARACTER:  group="character" → subfolder = karakter tipi
VEHICLE:    group="vehicle"   → subfolder = tren tipi
FX:         group="fx"        → subfolder = "anim" (kedi, bayrak vs.)

❌ ASLA assets/references/ KULLANMA
```

---

## KARAKTERLERİN MANIFEST YAPISI

```json
{
  "group": "character",
  "subfolder": "female_baker",
  "name": "idle_south",
  "file": "character/female_baker/idle_south.png"
}
```

### Karakter Sprite Yapısı (manifest'ten türetilir)
Her karakter subfolder'ında şu dosyalar bulunur:

```
idle:  idle_south, idle_north, idle_east, idle_west         (4 tile)
walk:  walk_east_f01..f08                                    (8 frame)
       walk_north_f01..f08                                   (8 frame)
       walk_south_f01..f08                                   (8 frame)
       walk_west_f01..f08                                    (8 frame)
                                                     Toplam: 36 tile
```

### Mevcut Karakterler
```
İnsan:     female_baker, female_cafe_maid, female_elder, female_office_worker,
           female_student, female_trendy, female_youth, male_businessman,
           male_businessman_old, male_casual, male_punk, male_student,
           male_student_alt, male_traditional, male_traffic_cop, male_youth,
           gutty_chan, witch, unknown
Hayvan:    shiba_inu
NPC:       npc (122 tile — farklı yapıda olabilir)
Figure:    figure (6 tile — statik)
```

### Tren Tipleri (group=vehicle)
```
bullet:    42 tile — Shinkansen tarzı
commuter:  65 tile — Banliyö treni
green:     102 tile — Yeşil vagon
silver:    41 tile — Gümüş vagon
train:     40 tile — Genel tren + ray parçaları
```

---

## PROSEDÜR

### 1. Karakter Kaynak Dosyası Oluştur

```python
import json, os

def generate_character_resource(char_subfolder, manifest):
    """
    Bir karakter için Godot SpriteFrames resource datası oluştur.
    """
    items = [i for i in manifest["items"]
             if i["group"] == "character" and i["subfolder"] == char_subfolder]

    if not items:
        print(f"❌ Karakter bulunamadı: {char_subfolder}")
        return None

    # Animasyonları grupla
    animations = {}
    for item in items:
        name = item["name"]
        if name.startswith("idle_"):
            direction = name.replace("idle_", "")
            anim_name = f"idle_{direction}"
            animations.setdefault(anim_name, []).append(item)
        elif name.startswith("walk_"):
            # walk_east_f01 → anim: walk_east, frame: 01
            parts = name.rsplit("_f", 1)
            if len(parts) == 2:
                anim_name = parts[0]
                animations.setdefault(anim_name, []).append(item)

    # Frame sırasını düzelt
    for anim_name in animations:
        animations[anim_name].sort(key=lambda x: x["name"])

    return {
        "character": char_subfolder,
        "tile_count": len(items),
        "animations": {
            name: [{"file": i["file"], "id": i["id"]} for i in frames]
            for name, frames in animations.items()
        }
    }
```

### 2. Godot AnimatedSprite2D Scripti

```gdscript
# scripts/characters/npc_character.gd
extends AnimatedSprite2D

## Manifest'ten yüklenen NPC karakter.
## tile-character-placer skill ile oluşturuldu.

@export var character_type: String = "female_baker"
@export var walk_speed: float = 48.0  # px/sec (1.5 tile/sec)
@export var walk_path: PackedVector2Array = []

var current_path_index := 0
var is_walking := false
var current_direction := "south"

func _ready():
    _load_animations()
    play(str("idle_", current_direction))

func _load_animations():
    # SpriteFrames resource runtime'da manifest'ten doldurulur
    # veya pre-built .tres dosyası kullanılır
    pass

func _process(delta: float):
    if is_walking and walk_path.size() > 0:
        _walk_step(delta)

func start_walking():
    if walk_path.size() < 2:
        return
    current_path_index = 0
    is_walking = true
    _update_direction()
    play(str("walk_", current_direction))

func _walk_step(delta: float):
    var target := walk_path[current_path_index + 1]
    var dir := (target - global_position).normalized()
    global_position += dir * walk_speed * delta

    if global_position.distance_to(target) < 2.0:
        current_path_index += 1
        if current_path_index >= walk_path.size() - 1:
            is_walking = false
            play(str("idle_", current_direction))
            return
        _update_direction()
        play(str("walk_", current_direction))

func _update_direction():
    if current_path_index >= walk_path.size() - 1:
        return
    var next_pos := walk_path[current_path_index + 1]
    var diff := next_pos - global_position
    if abs(diff.x) > abs(diff.y):
        current_direction = "east" if diff.x > 0 else "west"
    else:
        current_direction = "south" if diff.y > 0 else "north"
```

### 3. NPC Spawner — Sahneye Karakter Yerleştir

```gdscript
# scripts/spawners/npc_spawner.gd
extends Node2D

## NPC'leri platforma yerleştirir, yürüme yolları atar.
## tile-character-placer skill ile oluşturuldu.

@export var scene_mapping_path: String = ""
@export var max_npcs: int = 8

const TILE_SIZE := 32
const NPC_SCENE := preload("res://scripts/characters/npc_character.tscn")

# Kullanılacak karakter tipleri (manifest'ten)
const AVAILABLE_CHARACTERS := [
    "female_baker", "female_office_worker", "male_businessman",
    "male_casual", "female_student", "male_youth", "shiba_inu",
]

# Platform satırları (tile-scene-builder'dan alınır)
var platform_rows: Array[int] = []
var train_lane_rows: Array[int] = []

func _ready():
    _load_scene_config()
    _spawn_npcs()

func _load_scene_config():
    # mapping.json'dan platform ve tren şeridi bilgisini oku
    var f := FileAccess.open(scene_mapping_path, FileAccess.READ)
    var data := JSON.parse_string(f.get_as_text())
    f.close()

    for lane in data.get("train_lanes", []):
        for r in range(lane.rows[0], lane.rows[1] + 1):
            train_lane_rows.append(r)

    # Platform satırlarını bul (PLATFORM katmanı olan satırlar)
    var platform_entries = data.get("layers", {}).get("PLATFORM", [])
    for entry in platform_entries:
        if entry.row not in platform_rows:
            platform_rows.append(entry.row)

func _spawn_npcs():
    for i in range(max_npcs):
        var npc := NPC_SCENE.instantiate()
        npc.character_type = AVAILABLE_CHARACTERS[randi() % AVAILABLE_CHARACTERS.size()]

        # Platform üzerinde rastgele pozisyon
        var row: int = platform_rows[randi() % platform_rows.size()]
        var col: int = randi_range(1, 11)  # scene_cols - 2
        npc.global_position = Vector2(col * TILE_SIZE + 16, row * TILE_SIZE + 16)

        # Yürüme yolu: yatay hareket
        var start_x := float(1 * TILE_SIZE)
        var end_x := float(12 * TILE_SIZE)
        var y := float(row * TILE_SIZE + 16)
        npc.walk_path = PackedVector2Array([
            Vector2(npc.global_position.x, y),
            Vector2(end_x if randf() > 0.5 else start_x, y),
        ])

        add_child(npc)
        # Staggered start
        await get_tree().create_timer(randf() * 3.0).timeout
        npc.start_walking()
```

### 4. Tren Animasyonu

```gdscript
# scripts/vehicles/train_animator.gd
extends Node2D

## Treni ray şeridinde hareket ettirir.
## tile-character-placer skill ile oluşturuldu.

@export var train_type: String = "commuter"  # bullet, commuter, green, silver
@export var speed: float = 96.0  # px/sec
@export var lane_row_start: int = 9
@export var lane_row_end: int = 10
@export var direction: String = "left_to_right"  # veya "right_to_left"

const TILE_SIZE := 32
var wagon_sprites: Array[Sprite2D] = []
var is_moving := false

func _ready():
    _build_train()

func _build_train():
    # Manifest'ten tren tile'larını yükle
    # vehicle/{train_type}/ altındaki tile'lar sırayla dizilir
    # Tren yatay: her tile bir 32px'lik parça
    pass  # Manifest'ten dinamik yükleme

func start_arrival():
    """Tren ekranın dışından gelip istasyona yanaşır."""
    var start_x: float
    var end_x: float

    if direction == "left_to_right":
        start_x = -_get_train_width()
        end_x = 0.0  # veya ortalanmış pozisyon
    else:
        start_x = 416.0 + 32  # ekran dışı sağ
        end_x = 416.0 - _get_train_width()

    global_position.x = start_x
    global_position.y = float(lane_row_start * TILE_SIZE)
    is_moving = true

    var tween := create_tween()
    tween.tween_property(self, "position:x", end_x, abs(end_x - start_x) / speed)
    tween.tween_callback(func(): is_moving = false)
    await tween.finished
    # Tren durdu — yolcu inme/binme başlayabilir

func _get_train_width() -> float:
    return float(wagon_sprites.size() * TILE_SIZE)
```

### 5. Test Üretimi — Karakter Referansları

```python
def generate_character_tests(scene_name, used_characters, used_trains, manifest):
    """
    Sahnede kullanılan her karakter ve tren tipi için varlık testi.
    """
    lines = [
        f'# tests/tiles/test_{scene_name}_characters.gd',
        f'# AUTO-GENERATED by tile-character-placer — DO NOT EDIT MANUALLY',
        '',
        'extends GutTest',
        '',
        'const TILE_ROOT := "res://assets/tilemaps/"',
        '',
    ]

    # Karakter testleri
    for char_type in sorted(used_characters):
        items = [i for i in manifest["items"]
                 if i["group"] == "character" and i["subfolder"] == char_type]
        lines.extend([
            f'func test_character_{char_type}_complete():',
            f'    # {char_type}: {len(items)} tile bekleniyor',
        ])

        # idle kontrol
        for direction in ["south", "north", "east", "west"]:
            expected = f"character/{char_type}/idle_{direction}.png"
            lines.append(
                f'    assert_true(FileAccess.file_exists(TILE_ROOT + "{expected}"), '
                f'"Missing: {expected}")'
            )

        # walk kontrol
        for direction in ["east", "north", "south", "west"]:
            for frame in range(1, 9):
                expected = f"character/{char_type}/walk_{direction}_f{frame:02d}.png"
                lines.append(
                    f'    assert_true(FileAccess.file_exists(TILE_ROOT + "{expected}"), '
                    f'"Missing: {expected}")'
                )
        lines.append('')

    # Tren testleri
    for train_type in sorted(used_trains):
        items = [i for i in manifest["items"]
                 if i["group"] == "vehicle" and i["subfolder"] == train_type]
        lines.extend([
            f'func test_vehicle_{train_type}_tiles():',
            f'    # {train_type}: {len(items)} tile bekleniyor',
        ])
        for item in items:
            lines.append(
                f'    assert_true(FileAccess.file_exists(TILE_ROOT + "{item["file"]}"), '
                f'"Missing: {item["file"]}")'
            )
        lines.append('')

    return '\n'.join(lines)
```

### 6. Preview PNG — Karakter Pozisyonları

```python
from PIL import Image, ImageDraw

def render_character_preview(scene_preview_path, character_placements, scene_name):
    """
    Mevcut sahne preview üzerine karakter pozisyonlarını çiz.
    Karakterlerin idle_south frame'ini yerleştir.
    """
    canvas = Image.open(scene_preview_path).convert("RGBA")
    
    for placement in character_placements:
        char_type = placement["character"]
        row = placement["row"]
        col = placement["col"]
        
        # idle_south frame'ini yükle
        idle_path = f"assets/tilemaps/character/{char_type}/idle_south.png"
        if os.path.exists(idle_path):
            sprite = Image.open(idle_path).convert("RGBA")
            # Siyah → transparent
            data = list(sprite.getdata())
            data = [(0,0,0,0) if (p[0]<=10 and p[1]<=10 and p[2]<=10) else p for p in data]
            sprite.putdata(data)
            canvas.paste(sprite, (col * 32, row * 32), sprite)
    
    os.makedirs("logs/png", exist_ok=True)
    out_path = f"logs/png/{scene_name}_with_characters.png"
    canvas.save(out_path)
    
    # 2x büyütülmüş
    big = canvas.resize((canvas.width * 2, canvas.height * 2), Image.NEAREST)
    big.save(f"logs/png/{scene_name}_with_characters_2x.png")
    
    print(f"📸 {out_path}")
    return out_path
```

---

## ÇIKTI DOSYALARI

```
scripts/characters/
├── npc_character.gd            # Temel NPC scripti
└── npc_character.tscn          # NPC sahnesi

scripts/spawners/
├── npc_spawner.gd              # NPC yerleştirici
└── npc_spawner.tscn            # Spawner sahnesi

scripts/vehicles/
├── train_animator.gd           # Tren animasyon scripti
└── train_animator.tscn         # Tren sahnesi

tests/tiles/
└── test_{scene}_characters.gd  # Karakter/tren tile testleri

logs/png/
├── {scene}_with_characters.png     # Karakterli preview
└── {scene}_with_characters_2x.png  # 2x büyütülmüş
```

---

## Z-SORT KURALLARI — KARAKTERLERİN KATMANLAMASI

```
Senaryo                          Nasıl Çalışır
─────────────────────────────── ────────────────────────────────
NPC bina arkasından geçer        NPC y-sort z:0, bina z:5
NPC sundurma altından geçer      NPC z:0, sundurma z:15
Tren direklerin arkasından geçer Tren z:0, direk z:10
NPC trenin önünde durur           NPC.y > tren.y → y-sort ile NPC üstte
Köpek NPC'nin arkasından geçer   İkisi de z:0, y-sort belirler
Tren istasyona yanaşır           Tren z:0, platform furniture z:8 → mobilya üstte
```

**Entity Node Yapısı:**
```
StationScene (Node2D)
├── GroundBase (TileMap, z:-10)
├── Rails (TileMap, z:-5)
├── Platform (TileMap, z:-3)
├── Entities (Node2D, y_sort_enabled=true)  ← NPC + Tren BURADA
│   ├── NPC_1 (AnimatedSprite2D)
│   ├── NPC_2 (AnimatedSprite2D)
│   ├── Train (Node2D)
│   └── ShibaInu (AnimatedSprite2D)
├── StructuresLow (TileMap, z:5)
├── Furniture (TileMap, z:8)
├── StructuresHigh (TileMap, z:10)
└── Canopy (TileMap, z:15)
```

---

## MUTLAK KURALLAR

1. ❌ `assets/references/` KULLANMA — tek kaynak manifest
2. ❌ Karakter test'i yazmadan NPC ekleme
3. ❌ Entity'leri TileMap'e koyma — her zaman `Entities` node altında y-sort ile
4. ❌ Tren şeritlerini NPC yürüme yoluna koyma (çarpışma riski)
5. ✅ Her karakter idle_south'u preview PNG'de gösterilmeli
6. ✅ Walk animasyonu 8 frame × 4 yön — eksik frame test FAIL etmeli
7. ✅ Tren genişliği tile sayısından hesaplanmalı, hardcode değil
8. ✅ NPC spawn pozisyonları sadece platform satırlarında olmalı