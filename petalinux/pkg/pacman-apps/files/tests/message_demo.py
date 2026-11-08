#!/usr/bin/env python3
"""
Stepwise PACMAN message demo
Demonstrates increasing complexity of message types and words.
"""

import time

import pacman_message as pm

def test_message(msg_bytes):
    print(f"INFO:  raw bytes:  0x{msg_bytes[::-1].hex()}")
    if (pm.check_msg(msg_bytes)):
        print("INFO:  message passes consistency checks.")
        header, words = pm.unpack_msg(msg_bytes)
        print("INFO:  parsed header:  ", pm.parse_header(header))
        print("INFO:  parsed word:    ", pm.parse_word(words[0]))
        print("INFO:  header:  ", end="")
        pm.print_header(header)
        print("INFO:  word:    ", end="")
        pm.print_word(words[0])
    else:
        print("ERROR: messages fails consistency checks.")
    print("")

def demo():
    ts = int(time.time())

    # -----------------------------
    # Step 1: REQ / PING
    # -----------------------------
    print("INFO:  Step 1: send REQ/PING")
    content = [pm.content_ping()]
    msg_bytes = pm.pack_msg('REQ', content, ts)
    test_message(msg_bytes)


    # -----------------------------
    # Step 2: REQ / READ
    # -----------------------------
    print("Step 2: Send REQ/READ")
    words = [pm.content_read(addr=0x0010)]  # addr=0x01, placeholder val
    msg_bytes = pm.pack_msg('REQ', words, ts)
    test_message(msg_bytes)

    # -----------------------------
    # Step 3: REP / READ
    # -----------------------------
    print("Step 3: Send REP/READ")
    words = [pm.content_read(addr=0x0010, value=0x1234)]
    msg_bytes = pm.pack_msg('REP', words, ts)
    test_message(msg_bytes)

    # -----------------------------
    # Step 4: REQ / WRITE
    # -----------------------------
    print("Step 4: Send REQ/WRITE")
    words = [pm.content_write(addr=0x0010, value=0xABCD)]
    msg_bytes = pm.pack_msg('REQ', words, ts)
    test_message(msg_bytes)

    # -----------------------------
    # Step 5: REP / WRITE
    # -----------------------------
    print("Step 5: Send REP/WRITE")
    words = [pm.content_write(addr=0x0010, value=0xABCD, pacman=2)]
    msg_bytes = pm.pack_msg('REP', words, ts)
    test_message(msg_bytes)

    # -----------------------------
    # Step 6: DATA / DATA
    # -----------------------------
    print("Step 6: Send DATA/DATA")
    words = [pm.content_data(channel=3, timestamp=ts, payload=0x1234ABCD, pacman=2)]
    msg_bytes = pm.pack_msg('DATA', words, ts)
    test_message(msg_bytes)

    # -----------------------------
    # Step 7: DATA / CFG
    # -----------------------------
    print("Step 7: Send DATA/CFG")
    words = [pm.content_cfg(channel=3, timestamp=ts, payload=0x1234ABCD, pacman=2)]
    msg_bytes = pm.pack_msg('DATA', words, ts)
    test_message(msg_bytes)

    # -----------------------------
    # Step 8: DATA / SYNC
    # -----------------------------
    print("Step 8: Send DATA/SYNC")
    words = [pm.content_sync(sync_type=0x53, timestamp=ts, pacman=2)]
    msg_bytes = pm.pack_msg('DATA', words, ts)
    test_message(msg_bytes)

    # -----------------------------
    # Step 9: DATA / TRIG
    # -----------------------------
    print("Step 9: Send DATA/TRIG")
    words = [pm.content_trig(trig_type=3, timestamp=ts)]
    msg_bytes = pm.pack_msg('DATA', words, ts)
    test_message(msg_bytes)

    # -----------------------------
    # Step 10: REP / ERR
    # -----------------------------
    print("Step 10: Send REP/ERR")
    words = [pm.content_err(error_code=0xEEEE, timestamp=ts)]
    msg_bytes = pm.pack_msg('REP', words, ts)
    test_message(msg_bytes)

    # -----------------------------
    # Step 11: STRING message
    # -----------------------------
    print("Step 11: Send STRING message")
    test_str = "Hello PACMAN!"
    msg_bytes = pm.pack_string_msg(test_str, timestamp=ts, pacman=1)

    pm.print_msg(msg_bytes)

    # check message type
    if pm.is_string_msg(msg_bytes):
        print("INFO: detected STRING message type")
        header, s = pm.unpack_string_msg(msg_bytes)
        print("INFO:  parsed header: ", pm.parse_header(header))
        print("INFO:  unpacked string: ", s)
    else:
        print("ERROR: failed to detect STRING message type")
    print("")

    # cause some intentional failures:
    # print("DEBUG: intentional failures follow:")
    # test_message(msg_bytes[0:24])
    # msg_bytes_corrupt = b'X' + msg_bytes[1:]
    # test_message(msg_bytes_corrupt)
    # msg_bytes_corrupt = msg_bytes[:24] + b'X' + msg_bytes[25:]
    # test_message(msg_bytes_corrupt)


if __name__ == "__main__":
    demo()

