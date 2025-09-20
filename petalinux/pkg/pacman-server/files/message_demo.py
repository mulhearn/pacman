#!/usr/bin/env python3
"""
Stepwise PACMAN message demo
Demonstrates increasing complexity of message types and words.
"""

import time

import pacman_message as pm

def demo():
    ts = int(time.time())
    
    # -----------------------------
    # Step 1: REQ / PING
    # -----------------------------
    print("Step 1: Send REQ/PING")
    content = [pm.content_ping()]
    msg_bytes = pm.pack_msg('REQ', content, ts)
    print("Raw bytes:", msg_bytes.hex())
    header, words = pm.unpack_msg(msg_bytes)
    print("parsed header:  ", pm.parse_header(header))
    print("parsed word:    ", pm.parse_word(words[0]))
    print("header:  ", end="")
    pm.print_header(header)
    print("word:    ", end="")
    pm.print_word(words[0])
    print("")
    
    # -----------------------------
    # Step 2: REP / PING
    # -----------------------------
    print("Step 2: Send REP/PING")
    words = [pm.content_ping()]
    msg_bytes = pm.pack_msg('REP', words, ts)
    print("Raw bytes:", msg_bytes.hex())
    header, words = pm.unpack_msg(msg_bytes)
    print("parsed header:  ", pm.parse_header(header))
    print("parsed word:    ", pm.parse_word(words[0]))
    print("header:  ", end="")
    pm.print_header(header)
    print("word:    ", end="")
    pm.print_word(words[0])
    print("")
    
    # -----------------------------
    # Step 3: REQ / READ
    # -----------------------------
    print("Step 3: Send REQ/READ")
    words = [pm.content_read(addr=0x0010)]  # addr=0x01, placeholder val
    msg_bytes = pm.pack_msg('REQ', words, ts)
    print("Raw bytes:", msg_bytes.hex())
    header, words = pm.unpack_msg(msg_bytes)
    print("parsed header:  ", pm.parse_header(header))
    print("parsed word:    ", pm.parse_word(words[0]))
    print("header:  ", end="")
    pm.print_header(header)
    print("word:    ", end="")
    pm.print_word(words[0])
    print("")

    # -----------------------------
    # Step 4: REP / READ
    # -----------------------------
    print("Step 4: Send REP/READ")
    words = [pm.content_read(addr=0x0010, value=0x1234)]
    msg_bytes = pm.pack_msg('REP', words, ts)
    print("Raw bytes:", msg_bytes.hex())
    header, words = pm.unpack_msg(msg_bytes)
    print("parsed header:  ", pm.parse_header(header))
    print("parsed word:    ", pm.parse_word(words[0]))
    print("header:  ", end="")
    pm.print_header(header)
    print("word:    ", end="")
    pm.print_word(words[0])
    print("")


    # -----------------------------
    # Step 5: REQ / WRITE
    # -----------------------------
    print("Step 5: Send REQ/WRITE")
    words = [pm.content_write(addr=0x0010, value=0xABCD)]  
    msg_bytes = pm.pack_msg('REQ', words, ts)
    print("Raw bytes:", msg_bytes.hex())
    header, words = pm.unpack_msg(msg_bytes)
    print("parsed header:  ", pm.parse_header(header))
    print("parsed word:    ", pm.parse_word(words[0]))
    print("header:  ", end="")
    pm.print_header(header)
    print("word:    ", end="")
    pm.print_word(words[0])
    print("")

    # -----------------------------
    # Step 6: REP / WRITE
    # -----------------------------
    print("Step 6: Send REP/WRITE")
    words = [pm.content_write(addr=0x0010, value=0xABCD, pacman=2)]  
    msg_bytes = pm.pack_msg('REP', words, ts)
    print("Raw bytes:", msg_bytes.hex())
    header, words = pm.unpack_msg(msg_bytes)
    print("parsed header:  ", pm.parse_header(header))
    print("parsed word:    ", pm.parse_word(words[0]))
    print("header:  ", end="")
    pm.print_header(header)
    print("word:    ", end="")
    pm.print_word(words[0])
    print("")
    
    # -----------------------------
    # Step 7: DATA / DATA
    # -----------------------------
    print("Step 7: Send DATA/DATA")    
    words = [pm.content_data(channel=3, timestamp=ts, payload=0x1234ABCD, pacman=2)] 
    msg_bytes = pm.pack_msg('DATA', words, ts)
    print("Raw bytes:", msg_bytes.hex())
    header, words = pm.unpack_msg(msg_bytes)
    print("parsed header:  ", pm.parse_header(header))
    print("parsed word:    ", pm.parse_word(words[0]))
    print("header:  ", end="")
    pm.print_header(header)
    print("word:    ", end="")
    pm.print_word(words[0])
    print("")

    # -----------------------------
    # Step 8: DATA / SYNC
    # -----------------------------
    print("Step 8: Send DATA/SYNC")
    words = [pm.content_sync(sync_type=0x53, timestamp=ts, pacman=2)]
    msg_bytes = pm.pack_msg('DATA', words, ts)
    print("Raw bytes:", msg_bytes.hex())
    header, words = pm.unpack_msg(msg_bytes)
    print("parsed header:  ", pm.parse_header(header))
    print("parsed word:    ", pm.parse_word(words[0]))
    print("header:  ", end="")
    pm.print_header(header)
    print("word:    ", end="")
    pm.print_word(words[0])
    print("")

    # -----------------------------
    # Step 9: DATA / TRIG
    # -----------------------------
    print("Step 9: Send DATA/TRIG")    
    words = [pm.content_trig(trig_type=3, timestamp=ts)]
    msg_bytes = pm.pack_msg('DATA', words, ts)
    print("Raw bytes:", msg_bytes.hex())
    header, words = pm.unpack_msg(msg_bytes)
    print("parsed header:  ", pm.parse_header(header))
    print("parsed word:    ", pm.parse_word(words[0]))
    print("header:  ", end="")
    pm.print_header(header)
    print("word:    ", end="")
    pm.print_word(words[0])
    print("")

    # -----------------------------
    # Step 10: REP / ERR
    # -----------------------------
    print("Step 10: Send REP/ERR")    
    words = [pm.content_err(error=0xEEEE, timestamp=ts)]
    msg_bytes = pm.pack_msg('REP', words, ts)
    print("Raw bytes:", msg_bytes.hex())
    header, words = pm.unpack_msg(msg_bytes)
    print("parsed header:  ", pm.parse_header(header))
    print("parsed word:    ", pm.parse_word(words[0]))
    print("header:  ", end="")
    pm.print_header(header)
    print("word:    ", end="")
    pm.print_word(words[0])
    print("")

    
    
if __name__ == "__main__":
    demo()

