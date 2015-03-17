#!/usr/bin/env python

__author__ = 'Copyright (c) 2015 Alan Yorinks All rights reserved.'

"""
Copyright (c) 2015 Alan Yorinks All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU  General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

"""

"""
This example illustrates using polling for digital input, analog input and analog latches.
A switch is used to turn an LED on and off, and a potentiometer sets the intensity of a second LED.
When the potentiometer exceeds a raw value of 1000, the program is terminated.

There are some major problems with PySerial 2.7 running on Python 3.4. Polling should only be used with Python 2.7
"""

import sys
import time
import signal
import mido

from PyMata.pymata import PyMata
from mido import Message

# Bending sensors
BENDX1 = 0
BENDX2 = 1
BENDY1 = 2
BENDY2 = 3

count = 0

# create a PyMata instance
board = PyMata("/dev/cu.usbmodem641", False, False)


def signal_handler(sig, frame):
    print('You pressed Ctrl+C!!!!')
    if board is not None:
        board.reset()
    sys.exit(0)


signal.signal(signal.SIGINT, signal_handler)

# set pin modes
board.set_pin_mode(BENDX1, board.INPUT, board.ANALOG)
board.set_pin_mode(BENDX2, board.INPUT, board.ANALOG)
board.set_pin_mode(BENDY1, board.INPUT, board.ANALOG)
board.set_pin_mode(BENDY2, board.INPUT, board.ANALOG)

# do nothing loop - program exits when latch data event occurs for potentiometer
time.sleep(2)
offset = 0

while 1:
    count += 1
    if count == 100000:
        print('bye bye')
        board.close()
    x1 = board.analog_read(BENDX1)
    x2 = board.analog_read(BENDX2)
    y1 = board.analog_read(BENDY1)
    y2 = board.analog_read(BENDY2)

    if count == 1:
        print("Calculating offset: x: %d y:%d" % (((x1+x2)/2), ((y1+y2)/2)))
        offset = ((x1+x2)/2) - ((y1+y2)/2)

    bend = ((x1+x2)/2) - ((y1+y2)/2) - (offset)
    
    print("Bend: %d x1:%d x2:%d y1:%d y2:%d offset: %d" % (bend, x1, x2, y1, y2, offset))
    

