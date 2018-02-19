/* A function implementing a periodic loop using sdelay, illustrating an error handling mechanism that ensures that the overshoot is compensated to make it stay in phase. */

#include<stdio.h>
#include<cilktc.h>

int sense(){
  int i;
  for(i = 0; i < 1000; i++){}
  printf("Sense completed\n");
}

#include "sdelay-overshot-correction.main"

