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
    serial_input = serial.Serial(ports[0][0], 9600)
    print ("On port %s" % (ports[0][0]))
except:
    print ("Please select valid COM-ports!")
    sys.exit(0)

out = mido.open_output()

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
def map_angle_to_control(angle, maxReading, maxOutput):
    control_val = abs(angle) * (float(maxOutput) / float(maxReading))
    return max(min(127, int(control_val)),0)

note_msg = mido.Message("note_on", note=36, velocity=64)
out.send(note_msg)

while True:
    count += 1

    if count > 100:
        # first_value = True
        count = 0

    orientation_values = get_orientation()

    # print ("Roll: %f | Pitch: %f | Yaw: %f" % (orientation_values['roll'], orientation_values['pitch'], orientation_values['yaw']))

    roll = orientation_values['roll']
    pitch = orientation_values['pitch']

    roll_fx = map_angle_to_control(roll)
    pitch_fx = map_angle_to_control(pitch)

    roll_msg = mido.Message("control_change", control=1, value=roll_fx)
    pitch_msg = mido.Message("control_change", control=2, value=pitch_fx)
    out.send(roll_msg)
    out.send(pitch_msg)


    
    
