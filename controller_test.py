#!/usr/bin/env python

"""
Copyright (c) 2015 All rights reserved.
"""
import sys, os, select
import py_compile
import time
import signal
import mido
import statistics
from mido import Message
import serial.tools.list_ports

RATE = 10   # Refresh rate in ms
BEND_CAL = [{'min': sys.maxint, 'max': 0, 'center': None},
            {'min': sys.maxint, 'max': 0, 'center': None},
            {'min': sys.maxint, 'max': 0, 'center': None},
            {'min': sys.maxint, 'max': 0, 'center': None}]

AVG_DEV = 0
RING_BUF = [None, None, None, None, None, None, None, None]

# Default scale is C Major: C, D, E, F, G, A, B
# Scales should be at the -1 octave and are transposed
# up by OCTAVE octaves
SCALE = [0, 2, 4, 5, 7, 9, 10, 11]
NOTE_ON = [False, False, False, False, False, False, False, False]
LEDS = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
OCTAVE = 5
NOTE_ON_THRESHOLD = 220
NOTE_OFF_THRESHOLD = -100
NOTE_OFF_RELATIVE_THRESHOLD = 0.7
AFTER_TOUCH_CNT = 0
AFTER_TOUCH_ITER_COUNT = 22

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

# Initialize ring buffer
for i in range(0,8):
    RING_BUF[i] = {'idx':0, 'data':[0,0,0,0,0,0,0,0], 'thresh_val':0}

def handle_notes(sensor_values):

    global AFTER_TOUCH_CNT
    #Check all notes
    for idx in range(0,8):
        value = 0
        raw_value = RING_BUF[idx]['data'][RING_BUF[idx]['idx']]
        median = statistics.median(RING_BUF[idx]['data'])
        for i in range(0,4):
            value += RING_BUF[idx]['data'][(RING_BUF[idx]['idx'] - i)%8] - median
        value = int(value / 4)

        note_value = SCALE[idx]+(OCTAVE*12)
        #print("index: %i pin: %i value: %i note: %i" % (idx, NOTE_PINS[idx], value, SCALE[idx]))
        if(value >= NOTE_ON_THRESHOLD and not NOTE_ON[idx]):
            print("NOTE %i ON" % note_value)
            NOTE_ON[idx] = True
            RING_BUF[idx]['treshold_val'] = RING_BUF[idx]['data'][RING_BUF[idx]['idx']]
            AFTER_TOUCH_CNT = 0
            note_msg = Message("note_on", note=note_value, velocity=64)
            out_notes.send(note_msg)
        elif((value < NOTE_OFF_THRESHOLD and NOTE_ON[idx])): # Note OFF
            print("NOTE %i OFF"% note_value)
            RING_BUF[idx]['treshold_val'] = 0
            NOTE_ON[idx] = False
            note_msg = Message("note_off", note=note_value)
            out_notes.send(note_msg)
        elif((raw_value <= RING_BUF[idx].get('treshold_val', 16000)*NOTE_OFF_RELATIVE_THRESHOLD) and NOTE_ON[idx]):
            print("NOTE %i OFF value %i less than %i of threshold %i "% (note_value, raw_value,NOTE_OFF_RELATIVE_THRESHOLD, RING_BUF[idx]['treshold_val']))
            RING_BUF[idx]['treshold_val'] = 0
            NOTE_ON[idx] = False
            note_msg = Message("note_off", note=note_value)
            out_notes.send(note_msg)
        elif(NOTE_ON[idx]):
            if (AFTER_TOUCH_CNT < AFTER_TOUCH_ITER_COUNT):
                RING_BUF[idx]['treshold_val'] = (0.5*RING_BUF[idx]['treshold_val'] + 0.5*raw_value)
                AFTER_TOUCH_CNT = AFTER_TOUCH_CNT + 1
            else:
                after_value = max((raw_value - RING_BUF[idx]['treshold_val']),0)
                after_value = min(after_value, 127)
                print("Trsh: %i Cur: %i Aftertouch: %i"% (RING_BUF[idx]['treshold_val'],raw_value, after_value))
                after_msg = Message("aftertouch", value=int(after_value))
                out_notes.send(after_msg)

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

            print("(i: %i cur: %i min: %i max: %i ctr: %i)" % (i, cur_val, BEND_CAL[i]['min'], BEND_CAL[i]['max'], BEND_CAL[i]['center'])),
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

    had_input = False

    for msg in in_notes.iter_pending():
        had_input = True
        try:
            note = msg.note - 12*OCTAVE
            pin = SCALE.index(note)
            if(msg.type == 'note_on'):
                #print("Note %i Pin %i led ON" % (msg.note, pin)),
                if(msg.velocity < 64):
                    #print("Green")
                    LEDS[pin*2] = 1 # set green led
                    LEDS[pin*2 + 1] = 0 # reset red led
                else:
                    #print("Red")
                    LEDS[pin*2] = 0
                    LEDS[pin*2 + 1] = 1
            elif(msg.type == 'note_off'):
                #print("Note %i Pin %i led OFF" % (msg.note, pin))
                LEDS[pin*2] = 0
                LEDS[pin*2 + 1] = 0
        except:
            print("Warning: Message not a note or not in scale: %s" % msg)

    if (had_input):
        try:
            num_bytes = control_board.write(''.join(map(str, LEDS)))
            control_board.flush()
        except:
            print("Error: Write to board failed")

def get_serial_data():

    global RING_BUF
    #Occasionally there are errors on the strings read from serial, which causes ValueErrors when casted to float
    while True:
        try:
            sensors = control_board.readline().strip().split("\t")
            if len(sensors) == 12:
                for i in range(0,8):
                    note_sensors[i] = int(sensors[i])
                    #Fill the ring buffer
                    #RING_BUF[RING_BUF_IDX] = note_sensors[i]
                    #RING_BUF_IDX = (RING_BUF_IDX + 1) % 8
                    RING_BUF[i]['data'][RING_BUF[i]['idx']] = note_sensors[i]
                    RING_BUF[i]['idx'] = (RING_BUF[i]['idx'] + 1) % 8
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
        break

    if count == 100:
        AVG_DEV = 0

    # Check for serial input and handle incoming data
    read = get_serial_data()
    if read:

        #Print acceleration
        # for x in range(0,8):
        #     acc = 0
        #     val = RING_BUF[x]['data'][RING_BUF[1]['idx']]
        #     median = statistics.median(RING_BUF[x]['data'])
        #     for i in range(0,4):
        #         acc += RING_BUF[x]['data'][(RING_BUF[x]['idx'] - i)%8] - median
        #     acc = int(acc / 4)
        #     print("%i " % acc),
        #     if(AVG_DEV < abs(acc)):
        #         AVG_DEV = abs(acc)
        # print("")

        #if(acc >= 0):
        #    print("Cur: %i Acc:  %i Max Acc: %f Median: %i  Buf: %s " % (val, acc, AVG_DEV, median, RING_BUF[0]['data']))
        #else:
        #    print("Cur: %i Acc: %i Max Acc: %f Median: %i  Buf: %s " % (val, acc, AVG_DEV, median, RING_BUF[0]['data']))
        #print("Note values: %s Bending values %s" % (note_sensors, bend_sensors))
        #handle_bend(bend_sensors, calibrate)
        handle_notes(note_sensors)

    else:
        print "Received no data!"

    # Check MIDI input and write to Teensy on serial
    handle_leds()

    # Check for calibration end
    if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
        line = raw_input()
        calibrate = False

    #time.sleep(RATE*0.001)
