#include<stdio.h>
#include<cilktc.h>
/*Timing point with integer resolution*/

void main(){
	int a = 100;
	printf("1.\n");
	sdelay(1, ms);
	printf("2.\n");
	fdelay(2, ms);
        printf("3.\n");
	sdelay(3, ms);
	printf("4.\n");
	a = fdelay(0, ms);
        printf("End %d \n", a);
}

