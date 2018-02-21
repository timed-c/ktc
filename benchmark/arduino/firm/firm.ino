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
     handle_deadline();
     goto lbl;
  }
  sense();
  lbl:
  Timer1.restart();
}
