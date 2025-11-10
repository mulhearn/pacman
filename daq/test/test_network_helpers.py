# test/test_fragment_helpers.py
import unittest

from   asic.helpers import dict_from_yaml

from   asic.network_helpers import (
    validate_raw_hydra,
    parse_raw_hydra,
    print_hydra_table,
    find_root_chip,
    find_path_to_chip,
    chip_path_to_port_path,
    assign_coordinates,
    print_hydra_grid,
    print_hydra_grid_connected,
)

class test_fragment_helpers(unittest.TestCase):
    """Tests for fragment_helpers.py functionality"""

    def setUp(self):
        print("")
        self.raw_hydra = dict_from_yaml("config/hydra/simple_branch.yaml")
        validate_raw_hydra(self.raw_hydra)
        self.params, self.hydra = parse_raw_hydra(self.raw_hydra)

    def test_aaa_validate(self):
        validate_raw_hydra(self.raw_hydra, verbose=True)

    def test_bbb_parse(self):
        params, hydra = parse_raw_hydra(self.raw_hydra)
        print(hydra)
        print_hydra_table(hydra)

    def test_ccc_paths(self):
        root_chip = find_root_chip(self.hydra)
        print(f"root chip:  {root_chip}")
        path  = find_path_to_chip(self.hydra, 13, 11)
        ports = chip_path_to_port_path(self.hydra, path)
        print(path)
        print(ports)

    def test_ddd_paths(self):
        coords = assign_coordinates(self.hydra, self.params["ports"], self.params["directions"])
        print_hydra_grid(coords)
        print_hydra_grid_connected(self.hydra, self.params)

    def test_eee_examples(self):
        print("INFO: single chip network")
        raw_eg = dict_from_yaml("config/hydra/single.yaml")
        validate_raw_hydra(raw_eg)
        params, hydra = parse_raw_hydra(raw_eg)
        print_hydra_grid_connected(hydra, params)
        print("INFO: pair chip network")
        raw_eg = dict_from_yaml("config/hydra/pair.yaml")
        validate_raw_hydra(raw_eg)
        params, hydra = parse_raw_hydra(raw_eg)
        print_hydra_grid_connected(hydra, params)
        print("INFO: column network")
        raw_eg = dict_from_yaml("config/hydra/column.yaml")
        validate_raw_hydra(raw_eg)
        params, hydra = parse_raw_hydra(raw_eg)
        print_hydra_grid_connected(hydra, params)


if __name__ == "__main__":
    unittest.main()
