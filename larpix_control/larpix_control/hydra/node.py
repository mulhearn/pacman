#hydra/node.py

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class node:
    """
    Represents a single node in the Hydra network.
    """
    chip_id: Optional[int] = None
    listen_to_me: bool = False
    io_ready: bool = False
    parent_id: Optional[int] = None
    parent_port: Optional[str] = None
    children: dict[int, str] = field(default_factory=dict)
    coordinates: tuple[int, int] = (0, 0)
