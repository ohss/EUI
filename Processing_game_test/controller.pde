import processing.serial.*;
Serial orientationSerial;
Serial controlSerial;

public static final int NOTE_ON_THRESHOLD = 500;
public static final int NOTE_OFF_THRESHOLD = -130;
public static final float NOTE_OFF_RELATIVE_THRESHOLD = 1.0;
public static final int AFTER_TOUCH_ITER_COUNT = 66;
public static final float AFTER_TOUCH_SCALE = 127.0/2500.0;
public static final int BEND_UP_ON_THRESHOLD = -500;
public static final int BEND_UP_OFF_THRESHOLD = 240;
public static final float BEND_UP_SCALE = 2200.0;
public static final int BEND_DOWN_ON_THRESHOLD = 400;
public static final int BEND_DOWN_OFF_THRESHOLD = -240;
public static final float BEND_DOWN_SCALE = 4300.0;
public static final int BEND_RANGE = 6;

public static final int PITCHBEND_ITER_COUNT = 6;


String rollRaw, pitchRaw, yawRaw;
String gyroX, gyroY, gyroZ;
String compX, compY, compZ;
String kalmanX, kalmanY, kalmanZ;
float roll, pitch, yaw;
float rollStart, pitchStart, yawStart;
boolean firstValue = false;
int serialCounter = 0;
int high = Integer.MIN_VALUE;
int low = Integer.MAX_VALUE;
int bendThreshold = 0;
Boolean bendUp = false;
Boolean bendDown = false;
int bendCounter = 0;
ringBufferItem bendBuffer;

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
    notes[i] = new ringBufferItem(8);
  }
  for(int i = 0; i < bend.length; i++){
    bend[i] = new ringBufferItem(8);
  }
  bendBuffer = new ringBufferItem(16);
  /*
  println("\nAvailable serial ports:");
  for (int i = 0; i < Serial.list().length; i++)
    println("[" + i + "]: " +  Serial.list()[i]); // Use this to print all serial devices
  */
  // Initialize the Controller board
  try {
    int ctrlBoardIndex = java.util.Arrays.asList(Serial.list()).indexOf("/dev/cu.usbmodem39011");
    if(ctrlBoardIndex >= 0 ){
      println("Found control board at: " + Serial.list()[ctrlBoardIndex]);
      controlSerial = new Serial(this, Serial.list()[ctrlBoardIndex], 9600); // Set this to your serial port obtained using the line above
      controlSerial.bufferUntil('\n'); // Buffer until line feed
    }else{
      println("Could not find control board!");
    }
  } catch(Exception e) {
    println("Please select a valid COM-port!");
    exit();
  }

  // Initialize the Orientation board
  try {
    int orientationBoardIndex = java.util.Arrays.asList(Serial.list()).indexOf("/dev/cu.usbserial-A90RR5T1");
    if(orientationBoardIndex >= 0 ){
      println("Found orientation board at: " + Serial.list()[orientationBoardIndex]);
      orientationSerial = new Serial(this, Serial.list()[orientationBoardIndex], 9600); // Set this to your serial port obtained using the line above
      orientationSerial.bufferUntil('\n'); // Buffer until line feed
    }else{
      println("Could not find orientation board!");
    }
  } catch(Exception e) {
    println("Please select a valid COM-port!");
    exit();
  }

}
void serialEvent (Serial s) {
  if(s == orientationSerial){
    orientationSerialEvent(s);
  }else if(s == controlSerial){
    controlSerialEvent(s);
  }
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

void handleBend(){
  //printBendingValues();
  int median = bendBuffer.getMedian();
  int raw = bendBuffer.getRawCurrent();
  int acc = bendBuffer.getCurrent();

  // Bend up ON
  if(acc <= BEND_UP_ON_THRESHOLD && !bendBuffer.triggered && !bendDown){
    bendBuffer.trigger();
    bendUp = true;
    bendDown = false;
    println("\nBEND UP ON\n");

  // Bend up OFF
  }else if(((acc > BEND_UP_OFF_THRESHOLD) || (bendBuffer.threshold < raw)) && bendBuffer.triggered && bendUp){
    println("\nBEND UP OFF\n");
    if(acc > BEND_UP_OFF_THRESHOLD)
      println(" acc " + acc + " more than "+BEND_UP_OFF_THRESHOLD +"\n");
    if(bendBuffer.threshold > raw)
      println(" raw " + raw + " more than " +bendBuffer.threshold + "\n");

    bendBuffer.unTrigger();
    bendUp = false;
    // Bend down ON
  /*
  }else if(acc >= BEND_DOWN_ON_THRESHOLD && !bendBuffer.triggered && !bendUp){
    bendBuffer.trigger();
    bendDown = true;
    bendUp = false;
    println("\nBEND DOWN ON\n");
  // Bend down OFF
  }else if(((acc < BEND_DOWN_OFF_THRESHOLD) || (bendBuffer.threshold > raw)) && bendBuffer.triggered && bendDown){
    print("\nBEND DOWN OFF");
    if(acc < BEND_UP_OFF_THRESHOLD)
      println(" acc " + acc + " less than "+BEND_DOWN_OFF_THRESHOLD +"\n");
    if(bendBuffer.threshold > raw)
      println(" raw " + raw + " less than " +bendBuffer.threshold + "\n");

    bendBuffer.unTrigger();
    bendDown = false;
  */
  // Bend values
  }else if(bendBuffer.triggered){
    if(bendBuffer.pitchbend()){
      int bend = 0;
      int bend_normalized = 0;
      int raw_bend = raw - bendBuffer.threshold;
      if(bendUp){
        print("UP ");
        bend = (int)Math.round(BEND_RANGE*(min(BEND_UP_SCALE, Math.abs(raw_bend)) / BEND_UP_SCALE));
        bend_normalized = 8192+(int)Math.round(8191*(bend/(double)BEND_RANGE));
      }
      if(bendDown){
        print("DOWN ");
        bend = (int)Math.round(-1*BEND_RANGE*(min(BEND_DOWN_SCALE, Math.abs(raw_bend)) / BEND_DOWN_SCALE));
        bend_normalized = (int)Math.round(8192*(Math.abs(bend)/(double)BEND_RANGE));
      }
      print("Bend: " + bend + " raw bend " + raw_bend + " thrs: " + bendBuffer.threshold + " ");

      int byte1 = bend_normalized & 0xF;
      int byte2 = bend_normalized >> 8;
      String s1 = String.format("%8s", Integer.toBinaryString(byte1 & 0xFF)).replace(' ', '0');
      String s2 = String.format("%8s", Integer.toBinaryString(byte2 & 0xFF)).replace(' ', '0');
      println("int val: " +bend_normalized+" byte1: " + s1 + " byte2: " +s2);

      // Send the midi data
      ctrlBus.sendMessage(PITCHBEND, byte1, byte2);
    }

  }
  //println("val: " + raw + " med: " + median + " diff: "+ abs(raw - median) + " acc: " + acc);
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
  int bendval = bend[0].getRawCurrent() - bend[1].getRawCurrent() + bend[2].getRawCurrent();
  bendval = (bendval / 2);
  bendBuffer.addFiltered(bendval);

  //Skip first 500 inputs
  if(serialCounter > 200){
    handleNotes();
    //printBendingValues();
    //handleBend();
  }else{
    serialCounter++;
  }
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

  int averadge = 0;
  averadge += (int)input[3];
  averadge += (int)input[8];
  averadge += (int)input[13];
  averadge = averadge / 3;

  if(input[3]>1.5 ||
    input[8]>1.5 ||
    input[13]>1.5 ||
    Math.abs(array[2] / average < 0.8 ) ||
    Math.abs(array[2] / average > 1.2)) {
      println("------------Shaking!------------");
    }

  serial.clear(); // Clear buffer

  int pitch_midi = min(127,(int)(abs(pitch)*(127.0/90.0)));
  int roll_midi = 63 + min(63, (int)(roll*(63.0/90.0)));

  //println("roll: " + roll_midi + " pitch: " + pitch_midi);

  //Send the MIDI data
  //ctrlBus.sendControllerChange(CTRL_CH, 1, pitch_midi);
  ctrlBus.sendControllerChange(CTRL_CH, 2, roll_midi);
}

void keyPressed() {

  if (key == 'r') // Reset the orientation board axes
    firstValue = true;

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

void printBendingValues(){

  print("Bending values [");
    for(int i = 0; i < bend.length; i++){
    print(bend[i].getRawCurrent() + ", ");
  }
  print("]");

  print(" vel [");
    for(int i = 0; i < bend.length; i++){
    print(bend[i].getCurrent() + ", ");
  }
  print("] cur " + bendBuffer.getRawCurrent() + " acc: " + bendBuffer.getCurrent() + "\n");
}
