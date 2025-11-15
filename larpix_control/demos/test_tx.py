#!/usr/bin/env python3
"""
Send multiple TX words to PACMAN using REQ/REP.
"""

import sys
import time
from larpix_control.pacman.zmq_req import get_req_socket, send_and_receive, request_timeout
from larpix_control import pacman_message as pm

def main():
    endpoint = "tcp://127.0.0.1:5555"

    try:
        sock = get_req_socket(endpoint, timeout_ms=2000)

        pacman_id = 0
        words_to_send = [
            pm.content_data(channel=1, timestamp=int(time.time()), payload=0x11111111, pacman=pacman_id),
            pm.content_data(channel=2, timestamp=int(time.time()), payload=0x22222222, pacman=pacman_id),
            pm.content_data(channel=3, timestamp=int(time.time()), payload=0x33333333, pacman=pacman_id),
        ]

        tx_msg = pm.pack_msg("REQ", words_to_send, timestamp=int(time.time()))

        try:
            reply = send_and_receive(sock, tx_msg)
        except request_timeout:
            print("Timeout: no reply from server")
            sys.exit(1)

        print("Raw reply:", reply.hex())
        header, words = pm.unpack_msg(reply)
        print("Parsed reply:", header, words)

    finally:
        sock.close()

if __name__ == "__main__":
    main()
