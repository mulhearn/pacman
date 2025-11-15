#!/usr/bin/env python3
import sys
from pathlib import Path

from larpix_control import common, asic_spec, asic_spec_from_yaml, fragment_lib_from_yaml, asic_config, hydra_strand, pacman_io_request

verbose = False

def main():
        asic_spec = asic_spec_from_yaml("config/asics/larpix_v3.yaml")
        frag_lib = fragment_lib_from_yaml("config/fragments/library.yaml", "larpix_v3")
        #raw_network = common.dict_from_yaml("config/hydra/row.yaml")
        raw_network = common.dict_from_yaml("config/hydra/single.yaml")
        #raw_network = common.dict_from_yaml("config/hydra/pair.yaml")
        raw_params  = common.dict_from_yaml("config/hydra/parameters.yaml")
        io_req = pacman_io_request("config/network/single_local.yaml")
        cfg = asic_config(io_req, asic_spec, frag_lib, verbose=verbose)
        strand = hydra_strand(raw_network, raw_params, cfg)

        if verbose:
                print("INFO: printing table for hydra strand")
                strand.print_hydra_table()


        if verbose:
                print("INFO: printing grid for hydra strand")
                strand.print_hydra_table()

        strand.reset()

        if verbose:
                print("INFO: printing network state")
                strand.print_network_state()

        strand.init_network()

        if verbose:
                strand.print_network_state()


if __name__ == "__main__":
    main()
