#!/usr/bin/env python3
"""
PACMAN message packing/unpacking utilities (low-level).
Header: 192-bit (24 bytes)
"""

import struct

# -----------------------------
# Message version
# -----------------------------
MSG_MAJOR_VERSION = 1
MSG_MINOR_VERSION = 0

# -----------------------------
# Message type constants
# -----------------------------
MSG_TYPE_REQ    = b'?'
MSG_TYPE_REP    = b'!'
MSG_TYPE_DATA   = b'D'
MSG_TYPE_STRING = b'S'

MSG_TYPE_TABLE = {
    'REQ': MSG_TYPE_REQ,
    'REP': MSG_TYPE_REP,
    'DATA': MSG_TYPE_DATA,
    'STRING': MSG_TYPE_STRING
}


MSG_TYPE_TABLE_INV = {v:k for k,v in MSG_TYPE_TABLE.items()}

# -----------------------------
# Word type constants
# -----------------------------
WORD_TYPE_PING  = b'P'
WORD_TYPE_READ  = b'R'
WORD_TYPE_WRITE = b'W'
WORD_TYPE_DATA  = b'D'
WORD_TYPE_CFG   = b'C'
WORD_TYPE_SYNC  = b'S'
WORD_TYPE_TRIG  = b'T'
WORD_TYPE_ERR   = b'E'

WORD_TYPE_TABLE = {
    'PING':  WORD_TYPE_PING,
    'READ':  WORD_TYPE_READ,
    'WRITE': WORD_TYPE_WRITE,
    'DATA':  WORD_TYPE_DATA,
    'CFG':   WORD_TYPE_CFG,
    'SYNC':  WORD_TYPE_SYNC,
    'TRIG':  WORD_TYPE_TRIG,
    'ERR':   WORD_TYPE_ERR
}

WORD_TYPE_TABLE_INV = {v:k for k,v in WORD_TYPE_TABLE.items()}

# ----------------------------------------
# Word struct formats (192-bit / 24 bytes)
# ----------------------------------------

# PING:  (MSB) 0x00000000 00000000 00000000 00000000 00000000 0000PPWW (LSB)
#    W=word type P=PACMAN id
# READ:  (MSB) 0x00000000 00000000 RRRRRRRR AAAAAAAA 00000000 0000PPWW (LSB)
#    W=word type, P=PACMAN id, A=address, R=value
# WRITE: (MSB) 0x00000000 00000000 WWWWWWWW AAAAAAAA 00000000 0000PPWW (LSB)
#    W=word type, P=PACMAN id, A=address, W=value
# DATA:  (MSB) 0xDDDDDDDD DDDDDDDD TTTTTTTT TTTTTTTT 00000000 UUUUPPWW (LSB)
#    W=word type, P=PACMAN id, U=channel, T=timestamp, D=payload
# CFG:   (MSB) 0xDDDDDDDD DDDDDDDD TTTTTTTT TTTTTTTT 00000000 UUUUPPWW (LSB)
#    W=word type, U=channel, P=PACMAN id, T=timestamp, D=payload
# SYNC:  (MSB) 0x00000000 SSSSSSSS TTTTTTTT TTTTTTTT 00000000 CCBBPPWW (LSB)
#    W=word type, B=subtype, C=clock source, P=PACMAN id, T=timestamp, S=Status
# TRIG:  (MSB) 0xDDDDDDDD DDDDDDDD TTTTTTTT TTTTTTTT 00000000 GGBBPPWW (LSB)
#    W=word type, B=subtype, G=trig source, P=PACMAN id, T=timestamp, S=Status
# ERR:   (MSB) 0x00000000 EEEEEEEE TTTTTTTT TTTTTTTT 00000000 000PPWW (LSB)
#    W=word type, P=PACMAN id, T=timestamp, E=error code

WORD_BYTES   = 24  # 192-bit
WORD_STRUCT_TABLE = {
    'PING':  struct.Struct('<cB22x'),      # word_type, pacman
    'READ':  struct.Struct('<cB6xII8x'),   # word_type, pacman, address, value
    'WRITE': struct.Struct('<cB6xII8x'),   # word_type, pacman, address, value
    'DATA':  struct.Struct('<cBH4xQQ'),    # word_type, pacman, uart_channel, timestamp, payload
    'CFG':   struct.Struct('<cBH4xQQ'),    # word_type, pacman, uart_channel, timestamp, payload
    'SYNC':  struct.Struct('<cBBB4xQI4x'), # word_type, pacman, sync_type, clock_source, timestamp, status
    'TRIG':  struct.Struct('<cBBB4xQ8x'),  # word_type, pacman, trigger_type, trigger_source, timestamp
    'ERR':   struct.Struct('<cB6xQI4x')    # word_type, pacman, timestamp, error_code
}

WORD_FIELD_TABLE = {
    'PING':  ("word_type", "pacman"),
    'READ':  ("word_type", "pacman", "addr", "value"),
    'WRITE': ("word_type", "pacman", "addr", "value"),
    'DATA':  ("word_type", "pacman", "chan", "timestamp", "payload"),
    'CFG':   ("word_type", "pacman", "chan", "timestamp", "payload"),
    'SYNC':  ("word_type", "pacman", "sync_type", "clk_src", "timestamp", "status"),
    'TRIG':  ("word_type", "pacman", "trig_type", "trig_src", "timestamp"),
    'ERR':   ("word_type", "pacman", "timestamp", "error_code")
}

# -----------------------------
# Header struct (192-bit / 24 bytes)
# -----------------------------

# HEADER: 0xMMAABB00 NNNNNNNN TTTTTTTT TTTTTTTT 00000000 00000000
#    M=messsage type, A=major version, B=minor version, N=number of words, T=timestamp

HEADER_STRUCT = struct.Struct('<cBBBIQ8x') # message_type,
HEADER_FIELDS = ("msg_type", "pacman", "major_version", "minor_version", "n_bytes", "timestamp")
HEADER_LEN = HEADER_STRUCT.size

# -----------------------------
# Header functions
# -----------------------------
def pack_header(msg_type, n_bytes, timestamp, pacman=0):
    msg_type_byte = MSG_TYPE_TABLE[msg_type]
    return HEADER_STRUCT.pack(msg_type_byte, pacman, MSG_MAJOR_VERSION, MSG_MINOR_VERSION, n_bytes, timestamp)

def unpack_header(header_bytes):
    msg_type = MSG_TYPE_TABLE_INV[header_bytes[0:1]]
    values = HEADER_STRUCT.unpack(header_bytes)[1:]
    return (msg_type,) + values

def parse_header(header):
    return dict(zip(HEADER_FIELDS, header))

# -----------------------------
# Word functions
# -----------------------------
def pack_word(word_type, *data):
    word_type_byte = WORD_TYPE_TABLE[word_type]
    return WORD_STRUCT_TABLE[word_type].pack(word_type_byte, *data)

def unpack_word(word_bytes):
    word_type = WORD_TYPE_TABLE_INV[word_bytes[0:1]]
    values = WORD_STRUCT_TABLE[word_type].unpack(word_bytes)[1:]
    return (word_type,) + values

def parse_word(word):
    return dict(zip(WORD_FIELD_TABLE[word[0]], word))

# -----------------------------
# Message functions
# -----------------------------
def pack_msg(msg_type, msg_words, timestamp):
    n_bytes = len(msg_words) * WORD_BYTES
    header_bytes = pack_header(msg_type, n_bytes, timestamp)
    body_bytes = b''.join([pack_word(*w) for w in msg_words])
    return header_bytes + body_bytes


def unpack_msg(msg_bytes):
    header = unpack_header(msg_bytes[:HEADER_LEN])
    words = []
    for i in range(HEADER_LEN, len(msg_bytes), WORD_BYTES):
        words.append(unpack_word(msg_bytes[i:i+WORD_BYTES]))
    return header, words

def check_byte(name, value):
    if not (0 <= value <= 0xFF):
        print(f"ERROR: {name}={value} out of range for 1 byte (0-255)")
        raise ValueError(f"{name}={value} out of range for 1 byte (0-255)")

def check_uint32(name, value):
    if not (0 <= value <= 0xFFFFFFFF):
        print(f"ERROR: {name}={value} out of range for 32-bit unsigned int (0-0xFFFFFFFF)")
        raise ValueError(f"{name}={value} out of range for 32-bit unsigned int (0-0xFFFFFFFF)")

def check_uint64(name, value):
    if not (0 <= value <= 0xFFFFFFFFFFFFFFFF):
        print(f"ERROR: {name}={value} out of range for 64-bit unsigned int (0-0xFFFFFFFFFFFFFFFF)")
        raise ValueError(f"{name}={value} out of range for 64-bit unsigned int (0-0xFFFFFFFFFFFFFFFF)")

def content_ping(*, pacman=0):
    check_byte("pacman", pacman)
    return ('PING', pacman)

def content_read(*, addr, value=0, pacman=0):
    check_byte("pacman", pacman)
    check_uint32("addr", addr)
    check_uint32("value", value)
    return ('READ', pacman, addr, value)

def content_write(*, addr, value, pacman=0):
    check_byte("pacman", pacman)
    check_uint32("addr", addr)
    check_uint32("value", value)
    return ('WRITE', pacman, addr, value)

def content_data(*, channel, timestamp, payload, pacman=0):
    check_byte("pacman", pacman)
    check_byte("channel", channel)
    check_uint64("timestamp", timestamp)
    check_uint64("payload", payload)
    return ('DATA', pacman, channel, timestamp, payload)

def content_cfg(*, channel, timestamp, payload, pacman=0):
    check_byte("pacman", pacman)
    check_byte("channel", channel)
    check_uint64("timestamp", timestamp)
    check_uint64("payload", payload)
    return ('CFG', pacman, channel, timestamp, payload)

def content_sync(*, sync_type, timestamp, pacman=0, clock_source=0, status=0):
    check_byte("pacman", pacman)
    check_byte("sync_type", sync_type)
    check_byte("clock_source", clock_source)
    check_byte("status", status)
    check_uint64("timestamp", timestamp)
    return ('SYNC', pacman, sync_type, clock_source, timestamp, status)

def content_trig(*, trig_type, timestamp, pacman=0, trig_source=0):
    check_byte("pacman", pacman)
    check_byte("trig_type", trig_type)
    check_byte("trig_source", trig_source)
    check_uint64("timestamp", timestamp)
    return ('TRIG', pacman, trig_type, trig_source, timestamp)

def content_err(*, error_code, pacman=0, timestamp=0):
    check_byte("pacman", pacman)
    check_uint32("error_code", error_code)
    check_uint64("timestamp", timestamp)
    return ('ERR', pacman, timestamp, error_code)

def print_header(header):
    parsed = parse_header(header)
    print("msg_type: {msg_type} pacman: {pacman} version: {major_version}.{minor_version} n_bytes: {n_bytes} timestamp: {timestamp}".format(**parsed))
    return

def print_word(word):
    format_strings = {
        "PING": "PING",
        "READ":  "word_type:  READ:  pacman: {pacman:04d} addr: 0x{addr:08X} value: 0x{value:08X} ({value})",
        "WRITE": "word_type:  WRITE: pacman: {pacman:04d} addr: 0x{addr:08X} value: 0x{value:08X} ({value})",
        "DATA":  "word_type:  DATA:  pacman: {pacman:04d} chan: {chan:04d} payload: 0x{payload:08X} timestamp: {timestamp}",
        "CFG":   "word_type:  CFG:   pacman: {pacman:04d} chan: {chan:04d} payload: 0x{payload:08X} timestamp: {timestamp}",
        "SYNC":  "word_type:  SYNC:  pacman: {pacman:04d} sync_type: {sync_type:c} clk_src: {clk_src} timestamp: {timestamp} status: 0x{status:08x}",
        "TRIG":  "word_type:  TRIG:  pacman: {pacman:04d} trig_type: {trig_type} trig_src: {trig_src} timestamp={timestamp}",
        "ERR":   "word_type:  ERR:   pacman: {pacman:04d} error_code=0x{error_code:08X} timestamp={timestamp}",
    }
    fmt = format_strings.get(word[0], "unknown")
    parsed = parse_word(word)
    print(fmt.format(**parsed))

def check_msg(msg_bytes):
    """
    Validate a PACMAN message.

    Returns True if the message is structurally valid, False otherwise.
    Prints debug info and raw hex dumps on errors.
    Always enforces firmware version match.
    """
    try:
        # --- check header length ---
        if len(msg_bytes) < HEADER_LEN:
            raise ValueError(f"message too short: {len(msg_bytes)} bytes, expected at least {HEADER_LEN}")

        # --- raw msg_type check ---
        raw_type = bytes([msg_bytes[0]])
        if raw_type not in MSG_TYPE_TABLE_INV:
            raise ValueError(f"unknown msg_type byte: {raw_type.hex()}")

        # --- unpack header ---
        header = unpack_header(msg_bytes[:HEADER_LEN])
        parsed = parse_header(header)

        n_bytes = parsed["n_bytes"]
        expected_len = HEADER_LEN + n_bytes
        if len(msg_bytes) != expected_len:
            raise ValueError(f"length mismatch: expected {expected_len}, got {len(msg_bytes)}")

        # --- version check (always enforced) ---
        if (parsed["major_version"], parsed["minor_version"]) != (MSG_MAJOR_VERSION, MSG_MINOR_VERSION):
            raise ValueError(
                f"version mismatch: expected {MSG_MAJOR_VERSION}.{MSG_MINOR_VERSION}, "
                f"got {parsed['major_version']}.{parsed['minor_version']}"
            )

    except (struct.error, ValueError, KeyError) as e:
        print(f"ERROR: HEADER: {e}")
        print(f"ERROR: raw header bytes:  0x{msg_bytes[:HEADER_LEN].hex()}")
        return False

    # --- unpack and print words ---
    for i in range(HEADER_LEN, len(msg_bytes), WORD_BYTES):
        chunk = msg_bytes[i:i+WORD_BYTES]
        try:
            # check word type first
            raw_word_type = chunk[0:1]
            if raw_word_type not in WORD_TYPE_TABLE_INV:
                raise ValueError(f"Unknown word_type byte: {raw_word_type.hex()}")

            word = unpack_word(chunk)

        except (struct.error, ValueError, KeyError) as e:
            print(f"ERROR: WORD:  at word {(i - HEADER_LEN)//WORD_BYTES} {e}")
            print(f"ERROR: raw word bytes: 0x{chunk.hex()}")
            return False

    # All checks passed
    return True


# -----------------------------
# String message type
# -----------------------------

# --- check if a message is a variable-length string ---
def is_string_msg(msg_bytes):
    return msg_bytes[0:1] == MSG_TYPE_STRING

# --- pack a single string into a message ---
def pack_string_msg(s, timestamp=0, pacman=0):
    b = s.encode('utf-8')  # convert to bytes
    n_bytes = len(b)
    header_bytes = pack_header('STRING', n_bytes, timestamp, pacman)
    return header_bytes + b

# --- unpack a single string message ---
def unpack_string_msg(msg_bytes):
    header = unpack_header(msg_bytes[:HEADER_LEN])
    n_bytes = header[4]  # header tuple: (msg_type, pacman, major, minor, n_bytes, timestamp)
    s_bytes = msg_bytes[HEADER_LEN:HEADER_LEN + n_bytes]
    s = s_bytes.decode('utf-8')
    return header, s

def print_msg(msg_bytes):
    # Unpack the header first
    header = unpack_header(msg_bytes[:HEADER_LEN])
    print_header(header)

    # Check message type
    msg_type = header[0]
    if msg_type == 'STRING':
        # Extract string payload
        n_bytes = header[4]  # n_bytes field
        s_bytes = msg_bytes[HEADER_LEN:HEADER_LEN + n_bytes]
        s = s_bytes.decode('utf-8', errors='replace')  # replace bad characters
        print(f"string payload: {s}")
    else:
        # Word-based message: iterate over words
        for i in range(HEADER_LEN, len(msg_bytes), WORD_BYTES):
            word_chunk = msg_bytes[i:i+WORD_BYTES]
            word = unpack_word(word_chunk)
            print_word(word)
