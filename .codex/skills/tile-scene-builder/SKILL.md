---
name: tile-scene-builder
description: "Compose Godot 4.x scenes by arranging 32x32 tiles from the unified manifest. Handles multi-layer z-ordering (NPC behind buildings, trains behind poles, canopy over everything). Generates: Godot .tscn/.gd code, tile reference tests, and preview PNGs under logs/png/. Use for ANY scene composition: stations, train interiors, platforms, wagons."
---

# 🏗️ Tile Scene Builder

## Purpose
32x32 tile'ları manifest.json'dan okuyup yan yana ve üst üste dizerek Godot sahneleri oluştur. Her sahne katmanlı çalışır — NPC'ler binaların arkasından, trenler direklerin arkasından geçer.

---

## DATA SOURCE — TEK KAYNAK

```
MANIFEST:  assets/tilemaps/manifest.json
TILE ROOT: assets/tilemaps/              (manifest.root)
TILE PATH: assets/tilemaps/{item.file}   (manifest.root + item.file)

❌ ASLA assets/references/ KULLANMA
```

### Manifest Yapısı
```json
{
  "root": "assets/tilemaps",
  "tile_size": 32,
  "summary": { "groups": { "terrain": 79, "structure": 217, ... } },
  "items": [
    {
      "id": "station__ground__ground_cobble_center_a",
      "file": "terrain/ground/ground_cobble_center_a.png",
      "name": "ground_cobble_center_a",
      "group": "terrain",
      "subfolder": "ground",
      "tags": ["ground", "station", "terrain"]
    }
  ]
}
```

### Tile Erişim Kalıbı
```python
import json

def load_manifest():
    with open("assets/tilemaps/manifest.json") as f:
        return json.load(f)

def tile_path(item):
    """manifest item → dosya yolu"""
    return f"assets/tilemaps/{item['file']}"

def find_tiles(manifest, group=None, subfolder=None, name_contains=None):
    """Filtreli tile arama"""
    results = manifest["items"]
    if group:
        results = [i for i in results if i["group"] == group]
    if subfolder:
        results = [i for i in results if i["subfolder"] == subfolder]
    if name_contains:
        results = [i for i in results if name_contains in i["name"]]
    return results
```

---

## LAYER SİSTEMİ — Z-INDEX HARİTASI

Her sahne bu katman sırasına uymalı. Yanlış sıra = kırık görsel.

```
Z-INDEX  KATMAN            AÇIKLAMA                        ÖRNEK TILE'LAR
──────── ────────────────── ─────────────────────────────── ──────────────────
-10      GROUND_BASE        Opak zemin, boşluk bırakmaz     ground_cobble_*, ground_grass_*
 -8      GROUND_DETAIL      Zemin geçişleri, su kenarı       ground_*_edge_*, floor_*
 -5      RAILS              Raylar, traversler               rail_track_*, rail_*_sleeper_*
 -3      PLATFORM           Platform yüzeyi                  structure_platform_*
 -1      PLATFORM_EDGE      Platform kenarı, merdiven        structure_platform_edge_*
  0      ENTITIES           NPC + Tren (y-sort)              [runtime — kod yerleştirir]
  5      STRUCTURES_LOW     Bina duvarları, dükkan cephesi   building_*, wall_*
  8      FURNITURE          Bank, çiçek, tabela, lamba       furniture_*, electric_pole_base
 10      STRUCTURES_HIGH    Direkler, sundurma sütunları     electric_pole_upper, electric_pole_top
 15      CANOPY             Çatı, sundurma, ağaç tepesi      structure_canopy_*, structure_roof_*
 20      OVERLAY            Hava efekti, ışık                [runtime shader]
```

### Neden Bu Sıra?
- **Tren direklerin arkasından geçer:** Tren z:0, direk z:10 → direk üstte
- **NPC bina arkasından geçer:** NPC z:0 (y-sort), bina z:5 → bina üstte
- **NPC sundurma altından yürür:** NPC z:0, sundurma z:15 → sundurma üstte
- **Tren istasyona yanaşınca platformdaki NPC'ler önde:** Y-sort ile NPC'nin y > tren y → NPC üstte

---

## PROSEDÜR

### 1. Sahne Planı Oluştur

Kullanıcının isteğine göre grid planı yap:

```python
# Mobil portrait default: 13×23 tile = 416×736px
SCENE_COLS = 13
SCENE_ROWS = 23

# Sahne planı: her satır aralığı hangi katmana ait
# Bu ÖRNEK — kullanıcının sahne tanımına göre değiştir
scene_plan = [
    # (row_start, row_end, layer, tile_query)
    (0,  2,  "GROUND_BASE",     {"group": "terrain", "name_contains": "grass"}),
    (3,  5,  "STRUCTURES_LOW",  {"group": "structure", "subfolder": "building"}),
    (6,  8,  "PLATFORM",        {"group": "structure", "name_contains": "platform"}),
    (9,  10, "RAILS",           {"group": "vehicle", "subfolder": "train", "name_contains": "rail_track"}),
    (11, 14, "PLATFORM",        {"group": "structure", "name_contains": "platform"}),
    (15, 16, "RAILS",           {"group": "vehicle", "subfolder": "train", "name_contains": "rail_track"}),
    (17, 19, "GROUND_BASE",     {"group": "terrain", "name_contains": "cobble"}),
    (20, 22, "GROUND_BASE",     {"group": "terrain", "name_contains": "grass"}),
]

# Tren şeritleri — buralar entity katmanında temiz kalmalı
TRAIN_LANES = [
    {"rows": (9, 10),  "direction": "left_to_right"},
    {"rows": (15, 16), "direction": "right_to_left"},
]
```

### 2. Tile Seçimi — Akıllı Yerleştirme

```python
def select_tile_for_position(available_tiles, row, col, row_min, row_max, col_min, col_max):
    """
    Pozisyona göre en uygun tile'ı seç.
    Kenar → edge tile, köşe → corner tile, orta → center tile.
    Variant (_a, _b, _c, _d) varsa rastgele seç → tekrar önle.
    """
    import random

    is_top    = (row == row_min)
    is_bottom = (row == row_max)
    is_left   = (col == col_min)
    is_right  = (col == col_max)

    # Pozisyon bazlı tercih sırası
    if is_top and is_left:
        prefs = ["corner_tl", "edge_top", "edge_left"]
    elif is_top and is_right:
        prefs = ["corner_tr", "edge_top", "edge_right"]
    elif is_bottom and is_left:
        prefs = ["corner_bl", "edge_bottom", "edge_left"]
    elif is_bottom and is_right:
        prefs = ["corner_br", "edge_bottom", "edge_right"]
    elif is_top:
        prefs = ["edge_top"]
    elif is_bottom:
        prefs = ["edge_bottom"]
    elif is_left:
        prefs = ["edge_left"]
    elif is_right:
        prefs = ["edge_right"]
    else:
        prefs = ["center"]

    for pref in prefs:
        matches = [t for t in available_tiles if pref in t["name"]]
        if matches:
            return random.choice(matches)

    # Fallback: center veya herhangi biri
    centers = [t for t in available_tiles if "center" in t["name"]]
    if centers:
        return random.choice(centers)

    return random.choice(available_tiles) if available_tiles else None
```

### 3. Mapping Oluştur

```python
def build_mapping(scene_plan, manifest, scene_cols, scene_rows):
    """Tüm katmanlar için tile mapping üret."""
    mapping = []  # [{layer, row, col, tile_id, tile_file}]
    used_tiles = set()  # Test için: hangi tile'lar kullanıldı

    for (row_start, row_end, layer, query) in scene_plan:
        tiles = find_tiles(manifest, **query)
        if not tiles:
            print(f"⚠️  {layer} için tile bulunamadı: {query}")
            continue

        for row in range(row_start, row_end + 1):
            for col in range(scene_cols):
                tile = select_tile_for_position(
                    tiles, row, col,
                    row_start, row_end, 0, scene_cols - 1
                )
                if tile:
                    mapping.append({
                        "layer": layer,
                        "row": row,
                        "col": col,
                        "tile_id": tile["id"],
                        "tile_file": tile["file"],
                        "tile_name": tile["name"],
                    })
                    used_tiles.add(tile["id"])

    return mapping, used_tiles
```

### 4. Overlay Katmanları — Üst Üste Dizme

Bazı tile'lar şeffaf kısımlar içerir ve alttaki katmanın görünmesi gerekir. Overlay katmanları (GROUND_DETAIL, FURNITURE, STRUCTURES_HIGH, CANOPY) ayrı mapping girdisi olarak eklenir:

```python
def add_overlay_layer(mapping, overlay_plan, manifest, scene_cols):
    """
    Mevcut mapping üzerine overlay tile'ları ekle.
    Örnek: platform üzerine bank, çiçek, lamba direği.
    """
    for (row, col, layer, tile_query) in overlay_plan:
        tiles = find_tiles(manifest, **tile_query)
        if tiles:
            tile = tiles[0]  # veya kullanıcının seçimi
            mapping.append({
                "layer": layer,
                "row": row,
                "col": col,
                "tile_id": tile["id"],
                "tile_file": tile["file"],
                "tile_name": tile["name"],
            })
    return mapping

# Örnek: platforma mobilya ekle
overlay_plan = [
    (7, 2,  "FURNITURE",        {"name_contains": "furniture_bench"}),
    (7, 5,  "FURNITURE",        {"name_contains": "furniture_bin"}),
    (7, 8,  "FURNITURE",        {"name_contains": "furniture_lamp"}),
    (6, 3,  "STRUCTURES_HIGH",  {"name_contains": "electric_pole_upper"}),
    (5, 3,  "CANOPY",           {"name_contains": "structure_canopy"}),
]
```

### 5. Godot Kodu Üret

```gdscript
# scenes/stations/{scene_name}/{scene_name}.gd
extends Node2D

## Bu sahne tile-scene-builder skill ile oluşturuldu.
## Kullanılan tile'lar: tests/tiles/test_{scene_name}_tiles.gd

# Katman node referansları
@onready var ground_base     := $GroundBase      # z_index: -10
@onready var ground_detail   := $GroundDetail     # z_index: -8
@onready var rails           := $Rails            # z_index: -5
@onready var platform        := $Platform         # z_index: -3
@onready var platform_edge   := $PlatformEdge     # z_index: -1
@onready var structures_low  := $StructuresLow    # z_index: 5
@onready var furniture       := $Furniture        # z_index: 8
@onready var structures_high := $StructuresHigh   # z_index: 10
@onready var canopy          := $Canopy           # z_index: 15

const TRAIN_LANES = [
    {"row_start": 9, "row_end": 10, "direction": "left_to_right"},
    {"row_start": 15, "row_end": 16, "direction": "right_to_left"},
]

const SCENE_SIZE := Vector2i(13, 23)  # tile cinsinden

func get_train_lanes() -> Array:
    return TRAIN_LANES
```

### 6. Test Yaz — HER Kullanılan Tile İçin

**Bu adım ZORUNLU.** Üretilen her Godot kodu/mapping ile birlikte test dosyası oluştur.

```python
def generate_tile_tests(scene_name, used_tiles, manifest, mapping):
    """
    Kullanılan her tile için varlık testi üret.
    Tile ismi değişirse test FAIL eder → eski referanslar bulunur.
    """
    lines = [
        f'# tests/tiles/test_{scene_name}_tiles.gd',
        f'# AUTO-GENERATED by tile-scene-builder — DO NOT EDIT MANUALLY',
        f'# Sahne: {scene_name}',
        f'# Kullanılan tile sayısı: {len(used_tiles)}',
        f'# Değişiklik gerekiyorsa tile-renamer skill kullanın.',
        '',
        'extends GutTest',
        '',
        f'const MANIFEST_PATH := "res://assets/tilemaps/manifest.json"',
        f'const TILE_ROOT := "res://assets/tilemaps/"',
        '',
        'var manifest: Dictionary',
        'var manifest_ids: Array',
        '',
        'func before_all():',
        '    var f := FileAccess.open(MANIFEST_PATH, FileAccess.READ)',
        '    manifest = JSON.parse_string(f.get_as_text())',
        '    f.close()',
        '    manifest_ids = []',
        '    for item in manifest.items:',
        '        manifest_ids.append(item.id)',
        '',
    ]

    # Her tile için ayrı test fonksiyonu
    for tile_id in sorted(used_tiles):
        item = next(i for i in manifest["items"] if i["id"] == tile_id)
        func_name = tile_id.replace("__", "_").replace("-", "_")
        lines.extend([
            f'func test_tile_exists__{func_name}():',
            f'    # Tile: {item["name"]}',
            f'    # File:  {item["file"]}',
            f'    assert_true(',
            f'        manifest_ids.has("{tile_id}"),',
            f'        "Tile missing from manifest: {tile_id}"',
            f'    )',
            f'    assert_true(',
            f'        FileAccess.file_exists(TILE_ROOT + "{item["file"]}"),',
            f'        "Tile file missing: {item["file"]}"',
            f'    )',
            '',
        ])

    # Mapping bütünlük testi
    lines.extend([
        f'func test_mapping_integrity():',
        f'    # Mapping: {len(mapping)} hücre',
        f'    var mapping_path := "res://scenes/stations/{scene_name}/mapping.json"',
        f'    assert_true(FileAccess.file_exists(mapping_path), "Mapping file missing")',
        f'    var f := FileAccess.open(mapping_path, FileAccess.READ)',
        f'    var data := JSON.parse_string(f.get_as_text())',
        f'    f.close()',
        f'    assert_eq(data.size(), {len(mapping)}, "Mapping entry count mismatch")',
        '',
        f'    # Her mapping girdisinin tile dosyası mevcut olmalı',
        f'    for entry in data:',
        f'        var path := TILE_ROOT + entry.tile_file',
        f'        assert_true(',
        f'            FileAccess.file_exists(path),',
        f'            "Mapping references missing tile: " + entry.tile_file',
        f'        )',
        '',
    ])

    return '\n'.join(lines)
```

**Ayrıca Python tarafında çalıştırılabilir hızlı test:**

```python
def run_quick_validation(used_tiles, manifest):
    """CI/local'da hızlı kontrol — dosya varlığı + manifest tutarlılığı"""
    import os
    manifest_ids = {i["id"] for i in manifest["items"]}
    errors = []

    for tile_id in used_tiles:
        if tile_id not in manifest_ids:
            errors.append(f"MANIFEST'TE YOK: {tile_id}")
            continue
        item = next(i for i in manifest["items"] if i["id"] == tile_id)
        path = f"assets/tilemaps/{item['file']}"
        if not os.path.exists(path):
            errors.append(f"DOSYA YOK: {path} (id: {tile_id})")

    if errors:
        print(f"❌ {len(errors)} HATA:")
        for e in errors:
            print(f"  {e}")
        return False
    else:
        print(f"✅ {len(used_tiles)} tile doğrulandı")
        return True
```

### 7. Preview PNG Üret → `logs/png/`

**Her sahne için görsel preview ZORUNLU.** Kontrol için `logs/png/` altına kaydet.

```python
import os
from PIL import Image

def render_scene_preview(mapping, scene_name, scene_cols, scene_rows):
    """
    Mapping'den katmanlı preview PNG oluştur.
    GROUND_BASE opak, diğer katmanlar siyah→transparent overlay.
    """
    TILE_SIZE = 32
    os.makedirs("logs/png", exist_ok=True)

    LAYER_ORDER = [
        "GROUND_BASE", "GROUND_DETAIL", "RAILS", "PLATFORM", "PLATFORM_EDGE",
        "STRUCTURES_LOW", "FURNITURE", "STRUCTURES_HIGH", "CANOPY"
    ]

    canvas = Image.new("RGBA", (scene_cols * TILE_SIZE, scene_rows * TILE_SIZE), (0, 0, 0, 255))

    for layer_name in LAYER_ORDER:
        layer_entries = [m for m in mapping if m["layer"] == layer_name]
        for entry in layer_entries:
            tile = Image.open(f"assets/tilemaps/{entry['tile_file']}").convert("RGBA")

            # Ground base: opak. Diğerleri: siyah pikseller → transparent
            if layer_name != "GROUND_BASE":
                data = list(tile.getdata())
                data = [(0,0,0,0) if (p[0]<=10 and p[1]<=10 and p[2]<=10) else p for p in data]
                tile.putdata(data)

            canvas.paste(tile, (entry["col"] * TILE_SIZE, entry["row"] * TILE_SIZE), tile)

    # Tam boyut kaydet
    full_path = f"logs/png/{scene_name}_full.png"
    canvas.save(full_path)

    # 2x büyütülmüş versiyon (kontrol kolaylığı)
    big = canvas.resize((canvas.width * 2, canvas.height * 2), Image.NEAREST)
    big.save(f"logs/png/{scene_name}_2x.png")

    # Katman bazlı debug görsel
    for layer_name in LAYER_ORDER:
        layer_canvas = Image.new("RGBA", (scene_cols * TILE_SIZE, scene_rows * TILE_SIZE), (0, 0, 0, 0))
        layer_entries = [m for m in mapping if m["layer"] == layer_name]
        if not layer_entries:
            continue
        for entry in layer_entries:
            tile = Image.open(f"assets/tilemaps/{entry['tile_file']}").convert("RGBA")
            layer_canvas.paste(tile, (entry["col"] * TILE_SIZE, entry["row"] * TILE_SIZE), tile)
        layer_canvas.save(f"logs/png/{scene_name}_layer_{layer_name.lower()}.png")

    print(f"📸 Preview: {full_path}")
    print(f"📸 Layers:  logs/png/{scene_name}_layer_*.png")
    return full_path
```

---

## ÇIKTI DOSYALARI

Her sahne oluşturulduğunda şu dosyalar üretilir:

```
scenes/stations/{scene_name}/
├── {scene_name}.tscn              # Godot sahne dosyası
├── {scene_name}.gd                # Sahne scripti
└── mapping.json                   # Tile yerleşim verisi

tests/tiles/
└── test_{scene_name}_tiles.gd     # Tile varlık testleri (GUT framework)

logs/png/
├── {scene_name}_full.png          # Birleşik preview
├── {scene_name}_2x.png            # 2x büyütülmüş
├── {scene_name}_layer_ground_base.png
├── {scene_name}_layer_rails.png
├── {scene_name}_layer_structures_low.png
├── {scene_name}_layer_furniture.png
├── {scene_name}_layer_canopy.png
└── ...                            # Her aktif katman için ayrı
```

---

## mapping.json FORMAT

```json
{
  "scene": "ankara_station",
  "size": {"cols": 13, "rows": 23},
  "tile_size": 32,
  "train_lanes": [
    {"rows": [9, 10], "direction": "left_to_right"},
    {"rows": [15, 16], "direction": "right_to_left"}
  ],
  "layers": {
    "GROUND_BASE": [
      {"row": 0, "col": 0, "tile_id": "station__ground__ground_grass_center_a", "tile_file": "terrain/ground/ground_grass_center_a.png"}
    ],
    "RAILS": [ ... ],
    "FURNITURE": [ ... ]
  },
  "used_tile_ids": ["station__ground__ground_grass_center_a", ...]
}
```

---

## MUTLAK KURALLAR

1. ❌ `assets/references/` ASLA kullanma — tek kaynak `assets/tilemaps/manifest.json`
2. ❌ Test yazmadan sahne teslim etme — her sahne = test dosyası
3. ❌ Preview PNG olmadan bitirme — `logs/png/` altına kaydet
4. ❌ Manifest'te olmayan tile id kullanma — önce `find_tiles()` ile kontrol et
5. ❌ Tren şeritlerini (TRAIN_LANES) engelleme — o satırlarda sadece RAILS + GROUND_BASE
6. ❌ Katman sırasını değiştirme — z-index haritasına uy
7. ✅ Her tile referansı test edilebilir olmalı
8. ✅ Mapping JSON Godot'un runtime'da okuyabileceği formatta olmalı
9. ✅ Preview'ı oluşturduktan sonra kontrol et — boş alan, kırık tile, yanlış katman var mı?
10. ✅ Overlay tile'larda siyah→transparent dönüşümü uygula (GROUND_BASE hariç)