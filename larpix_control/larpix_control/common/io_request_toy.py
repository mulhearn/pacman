# larpix_control/pacman/io_request_toy.py

import time
from larpix_control.common.interfaces import io_request_iface
from larpix_control import pacman_message as pm

class io_request_toy(io_request_iface):
    """
    Toy/mock implementation of io_request_interface.
    Prints all messages instead of sending them.
    Returns empty list or None as replies.
    Timeout setter is a no-op.
    """

    def __init__(self, pacman=0):
        self.pacman = pacman
        self._timeout_ms = 0  # dummy value

    def set_timeout(self, timeout_ms: int):
        # no-op for toy
        pass

    def send_packets(self, io_chan, packets):
        for pkt in packets:
            msg = pm.pack_msg(
                "REQ",
                [pm.content_data(channel=io_chan, timestamp=int(time.time()), payload=pkt, pacman=self.pacman)],
                timestamp=int(time.time())
            )
            print(f"[TOY] Would send packet to channel {io_chan}: {msg.hex()}")
        # toy returns empty list of replies
        return []

    def send_string(self, s):
        msg = pm.pack_string_msg(s, timestamp=int(time.time()), pacman=self.pacman)
        print(f"[TOY] Would send string: {s!r}, packed: {msg.hex()}")
        return None
