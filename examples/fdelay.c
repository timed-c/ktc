/*A function implementing a simple periodic loop with fdelay*/

#include<stdio.h>
#include<cilktc.h>

int sense(){
  int i;
  static int count = 0;
  count++;
  if(count % 2 == 0){
  	for(i = 0; i < (100000000); i++){}
  }
  else{
	for(i = 0; i < (1000); i++){}
  }
  printf(" sense completed");

}

int countIteration(){
	static int i = 0;
	i++;
	printf("\n%d :", i);

}

void main(){
  while(1){
     countIteration();
     sense();
     fdelay(30, ms);
  }
}

