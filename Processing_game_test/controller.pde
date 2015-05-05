import processing.serial.*;
Serial orientationSerial;
Serial controlSerial;

public static final int NOTE_ON_THRESHOLD = 22;
public static final float NOTE_ON_RELATIVE_THRESHOLD = 0.98;
public static final int NOTE_OFF_THRESHOLD = -25;
public static final float NOTE_OFF_RELATIVE_THRESHOLD = 0.98;
public static final int AFTER_TOUCH_CNT = 0;
public static final int AFTER_TOUCH_ITER_COUNT = 12;

String rollRaw, pitchRaw, yawRaw;
String gyroX, gyroY, gyroZ;
String compX, compY, compZ;
String kalmanX, kalmanY, kalmanZ;
float roll, pitch, yaw;
float rollStart, pitchStart, yawStart;
boolean firstValue = false;

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

class ringBufferItem{
  int index;
  int[] data;
  int threshold;
  int afterTouchCounter;
  boolean triggered;
  
  ringBufferItem(){
    this.index = 0;
    this.threshold = 0;
    this.afterTouchCounter = 0;
    this.triggered = false;
    this.data = new int[8];
    for(int i = 0; i < data.length; i++){
      data[i] = 0;
    }
  }
  void add(int val){
    this.index = (this.index + 1) % 8;
    data[this.index] = val;
  }
  void trigger(){
    this.triggered = true;
    this.threshold = getRawCurrent();
  }
  void updateThreshold(){
    this.threshold = (this.threshold + getRawCurrent())/2;
  }
  
  int getMedian(){
    int[] sorted = sort(data);
    return(sorted[3]);
  }
  
  int getRawCurrent(){
    return this.data[this.index];
  }

  int getCurrent(){
    int value = 0;
    int median = getMedian();
    for(int i = 0; i < 4; i++){
      if((this.index - i) >= 0){
        value += data[(this.index - i) % 8];
      }else{
        value += data[(8 - this.index - i ) % 8];
      }
    }
    return(value/4);
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

void handleNotes(){
  /*
  print("Note values: [");
  for(int i = 0; i < notes.length; i++){
    print(notes[i].getRawCurrent() + ", ");
  }
  print("] Bending values [");
    for(int i = 0; i < bend.length; i++){
    print(bend[i].getRawCurrent() + ", ");
  }
  print("]\n");
  
  for(int i = 0; i < notes.length; i++){
    int value =  0;
  }*/
}

void controlSerialEvent (Serial serial) {
  String[] input = trim(split(serial.readString(), '\t'));
  if (input.length != 13) {
    println("Wrong length: " + input.length);
    return;
  }
  //println("Received data from control serial length: " + input.length);
  
  for(int i = 0; i < input.length - 1; i++){
    //print(i + ": " + input[i] + ", ");
    if(i < 8)
      notes[i].add(Integer.parseInt(input[i]));
    else
      bend[i%4].add(Integer.parseInt(input[i]));
  }
  /*
                       switch(i){
                        case 0: index = 5 break
                        case 1: index = 6 break
                        case 2: index = 11 break
                        case 3: index = 7 break
                        case 4: index = 1 break
                        case 5: index = 0 break
                        case 6: index = 9 break
                        case 7: index = 3 break
                        case 8: index = 8 break
                        case 9: index = 5 break
                        case 10: index = 4 break
                        case 11: index = 10 break
                    }
  */
  
  
  handleNotes();
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
