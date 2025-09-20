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
MSG_TYPE_REQ  = b'?'
MSG_TYPE_REP  = b'!'
MSG_TYPE_DATA = b'D'

MSG_TYPE_TABLE = {
    'REQ': MSG_TYPE_REQ,
    'REP': MSG_TYPE_REP,
    'DATA': MSG_TYPE_DATA
}

MSG_TYPE_TABLE_INV = {v:k for k,v in MSG_TYPE_TABLE.items()}

# -----------------------------
# Word type constants
# -----------------------------
WORD_TYPE_PING  = b'P'
WORD_TYPE_READ  = b'R'
WORD_TYPE_WRITE = b'W'
WORD_TYPE_DATA  = b'D'
WORD_TYPE_SYNC  = b'S'
WORD_TYPE_TRIG  = b'T'
WORD_TYPE_ERR   = b'E'

WORD_TYPE_TABLE = {
    'PING':  WORD_TYPE_PING,
    'READ':  WORD_TYPE_READ,    
    'WRITE': WORD_TYPE_WRITE,
    'DATA':  WORD_TYPE_DATA,
    'SYNC':  WORD_TYPE_SYNC,    
    'TRIG':  WORD_TYPE_TRIG,
    'ERR':   WORD_TYPE_ERR
}

WORD_TYPE_TABLE_INV = {v:k for k,v in WORD_TYPE_TABLE.items()}

# ----------------------------------------
# Word struct formats (192-bit / 24 bytes)
# ----------------------------------------

# PING:   0xWW000000 00000000 00000000 00000000 00000000 00000000
#    W=word type
# READ:   0xWWPP0000 00000000 AAAAAAAA RRRRRRRR 00000000 00000000 
#    W=word type, P=PACMAN id, A=address, R=value, S=Status
# WRITE:  0xWWPP0000 00000000 AAAAAAAA RRRRRRRR 00000000 00000000
#    W=word type, P=PACMAN id, A=address, R=value, S=Status
# DATA:   0xWWPPUUUU 00000000 TTTTTTTT TTTTTTTT DDDDDDDD DDDDDDDD
#    W=word type, P=PACMAN id, U=channel, T=timestamp, D=payload
# SYNC:   0xWWPPBBCC 00000000 TTTTTTTT TTTTTTTT SSSSSSSS 00000000
#    W=word type, P=PACMAN id, B=subtype, C=clock source, T=timestamp, S=Status
# TRIG:   0xWWPPBBGG 00000000 TTTTTTTT TTTTTTTT 00000000 00000000
#    W=word type, P=PACMAN id, B=subtype, G=trigger source, T=timestamp
# ERR:    0xWWPP0000 00000000 TTTTTTTT TTTTTTTT EEEEEEEE 00000000
#    W=word type, P=PACMAN id, T=timestamp, E=error code

WORD_LEN   = 24  # 192-bit
WORD_STRUCT_TABLE = {
    'PING':  struct.Struct('<c23x'),       # word_type
    'READ':  struct.Struct('<cB6xII8x'),   # word_type, pacman, address, value
    'WRITE': struct.Struct('<cB6xII8x'),   # word_type, pacman, address, value
    'DATA':  struct.Struct('<cBH4xQQ'),    # word_type, pacman, uart_channel, timestamp, payload
    'SYNC':  struct.Struct('<cBBB4xQI4x'), # word_type, pacman, sync_type, clock_source, timestamp, status  
    'TRIG':  struct.Struct('<cBBB4xQ8x'),  # word_type, pacman, trigger_type, trigger_source, timestamp
    'ERR':   struct.Struct('<cB6xQI4x')    # word_type, pacman, timestamp, error code
}

WORD_FIELD_TABLE = {
    'PING':  ("word_type",),
    'READ':  ("word_type", "pacman", "addr", "value"),
    'WRITE': ("word_type", "pacman", "addr", "value"),
    'DATA':  ("word_type", "pacman", "chan", "timestamp", "payload"),
    'SYNC':  ("word_type", "pacman", "sync_type", "clk_src", "timestamp", "status"),
    'TRIG':  ("word_type", "pacman", "trig_type", "trig_src", "timestamp"),
    'ERR':   ("word_type", "pacman", "timestamp", "error_code")
}

# -----------------------------
# Header struct (192-bit / 24 bytes)
# -----------------------------

# HEADER: 0xMMBBVVVV NNNNNNNN TTTTTTTT TTTTTTTT 00000000 00000000
#    M=messsage type, B=minor version, V=major version, N=number of words, T=timestamp

HEADER_STRUCT = struct.Struct('<cBHIQ8x') # message_type, 
HEADER_FIELDS = ("msg_type", "minor_version", "major_version", "n_words", "timestamp")
HEADER_LEN = HEADER_STRUCT.size

# -----------------------------
# Header functions
# -----------------------------
def pack_header(msg_type, n_words, timestamp):
    msg_type_byte = MSG_TYPE_TABLE[msg_type]
    return HEADER_STRUCT.pack(msg_type_byte, MSG_MINOR_VERSION, MSG_MAJOR_VERSION, n_words, timestamp)

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
    n_words = len(msg_words)
    header_bytes = pack_header(msg_type, n_words, timestamp)
    body_bytes = b''.join([pack_word(*w) for w in msg_words])
    return header_bytes + body_bytes

def unpack_msg(msg_bytes):
    header = unpack_header(msg_bytes[:HEADER_LEN])
    words = []
    for i in range(HEADER_LEN, len(msg_bytes), WORD_LEN):
        words.append(unpack_word(msg_bytes[i:i+WORD_LEN]))
    return header, words

def content_ping():
    return ('PING',)

def content_read(*, addr, value=0, pacman=0):
    return ('READ',  pacman, addr, value)

def content_write(*, addr, value, pacman=0):
    return ('WRITE', pacman, addr, value)

def content_data(*, channel, timestamp, payload, pacman=0):
    return ('DATA', pacman, channel, timestamp, payload)

def content_sync(*, sync_type, timestamp, pacman=0, clock_source=0, status=0):
    return ('SYNC', pacman, sync_type, clock_source, timestamp, status)

def content_trig(*, trig_type, timestamp, pacman=0, trig_source=0):
    return ('TRIG', pacman, trig_type, trig_source, timestamp)

def content_err(*, error,  pacman=0, timestamp=0):
    return ('ERR', pacman, timestamp, error)


def print_header(header):
    parsed = parse_header(header)
    print("msg_type: {msg_type} version: {major_version}.{minor_version} n_words: {n_words} timestamp: {timestamp}".format(**parsed))    
    return

def print_word(word):
    format_strings = {
        "PING": "PING",
        "READ":  "word_type:  READ:  pacman: {pacman:04d} addr: 0x{addr:08x} value=0x{value:08x} ({value})",
        "WRITE": "word_type:  WRITE: pacman: {pacman:04d} addr: 0x{addr:08x} value=0x{value:08x} ({value})",
        "DATA":  "word_type:  DATA:  pacman: {pacman:04d} chan={chan:04d} payload=0x{payload:08X} timestamp={timestamp}",
        "SYNC":  "word_type:  SYNC:  pacman: {pacman:04d} sync_type: {sync_type} timestamp={timestamp}",
        "TRIG":  "word_type:  TRIG:  pacman: {pacman:04d} trig_type: {trig_type} timestamp={timestamp}",
        "ERR":   "word_type:  ERR:   pacman: {pacman:04d} error=0x{error_code:08X} timestamp={timestamp}",
    }    
    fmt = format_strings.get(word[0], "unknown")
    parsed = parse_word(word)
    print(fmt.format(**parsed))
