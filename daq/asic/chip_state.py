from enum import Enum, auto
from dataclasses import dataclass
from typing import Optional

class network_state(Enum):
    undefined = auto()
    reset = auto()
    chip_id_valid = auto()
    io_valid = auto()

@dataclass
class chip_state:
    """
    Represents the configuration and I/O state of a single ASIC.

    Direction convention:
        - Downstream = toward FPGA (data egress)
        - Upstream   = away from FPGA (data ingress / config path)
    """

    chip_id: Optional[int] = None
    network_state: network_state = network_state.undefined

    input_mask: int = 0x0
    upstream_mask: int = 0x0
    downstream_mask: int = 0x0
    
