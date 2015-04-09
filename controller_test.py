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
from mido import Message
import serial.tools.list_ports

RATE = 10   # Refresh rate in ms
BEND_CAL = [{'min': sys.maxint, 'max': 0, 'center': None},
            {'min': sys.maxint, 'max': 0, 'center': None},
            {'min': sys.maxint, 'max': 0, 'center': None},
            {'min': sys.maxint, 'max': 0, 'center': None}]

# Default scale is C Major: C, D, E, F, G, A, B
# Scales should be at the -1 octave and are transposed
# up by OCTAVE octaves
SCALE = [0, 2, 4, 5, 7, 9, 10, 11]
NOTE_ON = [False, False, False, False, False, False, False, False]
LEDS = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
OCTAVE = 5
NOTE_TRESHOLD = 512

offset = 0
count = 0
calibrate = True
note_sensors = [0,0,0,0,0,0,0,0]
bend_sensors = [0,0,0,0]


# Globals for orientation
rollStart = 0
pitchStart = 0
yawStart = 0
first_value = True

# create a Serial instance

print ("Available serial ports:")
ports = serial.tools.list_ports.comports()
for port in ports:
    print port[0]

try:
    # select the right board from [x][0]
    control_board = serial.Serial(ports[2][0], 9600)
    print ("Control_board is on port: %s " % (control_board.port))
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
    if control_board is not None:
        control_board.close()
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

# sleep for a while to wait for board initialization
# time.sleep(2)

#Initialize mido
out_notes = mido.open_output(midiports[0])
in_notes = mido.open_input(midiports[1])

def handle_notes(sensor_values):
    #Check all notes
    for idx, axis in enumerate(sensor_values):
        value = sensor_values[idx]
        note_value = SCALE[idx]+(OCTAVE*12)
        #print("index: %i pin: %i value: %i note: %i" % (idx, NOTE_PINS[idx], value, SCALE[idx]))
        if(value >= NOTE_TRESHOLD and not NOTE_ON[idx]):
            print("NOTE %i ON" % note_value)
            NOTE_ON[idx] = True
            note_msg = Message("note_on", note=note_value, velocity=64)
            out_notes.send(note_msg)
        elif(value < (NOTE_TRESHOLD*0.9) and NOTE_ON[idx]):
            print("NOTE %i OFF"% note_value)
            NOTE_ON[idx] = False
            note_msg = Message("note_off", note=note_value)
            out_notes.send(note_msg)
        elif((value >= NOTE_TRESHOLD) and NOTE_ON[idx]):
            after_value = ((value-512)/4)-1
            #print("%i AFTERTOUCH: %i"% (SCALE[idx], after_value))
            #after_msg = Message("aftertouch", value=int(after_value))
            #out_notes.send(after_msg)

def scale(value, index, min_val=0, max_val=8192):
    OldRange = (BEND_CAL[index]['max'] - BEND_CAL[index]['min'])
    NewRange = (max_val - min_val)
    NewValue = (((value - BEND_CAL[index]['min']) * NewRange) / OldRange) + min_val
    return NewValue

def handle_bend(sensor_values, calibrate):

    sensor = [0,0,0,0]

    if(calibrate):
        print("CALIBRATE: "),
        for i, axis in enumerate(BEND_CAL):
            cur_val = sensor_values[i]
            if (cur_val > BEND_CAL[i]['max']):
                BEND_CAL[i]['max'] = cur_val
            if (cur_val < BEND_CAL[i]['min']):
                BEND_CAL[i]['min'] = cur_val
            if (BEND_CAL[i]['center'] == None):
                BEND_CAL[i]['center'] = cur_val
            else:
                BEND_CAL[i]['center'] = (BEND_CAL[i]['center']+cur_val)/2

            #print("(i: %i cur: %i min: %i max: %i ctr: %i)" % (i, cur_val, BEND_CAL[i]['min'], BEND_CAL[i]['max'], BEND_CAL[i]['center'])),
        print("")
        return
    else:
        bend = 0
        for i, axis in enumerate(sensor_values):
            scaled = scale(sensor_values[i], i)
            #print ("(i: %i org: %i dff: %i)" % (i, sensor[i], (sensor[i] - BEND_CAL[i]['center']))),
            sensor[i] = scaled
        bend = (sensor[0] + sensor[1] - sensor[2] - sensor[3])/4
        #print(" bend: %i" % bend)
        bend_msg = Message("pitchwheel", pitch=bend)
        out_notes.send(bend_msg)

def handle_leds():

    for msg in in_notes.iter_pending():
        #print(msg)
        try:
            note = msg.note - 12*OCTAVE
            pin = SCALE.index(note)
            print ("scaled note: %i" % note)
            print ("pin of note: %i" % pin)
            if(msg.type == 'note_on'):
                print("Note %i Pin %i led ON" % (msg.note, pin))
                LEDS[pin*2] = 1
            elif(msg.type == 'note_off'):
                print("Note %i Pin %i led OFF" % (msg.note, pin))
                LEDS[pin*2] = 0
        except:
            print("Note not in scale %s" % msg)
    try:
        control_board.write(''.join(map(str, LEDS)));
    except:
        print("Write to board failed")

def get_serial_data():

    #Occasionally there are errors on the strings read from serial, which causes ValueErrors when casted to float
    while True:
        try:
            sensors = control_board.readline().strip().split("\t")
            if len(sensors) == 12:
                for i in range(0,8):
                    note_sensors[i] = int(sensors[i])
                for i in range(0,4):
                    bend_sensors[i] = int(sensors[i+8])
                return True
            else:
                print "Got something we didn't expect len: %i input %s" % (len(sensors), sensors)
        except ValueError:
            print "again"

    return False

while 1:
    count += 1
    if count == 100000:
        print('bye bye')
        control_board.close()

    read = get_serial_data()

    if read:

        #print("Note values: %s Bending values %s" % (note_sensors, bend_sensors))

        handle_bend(bend_sensors, calibrate)
        handle_notes(note_sensors)
        handle_leds()
    else:
        print "Received no data!"

    # Check for calibration end
    if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
        line = raw_input()
        calibrate = False

    #time.sleep(RATE*0.001)
