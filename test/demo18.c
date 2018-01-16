#include<stdio.h>
#include<cilktc.h>
/*Timing point with integer resolution*/

void foo(){
	sdelay(0);
	printf("Starting bar\n");
	while(1){}
	fdelay(100, ms);
	printf("bar : fdelay completed\n");
	sdelay(50, ms);
	printf("ending bar\n");
}

void main(){
	foo();
}


