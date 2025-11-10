import unittest

from   asic.helpers import dict_from_yaml

from asic import asic_spec, asic_spec_from_yaml
from asic import chip_state
from asic import hydra_strand
from asic import load_fragment_library

verbose = True

class test_asic_model(unittest.TestCase):
    """tests related to asic model structure and verification"""

    def setUp(self):
        self.asic_spec = asic_spec_from_yaml("config/asics/larpix_v3.yaml")
        self.raw_hydra = dict_from_yaml("config/hydra/single.yaml")
        self.fragment_lib = load_fragment_library("config/fragments/library.yaml", "larpix_v3")
        self.strand = hydra_strand(self.asic_spec, self.raw_hydra, self.fragment_lib)
        
    def test_aaa_hydra_strand(self):
        print("")
        self.strand.list_fragments()
        print("INFO: printing grid for hydra strand")
        self.strand.print_grid()
        print("INFO: printing network state")
        self.strand.print_network_state()
        self.strand.reset()
        self.strand.init_root_chip()
        
if __name__ == "__main__":
    unittest.main()
