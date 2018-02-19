/*A function implementing a simple periodic loop with fdelay*/

#include<stdio.h>
#include<cilktc.h>

int sense(){
  int i;
  static int count = 0;
  count++;
  countIteration();
  if(count % 2 == 0){
  	for(i = 0; i < (1000000000); i++){}
  }
  else{
	for(i = 0; i < (1000); i++){}
  }
  printf(" sense completed\n");

}

int countIteration(){
	static int i = 0;
	i++;
	printf("iteration %d\n ", i);

}

#include "fdelay.main"

