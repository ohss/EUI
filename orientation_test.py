import mido
import serial
import serial.tools.list_ports
import time
import sys

print ("Available ports:")
ports = serial.tools.list_ports.comports()
for port in ports:
    print port[0]

try:
    serial_input = serial.Serial(ports[3][0], 9600)
    print ("On port %s" % (serial_input.port))
except:
    print ("Please select valid COM-ports!")
    sys.exit(0)

print ("Available midi ports:")
midiports = mido.get_output_names()
for port in midiports:
    print port

out = mido.open_output(midiports[0])

rollStart = 0
pitchStart = 0
yawStart = 0
first_value = True

def get_orientation():

    #Occasionally there are errors on the strings read from serial, which causes ValueErrors when casted to float
    while True:
        try:
            orientation = serial_input.readline().strip().split("\t")
            roll = float(orientation[0])
            pitch = float(orientation[1])
            yaw = float(orientation[2])
            break
        except ValueError, IndexError:
            print "again"

    global first_value, rollStart, pitchStart, yawStart

    if first_value:
        print 'reset'
        rollStart = roll;
        pitchStart = pitch;
        yawStart = yaw;
        first_value  = False;

    roll = normalise_degrees(roll-rollStart)
    pitch = normalise_degrees(pitch-pitchStart)
    yaw = normalise_degrees(yaw-yawStart)

    return {'roll': roll, 'pitch': pitch, 'yaw': yaw}

def normalise_degrees(degree):
    if (degree < -180):
        return degree%180
    elif (degree > 180):
        return degree%-180
    else:
        return degree

# Maps a value from [-maxReading, maxReading] to [0,127]
def map_angle_to_control(angle, maxReading=180, maxOutput=127):
    return int(abs(angle) * (float(maxOutput) / float(maxReading)))


note_msg = mido.Message("note_on", note=64, velocity=64)
out.send(note_msg)

while True:

    orientation_values = get_orientation()

    # print ("Roll: %f | Pitch: %f | Yaw: %f" % (orientation_values['roll'], orientation_values['pitch'], orientation_values['yaw']))

    roll = orientation_values['roll']
    pitch = orientation_values['pitch']

    roll_fx = map_angle_to_control(roll)
    pitch_fx = map_angle_to_control(pitch)

    roll_msg = mido.Message("control_change", control=1, value=roll_fx)
    pitch_msg = mido.Message("control_change", control=2, value=pitch_fx)
    #out.send(roll_msg)
    #print roll_msg
    out.send(pitch_msg)
    print pitch_msg
