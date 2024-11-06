#!/usr/bin/python

#
# Simple PUB server
#

import sys
import zmq
import time
import struct

port = "5567"

context = zmq.Context()
socket  = context.socket(zmq.PUB)
socket.bind ("tcp://*:%s" % port)
#socket.setsockopt(zmq.HWM, 100)
#socket.setsockopt(zmq.LINGER, 1000)
#socket.setsockopt(zmq.SNDTIMEO, args.timeout)

while(1):
    print("DEBUG:  update")
    socket.send(struct.pack("<LLLLL",0xA,0xB,0xC,0xD,0xE))    
    time.sleep(2)
