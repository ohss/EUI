import mido
import serial
import time

orientation_serial = serial.Serial("/dev/tty.usbserial-A90RR5T1", 9600)
time.sleep(1)

out = mido.open_output()

rollStart = 0
pitchStart = 0
yawStart = 0
first_value = True

def get_orientation():
    orientation_input = orientation_serial.readline().strip().split("\t")

    #Occasionally there are errors on the strings read from serial, which causes ValueErrors when casted to float
    while True:
        try: 
            roll = float(orientation_input[0])
            pitch = float(orientation_input[1])
            yaw = float(orientation_input[2])
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

def translate(value, leftMin, leftMax, rightMin, rightMax):
    # Figure out how 'wide' each range is
    leftSpan = leftMax - leftMin
    rightSpan = rightMax - rightMin

    # Convert the left range into a 0-1 range (float)
    valueScaled = float(value - leftMin) / float(leftSpan)

    # Convert the 0-1 range into a value in the right range.
    value_ranged = int(rightMin + (valueScaled * rightSpan))
    return max(min(rightMax, value_ranged), 0)

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
    print (roll, " ", roll_fx)
    print (pitch, " ", pitch_fx)
    # pitch_fx = 0

    roll_msg = mido.Message("control_change", control=1, value=roll_fx)
    pitch_msg = mido.Message("control_change", control=2, value=pitch_fx)
    out.send(roll_msg)
    out.send(pitch_msg)


    
    
