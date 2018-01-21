/*A function implementing two task with EDF scheduling policy*/

#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>


void senseA(){
   int i;
   printf("senseA\n");
   for(i = 0; i < 10000; i++){}
}

void senseB(){
   int i;
   printf("senseB\n");
   for(i = 0; i < 50000; i++){}
}

void initialize(){}

task foo(){ 
   spolicy(EDF);
   while(1){
      senseA();
      sdelay(30, ms);
   }
}

task bar(){
  spolicy(EDF);
  while(1){
     senseB();
     sdelay(50, ms);
     sdelay(15, ms);
  }
}
void main(){
  initialize();
  foo();
  bar();
}

