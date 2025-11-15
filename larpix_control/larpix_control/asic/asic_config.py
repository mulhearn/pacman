# larpix/asic/asic_config.py

from typing import Any
from larpix_control.common.interfaces import asic_config_iface, io_request_iface

from .asic_spec import asic_spec
from . import _fragment as _frag

class asic_config(asic_config_iface):
    """Concrete ASIC configuration class (no-op skeleton).

    Requires an asic_spec instance and a collapsed fragment library
    at initialization.
    """

    def __init__(self, io_req: io_request_iface, spec: asic_spec, frag_lib: dict[str, dict], verbose: bool = False):
        """
        Parameters:
            spec: an instance of asic_spec representing the hardware
            frag_lib: dict of collapsed fragments, keyed by name
            verbose: optional flag for printing progress
        """
        self.io_req = io_req
        self.spec = spec
        self.frag_lib = frag_lib
        self.verbose = verbose

        if verbose:
            spec_name = spec.name()
            print(f"asic_config initialized with spec {spec_name} and {len(frag_lib)} fragments")

    # hack for TX during development:
    def tx_list(self, l: [int]):
        self.io_req.send_packets(1, l)
        for w in l:
            pkt = self.spec.format_packet(w)
            print(f"#TRACE I/O:  0x{w:016X} {pkt}")
            #print(f"./utils/pacman_util.py --tx 1 0x{w:016X}")

    def list_fragments(self):
        print("available fragments:")
        for name in self.frag_lib:
            print(f"  {name}")

    def set_chip_id(self, chip_id: int):
        if self.verbose:
            print(f"INFO: initializing new chip with chip_id {chip_id}")
        external = { "chip_id": chip_id }
        evaluated = _frag.evaluate_collapsed(self.frag_lib["set_chip_id"], external, verbose=self.verbose)
        if self.verbose:
            _frag.print_evaluated(evaluated)
        #chip_id is 1 after reset:
        wl = self.spec.build_config_write_list(1,update=evaluated)
        self.tx_list(wl)

    def init_root_chip_io(self, chip_id: int, fpga_port: str) -> None:
        if self.verbose:
            print(f"init_root_chip_io called with chip_id={chip_id}, fpga_port={fpga_port}")
        fpga = self.spec.input_index(fpga_port)
        external = { "fpga": [fpga] }
        evaluated = _frag.evaluate_collapsed(self.frag_lib["init_rx_root_chip"], external, verbose=self.verbose)
        if self.verbose:
            print("INFO:  evaluated init_rx_root_chip fragment:")
            _frag.print_evaluated(evaluated)
        wl = self.spec.build_config_write_list(chip_id, update=evaluated)
        self.tx_list(wl)
        self.init_io(chip_id)

    def init_io(self, chip_id: int) -> None:
        if self.verbose:
            print(f"init_io called with chip_id={chip_id}")
        init_rx = self.frag_lib["init_rx"];
        init_tx = self.frag_lib["init_tx"];
        rxtx = _frag.merge_fragments([init_rx, init_tx])
        evaluated = _frag.evaluate_collapsed(rxtx, [], verbose=self.verbose)
        if self.verbose:
            _frag.print_evaluated(evaluated)
        wl = self.spec.build_config_write_list(chip_id, update=evaluated)
        self.tx_list(wl)

    def set_input_enables(self, chip_id: int, ports: list[str]) -> None:
        port_idxs = self.spec.input_indices(ports)
        if self.verbose:
            print(f"set_input_enables called with chip_id={chip_id}, ports={ports}")
            print(f"   port indices: {port_idxs}")
        frag = self.frag_lib["set_input"]
        external = { "input": port_idxs }
        evaluated = _frag.evaluate_collapsed(frag, external, verbose=self.verbose)
        if self.verbose:
            _frag.print_evaluated(evaluated)
        wl = self.spec.build_config_write_list(chip_id, update=evaluated)
        self.tx_list(wl)

    def set_downstream_output_enables(self, chip_id: int, ports: list[str]) -> None:
        port_idxs = self.spec.output_indices(ports)
        if self.verbose:
            print(f"set_downstream_output_enables called with chip_id={chip_id}, ports={ports}")
            print(f"   port indices: {port_idxs}")
        external = { "downstream": port_idxs }
        frag = self.frag_lib["set_downstream"]
        evaluated = _frag.evaluate_collapsed(frag, external, verbose=self.verbose)
        if self.verbose:
            _frag.print_evaluated(evaluated)
        wl = self.spec.build_config_write_list(chip_id, update=evaluated)
        self.tx_list(wl)

    def set_upstream_output_enables(self, chip_id: int, ports: list[str]) -> None:
        port_idxs = self.spec.output_indices(ports)
        if self.verbose:
            print(f"set_upstream_output_enables called with chip_id={chip_id}, ports={ports}")
            print(f"   port indices: {port_idxs}")
        external = { "upstream": port_idxs }
        frag = self.frag_lib["set_upstream"]
        evaluated = _frag.evaluate_collapsed(frag, external, verbose=self.verbose)
        if self.verbose:
            _frag.print_evaluated(evaluated)
        wl = self.spec.build_config_write_list(chip_id, update=evaluated)
        self.tx_list(wl)
