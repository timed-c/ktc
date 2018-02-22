#include <setjmp.h>
#include "TimerOne.h"
jmp_buf env;
unsigned long tinit = 0;
void setup(){
  Timer1.initialize();  
  Timer1.setPeriod(30000);//30ms
  Timer1.attachInterrupt(callback);  
  Timer1.start();
}
void callback(){
  longjmp(env, 2);
}
void loop() {
  int i;
  tinit = millis();
  i = setjmp(env);
  if(i == 0){
     sense();//read from sensor
  }
  Timer1.stop();
  delay(30 - (millis() - tinit));
  Timer1.restart();
}


