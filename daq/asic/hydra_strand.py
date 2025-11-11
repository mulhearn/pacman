# hydra_strand.py

from copy import deepcopy
from typing import Optional
from asic.asic_spec import asic_spec
from asic.chip_state import chip_state, network_state
from asic.fragment_helpers import evaluate_fragment, print_evaluated_fragment, merge_fragments
from asic.network_helpers import parse_raw_hydra, validate_raw_hydra, find_root_chip, find_fpga, print_hydra_grid_connected

def set_reset_state(chip: chip_state, asic: asic_spec):
    """Reset an existing chip_state in place."""
    all_ports_mask = (1 << asic.num_ports()) - 1
    chip.network_state = network_state.reset
    chip.input_mask = all_ports_mask
    chip.upstream_mask = 0
    chip.downstream_mask = 0


class hydra_strand:
    """
    Represents a single Hydra network (strand) attached to one UART.
    Owns the network topology, chip states, and an ASIC specification.
    """

    def __init__(self, spec: asic_spec, network_raw: dict, fragment_lib: dict):
        """
        Initialize the Hydra strand.

        Parameters:
            asic: asic_spec instance for this network (all chips share same ASIC version)
            network_raw: raw Hydra network dictionary (YAML-loaded or parsed)
        """
        self.spec = spec

        # deep copy the network so we own it
        self.network_raw = deepcopy(network_raw)

        # validate and parse network
        validate_raw_hydra(self.network_raw)
        self.params, self.network_dict = parse_raw_hydra(self.network_raw)

        # determine root chip
        self.root_chip = find_root_chip(self.network_dict)
        self.fpga      = self.spec.port_index(find_fpga(self.network_dict, self.params["ports"]))

        # allocate chip_state objects
        self.chips = {}
        for chip_id in self.network_dict:
            self.chips[chip_id] = chip_state(chip_id=chip_id)

        # initialize them to reset state
        for chip in self.chips.values():
            set_reset_state(chip, self.spec)

        # store the fragment library:
        self.fragment_lib = fragment_lib
            
        # placeholder for additional initialization
        self.initialized = True

    def tx_list(self, l: [int]):
        for w in l:
            pkt = self.spec.format_packet(w)
            print(f"#TRACE I/O:  0x{w:016X} {pkt}")            
            print(f"./utils/pacman_util.py --tx 1 0x{w:016X}")
                
    def list_fragments(self):
        print("available fragments:")
        for name in self.fragment_lib:
            print(f"  {name}")
        
    def print_grid(self):
        print_hydra_grid_connected(self.network_dict, self.params)
        print(f"root_chip:  {self.root_chip}")
        
    def print_network_state(self):
        print(f"root chip id:     {self.root_chip}")
        print(f"fpga port index:  {self.fpga}")
        for chip_id in self.chips:
            print(f"chip:  {chip_id}  {self.chips[chip_id].network_state}")

    def reset(self):
        print("INFO: sending full reset.")
        for chip in self.chips.values():
            set_reset_state(chip, self.spec)

    def set_chip_id(self, chip: int):
        print(f"INFO: initializing new chip with chip_id {chip}")
        external = {
            "chip_id": chip
        }
        evaluated = evaluate_fragment(self.fragment_lib["set_chip_id"], external, verbose=True)
        print_evaluated_fragment(evaluated)
        # chip_id is 1 after reset:
        wl = self.spec.build_config_write_list(1,update=evaluated)
        self.tx_list(wl)

            
    def init_io_chip(self, chip: int):
        init_rx = self.fragment_lib["init_rx"];
        init_tx = self.fragment_lib["init_tx"];    
        rxtx = merge_fragments([init_rx, init_tx])
        
        evaluated = evaluate_fragment(rxtx, [], verbose=True)            
        print_evaluated_fragment(evaluated)

        wl = self.spec.build_config_write_list(chip, update=evaluated)
        self.tx_list(wl)
            
    def set_routing(self, chip: int, inputs: list, upstream: list, downstream: list):
        external = {
            "input": inputs,
            "upstream": upstream,
            "downstream": downstream,
        }
        
        set_input      = self.fragment_lib["set_input"]
        set_downstream = self.fragment_lib["set_downstream"]    
        set_upstream   = self.fragment_lib["set_upstream"]    
        merged = merge_fragments([set_input, set_downstream, set_upstream])
        evaluated = evaluate_fragment(merged, external, verbose=True)      
        print_evaluated_fragment(evaluated)
        
        wl = self.spec.build_config_write_list(chip, update=evaluated)
        self.tx_list(wl)
            
    def init_root_chip(self):
        print(f"INFO: initializing root chip with chip_id {self.root_chip}")
        self.set_chip_id(self.root_chip)
        
        external = {
            "fpga": [self.fpga]
        }
        evaluated = evaluate_fragment(self.fragment_lib["init_rx_root_chip"], external, verbose=True)
        print("INFO:  evaluated init_rx_root_chip fragment:")
        print_evaluated_fragment(evaluated)
        
        wl = self.spec.build_config_write_list(self.root_chip, update=evaluated)
        self.tx_list(wl)

        self.init_io_chip(self.root_chip)
        

    def init_chip(self, chip: int):
        print(f"INFO: initializing chip with chip_id {chip}")
        self.set_chip_id(chip)
        self.init_io_chip(chip)

