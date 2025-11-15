#!/usr/bin/env python3
import sys
from pathlib import Path

from larpix_control import hydra_strand, common

from larpix_control.hydra.asic_config_toy import asic_config_toy

verbose = True

def main():
        toy = asic_config_toy(verbose=True)
        raw_network = common.dict_from_yaml("config/hydra/row.yaml")
        raw_params  = common.dict_from_yaml("config/hydra/parameters.yaml")
        strand = hydra_strand(raw_network, raw_params, toy)

        print("INFO: printing table for hydra strand")
        strand.print_hydra_table()

        print("INFO: printing grid for hydra strand")
        strand.print_hydra_grid()
        print("INFO: printing network state")
        strand.print_network_state()
        strand.reset()

        strand.init_network()
        strand.print_network_state()

if __name__ == "__main__":
    main()
