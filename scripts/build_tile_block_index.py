#!/usr/bin/env python3
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple

from PIL import Image, ImageDraw

TILE_SIZE = 32
BLOCK_COLS = 20
BLOCK_ROWS = 5
PADDING = 12
LABEL_HEIGHT = 24


@dataclass(frozen=True)
class SheetConfig:
    output_name: str
    filename: str
    cols: int
    rows: int


SHEETS: Tuple[SheetConfig, ...] = (
    SheetConfig(output_name="station", filename="station.png", cols=45, rows=16),
    SheetConfig(output_name="train", filename="train-exterior.png", cols=36, rows=12),
)


def _row_range(start: int, limit: int) -> Tuple[int, int]:
    end = min(start + BLOCK_ROWS, limit) - 1
    return start, end


def _col_range(start: int, limit: int) -> Tuple[int, int]:
    end = min(start + BLOCK_COLS, limit) - 1
    return start, end


def _slice_block(sheet_image: Image.Image, row_range: Tuple[int, int], col_range: Tuple[int, int]) -> Image.Image:
    row_start, row_end = row_range
    col_start, col_end = col_range
    left = col_start * TILE_SIZE
    top = row_start * TILE_SIZE
    right = (col_end + 1) * TILE_SIZE
    bottom = (row_end + 1) * TILE_SIZE
    return sheet_image.crop((left, top, right, bottom))


def _build_index_image(block_paths: List[Path], output_path: Path) -> None:
    if not block_paths:
        return

    block_images = [Image.open(path).convert("RGB") for path in block_paths]
    max_w = max(image.width for image in block_images)
    max_h = max(image.height for image in block_images)

    columns = min(3, len(block_images))
    rows = (len(block_images) + columns - 1) // columns
    canvas_w = PADDING + columns * (max_w + PADDING)
    canvas_h = PADDING + rows * (max_h + LABEL_HEIGHT + PADDING)

    canvas = Image.new("RGB", (canvas_w, canvas_h), (24, 24, 24))
    draw = ImageDraw.Draw(canvas)

    for idx, image in enumerate(block_images):
        row = idx // columns
        col = idx % columns
        x = PADDING + col * (max_w + PADDING)
        y = PADDING + row * (max_h + LABEL_HEIGHT + PADDING)

        canvas.paste(image, (x, y))
        block_id = block_paths[idx].stem.replace("block_", "")
        draw.text((x + 2, y + image.height + 4), block_id, fill=(210, 210, 210))

    canvas.save(output_path)


def generate_block_index(root: Path) -> Dict[str, List[str]]:
    tilemap_dir = root / "assets" / "tilemaps"
    logs_dir = root / "logs"
    logs_png_dir = logs_dir / "png"
    logs_png_dir.mkdir(parents=True, exist_ok=True)

    mapping: Dict[str, Dict] = {}
    generated: Dict[str, List[str]] = {sheet.output_name: [] for sheet in SHEETS}

    for sheet in SHEETS:
        sheet_image_path = tilemap_dir / sheet.filename
        sheet_image = Image.open(sheet_image_path).convert("RGB")

        block_counter = 1
        sheet_blocks: List[Path] = []

        for row_start in range(0, sheet.rows, BLOCK_ROWS):
            rows = _row_range(row_start, sheet.rows)
            for col_start in range(0, sheet.cols, BLOCK_COLS):
                cols = _col_range(col_start, sheet.cols)
                block_image = _slice_block(sheet_image, rows, cols)

                block_id = f"{sheet.output_name}_{block_counter:03d}"
                filename = f"block_{sheet.output_name}_{block_counter:03d}.png"
                relative_preview_path = Path("logs") / "png" / filename
                absolute_preview_path = root / relative_preview_path
                block_image.save(absolute_preview_path)

                mapping[block_id] = {
                    "sheet": sheet.output_name,
                    "row_range": [rows[0], rows[1]],
                    "col_range": [cols[0], cols[1]],
                    "preview_path": str(relative_preview_path),
                }

                sheet_blocks.append(absolute_preview_path)
                generated[sheet.output_name].append(str(relative_preview_path))
                block_counter += 1

        _build_index_image(sheet_blocks, logs_png_dir / f"index_{sheet.output_name}.png")

    block_index_path = logs_dir / "block_index.json"
    block_index_path.write_text(json.dumps(mapping, indent=2), encoding="utf-8")
    return generated


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    outputs = generate_block_index(root)
    total_blocks = sum(len(values) for values in outputs.values())
    print(f"Generated {total_blocks} blocks across {len(outputs)} sheets")


if __name__ == "__main__":
    main()
