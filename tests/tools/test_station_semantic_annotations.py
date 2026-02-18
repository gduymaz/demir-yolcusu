import json
import unittest
from pathlib import Path


class TestStationSemanticAnnotations(unittest.TestCase):
    def test_first_8x5_station_panel_has_semantic_annotations(self) -> None:
        manifest_path = Path('/Users/splendour/game-projects/demir-yolcusu/assets/tilemaps/manifest.json')
        data = json.loads(manifest_path.read_text(encoding='utf-8'))

        expected_ids = [
            'wall_grey_top_a', 'wall_grey_top_b', 'wall_grey_top_c', 'wall_grey_top_d',
            'wall_grey_top_e', 'wall_grey_top_f', 'wall_grey_corner_tr', 'wall_grey_vent',
            'wall_grey_mid_a', 'painting_landscape', 'wall_grey_mid_b', 'wall_grey_mid_c',
            'painting_map', 'wall_grey_mid_d', 'wall_grey_mid_e', 'wall_grey_lower_a',
            'wall_grey_lower_b', 'wall_grey_lower_c', 'wall_grey_lower_d', 'wall_grey_lower_e',
            'wall_grey_lower_f', 'wall_grey_lower_g', 'wall_grey_lower_h', 'wall_grey_base_a',
            'prop_bollard_a', 'prop_bollard_b', 'prop_bollard_c', 'wall_grey_base_b',
            'structure_stairs_top', 'structure_stairs_mid', 'wall_grey_base_c', 'terrain_rock_a',
            'terrain_rock_b', 'terrain_rock_c', 'terrain_rock_d', 'vegetation_hedge_a',
            'vegetation_hedge_b', 'terrain_rock_e', 'terrain_rock_f',
        ]

        for tile_id in expected_ids:
            tile = data['tiles'][tile_id]
            self.assertIn('semantic', tile, f'missing semantic for {tile_id}')
            self.assertIsInstance(tile['semantic'], str)
            self.assertNotEqual(tile['semantic'].strip(), '')

        self.assertIn('empty_semantics', data)
        self.assertIn('station_r00_c00', data['empty_semantics'])

    def test_second_8x5_station_panel_has_semantic_annotations(self) -> None:
        manifest_path = Path('/Users/splendour/game-projects/demir-yolcusu/assets/tilemaps/manifest.json')
        data = json.loads(manifest_path.read_text(encoding='utf-8'))

        expected_ids = [
            'station_r00_c08',
            'item_flower_white',
            'item_light_a',
            'item_light_b',
            'item_light_c',
            'item_light_d',
            'item_light_e',
            'wall_stripe_diagonal_a',
            'wall_stripe_diagonal_b',
            'wall_stripe_diagonal_c',
            'wall_grey_accent_a',
            'wall_grey_accent_b',
            'wall_grey_accent_c',
            'prop_vending_machine',
            'prop_crate_wooden',
            'prop_locker_green',
            'arch_canopy_tc',
            'arch_canopy_tr',
            'arch_canopy_detail_a',
            'arch_canopy_detail_b',
            'electric_pole_top',
            'prop_luggage',
            'station_r03_c09',
            'arch_canopy_bl',
            'arch_canopy_bc',
            'arch_canopy_pillar',
            'arch_canopy_glass_a',
            'arch_canopy_glass_b',
            'electric_pole_upper',
            'arch_frame_tl',
            'arch_frame_tc',
            'arch_frame_tr',
            'arch_inner_tl',
            'arch_inner_tc',
            'arch_inner_tr',
            'arch_large_tl',
            'prop_flowerpot',
        ]

        for tile_id in expected_ids:
            tile = data['tiles'][tile_id]
            self.assertIn('semantic', tile, f'missing semantic for {tile_id}')
            self.assertIsInstance(tile['semantic'], str)
            self.assertNotEqual(tile['semantic'].strip(), '')

        self.assertIn('empty_semantics', data)
        self.assertIn('station_r00_c15', data['empty_semantics'])
        self.assertIn('station_r01_c14', data['empty_semantics'])
        self.assertIn('station_r01_c15', data['empty_semantics'])

    def test_third_8x5_station_panel_has_semantic_annotations(self) -> None:
        manifest_path = Path('/Users/splendour/game-projects/demir-yolcusu/assets/tilemaps/manifest.json')
        data = json.loads(manifest_path.read_text(encoding='utf-8'))

        expected_ids = [
            'station_ground_top_r00_c16',
            'structure_gate_dark',
            'plank_wood_beam_a',
            'plank_wood_beam_b',
            'plank_wood_beam_c',
            'station_ground_top_r01_c16',
            'facade_shuttered',
            'facade_window_upper',
            'plank_shelf_a',
            'plank_shelf_b',
            'plank_shelf_c',
            'plank_shelf_d',
            'prop_bench_wood',
            'sign_info_board_a',
            'sign_info_board_b',
            'prop_arrow_up_a',
            'prop_signal_colored',
            'vegetation_bush_large_a',
            'vegetation_bush_large_b',
            'station_building_r02_c23',
            'sign_route_map_a',
            'sign_route_map_b',
            'station_building_r03_c19',
            'vegetation_bush_med',
            'vegetation_bush_sm_a',
            'vegetation_bush_sm_b',
            'vegetation_potted_a',
            'vegetation_potted_b',
            'prop_flower_white',
            'vegetation_grass_tall_a',
            'vegetation_grass_tall_b',
            'vegetation_grass_cluster_a',
            'vegetation_grass_cluster_b',
        ]

        for tile_id in expected_ids:
            tile = data['tiles'][tile_id]
            self.assertIn('semantic', tile, f'missing semantic for {tile_id}')
            self.assertIsInstance(tile['semantic'], str)
            self.assertNotEqual(tile['semantic'].strip(), '')

        self.assertIn('empty_semantics', data)
        self.assertIn('station_r00_c18', data['empty_semantics'])
        self.assertIn('station_r00_c19', data['empty_semantics'])
        self.assertIn('station_r00_c23', data['empty_semantics'])
        self.assertIn('station_r02_c16', data['empty_semantics'])
        self.assertIn('station_r03_c16', data['empty_semantics'])
        self.assertIn('station_r03_c20', data['empty_semantics'])
        self.assertIn('station_r04_c16', data['empty_semantics'])

    def test_station_building_block_121_160_is_marked_as_locked_composite(self) -> None:
        manifest_path = Path('/Users/splendour/game-projects/demir-yolcusu/assets/tilemaps/manifest.json')
        data = json.loads(manifest_path.read_text(encoding='utf-8'))

        self.assertIn('station_building_block_121_160', data['composites'])
        block = data['composites']['station_building_block_121_160']
        self.assertEqual(block['type'], 'rc_block_lock')
        self.assertEqual(block['sheet'], 'station')
        self.assertEqual(block['row_range'], [0, 4])
        self.assertEqual(block['col_range'], [24, 31])
        self.assertEqual(block['number_range'], [121, 160])
        self.assertTrue(block['atomic'])

    def test_station_fx_block_161_200_has_pairing_and_animation_semantics(self) -> None:
        manifest_path = Path('/Users/splendour/game-projects/demir-yolcusu/assets/tilemaps/manifest.json')
        data = json.loads(manifest_path.read_text(encoding='utf-8'))

        expected_tile_ids = [
            'flag_segment_top_f01', 'flag_segment_top_f02', 'flag_segment_top_f03',
            'flag_segment_top_f04', 'flag_segment_top_f05', 'flag_segment_top_f06',
            'flag_segment_top_f07',
            'flag_segment_bottom_f01', 'flag_segment_bottom_f02', 'flag_segment_bottom_f03',
            'flag_segment_bottom_f04', 'flag_segment_bottom_f05', 'flag_segment_bottom_f06',
            'flag_segment_bottom_f07',
            'cat_lie_f01', 'cat_lie_f02', 'cat_lie_f03', 'cat_lie_f04', 'cat_lie_f05',
            'cat_lie_f06', 'cat_lie_f07',
            'pigeon_ground_f01', 'pigeon_ground_f02', 'pigeon_ground_f03',
            'pigeon_ground_f04', 'pigeon_ground_f05', 'pigeon_ground_f06', 'pigeon_ground_f07',
            'pigeon_fly_f01', 'pigeon_fly_f02', 'pigeon_fly_f03', 'pigeon_fly_f04',
        ]

        for tile_id in expected_tile_ids:
            tile = data['tiles'][tile_id]
            self.assertIn('semantic', tile, f'missing semantic for {tile_id}')
            self.assertIsInstance(tile['semantic'], str)
            self.assertNotEqual(tile['semantic'].strip(), '')

        self.assertIn('flag_segment_top_162_168', data['animations'])
        self.assertIn('flag_segment_bottom_170_176', data['animations'])
        self.assertIn('cat_lie_178_184', data['animations'])
        self.assertIn('pigeon_ground_186_192', data['animations'])
        self.assertIn('pigeon_fly_194_197', data['animations'])

        self.assertEqual(len(data['animations']['flag_segment_top_162_168']['frames']), 7)
        self.assertEqual(len(data['animations']['flag_segment_bottom_170_176']['frames']), 7)
        self.assertEqual(len(data['animations']['cat_lie_178_184']['frames']), 7)
        self.assertEqual(len(data['animations']['pigeon_ground_186_192']['frames']), 7)
        self.assertEqual(len(data['animations']['pigeon_fly_194_197']['frames']), 4)

        self.assertIn('flag_segment_pair_lock_162_176', data['composites'])
        pair_lock = data['composites']['flag_segment_pair_lock_162_176']
        self.assertEqual(pair_lock['type'], 'vertical_frame_pairs')
        self.assertEqual(len(pair_lock['pairs']), 7)

        self.assertIn('empty_semantics', data)
        self.assertIn('station_r00_c32', data['empty_semantics'])
        self.assertIn('station_r01_c32', data['empty_semantics'])
        self.assertIn('station_r02_c32', data['empty_semantics'])
        self.assertIn('station_r03_c32', data['empty_semantics'])
        self.assertIn('station_r04_c32', data['empty_semantics'])


if __name__ == '__main__':
    unittest.main()
