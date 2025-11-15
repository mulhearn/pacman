# larpix/common/asic_config_toy.py
"""
Toy implementation of the common.asic_config interface.

This class implements the asic_config ABC without access to hardware.
It is used for independent testing of the hydra package.
"""

from larpix_control import common

class asic_config_toy(common.asic_config_iface):
    """Toy version of asic_config for testing."""

    def __init__(self, verbose = False):
        self.verbose = verbose
        if self.verbose:
            print("INFO: using toy ASIC configuration: no hardware access.")
        pass

    def set_chip_id(self, chip_id) -> None:
        if self.verbose:
            print(f"INFO: set chip id called for {chip_id}")
        pass

    def init_root_chip_io(self, chip_id: int, fpga_port: str) -> None:
        if self.verbose:
            print(f"INFO: init chip {chip_id} (root chip) I/O with FPGA at port {fpga_port}")
        pass

    def init_io(self, chip_id: int) -> None:
        if self.verbose:
            print(f"INFO: init chip {chip_id} I/O")
        pass

    def set_input_enables(self, chip_id: int, ports: list[str]) -> None:
        if self.verbose:
            ports_str = ", ".join(ports)
            print(f"INFO: set input enables for chip {chip_id} to {ports_str}")

    def set_downstream_output_enables(self, chip_id: int, ports: list[str]) -> None:
        if self.verbose:
            ports_str = ", ".join(ports)
            print(f"INFO: set downstream output enables for chip {chip_id} to {ports_str}")

    def set_upstream_output_enables(self, chip_id: int, ports: list[str]) -> None:
        if self.verbose:
            ports_str = ", ".join(ports)
            print(f"INFO: set upstream output enables for chip {chip_id} to {ports_str}")
