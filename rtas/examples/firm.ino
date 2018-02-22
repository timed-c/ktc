#include <setjmp.h>
#include "DueTimer.h"
jmp_buf env;
unsigned long tinit = 0;
int timer_interrupt = 0;
void callback(){
  timer_interrupt = 1;
}
void setup(){
  Timer3.setPeriod(30000);//30ms
  Timer3.attachInterrupt(callback);  
  Timer3.start();
}
void loop() {
  int i=0;
  tinit = millis();
  i = setjmp(env);
  if(i == 0){
     sense();
  }
  Timer3.stop();
  timer_interrupt = 0;
  delay(30 - (millis() - tinit));
  Timer3.start();
}


