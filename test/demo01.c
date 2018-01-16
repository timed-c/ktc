#include<stdio.h>
#include<cilktc.h>

void main(){
	printf("Main: start\n");
	sdelay(0, ms);
	sleep(1);
	sdelay(2, ms);
	sleep(1);
	fdelay(2, ms);
	printf("Main: end\n");	
}

