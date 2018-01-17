#include<stdio.h>
#include<cilktc.h>
/*Overshot using stp*/

void main(){
	int i, j;
	int a , b;
	for(i = 0; i < 100000000; i++){}
	a = sdelay(300, ms);
	printf("overshoot %d\n", a);
	for(i = 0; i < 100000000; i++){}
	a = stp(0, 300, ms);
	printf("overshoot %d\n", a);
	for(i = 0; i < 100000000; i++){}
	a = stp(300, 0, ms);
	printf("overshoot %d\n", a);
        printf("End \n");
}

