# test/test_fragment_helpers.py
import unittest

import larpix_control.common as common
import larpix_control.hydra._impl as _hydra

class test_hydra_impl(unittest.TestCase):
    """Tests of hydra/_impl.py functionality"""

    def setUp(self):
        print("")
        self.raw_params = common.dict_from_yaml("config/hydra/parameters.yaml")
        self.raw_hydra = common.dict_from_yaml("config/hydra/simple_branch.yaml")
        _hydra.validate_raw_parameters(self.raw_params)
        self.params = _hydra.parse_raw_parameters(self.raw_params)
        _hydra.validate_raw_network(self.raw_hydra, self.params)
        self.hnet = _hydra.parse_raw_network(self.raw_hydra, self.params)

    def test_aaa_validate(self):
        _hydra.validate_raw_parameters(self.raw_params, verbose=True)
        _hydra.validate_raw_network(self.raw_hydra, self.params, verbose=True)

    def test_bbb_parse(self):
        hnet = _hydra.parse_raw_network(self.raw_hydra, self.params)
        _hydra.print_hydra_table(hnet, self.params)

    def test_ccc_root_chip(self):
        root_chip_id = _hydra.find_root_chip_id(self.hnet)
        print(f"root chip:  {root_chip_id}")
        fpga_port = _hydra.find_fpga_port(self.hnet)
        print(f"fpga:  {fpga_port}")

    def test_ddd_node_tree(self):
        nodes = _hydra.build_node_tree(self.hnet, self.params)
        _hydra.print_node_tree(nodes)
        _hydra.print_hydra_grid_no_connections(nodes)
        _hydra.print_hydra_grid(nodes, self.params)

    def test_ddd_paths(self):
        #coords = _hydra.assign_coordinates(self.hnet, self.params)
        #_hydra.print_hydra_grid_no_connections(coords)
        #_hydra.print_hydra_grid(self.hnet, self.params)
        pass

    def test_eee_examples(self):
        #print("INFO: single chip network")
        #raw_eg = common.dict_from_yaml("config/hydra/single.yaml")
        #_hydra.validate_raw_network(raw_eg, self.params)
        #hnet = _hydra.parse_raw_network(raw_eg, self.params)
        #_hydra.print_hydra_grid(hnet, self.params)
        #print("INFO: pair chip network")
        #raw_eg = common.dict_from_yaml("config/hydra/pair.yaml")
        #_hydra.validate_raw_network(raw_eg, self.params)
        #hnet = _hydra.parse_raw_network(raw_eg, self.params)
        #_hydra.print_hydra_grid(hnet, self.params)
        #print("INFO: column network")
        #raw_eg = common.dict_from_yaml("config/hydra/column.yaml")
        #_hydra.validate_raw_network(raw_eg, self.params)
        #hnet = _hydra.parse_raw_network(raw_eg, self.params)
        #_hydra.print_hydra_grid(hnet, self.params)
        pass

if __name__ == "__main__":
    unittest.main()
