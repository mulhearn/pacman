#!/usr/bin/env python3
"""
Minimal test: ping local PACMAN command server using zmq_req.py
"""

import sys
import time
from larpix_control.pacman.zmq_req import get_req_socket, send_and_receive, request_timeout, set_debug
from larpix_control import pacman_message as pm



# optional: enable debug prints
#set_debug(print)

def main():
    endpoint = "tcp://127.0.0.1:5555"

    try:
        sock = get_req_socket(endpoint, timeout_ms=2000)

        # create one-word ping message
        ping_msg = pm.pack_msg("REQ", [pm.content_ping()], timestamp=int(time.time()))

        # send and wait for reply
        try:
            reply = send_and_receive(sock, ping_msg)
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

