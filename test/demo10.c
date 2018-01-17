#include<stdio.h>
#include<cilktc.h>
/*Timing point with 0 delay and no resolution*/

int  main(){
	int a, b;
	printf("Start \n");
	sdelay(0);
        printf("End \n");
	return 0;	
}

