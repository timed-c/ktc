#include<stdio.h>
#include<cilktc.h>
/*Timing point with integer resolution*/

void main(){
	int i, j;
	int a , b;
	for(i = 0; i < 100000000; i++){}
	a = sdelay(0, ms);
	printf("overshoot %d\n", a);
	for(i = 0; i < 100000000; i++){}
	a = stp(0, 30, ms);
	printf("overshoot %d\n", a);
        printf("End \n");
}

