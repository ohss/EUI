import processing.serial.*;
Serial orientationSerial;
Serial controlSerial;

public static final int NOTE_ON_THRESHOLD = 500;
public static final int NOTE_OFF_THRESHOLD = -150;
public static final float NOTE_OFF_RELATIVE_THRESHOLD = 0.98;
public static final int AFTER_TOUCH_ITER_COUNT = 60;
public static final float AFTER_TOUCH_SCALE = 127.0/2500.0;


String rollRaw, pitchRaw, yawRaw;
String gyroX, gyroY, gyroZ;
String compX, compY, compZ;
String kalmanX, kalmanY, kalmanZ;
float roll, pitch, yaw;
float rollStart, pitchStart, yawStart;
boolean firstValue = false;
int serialCounter = 0;

public MidiBus ctrlBus;

ringBufferItem[] notes;
ringBufferItem[] bend;

class calItem {
  int min;
  int max;
  int center;

  calItem() {
    this.min = Integer.MAX_VALUE;
    this.max = Integer.MIN_VALUE;
    this.center = 0;
  }
  
  void update(int val){
    if(this.min > val)
      this.min = val;
    if(this.max < val)
      this.max = val;
    this.center += (int)((this.center + val)/2);
  }
}

void controller_setup() {
  
  //                     Parent  In        Out
  //                     |     |          |
  ctrlBus = new MidiBus(this, "IAC Bus 2", "IAC Bus 1");
  
  // Initialize the ringbuffers
  notes = new ringBufferItem[8];
  bend = new ringBufferItem[4];
  for(int i = 0; i < notes.length; i++){
    notes[i] = new ringBufferItem();
  }
  for(int i = 0; i < bend.length; i++){
    bend[i] = new ringBufferItem();
  }
  
  println("\nAvailable serial ports:");
  for (int i = 0; i < Serial.list().length; i++)
    println("[" + i + "]: " +  Serial.list()[i]); // Use this to print all serial devices
  
  // Initialize the Controller board
  try {
    controlSerial = new Serial(this, Serial.list()[2], 9600); // Set this to your serial port obtained using the line above
    controlSerial.bufferUntil('\n'); // Buffer until line feed
  } catch(Exception e) {
    println("Please select a valid COM-port!");
    exit();
  }
  
  /*
  // Initialize the Orientation board
  try {
    orientationSerial = new Serial(this, Serial.list()[3], 9600); // Set this to your serial port obtained using the line above
    orientationSerial.bufferUntil('\n'); // Buffer until line feed
  } catch(Exception e) {
    println("Please select a valid COM-port!");
    exit();
  }
  */
}
void serialEvent (Serial s) {
  if(s == orientationSerial){
    orientationSerialEvent(s);
  }else if(s == controlSerial){
    controlSerialEvent(s);
  }
}

void printAllSensors(){
  print("Note values: [");
  for(int i = 0; i < notes.length; i++){
    print(notes[i].getRawCurrent() + ", ");
  }
  print("] Bending values [");
    for(int i = 0; i < bend.length; i++){
    print(bend[i].getRawCurrent() + ", ");
  }
  print("]\n");
}

void printSensorVelocity(){
  print("Note Vel [");
  for(int i = 0; i < notes.length; i++){
    print(notes[i].getCurrent() + ", ");
  }
  print("] Bending vel [");
    for(int i = 0; i < bend.length; i++){
    print(bend[i].getCurrent() + ", ");
  }
  print("]\n");
}

void handleNotes(){
  //printAllSensors();
  //printSensorVelocity();
  
  for(int i = 0; i < notes.length; i++){
    int value =  notes[i].getCurrent();
    int raw = notes[i].getRawCurrent();
    int median = notes[i].getMedian();
    int note_value = scale[i] + octave*12;
    
    // Note ON from velocity
    if(value >= NOTE_ON_THRESHOLD && !notes[i].triggered){
      println("NOTE ON " + i + " with vel: " + value);
      notes[i].trigger();
      ctrlBus.sendNoteOn(CTRL_CH, note_value, 127);
      
    // Note OFF from velocity or magnitude
    }else if(( (value < NOTE_OFF_THRESHOLD) || (raw <= (notes[i].threshold * NOTE_OFF_RELATIVE_THRESHOLD)) ) && notes[i].triggered){ 
      println("NOTE OFF " + i + " with vel: " + value + " with magnitude: " + raw + " Threshold: " + notes[i].threshold);
      notes[i].unTrigger();
      ctrlBus.sendNoteOff(CTRL_CH, note_value, 127);

      // If no notes are played set aftertouch to 0
      Boolean lastNote = true;
      for(int j = 0; j < notes.length; j++){
        if(notes[j].triggered){
          lastNote = false;
          break;
        }   
      }
      if(lastNote) 
        ctrlBus.sendMessage(AFTERTOUCH, 0);
        
    //Aftertouch
    }else if(notes[i].triggered){
      if(notes[i].aftertouch()){
        int afterValue = int((raw - notes[i].threshold)*AFTER_TOUCH_SCALE);
        afterValue = max(afterValue, 0);
        afterValue = min(afterValue, 127);
        //println("Trsh: " + notes[i].threshold + " Cur: " + raw + " Aftertouch: " + afterValue);
        ctrlBus.sendMessage(AFTERTOUCH, afterValue);
      }
    } 
  }
}

void controlSerialEvent (Serial serial) {
  String[] input = trim(split(serial.readString(), '\t'));
  if (input.length != 13) {
    println("Wrong length: " + input.length);
    return;
  }
  
  for(int i = 0; i < input.length - 1; i++){
    int index = 0;
    switch(i){  // Map the analog inputs correctly to notes and bend sensors
      case 0: index = 5; break;
      case 1: index = 6; break;
      case 2: index = 11; break;
      case 3: index = 7; break;
      case 4: index = 0; break;
      case 5: index = 1; break;
      case 6: index = 9; break;
      case 7: index = 3; break;
      case 8: index = 8; break;
      case 9: index = 2; break;
      case 10: index = 4; break;
      case 11: index = 10; break;
    }
    //print(i + ": " + input[i] + ", ");
    if(index < 8)
      notes[index].add(Integer.parseInt(input[i]));
    else
      bend[index%4].add(Integer.parseInt(input[i]));
  }
  //Skip first 500 inputs
  if(serialCounter > 512)
    handleNotes();
  else
    serialCounter++;
  
  serial.clear(); // Clear buffer
}

void orientationSerialEvent (Serial serial) {
  String[] input = trim(split(serial.readString(), '\t'));
  if (input.length != 15) {
    println("Wrong length: " + input.length);
    return;
  }

  // Get the ASCII strings:
  rollRaw = input[0];
  gyroX = input[1];
  compX = input[2];
  kalmanX = input[3];

  // Ignore extra tab
  pitchRaw = input[5];
  gyroY = input[6];
  compY = input[7];
  kalmanY = input[8];

  // Ignore extra tab
  yawRaw = input[10];
  gyroZ = input[11];
  compZ = input[12];
  kalmanZ = input[13];

  roll = float(kalmanX); // Show the Kalman values
  pitch = float(kalmanY);
  yaw = float(kalmanZ);

  if (firstValue) {
    rollStart = roll;
    pitchStart = pitch;
    yawStart = yaw;
    firstValue  = false;
  }
  
  roll -= rollStart;
  pitch -= pitchStart;
  yaw -= yawStart;

  serial.clear(); // Clear buffer
 
  int roll_midi = min(127,(int)(abs(roll)*(127.0/90.0)));
  int pitch_midi = min(127, (int)(abs(pitch)*(127.0/90.0)));
  
  //println("roll: " + roll_midi + " pitch: " + pitch_midi);
  
  //Send the MIDI data
  ctrlBus.sendControllerChange(CTRL_CH, 0, roll_midi);
  ctrlBus.sendControllerChange(CTRL_CH, 1, pitch_midi);
}

void keyPressed() {
  
  if (key == 'r') // Reset the orientation board axes
    firstValue = true;

  
}
