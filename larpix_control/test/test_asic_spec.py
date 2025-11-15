import unittest

from larpix_control import asic_spec, asic_spec_from_yaml

verbose = False

class test_asic_spec(unittest.TestCase):
    """tests related to asic model structure and verification"""

    def setUp(self):
        print("")
        self.asic_spec = asic_spec_from_yaml("config/asics/larpix_v3.yaml")

    def test_aaa_test_print(self):
        if (verbose):
            self.asic_spec.print_register_map()
            self.asic_spec.print_field_reset_values()
        pass

    def test_bbb_test_write_list(self):
        wl = self.asic_spec.build_config_write_list(11,  update={"r_term":0x3})
        print("wl:  ", wl)
        for w in wl:
            self.asic_spec.print_packet(w)

    def test_ccc_test_read_list(self):
        rl = self.asic_spec.build_config_read_list(11,  refresh=["r_term"])
        print("rl:  ", rl)
        for r in rl:
            self.asic_spec.print_packet(r)



if __name__ == "__main__":
    unittest.main()
