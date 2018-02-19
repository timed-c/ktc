
/*A function that implements a periodic loop using sdelay. The example shows an overshoot every other iteration of the while loop */

#include<stdio.h>
#include<cilktc.h>


int sense(){
  int i;
  static int count = 0;
  count++;
  printf("sense\n");
  if(count % 2 == 0)
  	for(i = 0; i < (100000000); i++){}
  else 
	for(i = 0; i < (1000); i++){}

}

#include "sdelay-overshot.main"
