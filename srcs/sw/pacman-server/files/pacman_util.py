#!/usr/bin/python2
'''
A lightweight, standalone python script to interface with the pacman servers
See help text for more details::

    python2 pacman_util.py --help

'''
import zmq
import struct
import time
import argparse
import sys

_SERVERS = dict(
    ECHO_SERVER = 'tcp://{ip}:5554',
    CMD_SERVER = 'tcp://{ip}:5555',
    DATA_SERVER = 'tcp://{ip}:5556'
    )

HEADER_LEN = 8
WORD_LEN = 16

MSG_TYPE = {
    'DATA': b'D',
    'REQUEST': b'?',
    'REPLY': b'!'
}
MSG_TYPE_INV = dict([(val, key) for key,val in MSG_TYPE.items()])

WORD_TYPE = {
    'DATA': b'D',
    'TRIG': b'T',
    'SYNC': b'S',
    'PING': b'P',
    'WRITE': b'W',
    'READ': b'R',
    'ERROR': b'E'
}
WORD_TYPE_INV = dict([(val, key) for key,val in WORD_TYPE.items()])

_VERBOSE = False

_msg_header_fmt = '<cLxH'
_msg_header_struct = struct.Struct(_msg_header_fmt)

_word_fmt = {
    'DATA': '<cBLxxQ',
    'TRIG': '<cBxxL8x',
    'SYNC': '<c2BxL8x',
    'PING': '<c15x',
    'WRITE': '<c3xL4xL',
    'READ': '<c3xL4xL',
    'ERROR': '<cB14s'
}
_word_struct = dict([
    (key, struct.Struct(fmt))
    for key,fmt in _word_fmt.items()
])

_depth = 0
def _verbose(func):
    def verbose_func(*args, **kwargs):
        global _depth, _VERBOSE
        ws = '\t'*_depth
        if _VERBOSE:
            print(ws+'call: '+repr(func.__name__))
            args_string = ' '.join([repr(val) for val in list(args) + list(kwargs.items())])
            print(ws+'args: '+args_string)
        _depth += 1
        rv = func(*args, **kwargs)
        _depth -= 1
        if _VERBOSE:
            print(ws+'return: '+repr(rv))
        return rv
    return verbose_func

@_verbose
def format_header(msg_type, msg_words):
    return _msg_header_struct.pack(MSG_TYPE[msg_type], int(time.time()), msg_words)

@_verbose
def format_word(word_type, *data):
    return _word_struct[word_type].pack(WORD_TYPE[word_type],*data)

@_verbose
def parse_header(header):
    data = _msg_header_struct.unpack(header)
    return (MSG_TYPE_INV[data[0]],) + tuple(data[1:])

@_verbose
def parse_word(word):
    word_type = WORD_TYPE_INV[word[0:1]]
    data = _word_struct[word_type].unpack(word)
    return (word_type,) + tuple(data[1:])

@_verbose
def format_msg(msg_type, msg_words):
    msg_bytes = format_header(msg_type, len(msg_words))
    for msg_word in msg_words:
        msg_bytes += format_word(*msg_word)
    return msg_bytes

@_verbose
def parse_msg(msg):
    header = parse_header(msg[:HEADER_LEN])
    words = [
        parse_word(msg[i:i+WORD_LEN])
        for i in range(HEADER_LEN,len(msg),WORD_LEN)
    ]
    return header, words

def print_msg(msg):
    header, words = parse_msg(msg)
    header_strings, word_strings = list(), list()
    header_strings.extend(header)
    for word in words:
        word_string = list()
        if word[0] == 'DATA':
            word_string.extend(word[:3])
            word_string.append(hex(word[3]))
        elif word[0] in ('TRIG', 'SYNC'):
            word_string.append(word[0])
            word_string.append(repr(word[1]))
            word_string.extend(word[2:])
        elif word[0] in ('WRITE', 'READ'):
            word_string.append(word[0])
            word_string.append(hex(word[1]))
            word_string.append(hex(word[2]))
        elif word[0] in ('PING','ERROR'):
            word_string.extend(word)
        word_strings.append(word_string)
    print(' | '.join([repr(val) for val in header_strings]) + '\n\t'
        + '\n\t'.join([' | '.join([repr(val) for val in word_string])for word_string in word_strings]))

@_verbose
def main(**kwargs):
    try:
        # create ZMQ context and sockets
        ctx = zmq.Context()
        cmd_socket = ctx.socket(zmq.REQ)
        data_socket = ctx.socket(zmq.SUB)
        echo_socket = ctx.socket(zmq.SUB)
        socket_opts = [
            (zmq.LINGER, 1000),
            (zmq.RCVTIMEO, 1000*kwargs['timeout'] if kwargs['timeout'] >= 0 else -1),
            (zmq.SNDTIMEO, 1000*kwargs['timeout'] if kwargs['timeout'] >= 0 else -1)
        ]
        for opt in socket_opts:
            cmd_socket.setsockopt(*opt)
            data_socket.setsockopt(*opt)
            echo_socket.setsockopt(*opt)

        for command,args in sorted(list(kwargs.items())):
            if not args: continue
            if not command in ('ping','write','read','tx', 'rx', 'listen'): continue
            
            # connect to pacman server
            connection = None
            socket = None
            server = None
            if command in ('ping','write','read','tx'):
                server = 'CMD_SERVER'
                socket = cmd_socket
            elif command == 'rx':
                server = 'DATA_SERVER'
                socket = data_socket
            elif command == 'listen':
                server = 'ECHO_SERVER'
                socket = echo_socket
            connection = _SERVERS[server].format(**kwargs)
            print('connect to {} @ {}...'.format(server, connection))
            socket.connect(connection)

            # run routine
            # data server interfacing
            if command in ('rx','listen'):
                for max_messages in args:
                    socket.setsockopt(zmq.SUBSCRIBE, b'')
                    msg_counter = 0
                    while max_messages[0] < 0 or msg_counter < max_messages[0]:
                        msg = socket.recv()
                        print_msg(msg)
                        msg_counter += 1
                        print('message count {}/{}'.format(msg_counter, max_messages[0]))
                    socket.setsockopt(zmq.UNSUBSCRIBE, b'')

            # command server interfacing
            else:
                msg = None

                if command == 'ping':
                    msg = format_msg('REQUEST',[['PING'] for arg in args])
                elif command == 'write':
                    msg = format_msg('REQUEST', [['WRITE'] + arg for arg in args])
                elif command == 'read':
                    msg = format_msg('REQUEST', [['READ', arg[0], 0] for arg in args])
                elif command == 'tx':
                    msg = format_msg('REQUEST', [['DATA', arg[0], 0, arg[-1]] for arg in args])

                if msg:
                    print_msg(msg)
                    socket.send(msg)
                    reply = socket.recv()
                    print_msg(reply)

            print('disconnect from {} @ {}...'.format(server, connection))
            socket.disconnect(connection)

    except Exception as err:
        # handle timeouts
        print('closing sockets')
        if isinstance(err,zmq.error.Again):
            print('timed out')
        else:
            raise
    finally:
        # cleanup
        echo_socket.close()
        data_socket.close()
        cmd_socket.close()
        ctx.destroy()

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
        A stand-alone utility script to control the PACMAN. To use, indicate
        which action(s) to take via by specifying control flags (one of --ping,
        --write, --read, --tx, --rx, or --listen) followed by the necessary data to
        complete the command, described in more detail below. Data can be
        specified in hex, binary, or base-10. Multiple flags can be specified to
        perform an action more than once, e.g. to read from register 0x0 and then 0x1:
        --read 0x0 --read 0x1.
        ''')
    parser.add_argument('-v','--verbose', action='store_true')
    parser.add_argument('--ip', default='127.0.0.1',
                        help='''
                        ip address of PACMAN (default=%(default)s)
                        ''')
    parser.add_argument('-t','--timeout', type=_int_parser, default=11,
                        help='''
                        timeout in seconds for server response (default=%(default)ss)
                        ''')
    
    parser.add_argument('--ping', action='append_const', const=True,
                        help='''
                        pings command server and prints response
                        ''')
    parser.add_argument('--write', nargs=2, type=_int_parser,
                        action='append', metavar=('ADDR','VAL'), help='''
                        write a value to a pacman register
                        ''')
    parser.add_argument('--read', nargs=1, type=_int_parser,
                        action='append', metavar=('ADDR'), help='''
                        read a pacman register
                        ''')
    parser.add_argument('--tx', nargs=2, type=_int_parser,
                        action='append', metavar=('CHANNEL','WORD'), help='''
                        transmit a larpix message on a uart channel (channel 255 is broadcast)
                        ''')
    parser.add_argument('--rx', nargs=1, type=_int_parser,
                        action='append', metavar=('N'), help='''
                        prints data server messages to stdout, for N negative, runs indefinitely
                        ''')
    parser.add_argument('--listen', nargs=1, type=_int_parser,
                        action='append', metavar=('N'), help='''
                        print handled pacman command server messages to stdout, for N negative, runs indefinitely
                        ''')
    args = parser.parse_args()

    _VERBOSE = args.verbose

    if not any([bool(getattr(args,key)) for key in ('rx','ping','write','read','tx','listen')]):
        parser.print_help()
    else:
        main(**vars(args))
