import themidibus.*;
import javax.sound.midi.MidiMessage; //Import the MidiMessage classes http://java.sun.com/j2se/1.5.0/docs/api/javax/sound/midi/MidiMessage.html
import javax.sound.midi.SysexMessage;
import javax.sound.midi.ShortMessage;

public static final int CC = 176;
public static final int AFTERTOUCH = 208;
public static final int PITCHBEND = 224;
public static final int CTRL_CH = 0;
public static final int GAME_CH = 1;
public static final int ABLETON_CH = 3;

public MidiBus myBus;                   // The MidiBus
public Targets playerState;             // The current state of the player
public ArrayList<Integer> playerNotes;  // The current notes held by the player

public eventList currentNotes; // List of notes and CC events that need to be completed
int score;              // Current Score
int abletonEventNoteNumber;  // The number of the note for the next Ableton Live loop
boolean abletonTrigger = false;

//int[] scale = {0, 2, 4, 5, 7, 9, 10, 11};
int[] scale = {4, 6, 8, 9, 11, 13, 14, 18};
int octave = 5;

void setup() {
  size(1024, 768, P2D);
  //background(255);
  //stroke(0);
  //MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

  //                 Parent  In        Out
  //                   |     |          |
  myBus = new MidiBus(this, "IAC Bus 1", "IAC Bus 2"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.
  currentNotes = new eventList();
  playerNotes = new ArrayList<Integer>();
  playerState = new Targets(new int[]{}, 0, new int[]{0,0}, 0);
  score = 0;
  abletonEventNoteNumber = 0; // Magic number
  // Setup orientation board
  controller_setup();
  setupUI();
  // Trigger first event

  myBus.sendNoteOn(ABLETON_CH, abletonEventNoteNumber, 127);
  delay(100);
  myBus.sendNoteOff(ABLETON_CH, abletonEventNoteNumber, 127);

  //abletonEventNoteNumber++;
}

void draw() {
  if(currentNotes.hasBeenCompletelyFullfilled() && currentNotes.size() > 0){
    score++;
    //Send MIDI to go to next event in Ableton
    abletonTrigger = true;
    drawGraphics(true);
    currentNotes.clear();
  }else{
    drawGraphics(false);
  }
  // Send Ableton notes
  /*
  for(int i = 0; i < 32; i++){
    print("Sending note:" + i);
     myBus.sendNoteOn(3, i, 127);
    delay(100) ;
    myBus.sendNoteOff(3, i, 127);
    delay(2000);
  }
  */
}

/**
 *


void drawGraphics(Boolean wasCorrect){

    Targets targets = currentNotes.getTargets();
    int[] notes = targets.notes; // Array of ints with range of [0-7]
    int aftertouch = targets.aftertouch; // Pressure with range of 0-127
    int[] orientation = targets.orientation; // roll and pitch with range of 0-127, mapped from 0-90 degrees
    int bend = targets.bend; // Bending range from -8192 - 8191
    //println("Targets: " + targets);

    Targets playerState = getPlayerState();
    //println("Player:  " + playerState);

    turnOnLeds(notes);
}
*/
void turnOnLeds(int[] notes) {
  byte[] leds = {48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48};
  for (int note : notes) {
    leds[(note*2)+1] = 49;
  }
  //println("serialoutput: " + new String(leds));
  if(controlSerial != null)
    controlSerial.write(leds);
}

Targets getPlayerState(){
  int[] notes = new int[playerNotes.size()];
  for(int i = 0; i < notes.length; i++){
    notes[i] = playerNotes.get(i).intValue();
  }
  return new Targets(notes, playerState.aftertouch, playerState.orientation, playerState.bend);
}

void updatePlayerState(gameEvent e, Boolean isNoteOn){

  if(e.note != null){ // Update notes
    int relativePitch = e.note.relativePitch() % 12;
    int noteIndex = java.util.Arrays.binarySearch(scale, relativePitch);
    if(isNoteOn){ //Adding note to the list
       //println("Adding note to playerState " + e.note.pitch() % 12);
       if(noteIndex >= 0){
         playerNotes.add(new Integer(noteIndex));
       }
    }else{
      playerNotes.remove(new Integer(noteIndex));
    }
  }else if(e.cc != null){  //Update CC portion of player state
    switch(e.cc.type){
      case PITCHBEND: playerState.bend = e.cc.value; break;
      case AFTERTOUCH: playerState.aftertouch = e.cc.value; break;
      case CC:
        if(e.cc.number == 1)
          playerState.orientation[0] = e.cc.value;
        if(e.cc.number == 2)
          playerState.orientation[1] = e.cc.value;
    }
  }
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
      val = Math.abs((data[2] << 7) | data[1]) - 8192; // We need to combine the two bytes to form pitchbend value
      isGameLogic = true;
      type = PITCHBEND;
      //println("GAME: Pitchbend " + val);
      break;
    case AFTERTOUCH:
      val = data[1];
      isGameLogic = true;
      type = AFTERTOUCH;
      //println("GAME: Aftertouch " + val);
      break;
    case CC:
      num = data[1]; val = data[2];
      isGameLogic = true;
      type = CC;
      //println("GAME: ControlChange " + num + " val: " + val);
      break;
  }

  // Message from Controller
  switch(status - CTRL_CH){
    case PITCHBEND:
      val = (data[2] << 7) | data[1] - 8192;
      isGameLogic = false;
      type = PITCHBEND;
      //println("CTRL: Pitchbend " + val);
      break;
    case AFTERTOUCH:
      val = data[1];
      type = AFTERTOUCH;
      isGameLogic = false;
      //println("CTRL: Aftertouch " + val);
      break;
    case CC:
      num = data[1]; val = data[2];
      type = CC;
      isGameLogic = false;
      //println("CTRL: ControlChange " + num + " val: " + val);
      break;
  }
  //Create a gameEvent from the incomming message
  gameEvent newEvent = new gameEvent(null, new ccEvent(type, num, val));

  if(isGameLogic){
    // Adding the message to the currentNotes list
    currentNotes.add(newEvent);
    //println("GAME: Adding new CC New list:\n" + currentNotes.toString());
  }else{
    //Adding to player state
    updatePlayerState(newEvent, false);

    // Checking if the received message fullfills a condition on the list
    gameEvent listElement = currentNotes.contains(newEvent);
    if(listElement != null){
      //println("CTRL: Found a CC on the list");
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
    println("GAME: Received a new note: " + pitch); // Game list:\n" + currentNotes.toString());
  }else if(channel == CTRL_CH){
    //Add to playerState
    updatePlayerState(newEvent, true);

    //THIS WAS MOVED TO NOTE OFF
    //Check if the played notes are what we are looking for
    println("CTRL: Checking for correct note: " + pitch);
    gameEvent listElement = currentNotes.contains(newEvent);
    if(listElement != null){
      //print("YES\n");
      listElement.match();
    }else{
      //print("NO\n");
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

  gameEvent newEvent = new gameEvent(new Note(1, pitch, velocity), null);

  if(channel == CTRL_CH){
    // Send the note to Ableton
    if(abletonTrigger){
      abletonEventNoteNumber = (abletonEventNoteNumber + 1)%23;
      myBus.sendNoteOn(ABLETON_CH, abletonEventNoteNumber, 127);
      //delay(100);
      myBus.sendNoteOff(ABLETON_CH, abletonEventNoteNumber, 127);
      println("New score + " + score + " Next note: " + abletonEventNoteNumber);
      abletonTrigger = false;
    }

    //Remove from the playerState
    updatePlayerState(new gameEvent(new Note(1, pitch, velocity),null), false);
  }
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
