import unittest

from larpix_control import asic_spec, asic_spec_from_yaml, fragment_lib_from_yaml, asic_config
from larpix_control.common.io_request_toy import io_request_toy

verbose = False

class test_asic_config(unittest.TestCase):
    """tests related to asic model structure and verification"""

    def setUp(self):
        print("")
        self.asic_spec = asic_spec_from_yaml("config/asics/larpix_v3.yaml")
        self.frag_lib = fragment_lib_from_yaml("config/fragments/library.yaml", "larpix_v3")
        self.cfg = asic_config(io_request_toy(), self.asic_spec, self.frag_lib, verbose=True)

    def test_aaa_test_list(self):
        print("")
        self.cfg.list_fragments();

    def test_bbb_test_interface(self):
        print("")
        self.cfg.set_chip_id(11)
        self.cfg.init_root_chip_io(11, "w")
        self.cfg.init_io(12)
        self.cfg.set_input_enables(12, ["w", "e"])
        self.cfg.set_downstream_output_enables(12, ["w"])
        self.cfg.set_upstream_output_enables(11, ["e"])

if __name__ == "__main__":
    unittest.main()
