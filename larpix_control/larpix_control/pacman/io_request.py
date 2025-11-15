# larpix_control/pacman/io_interface.py

import time
from larpix_control.pacman.zmq_req import get_req_socket, send_and_receive, request_timeout
from larpix_control import pacman_message as pm
from larpix_control.common.interfaces import io_request_iface
import zmq

class io_request(io_request_iface):
    """
    UART REQ/REP interface to send config packets to a PACMAN channel.
    """
    def __init__(self, endpoint="tcp://127.0.0.1:5555", timeout_ms=2000, pacman=0):
        self.endpoint = endpoint
        self._timeout_ms = timeout_ms
        self.pacman = pacman
        self.sock = get_req_socket(endpoint, timeout_ms=self._timeout_ms)

    def close(self):
        self.sock.close()

    def set_timeout(self, timeout_ms: int):
        """
        Update the timeout for send/receive operations.
        Also updates socket options.
        """
        self._timeout_ms = timeout_ms
        self.sock.setsockopt(zmq.RCVTIMEO, self._timeout_ms)
        self.sock.setsockopt(zmq.SNDTIMEO, self._timeout_ms)

    def send_packets(self, io_chan, packets):
        replies = []
        for pkt in packets:
            msg = pm.pack_msg(
                "REQ",
                [pm.content_data(channel=io_chan, timestamp=int(time.time()), payload=pkt, pacman=self.pacman)],
                timestamp=int(time.time())
            )
            try:
                reply = send_and_receive(self.sock, msg)
            except request_timeout:
                replies.append(None)
                continue
            replies.append(reply)
        return replies

    def send_string(self, s):
        msg = pm.pack_string_msg(s, timestamp=int(time.time()), pacman=self.pacman)
        try:
            reply = send_and_receive(self.sock, msg)
        except request_timeout:
            return None
        return reply
