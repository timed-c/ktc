#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>


int lvchannel chan1;

int sense(){
  static int count = 0;
  int i;
  for(i = 0; i < 1000000; i++){}
  count++;
  printf("Sense: Value of sensor is %d\n", count);
  return count;
}

int compute(int d){
    printf("Compute : Value of sensor is %d\n", d);
}


task bar(){
 int c;
 while(1){
  c = sense();
  cwrite(chan1, c);
 }
}
 
task foo(){
 int d;
 while(1){
   cread(chan1, d);
   compute(d);
   sdelay(60, ms);
 } 
} 

void main(){
  bar();
  foo();
}

