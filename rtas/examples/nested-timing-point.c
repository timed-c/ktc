/*A function implementing nested timing-points*/

#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>

int control(){
   int i;
   for(i = 0; i <1000000000; i++){}	
   printf("control completed\n");
}

void compute(){
  control();
  sdelay(30, ms);
}

void main(){
  int a;
  compute();
  fdelay(50, ms);
  printf("end of main\n");

}

