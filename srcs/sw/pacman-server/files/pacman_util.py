#!/usr/bin/python
'''
A lightweight, standalone python script to interface with the pacman servers
See help text for more details::

    python3 pacman_util.py --help

'''
import zmq
import struct
import time
import argparse

ECHO_SERVER = 'tcp://{ip}:5554'
CMD_SERVER = 'tcp://{ip}:5555'
DATA_SERVER = 'tcp://{ip}:5556'

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
            args_string = ' '.join([repr(val) for val in list(args) + kwargs.items()])
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

        # connect to pacman server
        connection = None
        socket = None
        if any([kwargs[key] for key in ('ping','write','read','tx')]):
            connection = CMD_SERVER.format(**kwargs)
            socket = cmd_socket
        elif kwargs['rx']:
            connection = DATA_SERVER.format(**kwargs)
            socket = data_socket
        elif kwargs['listen']:
            connection = ECHO_SERVER.format(**kwargs)
            socket = echo_socket
        print('connect to server @ {}...'.format(connection))
        socket.connect(connection)

        # run routine
        # data server interfacing
        if kwargs['rx'] or kwargs['listen']:
            socket.setsockopt(zmq.SUBSCRIBE, b'')
            max_messages = -1
            if kwargs['rx']: max_messages = kwargs['rx'][0]
            elif kwargs['listen']: max_messages = kwargs['listen'][0]
            msg_counter = 0
            while max_messages < 0 or msg_counter < max_messages:
                msg = socket.recv()
                print_msg(msg)
                msg_counter += 1
                print('message count {}'.format(msg_counter))
            socket.setsockopt(zmq.UNSUBSCRIBE, b'')

        # command server interfacing
        else:
            msg = None

            if kwargs['ping']:
                msg = format_msg('REQUEST',[('PING',)])
            elif kwargs['write']:
                msg = format_msg('REQUEST', [['WRITE']+kwargs['write']])
            elif kwargs['read']:
                msg = format_msg('REQUEST', [['READ']+kwargs['read']+[0]])
            elif kwargs['tx']:
                msg = format_msg('REQUEST', [['DATA'] + [kwargs['tx'][0], 0, kwargs['tx'][-1]]])

            if msg:
                print_msg(msg)
                socket.send(msg)
                reply = socket.recv()
                print_msg(reply)

    except Exception as err:
        # handle timeouts
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
        which action to take via a control flag (one of --ping,
        --write, --read, --tx, --rx, or --listen) followed by the necessary data to
        complete the command, described in more detail below. Data can be
        specified in hex, binary, or base-10.
        ''')
    parser.add_argument('-v','--verbose', action='store_true')
    parser.add_argument('--ip', default='127.0.0.1', help='''
        ip address of PACMAN (default=%(default)s)
        ''')
    parser.add_argument('-t','--timeout', type=_int_parser, default=11, help='''
        timeout in seconds for server response (default=%(default)ss)
        ''')
    parser.add_argument('--ping', action='store_true', help='''
        pings command server and prints response
        ''')
    parser.add_argument('--write', nargs=2, type=_int_parser, default=None, help='''
        write a value to a pacman register, args: <address> <value>
        ''')
    parser.add_argument('--read', nargs=1, type=_int_parser, default=None, help='''
        read a pacman register, args: <address>
        ''')
    parser.add_argument('--tx', nargs=2, type=_int_parser, default=None, help='''
        transmit a larpix message on a uart channel (channel 255 is broadcast),
        args: <channel> <64-bit word>
        ''')
    parser.add_argument('--rx', nargs=1, type=_int_parser, default=None, help='''
        prints data server messages to stdout, args: <n msgs, -1 for no limit>
        ''')
    parser.add_argument('--listen', nargs=1, type=_int_parser, default=None, help='''
        print handled pacman command server messages to stdout, args: <n msgs, -1 for no limit>
        ''')
    args = parser.parse_args()

    _VERBOSE = args.verbose

    if not any([bool(getattr(args,key)) for key in ('rx','ping','write','read','tx','listen')]):
        parser.print_help()
    else:
        main(**vars(args))
