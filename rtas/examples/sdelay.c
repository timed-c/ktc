/*The main function implements a simple function that uses two sdelay timing points. Note that time between the start of the function and the first sdelay (line 11) takes 20 ms, even if the execution of initialize() takes less than 20 ms. Similarly, the time between the first and second sdelay (line 13) is 50 ms.*/

#include<stdio.h>
#include<cilktc.h>

int initialize();
int sense();

#include "sdelay.main"

int initialize(){
  printf("intializing\n");
}

int sense(){
  int i;
  for(i = 0; i < 1000; i++){}
}


