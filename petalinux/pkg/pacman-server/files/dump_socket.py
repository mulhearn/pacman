#!/usr/bin/python

#
# Simple SUB client that just dumps the contents, just change port as needed (run on localhost)
#

import sys
import zmq
import struct

port = "5554"

context = zmq.Context()
socket = context.socket(zmq.SUB)
socket.connect ("tcp://127.0.0.1:%s" % port)
socket.setsockopt(zmq.SUBSCRIBE, b'')

count = 0;
while True:
    msg = socket.recv()
    count = count + 1
    words = struct.iter_unpack("<L", msg)
    for i,word in enumerate(words):
        print(hex(word[0]), end=" ")
        if (((i+1)%10)==0):
            print("")
    print(" count=", count)
