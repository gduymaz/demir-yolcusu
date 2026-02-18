import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image


class TestBuildTileBlockIndex(unittest.TestCase):
    def test_generate_outputs_creates_block_images_index_and_mapping(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            tilemaps = root / "assets" / "tilemaps"
            logs_png = root / "logs" / "png"
            tilemaps.mkdir(parents=True)
            logs_png.mkdir(parents=True)

            station = Image.new("RGB", (45 * 32, 16 * 32), (30, 60, 90))
            train = Image.new("RGB", (36 * 32, 12 * 32), (90, 60, 30))
            station.save(tilemaps / "station.png")
            train.save(tilemaps / "train-exterior.png")

            script_path = Path(__file__).resolve().parents[2] / "scripts" / "build_tile_block_index.py"
            spec = importlib.util.spec_from_file_location("build_tile_block_index", script_path)
            self.assertIsNotNone(spec)
            module = importlib.util.module_from_spec(spec)
            assert spec.loader is not None
            sys.modules[spec.name] = module
            spec.loader.exec_module(module)

            outputs = module.generate_block_index(root)

            self.assertTrue((root / "logs" / "block_index.json").exists())
            data = json.loads((root / "logs" / "block_index.json").read_text(encoding="utf-8"))
            self.assertIn("station_001", data)
            self.assertIn("train_001", data)
            self.assertEqual(data["station_001"]["sheet"], "station")
            self.assertEqual(data["train_001"]["sheet"], "train")
            self.assertTrue((root / data["station_001"]["preview_path"]).exists())
            self.assertTrue((root / data["train_001"]["preview_path"]).exists())
            self.assertTrue((root / "logs" / "png" / "index_station.png").exists())
            self.assertTrue((root / "logs" / "png" / "index_train.png").exists())

            self.assertGreaterEqual(len(outputs["station"]), 1)
            self.assertGreaterEqual(len(outputs["train"]), 1)


if __name__ == "__main__":
    unittest.main()
