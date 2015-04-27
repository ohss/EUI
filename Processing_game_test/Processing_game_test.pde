import themidibus.*;
import javax.sound.midi.MidiMessage; //Import the MidiMessage classes http://java.sun.com/j2se/1.5.0/docs/api/javax/sound/midi/MidiMessage.html
import javax.sound.midi.SysexMessage;
import javax.sound.midi.ShortMessage;

public static final int CC = 176;
public static final int AFTERTOUCH = 208;
public static final int PITCHBEND = 224;
public static final int CTRL_CH = 0;
public static final int GAME_CH = 1;

public MidiBus myBus;   // The MidiBus
eventList currentNotes; // List of notes and CC events that need to be completed
int score;              // Current Score
int abletonEventNoteNumber;  // The number of the note for the next Ableton Live loop

void setup() {
  size(400, 400);
  background(255);
  stroke(0);
  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

  //                 Parent  In        Out
  //                   |     |          |
  myBus = new MidiBus(this, "IAC Bus 1", "IAC Bus 2"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.
  currentNotes = new eventList();
  score = 0;
  abletonEventNoteNumber = 2; // Magic number
}

void draw() {

  if(currentNotes.hasBeenCompletelyFullfilled() && currentNotes.size() > 0){
    score++;
    println("New score + " + score);
    currentNotes.clear();

    //Send MIDI to go to next event in Ableton
    myBus.sendNoteOn(GAME_CH, abletonEventNoteNumber, 127);
    delay(100);
    myBus.sendNoteOff(GAME_CH, abletonEventNoteNumber, 127);
    abletonEventNoteNumber++;
  }
  // TODO: Illustrate on the screen what to do based on the currentNotes list of gameEvents

}

void midiMessage(MidiMessage message) {
  // Receive a MidiMessage
  // println();
  // println("MidiMessage Data:");
  // println("--------");
  // println("Status Byte/MIDI Command:"+message.getStatus());
  // for (int i = 1; i < message.getMessage ().length; i++) {
  //   println("Param "+(i+1)+": "+(int)(message.getMessage()[i] & 0xFF));
  // }

  int status = message.getStatus();
  byte[] data = message.getMessage();
  int val = 0, num = 0, type = 0;
  boolean isGameLogic = false;

  // Handle different MIDI data encodings
  // Message from Game logic
  switch(status - GAME_CH){
    case PITCHBEND:
      val = (data[2] << 7) | data[1] - 8192; // We need to combine the two bytes to form pitchbend value
      isGameLogic = true;
      type = PITCHBEND;
      println("GAME: Pitchbend " + val);
      break;
    case AFTERTOUCH:
      val = data[1];
      isGameLogic = true;
      type = AFTERTOUCH;
      println("GAME: Aftertouch " + val);
      break;
    case CC:
      num = data[1]; val = data[2];
      isGameLogic = true;
      type = CC;
      println("GAME: ControlChange " + num + " val: " + val);
      break;
  }

  // Message from Controller
  switch(status - CTRL_CH){
    case PITCHBEND:
      val = (data[2] << 7) | data[1] - 8192;
      isGameLogic = false;
      type = PITCHBEND;
      println("CTRL: Pitchbend " + val);
      break;
    case AFTERTOUCH:
      val = data[1];
      type = AFTERTOUCH;
      isGameLogic = false;
      println("CTRL: Aftertouch " + val);
      break;
    case CC:
      num = data[1]; val = data[2];
      type = CC;
      isGameLogic = false;
      println("CTRL: ControlChange " + num + " val: " + val);
      break;
  }
  //Create a gameEvent from the incomming message
  gameEvent newEvent = new gameEvent(null, new ccEvent(type, num, val));

  if(isGameLogic){
    // Adding the message to the currentNotes list
    currentNotes.add(newEvent);
    println("GAME: Adding new CC New list:\n" + currentNotes.toString());
  }else{
    // Checking if the received message fullfills a condition on the list 
    gameEvent listElement = currentNotes.contains(newEvent);
    if(listElement != null){
      println("CTRL: Found a CC on the list");
      listElement.match();
    }
  }
}

void noteOn(int channel, int pitch, int velocity) {
  // Received a noteOn
  // println();
  // println("Note On:");
  // println("--------");
  // println("Channel:"+channel);
  // println("Pitch:"+pitch);
  // println("Velocity:"+velocity);

  // Create a new gameEvent from the received note
  gameEvent newEvent = new gameEvent(new Note(1, pitch, velocity), null);

  if(channel == GAME_CH){
    currentNotes.add(newEvent);
    println("GAME: Received a new note."); // Game list:\n" + currentNotes.toString());
  }else if(channel == CTRL_CH){
    //Check if the played notes are what we are looking for
    print("CTRL: Checking for correct note: ");
    gameEvent listElement = currentNotes.contains(newEvent);
    if(listElement != null){
      print("YES\n");
      listElement.match();
    }else{
      print("NO\n");
    }
  }
}

void noteOff(int channel, int pitch, int velocity) {
  // Received a noteOff
  // println();
  // println("Note Off:");
  // println("--------");
  // println("Channel:"+channel);
  // println("Pitch:"+pitch);
  // println("Velocity:"+velocity);
  // Create a new gameEvent from the received note
  
  /*
  if(channel == GAME_CH){
    currentNotes.remove(new gameEvent(new Note(1, pitch, velocity), null));
  }
  */
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}
