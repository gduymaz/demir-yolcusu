#!/usr/bin/env python3
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Tuple

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
TILEMAP_DIR = ROOT / "assets" / "tilemaps"
LOG_DIR = ROOT / "logs" / "png"
MANIFEST_PATH = TILEMAP_DIR / "manifest.json"

TS = 32
ZOOM = 4
BIG = TS * ZOOM

SHEETS: Dict[str, Dict] = {
    "station": {"file": "station.png", "grid": [45, 16], "chunk_rows": 4},
    "train_ext": {"file": "train-exterior.png", "grid": [36, 12], "chunk_rows": 3},
    "train_int": {"file": "train-interiors.png", "grid": [60, 24], "chunk_rows": 4},
    "chars": {"file": "characters.png", "grid": [5, 62], "chunk_rows": 15},
}

Z_LAYERS = {
    "GROUND_BASE": -10,
    "GROUND_DETAIL": -8,
    "RAILS": -5,
    "PLATFORM": -3,
    "PLATFORM_EDGE": -1,
    "ENTITIES": 0,
    "STRUCTURES_LOW": 5,
    "FURNITURE": 8,
    "STRUCTURES_HIGH": 10,
    "CANOPY": 15,
    "OVERLAY": 20,
}

CHAR_LIST = [
    "gutty_chan",
    "female_baker",
    "female_trendy",
    "female_youth",
    "male_student",
    "male_student_alt",
    "female_elder",
    "male_businessman",
    "male_businessman_old",
    "male_traditional",
    "male_traffic_cop",
    "female_cafe_maid",
    "female_office_worker",
    "female_student",
    "male_casual",
    "male_punk",
    "male_youth",
    "shiba_inu",
    "witch",
    "unknown",
]


def load_images() -> Dict[str, Image.Image]:
    imgs = {}
    for key, info in SHEETS.items():
        path = TILEMAP_DIR / info["file"]
        imgs[key] = Image.open(path).convert("RGB")
    return imgs


def is_empty_tile(tile: Image.Image) -> bool:
    # RGB-only sheets; treat near-black as empty.
    return all((r <= 5 and g <= 5 and b <= 5) for r, g, b in tile.getdata())


def detect_empties(imgs: Dict[str, Image.Image]) -> Dict[str, List[List[int]]]:
    empties: Dict[str, List[List[int]]] = {}
    for key, info in SHEETS.items():
        cols, rows = info["grid"]
        img = imgs[key]
        empty_cells: List[List[int]] = []
        for r in range(rows):
            for c in range(cols):
                tile = img.crop((c * TS, r * TS, (c + 1) * TS, (r + 1) * TS))
                if is_empty_tile(tile):
                    empty_cells.append([r, c])
        empties[key] = empty_cells
    return empties


def make_contact_sheet(
    imgs: Dict[str, Image.Image],
    empties_set: Dict[str, set[Tuple[int, int]]],
    sheet_key: str,
    row_start: int,
    row_end: int,
) -> Path:
    info = SHEETS[sheet_key]
    cols = info["grid"][0]
    img = imgs[sheet_key]

    margin = 4
    label_h = 24
    num_rows = row_end - row_start
    w = margin + cols * (BIG + margin)
    h = margin + num_rows * (BIG + label_h + margin)

    out = Image.new("RGB", (w, h), (20, 20, 20))
    draw = ImageDraw.Draw(out)

    for ri, r in enumerate(range(row_start, row_end)):
        for c in range(cols):
            tile = img.crop((c * TS, r * TS, (c + 1) * TS, (r + 1) * TS))
            big = tile.resize((BIG, BIG), Image.NEAREST)
            x = margin + c * (BIG + margin)
            y = margin + ri * (BIG + label_h + margin)
            out.paste(big, (x, y))

            if (r, c) in empties_set[sheet_key]:
                draw.line([(x, y), (x + BIG, y + BIG)], fill=(255, 0, 0), width=2)
                draw.line([(x + BIG, y), (x, y + BIG)], fill=(255, 0, 0), width=2)

            draw.text((x + 2, y + BIG + 2), f"r{r}c{c}", fill=(140, 140, 140))

    out_path = LOG_DIR / f"inspect_{sheet_key}_r{row_start}-{row_end}.png"
    out.save(out_path)
    return out_path


def build_contact_sheets(imgs: Dict[str, Image.Image], empties: Dict[str, List[List[int]]]) -> List[Path]:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    empties_set = {k: {tuple(rc) for rc in v} for k, v in empties.items()}
    generated: List[Path] = []
    for key, info in SHEETS.items():
        rows = info["grid"][1]
        step = info["chunk_rows"]
        for start in range(0, rows, step):
            end = min(start + step, rows)
            generated.append(make_contact_sheet(imgs, empties_set, key, start, end))
    return generated


def uniq_id(tile_id: str, tiles: Dict[str, Dict]) -> str:
    if tile_id not in tiles:
        return tile_id
    i = 2
    while f"{tile_id}_{i}" in tiles:
        i += 1
    return f"{tile_id}_{i}"


def station_meta(r: int, c: int) -> Tuple[str, str, List[str], str]:
    if c >= 33:
        return "fx", "static", ["station", "fx_region"], f"station_fx_r{r:02d}_c{c:02d}"
    if r <= 1:
        return "terrain", "ground", ["station", "ground", "top"], f"station_ground_top_r{r:02d}_c{c:02d}"
    if 2 <= r <= 3:
        return "structure", "building", ["station", "building"], f"station_building_r{r:02d}_c{c:02d}"
    if 4 <= r <= 5:
        return "structure", "platform", ["station", "platform", "upper"], f"station_platform_upper_r{r:02d}_c{c:02d}"
    if 6 <= r <= 8:
        return "vehicle", "rail", ["station", "rails", "lane1"], f"station_rail_lane1_r{r:02d}_c{c:02d}"
    if 9 <= r <= 13:
        return "structure", "platform", ["station", "platform", "main"], f"station_platform_main_r{r:02d}_c{c:02d}"
    return "terrain", "ground", ["station", "ground", "bottom"], f"station_ground_bottom_r{r:02d}_c{c:02d}"


def train_ext_meta(r: int, c: int, band_mins: Dict[int, int]) -> Tuple[str, str, List[str], str]:
    band = r // 3
    row_kind = ["upper", "middle", "lower"][r % 3]
    train_type = {0: "green", 1: "bullet", 2: "silver", 3: "commuter"}.get(band, "train")
    rel = c - band_mins.get(band, 0) + 1
    rel = max(rel, 1)
    tile_id = f"{train_type}_tile_{row_kind}_c{rel:02d}"
    tags = ["train", train_type, row_kind, f"band_{band}"]
    return "vehicle", train_type, tags, tile_id


def train_int_meta(r: int, c: int) -> Tuple[str, str, List[str], str]:
    if r <= 5:
        sub = "wall"
    elif r <= 11:
        sub = "seat"
    elif r <= 17:
        sub = "props"
    else:
        sub = "floor"
    tile_id = f"train_int_{sub}_r{r:02d}_c{c:02d}"
    return "interior", sub, ["train_interior", sub], tile_id


def chars_meta(r: int, c: int) -> Tuple[str, str, List[str], str]:
    if r >= 60:
        return "character", "extra", ["characters", "extra"], f"chars_extra_r{r:02d}_c{c:02d}"
    block = r // 3
    row_in = r % 3
    cname = CHAR_LIST[block] if block < len(CHAR_LIST) else f"char_{block:02d}"
    if row_in == 0:
        dir_map = {0: "south", 1: "north", 2: "east", 3: "west", 4: "alt"}
        d = dir_map.get(c, f"c{c}")
        tile_id = f"{cname}_idle_{d}"
        tags = ["character", cname, "idle", d]
    else:
        seq = "walk_a" if row_in == 1 else "walk_b"
        tile_id = f"{cname}_{seq}_f{c+1:02d}"
        tags = ["character", cname, "walk", seq]
    return "character", cname, tags, tile_id


def collect_animation_frames(
    sheet: str,
    coords: List[Tuple[int, int]],
    empties_set: Dict[str, set[Tuple[int, int]]],
    ms: int,
) -> List[Dict]:
    frames = []
    for r, c in coords:
        if (r, c) in empties_set[sheet]:
            continue
        frames.append({"rc": [r, c], "ms": ms})
    return frames


def build_animations(empties_set: Dict[str, set[Tuple[int, int]]]) -> Dict[str, Dict]:
    # Based on station right animation region c33..44
    def row_cols(row: int, c0: int, c1: int) -> List[Tuple[int, int]]:
        return [(row, c) for c in range(c0, c1 + 1)]

    animations = {
        "flag_top": {
            "sheet": "station",
            "frames": collect_animation_frames("station", row_cols(0, 33, 44), empties_set, 150),
            "loop": True,
            "group": "fx",
            "tags": ["flag", "top"],
        },
        "flag_bottom": {
            "sheet": "station",
            "frames": collect_animation_frames("station", row_cols(1, 33, 44), empties_set, 150),
            "loop": True,
            "group": "fx",
            "tags": ["flag", "bottom"],
        },
        "pigeon_fly": {
            "sheet": "station",
            "frames": collect_animation_frames("station", row_cols(2, 33, 36), empties_set, 150),
            "loop": True,
            "group": "fx",
            "tags": ["bird", "pigeon", "fly"],
        },
        "seagull_fly": {
            "sheet": "station",
            "frames": collect_animation_frames("station", row_cols(2, 37, 40), empties_set, 150),
            "loop": True,
            "group": "fx",
            "tags": ["bird", "seagull", "fly"],
        },
        "pigeon_walk": {
            "sheet": "station",
            "frames": collect_animation_frames("station", row_cols(3, 33, 44), empties_set, 120),
            "loop": True,
            "group": "fx",
            "tags": ["bird", "pigeon", "walk"],
        },
        "seagull_walk": {
            "sheet": "station",
            "frames": collect_animation_frames("station", row_cols(4, 33, 44), empties_set, 120),
            "loop": True,
            "group": "fx",
            "tags": ["bird", "seagull", "walk"],
        },
        "cat_calico_rest": {
            "sheet": "station",
            "frames": collect_animation_frames("station", row_cols(5, 33, 44), empties_set, 150),
            "loop": True,
            "group": "fx",
            "tags": ["cat", "rest"],
        },
        "cat_orange_run": {
            "sheet": "station",
            "frames": collect_animation_frames("station", row_cols(6, 33, 44), empties_set, 120),
            "loop": True,
            "group": "fx",
            "tags": ["cat", "run"],
        },
        "tree_top": {
            "sheet": "station",
            "frames": collect_animation_frames("station", row_cols(7, 33, 44), empties_set, 200),
            "loop": True,
            "group": "fx",
            "tags": ["tree", "top"],
        },
        "tree_bottom": {
            "sheet": "station",
            "frames": collect_animation_frames("station", row_cols(8, 33, 44), empties_set, 200),
            "loop": True,
            "group": "fx",
            "tags": ["tree", "bottom"],
        },
    }
    # Remove empty animations
    return {k: v for k, v in animations.items() if v["frames"]}


def build_tiles(
    imgs: Dict[str, Image.Image],
    empties_set: Dict[str, set[Tuple[int, int]]],
    animation_used: set[Tuple[str, int, int]],
) -> Dict[str, Dict]:
    tiles: Dict[str, Dict] = {}

    # Relative min column per train exterior band
    band_mins: Dict[int, int] = {}
    cols, rows = SHEETS["train_ext"]["grid"]
    for band in range(rows // 3):
        candidates = [
            c
            for r in range(band * 3, band * 3 + 3)
            for c in range(cols)
            if (r, c) not in empties_set["train_ext"]
        ]
        band_mins[band] = min(candidates) if candidates else 0

    for sheet_key, info in SHEETS.items():
        cols, rows = info["grid"]
        for r in range(rows):
            for c in range(cols):
                if (r, c) in empties_set[sheet_key]:
                    continue
                if (sheet_key, r, c) in animation_used:
                    continue

                if sheet_key == "station":
                    g, sub, tags, tile_id = station_meta(r, c)
                elif sheet_key == "train_ext":
                    g, sub, tags, tile_id = train_ext_meta(r, c, band_mins)
                elif sheet_key == "train_int":
                    g, sub, tags, tile_id = train_int_meta(r, c)
                else:
                    g, sub, tags, tile_id = chars_meta(r, c)

                tile_id = uniq_id(tile_id, tiles)
                tiles[tile_id] = {"s": sheet_key, "rc": [r, c], "g": g, "sub": sub, "tags": tags}

    return tiles


def build_composites(tiles: Dict[str, Dict]) -> Dict[str, Dict]:
    def pick_ids(prefix: str, limit: int = 8) -> List[str]:
        out = [k for k in tiles if k.startswith(prefix)]
        return out[:limit]

    pole_tiles = pick_ids("station_platform_main_r09", 1) + pick_ids("station_platform_main_r10", 1)
    pole_tiles += pick_ids("station_platform_main_r11", 1) + pick_ids("station_platform_main_r12", 1)

    arch_row = [k for k, v in tiles.items() if v["s"] == "station" and 4 <= v["rc"][0] <= 5 and 15 <= v["rc"][1] <= 20][:6]
    building_row = [k for k, v in tiles.items() if v["s"] == "station" and 2 <= v["rc"][0] <= 3 and 10 <= v["rc"][1] <= 15][:6]

    green_strip = [k for k in tiles if k.startswith("green_tile_upper_c")][:8]
    if not green_strip:
        green_strip = [k for k in tiles if k.startswith("green_tile_middle_c")][:8]

    return {
        "electric_pole_stack": {
            "type": "vertical_stack",
            "tiles": pole_tiles,
            "layout": [[pole_tiles[0]] if len(pole_tiles) > 0 else [], [pole_tiles[1]] if len(pole_tiles) > 1 else []],
            "z_layers": {tid: "STRUCTURES_HIGH" for tid in pole_tiles},
        },
        "arch_canopy": {
            "type": "grid_block",
            "tiles": arch_row,
            "layout": [arch_row[:3], arch_row[3:6]],
            "z_layers": {tid: "CANOPY" for tid in arch_row},
        },
        "building_facade": {
            "type": "grid_block",
            "tiles": building_row,
            "layout": [building_row[:3], building_row[3:6]],
            "z_layers": {tid: "STRUCTURES_LOW" for tid in building_row},
        },
        "train_green_strip": {
            "type": "horizontal_strip",
            "tiles": green_strip,
            "layout": [green_strip],
            "z_layers": {tid: "ENTITIES" for tid in green_strip},
        },
    }


def build_characters_block() -> Dict:
    return {
        "sheet": "chars",
        "block_rows": 3,
        "idle_row": 0,
        "walk_rows": [1, 2],
        "cols": 5,
        "idle_dirs": {"south": 0, "north": 1, "east": 2, "west": 3},
        "walk_frames": 5,
        "walk_dirs": {},
        "list": [{"name": name, "start_row": i * 3} for i, name in enumerate(CHAR_LIST)],
    }


def validate_manifest(manifest: Dict, empties_set: Dict[str, set[Tuple[int, int]]], sheets: Dict[str, Dict]) -> Tuple[bool, List[str]]:
    errors: List[str] = []

    for tid, tile in manifest["tiles"].items():
        cols, rows = sheets[tile["s"]]["grid"]
        r, c = tile["rc"]
        if r < 0 or r >= rows or c < 0 or c >= cols:
            errors.append(f"OUT_OF_BOUNDS: {tid} rc={tile['rc']} grid={sheets[tile['s']]['grid']}")

    seen = {}
    for tid, tile in manifest["tiles"].items():
        key = (tile["s"], tuple(tile["rc"]))
        if key in seen:
            errors.append(f"DUPLICATE_RC: {tid} and {seen[key]} at {key}")
        seen[key] = tid

    for cid, comp in manifest["composites"].items():
        for ref in comp.get("tiles", []):
            if ref not in manifest["tiles"]:
                errors.append(f"COMPOSITE_REF: {cid} missing {ref}")
        for row in comp.get("layout", []):
            for ref in row:
                if ref and ref not in manifest["tiles"]:
                    errors.append(f"COMPOSITE_LAYOUT: {cid} missing {ref}")

    for aid, anim in manifest["animations"].items():
        for f in anim.get("frames", []):
            if tuple(f["rc"]) in empties_set.get(anim["sheet"], set()):
                errors.append(f"ANIM_EMPTY: {aid} frame={f['rc']}")

    all_defined = {(t["s"], tuple(t["rc"])) for t in manifest["tiles"].values()}
    for anim in manifest["animations"].values():
        for f in anim.get("frames", []):
            all_defined.add((anim["sheet"], tuple(f["rc"])))

    for sheet_key, info in sheets.items():
        cols, rows = info["grid"]
        for r in range(rows):
            for c in range(cols):
                if (r, c) in empties_set[sheet_key]:
                    continue
                if (sheet_key, (r, c)) not in all_defined:
                    errors.append(f"UNNAMED: {sheet_key} r{r}c{c}")

    return len(errors) == 0, errors


def main() -> None:
    imgs = load_images()
    empties = detect_empties(imgs)
    sheets = build_contact_sheets(imgs, empties)

    empties_set = {k: {tuple(rc) for rc in v} for k, v in empties.items()}
    animations = build_animations(empties_set)

    animation_used: set[Tuple[str, int, int]] = set()
    for anim in animations.values():
        for f in anim["frames"]:
            animation_used.add((anim["sheet"], f["rc"][0], f["rc"][1]))

    tiles = build_tiles(imgs, empties_set, animation_used)
    composites = build_composites(tiles)

    manifest = {
        "version": 3,
        "tile_size": 32,
        "generated": datetime.now(timezone.utc).isoformat(),
        "sheets": {k: {"file": v["file"], "grid": v["grid"]} for k, v in SHEETS.items()},
        "tiles": tiles,
        "composites": composites,
        "animations": animations,
        "characters": build_characters_block(),
        "empties": empties,
        "z_layers": Z_LAYERS,
    }

    ok, errors = validate_manifest(manifest, empties_set, SHEETS)

    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    with MANIFEST_PATH.open("w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print(f"contact_sheets={len(sheets)}")
    print(f"tiles={len(manifest['tiles'])} composites={len(manifest['composites'])} animations={len(manifest['animations'])}")
    print(f"validation={'OK' if ok else 'FAIL'} errors={len(errors)}")
    if errors:
        for e in errors[:50]:
            print(f"ERR {e}")


if __name__ == "__main__":
    main()
