#include<stdio.h>
#include<cilktc.h>
/*Timing point with integer resolution*/

void main(){
	int i, j;
	int a , b;
	for(i = 0; i < 100000000; i++){}
	a = sdelay(0, ms);
	printf("overshoot 1 %d\n", a);
	for(i = 0; i < 100000000; i++){}
	a = fdelay(1, ms);
        printf("End \n");
}

