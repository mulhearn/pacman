#!/usr/bin/python

#
# Simple SUB client that just dumps the contents, just change port as needed (run on localhost)
#

import sys
import zmq
import struct

port = "5567"

context = zmq.Context()
socket = context.socket(zmq.REP)
socket.connect("tcp://127.0.0.1:%s" % port)

count = 0;
while True:
    msg = socket.recv()
    print("message received...")
    count = count + 1
    words = struct.iter_unpack("<L", msg)
    for i,word in enumerate(words):
        print(hex(word[0]), end=" ")
        if (((i+1)%10)==0):
            print("")
    print(" count=", count)
    socket.send(msg)
