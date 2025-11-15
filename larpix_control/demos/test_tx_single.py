#!/usr/bin/env python3
"""
Minimal test: send one TX REQ message to PACMAN command server.
"""

import sys
import time
from larpix_control.pacman.zmq_req import get_req_socket, send_and_receive, request_timeout
from larpix_control import pacman_message as pm

def main():
    endpoint = "tcp://127.0.0.1:5555"

    try:
        sock = get_req_socket(endpoint, timeout_ms=2000)

        # Example TX parameters
        channel = 1
        payload = 0xAAAABBBBCCCCDDDD
        pacman_id = 0  # usually 0 unless multi-chip setup

        # Create the TX message (REQ)
        tx_msg = pm.pack_msg(
            "REQ",
            [pm.content_data(channel=channel, timestamp=int(time.time()), payload=payload, pacman=pacman_id)],
            timestamp=int(time.time())
        )

        # send and wait for reply
        try:
            reply = send_and_receive(sock, tx_msg)
        except request_timeout:
            print("Timeout: no reply from server")
            sys.exit(1)

        # print raw reply and parsed content
        print("Raw reply:", reply.hex())
        header, words = pm.unpack_msg(reply)
        print("Parsed reply:", header, words)

    finally:
        sock.close()

if __name__ == "__main__":
    main()
