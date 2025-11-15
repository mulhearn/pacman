#!/usr/bin/env python3
"""
Send a high-level string message to PACMAN using REQ/REP.
"""

import sys
import time
from larpix_control.pacman.zmq_req import get_req_socket, send_and_receive, request_timeout
from larpix_control import pacman_message as pm

def main():
    endpoint = "tcp://127.0.0.1:5555"

    try:
        sock = get_req_socket(endpoint, timeout_ms=2000)

        # the string we want to send
        s = "ping"

        # pack the string message
        string_msg = pm.pack_string_msg(s, timestamp=int(time.time()), pacman=0)

        # send and wait for reply
        try:
            reply = send_and_receive(sock, string_msg)
        except request_timeout:
            print("Timeout: no reply from server")
            sys.exit(1)

        # print raw reply and parsed content
        print("Raw reply:", reply.hex())
        reply_str = pm.unpack_string_msg(reply)
        print("Parsed reply string:", reply_str)

    finally:
        sock.close()


if __name__ == "__main__":
    main()
