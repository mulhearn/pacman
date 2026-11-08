#!/usr/bin/env python3
'''
A lightweight, standalone python script to interface with the pacman servers
(using pacman_message.py for the message format)

Usage:
    python3 pacman_util.py --help
'''
import zmq
import time
import argparse
import sys

import pacman_message as pm

_SERVERS = dict(
    ECHO_SERVER = 'tcp://{ip}:5554',
    CMD_SERVER  = 'tcp://{ip}:5555',
    DATA_SERVER = 'tcp://{ip}:5556'
)

# timeout and verbosity are controlled via CLI args
_VERBOSE = False

def format_msg_req_from_words(pm_words):
    """
    pm_words: list of tuples returned by pm.content_* helpers
    Returns packed message bytes (REQ)
    """
    timestamp = int(time.time())
    return pm.pack_msg('REQ', pm_words, timestamp)

def parse_msg(msg_bytes):
    """
    Return (header_tuple, [word_tuples...]) using pacman_message.unpack_msg
    """
    return pm.unpack_msg(msg_bytes)

def log_msg(msg_bytes, log_path, log_data):
    """
    Log read/write (and optionally data) messages to a file in a simple plain-text format.
    Uses pm.unpack_msg to get structured tuples.
    """
    if not log_path:
        return

    header, words = parse_msg(msg_bytes)
    # header[0] is msg_type: 'REQ' or 'REP' or 'DATA'
    is_request = (header[0] == 'REQ')
    with open(log_path, "a") as f:
        if is_request:
            # For request messages, log READ/WRITE commands and optionally DATA
            for w in words:
                if w[0] == 'WRITE':
                    # ('WRITE', pacman, addr, value)
                    _, pacman, addr, value = w
                    f.write(f"WRITE pacman={pacman} addr=0x{addr:08X} value=0x{value:08X}\n")
                elif w[0] == 'READ':
                    # ('READ', pacman, addr, value)
                    _, pacman, addr, value = w
                    f.write(f"READ  pacman={pacman} addr=0x{addr:08X}\n")
                elif log_data and w[0] == 'DATA':
                    # ('DATA', pacman, chan, timestamp, payload)
                    _, pacman, chan, timestamp, payload = w
                    f.write(f"DATA  pacman={pacman} chan={chan} timestamp={timestamp} payload=0x{payload:016X}\n")
        elif log_data and header[0] == 'DATA':
            # For data messages (published), log DATA words
            for w in words:
                if w[0] == 'DATA':
                    _, pacman, chan, timestamp, payload = w
                    f.write(f"DATA  pacman={pacman} chan={chan} timestamp={timestamp} payload=0x{payload:016X}\n")

def main(**kwargs):
    global _VERBOSE

    try:
        # create ZMQ context and sockets
        ctx = zmq.Context()
        cmd_socket = ctx.socket(zmq.REQ)
        data_socket = ctx.socket(zmq.SUB)
        echo_socket = ctx.socket(zmq.SUB)

        # set socket options (linger, recv/send timeouts)
        timeout_ms = 1000 * kwargs['timeout'] if kwargs['timeout'] >= 0 else -1
        socket_opts = [
            (zmq.LINGER, 1000),
            (zmq.RCVTIMEO, timeout_ms),
            (zmq.SNDTIMEO, timeout_ms)
        ]
        for opt, val in socket_opts:
            cmd_socket.setsockopt(opt, val)
            data_socket.setsockopt(opt, val)
            echo_socket.setsockopt(opt, val)

        # iterate over CLI-specified commands in sorted order for deterministic behavior
        for command, args in sorted(list(kwargs.items())):
            if not args:
                continue
            # only handle supported commands
            if command not in ('ping','write','read','tx','rx','listen','string'):
                continue

            # choose server/socket
            server = None
            socket = None
            if command in ('ping','write','read','tx','string'):
                server = 'CMD_SERVER'
                socket = cmd_socket
            elif command == 'rx':
                server = 'DATA_SERVER'
                socket = data_socket
            elif command == 'listen':
                server = 'ECHO_SERVER'
                socket = echo_socket

            connection = _SERVERS[server].format(**kwargs)
            if _VERBOSE:
                print(f'connect to {server} @ {connection}...')
            socket.connect(connection)

            # RX / LISTEN modes (subscribe streams)
            if command in ('rx','listen'):
                # args is a list of lists (each inner list is the nargs for the flag)
                for max_messages in args:
                    # max_messages is list-like; earlier CLI used nargs=1 for rx/listen so max_messages[0] is the count
                    nmsg = int(max_messages[0])
                    socket.setsockopt(zmq.SUBSCRIBE, b'')  # subscribe to all topics
                    msg_counter = 0
                    log = kwargs.get('log')
                    log_path = log[0] if log else None
                    if log_path:
                        print("logging read and write requests to", log_path)
                    # if negative, run indefinitely
                    while nmsg < 0 or msg_counter < nmsg:
                        msg = socket.recv()
                        pm.print_msg(msg)
                        log_msg(msg, log_path, kwargs.get('log_data', False))
                        msg_counter += 1
                        if _VERBOSE:
                            print(f'message count {msg_counter}/{nmsg}')
                    socket.setsockopt(zmq.UNSUBSCRIBE, b'')

            # Command server interactions (REQ/REP)
            else:
                msg_bytes = None

                if command == 'ping':
                    # produce one ping per provided flag (args is a list of 'True' entries)
                    # Build one-word messages for each ping requested
                    pm_words = [pm.content_ping() for _ in args]
                    msg_bytes = format_msg_req_from_words(pm_words)

                elif command == 'write':
                    # args is a list of [addr, val] lists
                    pm_words = []
                    for arg in args:
                        addr = int(arg[0])
                        val = int(arg[1])
                        pm_words.append(pm.content_write(addr=addr, value=val, pacman=0))
                    msg_bytes = format_msg_req_from_words(pm_words)

                elif command == 'read':
                    # args is a list of [addr] lists
                    pm_words = []
                    for arg in args:
                        addr = int(arg[0])
                        pm_words.append(pm.content_read(addr=addr, value=0, pacman=0))
                    msg_bytes = format_msg_req_from_words(pm_words)

                elif command == 'tx':
                    # args is a list of [channel, word] lists
                    pm_words = []
                    for arg in args:
                        channel = int(arg[0])
                        payload = int(arg[1])
                        pm_words.append(pm.content_data(channel=channel, timestamp=0, payload=payload, pacman=0))
                    msg_bytes = format_msg_req_from_words(pm_words)

                elif command == 'string':
                    # args is a list of single-element lists; take the first element
                    s = args[0]
                    print("DEBUG: sending string...", s)

                    msg_bytes = pm.pack_string_msg(s, timestamp=int(time.time()), pacman=0)

                if msg_bytes:
                    # print and send the request, then wait for reply
                    pm.print_msg(msg_bytes)
                    socket.send(msg_bytes)
                    reply = socket.recv()
                    pm.print_msg(reply)

            if _VERBOSE:
                print(f'disconnect from {server} @ {connection}...')
            socket.disconnect(connection)

    except Exception as err:
        # handle timeouts / zmq errors gracefully
        print('closing sockets')
        if isinstance(err, zmq.error.Again):
            print('timed out')
        else:
            raise
    finally:
        # cleanup sockets/context
        try:
            echo_socket.close()
            data_socket.close()
            cmd_socket.close()
            ctx.destroy()
        except Exception:
            pass

def _int_parser(s):
    if len(s) >= 2:
        if s[:2] == '0x' or s[:1] == 'x':
            return int(s.split('x')[-1],16)
        elif s[:2] == '0b' or s[:1] == 'b':
            return int(s.split('b')[-1],2)
    return int(s)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='''
        A stand-alone utility script to control the PACMAN. Uses pacman_message.py
        for the 24-byte header / 24-byte word message format. To use, indicate
        which action(s) to take via control flags (one of --ping, --write, --read,
        --tx, --rx, or --listen) followed by the necessary data to complete the command.
        ''')
    parser.add_argument('-v','--verbose', action='store_true')
    parser.add_argument('--ip', default='127.0.0.1',
                        help='ip address of PACMAN (default=%(default)s)')
    parser.add_argument('-t','--timeout', type=_int_parser, default=11,
                        help='timeout in seconds for server response (default=%(default)ss)')

    parser.add_argument('--ping', action='append_const', const=True,
                        help='pings command server and prints response')
    parser.add_argument('--write', nargs=2, type=_int_parser,
                        action='append', metavar=('ADDR','VAL'),
                        help='write a value to a pacman register')
    parser.add_argument('--read', nargs=1, type=_int_parser,
                        action='append', metavar=('ADDR'),
                        help='read a pacman register')
    parser.add_argument('--tx', nargs=2, type=_int_parser,
                        action='append', metavar=('CHANNEL','WORD'),
                        help=('transmit a larpix message on a uart channel '
                              '(channel 255 is broadcast, channel 0 is not used)'))
    parser.add_argument('--rx', nargs=1, type=_int_parser,
                        action='append', metavar=('N'),
                        help='prints data server messages to stdout, for N negative, runs indefinitely')
    parser.add_argument('--listen', nargs=1, type=_int_parser,
                        action='append', metavar=('N'),
                        help='print handled pacman command server messages to stdout, for N negative, runs indefinitely')
    parser.add_argument('--log', nargs=1, metavar=('LOGFILE'),
                        help='log read and write requests to LOGFILE')
    parser.add_argument('--log_data', action='store_true',
                        help='include TX/RX in LOGFILE')
    parser.add_argument('--string', nargs=1, type=str,
                        help='send a variable-length string to the PACMAN command server')

    args = parser.parse_args()

    _VERBOSE = args.verbose

    # ensure at least one action
    if not any([bool(getattr(args,key)) for key in ('string','rx','ping','write','read','tx','listen')]):
        parser.print_help()
        sys.exit(0)
    else:
        main(**vars(args))
