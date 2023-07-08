#include <EEPROM.h>

//X:
#define dirPin 2
#define stepPin 3
#define limitSwitchPin 10

//Z:
#define dirPinZ 9
#define stepPinZ 8
#define stepsPerRevolution 500
#define stepDelay 600
#define mmToStep 1000
#define ZmmToStep 480

// variable for data collection
int z_impulse_period = 1000; // microsec
// int z_impulse_period = 500; // microsec
// int z_impulse_period = 3000; // microsec
int t_waiting = 8000; // millisec
// int t_waiting = 20000; // millisec
// int t_waiting = 0; // millisec

int homingState = 0;
bool isReturningFromHoming = false;
unsigned long stateChangeTime = 0;
int homingPulseDelay = 50;

long stepCount = 0;
long stepTarget = 0;
int stepMultiplier = 1; //for step to mm conversion in X
bool isSetHome = true; //distinguish between going home and setting home
bool isGoingLeft = true; //for homing
bool isGoingDown = true; 
unsigned long homeStepCounter = 0;
//unsigned long zStepCounter = 0;
long absolutePos = 0;


bool repeat = false;
long n_sampling = 0;
long total_sampling = 0;
//******
//Driver takes pulse widths no lower than 2.5 microseconds
//dirPin HIGH -> moving away from stepper
//screw pitch 5mm

//Homing States:
//0 - idle
//1 - homing requested
//******

String in_chars = "";


void setup() {

  //pinMode(stepPinZ, OUTPUT);
  //pinMode(dirPinZ, OUTPUT);

  pinMode(stepPin, OUTPUT);
  pinMode(dirPin, OUTPUT);
  pinMode(limitSwitchPin, INPUT);

  homingState = 0;

  Serial.begin(115200);
  delay(100);
  Serial.println("");
  Serial.println("");

  Serial.println("------Commands:----------------");
  Serial.println("st+X  (move X steps to the right)");
  Serial.println("st-X  (move X steps to the left)");
  Serial.println("mm+Xr  (move X millimetres to the right)");
  Serial.println("mm-X  (move X millimetres to the left)");
  Serial.println("setHome  (set current position as home)");
  Serial.println("home  (go to home)");
  Serial.println("aaa");
  Serial.println("-------------------------------");

}

void loop() {
  readSerialCommand();

  if (stepCount < stepTarget) {
    // Serial.println('-=---=--=');
    delayMicroseconds(50);
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(50);
    digitalWrite(stepPin, LOW);
    // Serial.println('-=---=--=');
    stepCount++;
    
    if (isGoingLeft){
      absolutePos--;
    }else{
      absolutePos++;
    }

    if (!(absolutePos % 10) && !isReturningFromHoming){
      Serial.println('x' + String(-absolutePos));
    }
    
    if (stepCount == stepTarget) {
      Serial.println("Done");
      if(n_sampling < total_sampling-1){
        n_sampling++;
        delay(1000);
        moveStepperFromSerial();
        sendMessage("mov");
        stepCount = 0;
      }
      Serial.println("-------------------------");
      isReturningFromHoming = false;
    }
  }
}

void sendMessage(const String& message) {
  Serial.println(message);
}

void moveStepperFromSerial() {
  if(n_sampling <= total_sampling)
  {
    if (in_chars[2] == '+' || in_chars[2] == '-') {
      digitalWrite(dirPin, in_chars[2] == '+'); //HIGH if 3rd char is '+'
      isGoingLeft =  in_chars[2] == '-';
      char *dist = &in_chars[3]; //eliminate first two chars
      dist[strlen(dist) - 1] = '\0'; //eliminate \n
      //    Serial.println(atof(dist)*stepMultiplier);
      stepTarget = atof(dist) * stepMultiplier;
      Serial.print("moving [");
      Serial.print(in_chars[2]);
      Serial.print(stepTarget);
      Serial.println("] steps in X...");
      if (stepTarget) {
  //      Serial.println("running...");
        stepCount = 0;
      } else {
        Serial.println("[invalid step count!]");
      }
    } else {
      Serial.println("[invalid command!]");
    }
  }

}

void startHoming() {
  homingState = 1;
  stateChangeTime = millis();
  homingPulseDelay = 50;
  digitalWrite(dirPin, LOW);
  isGoingLeft = true;
  homeStepCounter = 0;
  Serial.println("running...");
}


void readSerialCommand() {
  //Read Serial ASCII input
  char in_char = ' ';
  while (Serial.available()) {
    in_char = Serial.read();
    if (int(in_char) != -1) {
      in_chars += in_char;
    }
  }
  
  // identify commands
  if (in_char == '\n') {
    Serial.print(in_chars); //includes newLine at the end
    if (in_chars[0] == 's' && in_chars[1] == 't') {
      stepMultiplier = 1;
      moveStepperFromSerial(); //move
    } else if (in_chars[0] == 'm' && in_chars[1] == 'm') {
      stepMultiplier = mmToStep;
      if(in_chars[4] == 'r'){
        total_sampling = 10;
      }
      moveStepperFromSerial();
      
      
    }  else if (in_chars[0] == 's' && in_chars[1] == 'e') { // originally in_chars == "setHome\n"
      isSetHome = true;
      startHoming();           //back to origin
    } else if (in_chars[0] == 'h' && in_chars[1] == 'o') {    // originally in_chars == "home\n"
      isSetHome = false;
      startHoming();
    } else{
      Serial.println("[invalid command!]");
    }
    
    in_chars = "";
  }

}
