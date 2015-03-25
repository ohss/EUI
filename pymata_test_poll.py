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

RATE = 30   # Refresh rate in ms
BENDING_PINS = [0,1,2,3] # Bending sensors pins
NOTE_PINS = [2,3,4,5] # Note pins

# Default scale is C Major: C, D, E, F, G, A, B
# Scales should be at the -1 octave and are transposed
# up by OCTAVE octaves
SCALE = [0, 2, 4, 5, 7, 11]
NOTE_ON = [False, False, False, False, False, False, False, False]
OCTAVE = 3
NOTE_TRESHOLD = 512

offset = 0
count = 0

# create a PyMata instance
board = PyMata("/dev/cu.usbmodem641", False, False)

# Interrupt handler
def signal_handler(sig, frame):
    print('You pressed Ctrl+C!!!!')
    if board is not None:
        board.reset()
    sys.exit(0)


signal.signal(signal.SIGINT, signal_handler)

# set pin modes
#for pin in BENDING_PINS:
#    board.set_pin_mode(pin, board.INPUT, board.ANALOG)

for pin in NOTE_PINS:
    #For Analog input
    #board.set_pin_mode(pin, board.INPUT, board.ANALOG)
    #For Digital input
    board.set_pin_mode(pin, board.INPUT, board.DIGITAL)

# set sampling interval
board.set_sampling_interval(RATE)


# sleep for a while to wait for board initialization
time.sleep(2)
note_on = False

#Initialize mido
out = mido.open_output()

#Calibration
note = board.analog_read(NOTE_PINS[0])
print("NOTE[0]: %i" % note)


def handle_notes_analog():
    #Check all notes
    for idx, pin in enumerate(NOTE_PINS):
        value = board.analog_read(NOTE_PINS[idx])
        note_value = SCALE[idx]+(OCTAVE*12)
        #print("index: %i pin: %i value: %i note: %i" % (idx, NOTE_PINS[idx], value, SCALE[idx]))
        if(value >= NOTE_TRESHOLD and not NOTE_ON[idx]):
            print("NOTE %i ON" % note_value)
            NOTE_ON[idx] = True
            note_msg = Message("note_on", note=note_value, velocity=64)
            out.send(note_msg)
        elif(value < (NOTE_TRESHOLD*0.9) and NOTE_ON[idx]):
            print("NOTE %i OFF"% note_value)
            NOTE_ON[idx] = False
            note_msg = Message("note_off", note=note_value)
            out.send(note_msg)
        elif((value >= NOTE_TRESHOLD) and NOTE_ON[idx]):
            after_value = ((value-512)/4)-1
            print("%i AFTERTOUCH: %i"% (SCALE[idx], after_value))
            after_msg = Message("aftertouch", value=int(after_value))
            out.send(after_msg)

def handle_notes_digital():
    for idx, pin in enumerate(NOTE_PINS):
        value = board.digital_read(NOTE_PINS[idx])
        note_value = SCALE[idx]+(OCTAVE*12)
        print("NOTE %i VALUE: %s" % (note_value, value))
        if(value == 0 and not NOTE_ON[idx]):
            print("NOTE %i ON" % note_value)
            NOTE_ON[idx] = True
            note_msg = Message("note_on", note=note_value, velocity=64)
            out.send(note_msg)
        elif(value == 1 and NOTE_ON[idx]):
            print("NOTE %i OFF"% note_value)
            NOTE_ON[idx] = False
            note_msg = Message("note_off", note=note_value)
            out.send(note_msg)

def handle_bend():

    x1 = board.analog_read(BENDING_PINS[0])
    x2 = board.analog_read(BENDING_PINS[1])
    y1 = board.analog_read(BENDING_PINS[2])
    y2 = board.analog_read(BENDING_PINS[3])

    #Calibrate in the beginning
    if count == 1:
        print("Calculating offset: x: %d y:%d" % (((x1+x2)/2), ((y1+y2)/2)))
        offset = ((x1+x2)/2) - ((y1+y2)/2)

    bend = ((x1+x2)/2) - ((y1+y2)/2)

    bend = bend*64
    bend = max(min(8191, bend), -8192)
    #print("Bend: %d x1:%d x2:%d y1:%d y2:%d offset: %d" % (bend, x1, x2, y1, y2, offset))

    bend_msg = Message("pitchwheel", pitch=bend)
    out.send(bend_msg)

while 1:
    count += 1
    if count == 100000:
        print('bye bye')
        board.close()

    #handle_bend()
    handle_notes_digital()

    time.sleep(RATE*0.001)
