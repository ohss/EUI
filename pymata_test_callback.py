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

# index to retrieve data from an analog or digital callback list
DATA_VALUE = 2

# indices for data list passed to latch callback
LATCH_TYPE = 0
LATCH_PIN = 1
LATCH_DATA_VALUE = 2
LATCH_TIME_STAMP = 3

# Bending sensors
BENDX1 = 0
BENDX2 = 1
BENDY1 = 2
BENDY2 = 3

# Notes
NOTE1 = 4

# Bending sensor callback
def cb_bend(data):
    print("Bend callback: %d" % data[DATA_VALUE] )
    #x1 = data[DATA_VALUE]
    #x2 = board.analog_read(BENDX2)
    #y1 = board.analog_read(BENDY1)
    #y2 = board.analog_read(BENDY2)
    #bend = ((x1+x2)/2) - ((y1+y2)/2) - (offset)
    #print("Bend: %d x1:%d x2:%d y1:%d y2:%d offset: %d" % (bend, x1, x2, y1, y2, offset))
    
def cb_note(data):
    # print all data from the latch callback including time stamp
    print('Latching Event Mode:%x  Pin:%d  Data Value:%d Time of Event:%s' % (data[LATCH_TYPE], data[LATCH_PIN], data[LATCH_DATA_VALUE], time.asctime(time.gmtime(data[LATCH_TIME_STAMP]))))
    
# create a PyMata instance
board = PyMata("/dev/cu.usbmodem641", True, False)

# Interrupt handler
def signal_handler(sig, frame):
    print('You pressed Ctrl+C!!!!')
    if board is not None:
        board.reset()
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

# set pin modes
board.set_pin_mode(BENDX1, board.INPUT, board.ANALOG, cb_bend)
#board.set_pin_mode(BENDX2, board.INPUT, board.ANALOG)
#board.set_pin_mode(BENDY1, board.INPUT, board.ANALOG)
#board.set_pin_mode(BENDY2, board.INPUT, board.ANALOG)
#board.set_analog_latch(NOTE1, board.ANALOG_LATCH_GTE, 512, cb_note)

# set sampling interval
board.set_sampling_interval(33)

# do nothing loop - program exits when latch data event occurs for potentiometer
offset = 0
outport = mido.open_output()
note_on = False

# do nothing loop - program exits when latch data event occurs for potentiometer or timer expires
time.sleep(150)
print('Timer expired')
board.close()
