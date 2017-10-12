/* Function foo calculates the time taken to execute compute using sdelay*/
#include<stdio.h>
#include<cilktc.h>

void compute(){
	int i;
	for(i = 0; i < 100000000; i++) {} 
}


unsigned int foo(){
   compute();
   return sdelay(0, ms);
}

void main(){
   unsigned int t;
   t = foo();
   printf("Time taken to executed is %d\n", t);

} 
