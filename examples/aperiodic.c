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
   return (count); 
}

task foo(){
  int a;
  spolicy(FIFO_RM);
  aperiodic(3000, ms);
  while(1){
     a = compute();
     sdelay(a*1000, ms);
  }
}

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
