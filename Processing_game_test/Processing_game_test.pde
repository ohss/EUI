import themidibus.*;
import javax.sound.midi.MidiMessage; //Import the MidiMessage classes http://java.sun.com/j2se/1.5.0/docs/api/javax/sound/midi/MidiMessage.html
import javax.sound.midi.SysexMessage;
import javax.sound.midi.ShortMessage;

public static int BPM = 120;
public static int TIMEOUT = 10000; // Timeout until the note plays again
public static final int CC = 176;
public static final int AFTERTOUCH = 208;
public static final int PITCHBEND = 224;

MidiBus myBus; // The MidiBus
int midi_ch = 1;
long tick_len;

int[] scale = {
  0, 2, 4, 5, 7, 9, 10, 11
}; // Current note scale
int octave = 5; // Current octave
gameEvent[] track;
int current_event = 0;
Boolean correctAnswer = true;
Boolean correctNote = false;
Boolean[] correctCC;
int timeStart = 0;

class ccEvent {
  int type;
  int number;
  int value;
  long time;

  ccEvent(int type, int num, int val, long t) {
    this.type = type;
    this.number = num;
    this.value = val;
    this.time = t;
  }
}

class gameEvent {
  Note note;
  ArrayList<ccEvent> cc;
  gameEvent(Note note, ArrayList<ccEvent> cc_list) {
    this.note = note;
    this.cc = cc_list;
  }
}

void setup() {
  size(400, 400);
  background(255);
  stroke(0);
  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

  //                 Parent  In        Out
  //                   |     |          |
  myBus = new MidiBus(this, "IAC Bus 1", "IAC Bus 2"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.
  track = new gameEvent[scale.length];

  for (int i = 0; i < scale.length; i++) {
    Note n = new Note(midi_ch, scale[i]+12*octave, 127, 100);
    ArrayList<ccEvent> cc_list = new ArrayList<ccEvent>();
    cc_list.add(new ccEvent(AFTERTOUCH, 0, 127, 1000));
    track[i] = new gameEvent(n, cc_list);
  }
}

int getTicksInMillis(long ticks) {
  return (int)((60000 / (BPM * 192))*ticks);
}

void draw() {

  Boolean allCCCorrect = true;
  if(correctCC != null){
    for(int i = 0; i < correctCC.length; i++){
      if(!correctCC[i]){
        allCCCorrect = false;
        break;
      }
    }
  }else{
    allCCCorrect = false;
  }
  
  if (correctNote && allCCCorrect) {
    correctAnswer = true;
    current_event++;
    delay(500);
  }

  //Get current note
  if (correctAnswer || TIMEOUT < (millis() - timeStart)) {
    Note n = track[current_event].note;
    myBus.sendNoteOn(n.channel, n.pitch, n.velocity); // Send a Midi noteOn
    println("Note time in ms: " + getTicksInMillis(n.ticks));
    delay(getTicksInMillis(n.ticks));
    myBus.sendNoteOff(n.channel, n.pitch, n.velocity); // Send a Midi nodeOff
    timeStart = millis();
    correctAnswer = false;
    correctNote = false;
    correctCC = new Boolean[track[current_event].cc.size()];
    for(int i = 0; i < correctCC.length; i++){
      correctCC[i] = false;
    }
  }

  /*
  int number = 0;
   int value = 90;
   
   myBus.sendControllerChange(channel, number, value); // Send a controllerChange
   delay(10000);
   */
}

void midiMessage(MidiMessage message) { // You can also use midiMessage(MidiMessage message, long timestamp, String bus_name)
  // Receive a MidiMessage
  // MidiMessage is an abstract class, the actual passed object will be either javax.sound.midi.MetaMessage, javax.sound.midi.ShortMessage, javax.sound.midi.SysexMessage.
  // Check it out here http://java.sun.com/j2se/1.5.0/docs/api/javax/sound/midi/package-summary.html
  /*
  println();
  println("MidiMessage Data:");
  println("--------");
  println("Status Byte/MIDI Command:"+message.getStatus());
  for (int i = 1; i < message.getMessage ().length; i++) {
    println("Param "+(i+1)+": "+(int)(message.getMessage()[i] & 0xFF));
  }*/
  int status = message.getStatus();
  byte[] data = message.getMessage();
  
  for(int i = 0; i < track[current_event].cc.size(); i++) {
    ccEvent e = track[current_event].cc.get(i);
    int val = 0;
    int num = 0;
    
    //Handle different MIDI data encondings
    switch(status){ 
      case PITCHBEND:
        // We need to combine the two bytes in midi message to
        // the pitchbend value
        val = data[2] << 7;
        val = (val | data[1]) - 8192;
        println("Pitchbend " + val);
        break;
      case AFTERTOUCH:
        val = data[1];
        println("Aftertouch " + val);
        break;
      case CC:
        num = data[1];
        val = data[2];
        println("ControlChange " + num + " val: " + val);
        break;
    }
    
    if((status == e.type) && (val > e.value) && (num == e.number)) {
      println("Got matching CC change");
      correctCC[i] = true;
    } 
  }
}

void noteOn(int channel, int pitch, int velocity) {
  // Received a noteOn
  println();
  println("Note On:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
}

void noteOff(int channel, int pitch, int velocity) {
  // Received a noteOff
  println();
  println("Note Off:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);

  Note n = track[current_event].note;  
  if (n.pitch == pitch) {
    println("Got the correct note: " + pitch);
    correctNote = true;
  }
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}

