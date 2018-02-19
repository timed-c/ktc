/*A function implementing an aperiodic task*/

#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>

void senseA(){
   int i;
   printf("senseA\n");
   for(i = 0; i < 10000; i++){}
}


int compute(){
   static int count;
   count++;
   printf("compute\n");
   return (count * 1000); 
}

#include "aperiodic.foo"

task bar(){
  spolicy(FIFO_RM);
  while(1){
     senseA();
     sdelay(2000, ms);
  }
}

void main(){

  foo();
  bar();
}
