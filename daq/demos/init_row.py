#!/usr/bin/env python3
import sys
from pathlib import Path

# Add project root (one level up from daq/) to sys.path
sys.path.append(str(Path(__file__).resolve().parents[1]))

from   asic.helpers import dict_from_yaml

from asic import asic_spec, asic_spec_from_yaml
from asic import chip_state
from asic import hydra_strand
from asic import load_fragment_library

verbose = True

def main():
        spec = asic_spec_from_yaml("config/asics/larpix_v3.yaml")
        raw_hydra = dict_from_yaml("config/hydra/row.yaml")
        fragment_lib = load_fragment_library("config/fragments/library.yaml", "larpix_v3")
        strand = hydra_strand(spec, raw_hydra, fragment_lib)
        
        strand.list_fragments()
        print("INFO: printing grid for hydra strand")
        strand.print_grid()
        print("INFO: printing network state")
        strand.print_network_state()
        strand.reset()
        
        strand.init_root_chip()
        strand.set_routing(strand.root_chip,inputs=[1,3],downstream=[0],upstream=[2])

        strand.init_chip(13)
        strand.set_routing(13,inputs=[1,3],downstream=[0],upstream=[2])

        strand.init_chip(12)
        strand.set_routing(12,inputs=[1,3],downstream=[0],upstream=[2])

        strand.init_chip(11)
        strand.set_routing(11,inputs=[1],downstream=[0],upstream=[])
        
if __name__ == "__main__":
    main()
