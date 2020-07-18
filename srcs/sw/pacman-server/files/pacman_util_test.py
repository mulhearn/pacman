#!/usr/bin/python2
'''
A simple program that mimic the basic PACMAN server functionality, useful to
test interfacing with the PACMAN board

'''
import zmq
import time
from pacman_util import *

_echo_server = 'tcp://*:5554'
_cmd_server = 'tcp://*:5555'
_data_server = 'tcp://*:5556'

# set up zmq ports
try:
    ctx = zmq.Context()
    cmd_socket = ctx.socket(zmq.REP)
    data_socket = ctx.socket(zmq.PUB)
    echo_socket = ctx.socket(zmq.PUB)
    socket_opts = [
        (zmq.LINGER,100),
        (zmq.RCVTIMEO,100),
        (zmq.SNDTIMEO,100)
    ]
    for opt in socket_opts:
        cmd_socket.setsockopt(*opt)
        data_socket.setsockopt(*opt)
        echo_socket.setsockopt(*opt)
    cmd_socket.bind(_cmd_server)
    data_socket.bind(_data_server)
    echo_socket.bind(_echo_server)

    last_sent = time.time()
    while True:
        now = time.time()

        try:
            req_msg = cmd_socket.recv()
            print_msg(req_msg)
            rep_msg = format_msg('REPLY',parse_msg(req_msg)[-1])
            cmd_socket.send(rep_msg)
            echo_socket.send(rep_msg)
        except Exception as err:
            if isinstance(err,zmq.error.Again): pass
            else: raise

        if now - last_sent > 1:
            data_msg = format_msg('DATA',[
                ('DATA',1,12345678,0x1020304050607080),
                ('SYNC',0x53,0,12345678),
                ('TRIG',0x01,12345678)
                ])
            data_socket.send(data_msg)
            last_sent = now
except:
    raise
finally:
    data_socket.close()
    cmd_socket.close()
    echo_socket.close()
    ctx.destroy()

