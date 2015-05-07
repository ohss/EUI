import java.util.Random;

PImage img;  // Declare variable "a" of type PImage
Ground animateGround;
Cloud cloud1;
Cloud cloud2;
instruction instructionHolder;
People PeopleImg;
String animateState ="idle";

//dummy var for generating result
int whatInput = 0;  //0 idel, 1 right, 2 wrong
int testingCounter = 0 ; // sue for tragger the input
//currentNotes currentNotes = new currentNotes();;

void setupUI() {
  // The image file must be in the data folder of the current sketch
  // to load successfully
  frameRate(40);
  img = loadImage("logo.png");  // Load the image into the program

  animateGround = new Ground();
  cloud1 = new Cloud(1.3, 1, "cloud1.png");
  cloud2 = new Cloud(1.5, 2, "cloud2.png");
  instructionHolder = new instruction();
  PeopleImg = new People();
}

void drawGraphics(Boolean wasCorrect){

  /*
    Targets targets = currentNotes.getTargets();
    int[] notes = targets.notes; // Array of ints with range of [0-7]
    int aftertouch = targets.aftertouch; // Pressure with range of 0-127
    int[] orientation = targets.orientation; // roll and pitch with range of 0-127, mapped from 0-90 degrees
    int bend = targets.bend; // Bending range from -8192 - 8191
    //println("Targets: " + targets);

    Targets playerState = getPlayerState();
    //println("Player: " + playerState);
    */
  println((int)frameRate+"fps Targets: " + currentNotes.getTargets() + " " +wasCorrect + " User: " + getPlayerState());
  //turnOnLeds(getPlayerState().notes);

  clear();
  //println("the ainmation state = " + animateState);
  if(wasCorrect) // print only when it is true
    println("The wasCorrect = " +wasCorrect);

  if(animateState.equals("idle") )
  {
    background(77, 120, 143);
    if(wasCorrect)
    {
      //println("Setting animateState to right");
      //there was right
      animateState = "right";
      PeopleImg.changeState("right");
      instructionHolder.changeState("right");
    }
    else
    {
      if(getPlayerState().notes.length != 0)
      {
        animateState = "wrong";
        PeopleImg.changeState("wrong");
        instructionHolder.changeState("wrong");
      }
    }
    PeopleImg.display();
  }
  else if(animateState.equals("right") )
  {
    background(157, 228, 245);
    Boolean isAnimateDone = PeopleImg.display();

    //the right animation is done, turn it back to normal state
    if(isAnimateDone)
    {
      animateState = "idle";
      instructionHolder.changeState("normal");
    }
    else
    {
      //System.out.println("right animate not yet done");
    }
    animateGround.move();
  }
  else  //wrong animation
  {
    background(46, 89, 99);
    Boolean isAnimateDone = PeopleImg.display();

    //the wrong animation is done, turn it back to normal state
    if(isAnimateDone)
    {
      animateState = "idle";
      instructionHolder.changeState("normal");
    }
    else
    {
      //System.out.println("wrong animate not yet done!!!!!!!!!!!!!");
    }
    if(wasCorrect)
    {
      //println("Setting animateState to right");
      //there was right
      animateState = "right";
      PeopleImg.changeState("right");
      instructionHolder.changeState("right");
    }
  }

  cloud1.move();
  cloud1.display();
  cloud2.move();
  cloud2.display();
  animateGround.display();
  instructionHolder.display();

  //draw score
  textSize(24);
  textAlign(LEFT);
  text("Score: "+new Integer(score).toString(),850,46);
}

class instruction
{
  String state = "normal";
  PImage[] RightNote = new PImage[8];
  PImage[] WrongNote = new PImage[8];
  PImage[] TargetNote = new PImage[8];
  PImage[] NonTargetNote = new PImage[8];
  PImage[] orientation = new PImage[4];
  PImage bandHarder;
  PImage aftertouch;
  PImage noteBackground;
  Targets userInput;
  int ringWIdth = 261;
  int ringHeight = 210;
  int ringX = 400;
  int ringY = 420;
  int OtherY = 230;
  int[] otherX ;
  int otherHeight = 168;
  int otherWeidth = 209;

  instruction()
  {
    for(int i = 0 ; i< 8 ; i++)
    {
      RightNote[i] = loadImage("note"+new Integer(i+1).toString()+"Right.png");
      TargetNote[i] = loadImage("note"+new Integer(i+1).toString()+"Normal.png");
      NonTargetNote[i] = loadImage("note"+new Integer(i+1).toString()+"nonTarget.png");
      WrongNote[i] = loadImage("note"+new Integer(i+1).toString()+"Wrong.png");
    }
    orientation[0] = loadImage("orientationXLeft.png");
    orientation[1] = loadImage("orientationXRight.png");
    orientation[2] = loadImage("orientationYBack.png");
    orientation[3] = loadImage("orientationYFont.png");
    bandHarder = loadImage("bandHarder.png");
    aftertouch = loadImage("afterTouchHarder.png");
    noteBackground = loadImage("noteBackground.png");
    otherX = new int[]{10, 290, 520, 800, 1000};
  }
  //change the state of people img
  void changeState(String newState)
  {
    state = newState;
    if(newState == "wrong" || newState == "right"){
      userInput = getPlayerState();//get user current input
    }
  }
  void display()
  {
    //output the ring
    image(noteBackground, ringX, ringY, ringWIdth, ringHeight);

    //get the targets
    Targets targetCommand= currentNotes.getTargets();

    //display all stuff;
    if(state.equals("normal"))
    {
      //display ring
      for(int i=0; i < 8; i++){
        if(TargetHaveThisNote(i, targetCommand.notes)){//+1)){
          image(TargetNote[i], ringX, ringY, ringWIdth, ringHeight);
        }else{
          image(NonTargetNote[i], ringX, ringY, ringWIdth, ringHeight);
        }
      }

      //display other
      int numberPicDisplayed =0;

      //after touch part
      if(targetCommand.aftertouch >0){
        image(aftertouch, otherX[numberPicDisplayed], OtherY, otherWeidth, otherHeight);
        numberPicDisplayed++;
      }
      //bend paart
      if(targetCommand.bend >0){
        image(bandHarder, otherX[numberPicDisplayed], OtherY, otherWeidth, otherHeight);
        numberPicDisplayed++;
      }
      //orientation x
      if(targetCommand.orientation[1] != 0){
        if(targetCommand.orientation[1] >100){  //right
          //println("Orientation right");
          image(orientation[0], otherX[numberPicDisplayed], OtherY, otherWeidth, otherHeight);
          numberPicDisplayed++;
        }else if(targetCommand.orientation[1] <30){ //left
          //println("Orientation left");
          image(orientation[1], otherX[numberPicDisplayed], OtherY, otherWeidth, otherHeight);
          numberPicDisplayed++;
        }
      }else{
        //println("Orientation normal");
      }

      //orientation y
      if(targetCommand.orientation[0] >0){
        image(orientation[3], otherX[numberPicDisplayed], OtherY, otherWeidth, otherHeight);
        numberPicDisplayed++;
      }

    }
    else if(state.equals("wrong"))    //wrong state
    {
      for(int i =0 ; i < 8; i++){
        if(UserPressThisNote(i, userInput.notes)){//+1)){
          image(WrongNote[i], ringX, ringY, ringWIdth, ringHeight);
        }else if(TargetHaveThisNote(i, targetCommand.notes)){//+1)){
          image(TargetNote[i], ringX, ringY, ringWIdth, ringHeight);
        }else{
          image(NonTargetNote[i], ringX, ringY, ringWIdth, ringHeight);
        }
      }


          //display other
          int numberPicDisplayed =0;

          //after touch part
          if(targetCommand.aftertouch >0){
            image(aftertouch, otherX[numberPicDisplayed], OtherY, otherWeidth, otherHeight);
            numberPicDisplayed++;
          }
          //bend paart
          if(targetCommand.bend >0){
            image(bandHarder, otherX[numberPicDisplayed], OtherY, otherWeidth, otherHeight);
            numberPicDisplayed++;
          }
          //orientation x
          if(targetCommand.orientation[1] != 0){
            if(targetCommand.orientation[1] >100){  //right
              //println("Orientation right");
              image(orientation[0], otherX[numberPicDisplayed], OtherY, otherWeidth, otherHeight);
              numberPicDisplayed++;
            }else if(targetCommand.orientation[1] <30){ //left
              //println("Orientation left");
              image(orientation[1], otherX[numberPicDisplayed], OtherY, otherWeidth, otherHeight);
              numberPicDisplayed++;
            }
          }
    }
    else if(state.equals("right"))
    {
      for(int i =0 ; i < 8; i++){
        if(UserPressThisNote(i, targetCommand.notes)){//+1)){
          image(RightNote[i], ringX, ringY, ringWIdth, ringHeight);
        }else{
          image(NonTargetNote[i], ringX, ringY, ringWIdth, ringHeight);
        }
      }
    }

  }
  boolean TargetHaveThisNote(int theNoteTested, int[] notes){
    for(int i = 0 ; i < notes.length; i++){
      if(notes[i]  == theNoteTested)
        return true;
    }
    return false;
  }
  boolean UserPressThisNote(int theNoteTested, int[] notes){
    for(int i = 0 ; i < notes.length; i++){
      if(notes[i]  == theNoteTested)
        return true;
    }
    return false;
  }
}

class People
{
  String state = "normal";
  PImage[] normalImg = new PImage[4];
  PImage[] wrongImg = new PImage[12];
  PImage[] rightImg  = new PImage[12];
  int CurrentImg = 0;
  int ImgNumberCount =0;
  float imgRatio = 1.85;
  int specialAnimateLoop = 0;

  People()
  {
    for(int i =0; i<4; i++){
      normalImg[i] = loadImage("normal"+new Integer(i+1).toString()+".png");
    }
    for(int i =0; i<12; i++){
      rightImg[i] = loadImage("right"+new Integer(i+1).toString()+".png");
    }
    for(int i =0; i<12; i++){
      wrongImg[i] = loadImage("wrong"+new Integer(i+1).toString()+".png");
    }
  }
  //return end animation or not
  //return false when animation not yet done or in normal state
  Boolean display()
  {
    Boolean result = false;
    if(state.equals("normal"))
    {
      if(CurrentImg>3)
        CurrentImg =0;
      image(normalImg[CurrentImg], 60, 400, 100*imgRatio, 150*imgRatio);
    }
    else if(state.equals("right"))
    {
      if(CurrentImg>11)
      {
        CurrentImg =0;
        if(specialAnimateLoop > 0)//2)
        {
          result = true;
          state = "normal";
          specialAnimateLoop = 0;
        }
        specialAnimateLoop++;
      }
      image(rightImg[CurrentImg], 60, 400, 100*imgRatio, 150*imgRatio);
    }
    else if(state.equals("wrong"))    //wrong state
    {
      if(CurrentImg>11)
      {
        CurrentImg =0;
        if(specialAnimateLoop >0)//2)
        {
          result = true;
          state = "normal";
          specialAnimateLoop = 0;
        }
        specialAnimateLoop++;
      }
      image(wrongImg[CurrentImg], 60, 400, 100*imgRatio, 150*imgRatio);
    }

    if(ImgNumberCount >0)
    {
      CurrentImg++;
      ImgNumberCount=0;
    }
    else
      ImgNumberCount++;


    return result;
  }

  //change the state of people img
  void changeState(String newState)
  {
    state = newState;
  }
}

class Ground
{
  int pixelPerMove = 12;
  PImage groundImg;
  int xPos=0;
  // 256 x 140
  Ground ()
  {
    groundImg = loadImage("ground.png");
  }
  void display()
  {
    int numberOfTimes =  1024/256 +2;
    for(int i = 0 ; i < numberOfTimes; i++){
      image(groundImg, xPos +i*256, 646);
    }
  }
  void move()
  {
    xPos-=pixelPerMove;
    if(xPos < -256)
      xPos += 256;
  }
}

class Cloud
{
  //150X??
  float imgRatio;
  int movingSpeed;
  PImage cloudImg;
  int[][] cloudPos;

  Cloud (float ratio, int speed, String ImgName)
  {
     imgRatio = ratio;
     movingSpeed = speed;
     Random randomGenerator = new Random();
     int noOfCloud = randomGenerator.nextInt(4)+1;
     cloudPos= new int[noOfCloud][2];
     for(int i = 0 ; i < noOfCloud;i++)
     {
       cloudPos[i][0]= randomGenerator.nextInt(1024);
       cloudPos[i][1]= randomGenerator.nextInt(250);
     }

     cloudImg= loadImage(ImgName);
  }
  void display()
  {
    for(int i = 0 ; i < cloudPos.length; i++)
    {
      image(cloudImg, cloudPos[i][0], cloudPos[i][1], 150*imgRatio, 100*imgRatio);
    }
  }
  void move()
  {
    for(int i =0; i < cloudPos.length; i++){
      cloudPos[i][0] -= movingSpeed;
      if(cloudPos[i][0] <-200 )
      {
        Random randomGenerator = new Random();
        cloudPos[i][0] = 1100 + randomGenerator.nextInt(300);
        cloudPos[i][1] = randomGenerator.nextInt(250);
      }
    }
  }
}

/*
Targets getPlayerState()
{
  //idle state
  if(whatInput == 0 )
  {
    return new targets(0,0,10,10,20);
  }
  else if (whatInput == 1 )
  {
    //right state
    return new targets(1,0,10,10,20);
  }
  else
  {
    //wrong state
    return new targets(2,10,10,10,20);
  }
}

//dummy class for testing purpose
class targets
{
     //Random randomGenerator = new Random();
     //int noOfCloud = randomGenerator.nextInt(4)+1;
  int[] notes;
  int aftertouch;
  int[] orientation = new int[2];
  int bend;

  targets(int numberOfNotes, int aftertouchValue, int orientationintX, int orientationY, int bendInt)
  {
    notes = new int[numberOfNotes];
    Random randomGenerator = new Random();
    for(int i = 0 ; i < numberOfNotes; i ++)
    {
      notes[i] = randomGenerator.nextInt(7);
    }

    aftertouch = aftertouchValue;

    orientation[0] = orientationintX;
    orientation[1] = orientationY;

    bend = bendInt;
  }
}
*/
//dummy class currentNotes
/*
class currentNotes{
   targets getTargets(){
      return new targets(2,4,10,10,20);
   }
}
*/

/*
    int[] notes = targets.notes; // Array of ints with range of [0-7]
    int aftertouch = targets.aftertouch; // Pressure with range of 0-127   if aftertouch >0
    int[] orientation = targets.orientation; // roll and pitch with range of 0-127, mapped from 0-90 degrees   >0
    int bend = targets.bend; // Bending range from -8192 - 8191      > 0 show
*/

/*
void draw() {
  if(testingCounter <300){
    drawGraphics(false);    //idle state
  }
  else if(testingCounter == 300)
  {
    whatInput =1;
    drawGraphics(true);    //true state
    System.out.println("i got to right state  ===========input=====================================");
  }
  else if(testingCounter == 600)
  {
    whatInput=2;
    drawGraphics(false);    //Wrong state
    System.out.println("i got to wrong state xxxxxxxxxinputxxxxxxxxxxxxxxxxxxxxxxxxx");
  }
  else
  {
    whatInput =0;
    drawGraphics(false);    //idle state
    System.out.println("i back to idle.....input.............");
  }

  testingCounter++;
  score = testingCounter;
}
*/
