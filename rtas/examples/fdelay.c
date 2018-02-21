/*A function implementing a simple periodic loop with fdelay*/

#include<stdio.h>
#include<cilktc.h>

int sense(){
  int i;
  static int count = 0;
  count++;
  printf("iteration %d\n ", count++);
  if(count % 2 == 0){
  	for(i = 0; i < (1000000000); i++){}
  }
  else{
	for(i = 0; i < (1000); i++){}
  }
  printf(" sense completed\n");

}



#include "fdelay.main"

