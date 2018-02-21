#include <setjmp.h>
#include "TimerOne.h"
jmp_buf env;
void setup(){
  Timer1.initialize(500000);  
  Timer1.attachInterrupt(callback);  
}
void callback(){
  longjmp(env, 2);
}
void loop() {
  int i;
  i = setjmp(env);
  if (i != 0){ 
     goto lbl;
  }
  sense();//read from sensor
  lbl:
  Timer1.restart();
}
