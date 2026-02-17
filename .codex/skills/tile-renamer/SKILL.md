---
name: tile-renamer
description: "Inspect tile visuals vs names, rename mismatches, and propagate changes across manifest + all code references. Use when a tile's name doesn't match its visual content, when tiles need reorganizing, or when test failures indicate broken tile references. Updates manifest.json, renames physical files, updates all mapping.json and test files that reference the changed tile."
---

# 🔄 Tile Renamer

## Purpose
Tile isimlerinin görsel içerikle eşleşmesini sağla. Yanlış isimli tile'ları bul, yeniden adlandır, manifest'i güncelle, ve tüm referansları (mapping, test, Godot kodu) otomatik düzelt.

---

## When To Use
- "Bu tile'ın ismi yanlış, X olmalı"
- "ground_cobble diyor ama aslında platform kenarı"
- Test FAIL oldu — tile ismi değişmiş, eski referansları düzelt
- Toplu rename: bir kategorideki tüm tile'ları yeniden adlandır
- Tile'ları görsel olarak kontrol et, yanlış olanları bul

## DATA SOURCE
```
MANIFEST:  assets/tilemaps/manifest.json
TILE ROOT: assets/tilemaps/
❌ ASLA assets/references/ KULLANMA
```

---

## PROSEDÜR

### Mode A: Görsel İnceleme → İsim Düzeltme

Kullanıcı "bu tile'ları kontrol et" dediğinde:

#### A1. Tile'ları 4x Zoom ile İncele

```python
from PIL import Image, ImageDraw, ImageFont
import json, os

def load_manifest():
    with open("assets/tilemaps/manifest.json") as f:
        return json.load(f)

def inspect_group(group, subfolder=None, max_tiles=40):
    """
    Bir gruptaki tile'ları 4x büyüterek contact sheet oluştur.
    Her tile'ın altında mevcut ismi yazar.
    logs/png/inspect_{group}_{subfolder}.png olarak kaydet.
    """
    manifest = load_manifest()
    items = [i for i in manifest["items"] if i["group"] == group]
    if subfolder:
        items = [i for i in items if i["subfolder"] == subfolder]
    items = items[:max_tiles]

    if not items:
        print(f"Tile bulunamadı: group={group}, subfolder={subfolder}")
        return None

    ZOOM = 4
    ts = 32 * ZOOM  # 128px
    margin = 6
    label_h = 28
    cols_per_row = min(len(items), 8)
    rows_needed = (len(items) + cols_per_row - 1) // cols_per_row

    sheet_w = margin + cols_per_row * (ts + margin)
    sheet_h = margin + rows_needed * (ts + label_h + margin)
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (30, 30, 30, 255))
    draw = ImageDraw.Draw(sheet)

    for idx, item in enumerate(items):
        r, c = divmod(idx, cols_per_row)
        x = margin + c * (ts + margin)
        y = margin + r * (ts + label_h + margin)

        tile_file = f"assets/tilemaps/{item['file']}"
        if os.path.exists(tile_file):
            tile = Image.open(tile_file).convert("RGBA")
            big = tile.resize((ts, ts), Image.NEAREST)
            # Checker background for transparency
            checker = Image.new("RGBA", (ts, ts))
            for cy in range(0, ts, 16):
                for cx in range(0, ts, 16):
                    color = (60,60,60,255) if (cx//16 + cy//16) % 2 == 0 else (40,40,40,255)
                    for dy in range(16):
                        for dx in range(16):
                            if cy+dy < ts and cx+dx < ts:
                                checker.putpixel((cx+dx, cy+dy), color)
            checker.paste(big, (0, 0), big)
            sheet.paste(checker, (x, y))
        else:
            draw.rectangle([x, y, x+ts, y+ts], fill=(80, 0, 0), outline=(255, 0, 0))
            draw.text((x+4, y+ts//2), "MISSING", fill=(255, 50, 50))

        # İsim etiketi
        label = item["name"][:20]
        draw.text((x + 2, y + ts + 2), label, fill=(180, 180, 180))

    os.makedirs("logs/png", exist_ok=True)
    suffix = f"_{subfolder}" if subfolder else ""
    out_path = f"logs/png/inspect_{group}{suffix}.png"
    sheet.save(out_path)
    print(f"📸 {out_path} — {len(items)} tile")
    return out_path
```

#### A2. Yanlış İsimleri Tespit Et

Contact sheet'i `view` ile incele. Her tile için:
- **İsim doğru mu?** → Devam
- **İsim yanlış mı?** → Rename listesine ekle

```python
# Rename planı — kullanıcı onayı gerekir
rename_plan = [
    {
        "tile_id": "station__ground__ground_cobble_edge_top",
        "current_name": "ground_cobble_edge_top",
        "new_name": "platform_concrete_edge_top",
        "reason": "Görsel olarak arnavut kaldırımı değil, platform beton kenarı"
    },
    {
        "tile_id": "station__props__furniture_bird_dove",
        "current_name": "furniture_bird_dove",
        "new_name": "decoration_bird_dove",
        "reason": "Kuş mobilya değil, dekorasyon"
    },
]
```

**KURAL: Rename planını kullanıcıya göster ve onay al. Onaysız rename yapma.**

#### A3. Rename Uygula

```python
def apply_renames(rename_plan, dry_run=True):
    """
    1. Fiziksel dosyayı yeniden adlandır
    2. Manifest.json güncelle
    3. Tüm mapping.json dosyalarını güncelle
    4. Tüm test dosyalarını güncelle
    5. Tüm .gd dosyalarında string referansları güncelle
    """
    manifest = load_manifest()
    changes_log = []

    for rename in rename_plan:
        tile_id = rename["tile_id"]
        new_name = rename["new_name"]

        # Manifest'te tile'ı bul
        item = next((i for i in manifest["items"] if i["id"] == tile_id), None)
        if not item:
            print(f"❌ Tile bulunamadı: {tile_id}")
            continue

        old_file = item["file"]
        old_name = item["name"]

        # Yeni dosya yolu hesapla (aynı klasörde kalır)
        dir_part = os.path.dirname(old_file)
        new_file = f"{dir_part}/{new_name}.png"

        # Yeni ID hesapla
        old_id = item["id"]
        # ID formatı: {source}__{subfolder}__{name}
        id_parts = old_id.rsplit("__", 1)
        new_id = f"{id_parts[0]}__{new_name}"

        change = {
            "old_id": old_id,
            "new_id": new_id,
            "old_file": old_file,
            "new_file": new_file,
            "old_name": old_name,
            "new_name": new_name,
        }
        changes_log.append(change)

        if dry_run:
            print(f"  [DRY] {old_name} → {new_name}")
            print(f"         {old_file} → {new_file}")
            print(f"         {old_id} → {new_id}")
            continue

        # 1. Dosya taşı
        old_path = f"assets/tilemaps/{old_file}"
        new_path = f"assets/tilemaps/{new_file}"
        if os.path.exists(old_path):
            os.rename(old_path, new_path)

        # 2. Manifest güncelle
        item["id"] = new_id
        item["file"] = new_file
        item["name"] = new_name
        # Tags güncelle — eski isimden türetilmiş tag'ları değiştir
        if old_name.split("_")[0] != new_name.split("_")[0]:
            # Kategori değişti — tag'ları güncelle
            item["tags"] = [t if t != old_name.split("_")[0] else new_name.split("_")[0] for t in item["tags"]]

    if not dry_run:
        # Manifest kaydet
        with open("assets/tilemaps/manifest.json", "w") as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)
        print(f"✅ Manifest güncellendi: {len(changes_log)} tile")

        # 3-5. Referansları güncelle
        update_all_references(changes_log)

    return changes_log
```

#### A4. Referans Güncelleme — Tüm Dosyalarda

```python
import glob

def update_all_references(changes_log):
    """
    Tüm proje dosyalarında eski tile id/file/name referanslarını güncelle.
    Hedef dosyalar: mapping.json, test_*.gd, *.gd, *.tscn
    """
    # Aranacak dosya kalıpları
    file_patterns = [
        "scenes/**/mapping.json",
        "tests/tiles/test_*.gd",
        "scenes/**/*.gd",
        "scenes/**/*.tscn",
    ]

    updated_files = []

    for pattern in file_patterns:
        for filepath in glob.glob(pattern, recursive=True):
            with open(filepath, "r") as f:
                content = f.read()

            original = content
            for change in changes_log:
                content = content.replace(change["old_id"], change["new_id"])
                content = content.replace(change["old_file"], change["new_file"])
                content = content.replace(change["old_name"], change["new_name"])

            if content != original:
                with open(filepath, "w") as f:
                    f.write(content)
                updated_files.append(filepath)

    print(f"📝 {len(updated_files)} dosya güncellendi:")
    for f in updated_files:
        print(f"  {f}")

    return updated_files
```

---

### Mode B: Test Failure → Otomatik Düzeltme

Test FAIL edince hangi tile'ların eksik olduğunu bul ve düzelt:

```python
def find_broken_references():
    """
    Tüm mapping.json ve test dosyalarındaki tile referanslarını kontrol et.
    Manifest'te olmayan referansları bul.
    """
    manifest = load_manifest()
    manifest_ids = {i["id"] for i in manifest["items"]}
    manifest_files = {i["file"] for i in manifest["items"]}

    broken = []

    # Mapping dosyalarını tara
    for mapping_path in glob.glob("scenes/**/mapping.json", recursive=True):
        with open(mapping_path) as f:
            data = json.load(f)
        for layer_name, entries in data.get("layers", {}).items():
            for entry in entries:
                if entry["tile_id"] not in manifest_ids:
                    broken.append({
                        "file": mapping_path,
                        "tile_id": entry["tile_id"],
                        "tile_file": entry["tile_file"],
                        "type": "mapping",
                    })

    if broken:
        print(f"🔍 {len(broken)} kırık referans bulundu:")
        for b in broken:
            print(f"  {b['file']}: {b['tile_id']}")

        # Fuzzy match ile olası eşleşmeleri öner
        suggest_fixes(broken, manifest)
    else:
        print("✅ Tüm referanslar geçerli")

    return broken


def suggest_fixes(broken, manifest):
    """Kırık referanslar için en yakın eşleşmeyi öner."""
    from difflib import get_close_matches

    all_ids = [i["id"] for i in manifest["items"]]
    all_names = [i["name"] for i in manifest["items"]]

    for b in broken:
        old_name = b["tile_id"].rsplit("__", 1)[-1]  # ID'nin son kısmı = tile name
        matches = get_close_matches(old_name, all_names, n=3, cutoff=0.5)
        if matches:
            print(f"\n  {b['tile_id']}:")
            print(f"    Öneriler: {matches}")
            # En yakın eşleşmenin tam id'sini bul
            best = matches[0]
            best_item = next(i for i in manifest["items"] if i["name"] == best)
            print(f"    → {best_item['id']}")
```

---

### Mode C: Toplu Kategori Rename

Bir subfolder'daki tüm tile'ların prefix'ini değiştir:

```python
def batch_rename_prefix(group, subfolder, old_prefix, new_prefix, dry_run=True):
    """
    Örnek: ground grubundaki tüm 'ground_cobble_' → 'cobblestone_' yapmak
    """
    manifest = load_manifest()
    items = [i for i in manifest["items"]
             if i["group"] == group
             and i["subfolder"] == subfolder
             and i["name"].startswith(old_prefix)]

    rename_plan = []
    for item in items:
        new_name = item["name"].replace(old_prefix, new_prefix, 1)
        rename_plan.append({
            "tile_id": item["id"],
            "current_name": item["name"],
            "new_name": new_name,
            "reason": f"Batch: {old_prefix} → {new_prefix}",
        })

    print(f"Toplu rename planı: {len(rename_plan)} tile")
    for r in rename_plan[:5]:
        print(f"  {r['current_name']} → {r['new_name']}")
    if len(rename_plan) > 5:
        print(f"  ... ve {len(rename_plan) - 5} tile daha")

    if not dry_run:
        return apply_renames(rename_plan, dry_run=False)
    return rename_plan
```

---

## ÇIKTI DOSYALARI

```
logs/png/
├── inspect_{group}_{subfolder}.png    # 4x zoom contact sheet
└── inspect_rename_preview.png         # Rename öncesi/sonrası karşılaştırma

assets/tilemaps/
├── manifest.json                      # Güncellenmiş manifest
└── {group}/{subfolder}/{new_name}.png # Yeniden adlandırılmış dosyalar

scenes/**/mapping.json                 # Güncellenen referanslar
tests/tiles/test_*_tiles.gd            # Güncellenen test dosyaları
```

---

## GÜVENLİK KURALLARI

1. ❌ Kullanıcı onayı olmadan rename yapma — önce plan göster, onay al
2. ❌ dry_run=True ile test etmeden gerçek rename yapma
3. ✅ Her rename işleminden önce `find_broken_references()` çalıştır
4. ✅ Her rename işleminden sonra `find_broken_references()` çalıştır (kalan hata var mı?)
5. ✅ Rename log'unu `logs/rename_log.json` olarak kaydet (geri alma için)
6. ✅ Fiziksel dosya taşımadan önce dosyanın var olduğunu doğrula
7. ✅ Manifest yazarken backup al: `manifest.json.bak`

---

## RENAME LOG FORMAT

Her rename işlemi kalıcı log olarak kaydedilir:

```json
{
  "timestamp": "2026-02-17T14:30:00",
  "operation": "rename",
  "changes": [
    {
      "old_id": "station__ground__ground_cobble_edge_top",
      "new_id": "station__ground__platform_concrete_edge_top",
      "old_file": "terrain/ground/ground_cobble_edge_top.png",
      "new_file": "terrain/ground/platform_concrete_edge_top.png",
      "reason": "Görsel olarak platform betonu"
    }
  ],
  "affected_files": [
    "scenes/stations/ankara/mapping.json",
    "tests/tiles/test_ankara_tiles.gd"
  ]
}
```

Bu log ile gerekirse geri alma yapılabilir.