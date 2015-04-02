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
import sys, os, select
import py_compile
import time
import signal
import mido

from PyMata.pymata import PyMata
from mido import Message

import serial.tools.list_ports
RATE = 30   # Refresh rate in ms
BENDING_PINS = [0,1,2,3] # Bending sensors pins
BEND_CAL = [{'min': sys.maxint, 'max': 0, 'center': None},
            {'min': sys.maxint, 'max': 0, 'center': None},
            {'min': sys.maxint, 'max': 0, 'center': None},
            {'min': sys.maxint, 'max': 0, 'center': None}]
NOTE_PINS = [2,3,4,5,6,7,8,9] # Note pins

# Default scale is C Major: C, D, E, F, G, A, B
# Scales should be at the -1 octave and are transposed
# up by OCTAVE octaves
SCALE = [0, 2, 4, 5, 7, 9, 10, 11]
NOTE_ON = [False, False, False, False, False, False, False, False]
OCTAVE = 5
NOTE_TRESHOLD = 512

offset = 0
count = 0
calibrate = 1

# Globals for orientation
rollStart = 0
pitchStart = 0
yawStart = 0
first_value = True

# create a PyMata and a Serial instance

py_compile.compile('pymata_test_poll.py')

print ("Available serial ports:")
ports = serial.tools.list_ports.comports()
for port in ports:
    print port[0]

try:
    # select the right board from [x][0]
    board = PyMata(ports[2][0], False, False)
    print ("Board is on port: %s " % (ports[2][0]))
    #orientation_board = serial.Serial(ports[3][0], 9600)
    #print ("Orientation_board is on port: %s " % (orientation_board.port))
except Exception as e:
    print e
    print ("Please select valid COM-ports!")
    sys.exit(0)

print ("Available midi ports:")
midiports = mido.get_output_names()
for port in midiports:
    print port

# Interrupt handler
def signal_handler(sig, frame):
    print('You pressed Ctrl+C!!!!')
    if board is not None:
        board.reset()
    sys.exit(0)


signal.signal(signal.SIGINT, signal_handler)

# set pin modes
for pin in BENDING_PINS:
    board.set_pin_mode(pin, board.INPUT, board.ANALOG)

for pin in NOTE_PINS:
    #For Analog input
    #board.set_pin_mode(pin, board.INPUT, board.ANALOG)
    #For Digital input
    board.set_pin_mode(pin, board.INPUT, board.DIGITAL)

# set sampling interval
board.set_sampling_interval(RATE)


# sleep for a while to wait for board initialization
time.sleep(2)
#Initialize mido
out_notes = mido.open_output(midiports[0])
out_cc = mido.open_output(midiports[1])

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
        #print("NOTE %i VALUE: %s" % (note_value, value))
        if(value == 0 and not NOTE_ON[idx]):
            print("NOTE %i ON" % note_value)
            first_value = True
            NOTE_ON[idx] = True
            note_msg = Message("note_on", note=note_value, velocity=64)
            out_notes.send(note_msg)
        elif(value == 1 and NOTE_ON[idx]):
            print("NOTE %i OFF"% note_value)
            NOTE_ON[idx] = False
            note_msg = Message("note_off", note=note_value)
            out_notes.send(note_msg)

def scale(value, index, min_val=0, max_val=8192):
    OldRange = (BEND_CAL[index]['max'] - BEND_CAL[index]['min'])
    NewRange = (max_val - min_val)
    NewValue = (((value - BEND_CAL[index]['min']) * NewRange) / OldRange) + min_val
    return NewValue

def handle_bend(calibrate):

    sensor = [0,0,0,0]

    if(calibrate):
        print("CALIBRATE: "),
        for i, axis in enumerate(BEND_CAL):
            cur_val = board.analog_read(BENDING_PINS[i])
            if (cur_val > BEND_CAL[i]['max']):
                BEND_CAL[i]['max'] = cur_val
            if (cur_val < BEND_CAL[i]['min']):
                BEND_CAL[i]['min'] = cur_val
            if (BEND_CAL[i]['center'] == None):
                BEND_CAL[i]['center'] = cur_val
            else:
                BEND_CAL[i]['center'] = (BEND_CAL[i]['center']+cur_val)/2

            print("(i: %i cur: %i min: %i max: %i ctr: %i)" % (i, cur_val, BEND_CAL[i]['min'], BEND_CAL[i]['max'], BEND_CAL[i]['center'])),
        print("")
        return
    else:
        bend = 0
        for i, axis in enumerate(BENDING_PINS):
            sensor[i] = board.analog_read(BENDING_PINS[i])
            scaled = scale(sensor[i], i)
            print ("(i: %i org: %i dff: %i)" % (i, sensor[i], (sensor[i] - BEND_CAL[i]['center']))),
            sensor[i] = scaled
        bend = (sensor[0] + sensor[1] - sensor[2] - sensor[3])/4
        print(" bend: %i" % bend)
        bend_msg = Message("pitchwheel", pitch=bend)
        out_notes.send(bend_msg)

    #
    # bend = ((x1+x2)/2) - ((y1+y2)/2)
    # bend = bend*64
    # bend = max(min(8191, bend), -8192)
    # print("Bend: %d x1:%d x2:%d y1:%d y2:%d offset: %d" % (bend, x1, x2, y1, y2, offset))
    #
    # bend_msg = Message("pitchwheel", pitch=bend)
    # out.send(bend_msg)
def get_orientation():

    #Occasionally there are errors on the strings read from serial, which causes ValueErrors when casted to float
    while True:
        try:
            orientation = orientation_board.readline().strip().split("\t")
            if len(orientation) > 2:
                roll = float(orientation[0])
                pitch = float(orientation[1])
                yaw = float(orientation[2])
                orientation_board.flushInput()
                break
        except ValueError:
            print "again"

    global first_value, rollStart, pitchStart, yawStart

    if first_value:
        print 'reset'
        rollStart = roll;
        pitchStart = pitch;
        yawStart = yaw;
        first_value  = False;

    roll -= rollStart;
    pitch -= pitchStart;
    yaw -= yawStart;

    return {'roll': roll, 'pitch': pitch, 'yaw': yaw}

# Maps a value from [-maxReading, maxReading] to [0,127]
def map_angle_to_control(angle, maxReading=180, maxOutput=127):
    ranged_angle = min(abs(angle), maxReading) # if a reading is over 180 (which it shouldn't be!)
    return int(ranged_angle * (float(maxOutput) / float(maxReading)))

while 1:
    count += 1
    if count == 100000:
        print('bye bye')
        board.close()

    # orientation_values = get_orientation()
    #
    # print ("Roll: %f | Pitch: %f | Yaw: %f" % (orientation_values['roll'], orientation_values['pitch'], orientation_values['yaw']))
    #
    # roll = orientation_values['roll']
    # #pitch = orientation_values['pitch']
    #
    # roll_fx = map_angle_to_control(roll)
    # #pitch_fx = map_angle_to_control(pitch)
    #
    # roll_msg = mido.Message("control_change", control=1, value=roll_fx)
    # #pitch_msg = mido.Message("control_change", control=2, value=pitch_fx)
    # print roll_msg
    # out_cc.send(roll_msg)

    handle_bend(calibrate)
    handle_notes_digital()


    # Check for calibration end
    if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
        line = raw_input()
        calibrate = False

    time.sleep(RATE*0.001)
