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

#include "spolicy.main"



