/*
  AnalogReadSerial
  Reads an analog input on pin 0, prints the result to the serial monitor.
  Attach the center pin of a potentiometer to pin A0, and the outside pins to +5V and ground.

 This example code is in the public domain.
 */

// the setup routine runs once when you press reset:
void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
  
  //set port to output
  for(int  i = 0 ; i < 8; i++){
    pinMode(i, OUTPUT); 
  }
  for(int i = 24; i< 32; i++){
    pinMode(i, OUTPUT); 
  }
  
}

// the loop routine runs over and over again forever:
void loop() {
  while (Serial.available() >= 16) {
    //0100000000000000
    //check input from computer  
    for(int i = 24; i< 32; i++){
      int result = Serial.read();
      digitalWrite(i, (result == 49 )?HIGH:LOW );
    }
    for(int  i = 0 ; i < 8; i++){
      int result = Serial.read();
      digitalWrite(i, ( result== 49 )?HIGH:LOW );
    }

    // Read the buffer until it's empty
    while (Serial.available() > 0) {
      Serial.read();
    }
    
  }
  //read data
  analogReadResolution(14);
  for(int i = 0 ; i < 12; i++){
    String portWillRead = "A"+String(i);
    // read the input on analog pin 0:
    int sensorValue = analogRead(i);
    // print out the value you read:
    Serial.print( String(sensorValue) + "\t");
  }
  Serial.println();
  delay(10);        // delay in between reads for stability
}
