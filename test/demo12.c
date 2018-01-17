#include<stdio.h>
#include<cilktc.h>
/*Checking overshot*/

void main(){
	int i, j;
	int a , b;
	for(i = 0; i < 100000000; i++){}
	a = sdelay(0, -2);
	printf("overshoot %d\n", a);
	for(i = 0; i < 100000000; i++){}
	a = sdelay(0, -10);
	printf("overshoot %d\n", a);
        printf("End \n");
}

