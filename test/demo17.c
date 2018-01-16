#include<stdio.h>
#include<cilktc.h>
/*Timing point with integer resolution*/

task foo(){
	printf("Starting foo\n");
	while(1){}
	fdelay(50, ms);
	printf("ending foo\n");	
}


task bar(){
	printf("Starting bar\n");
	while(1){}
	fdelay(100, ms);
	printf("bar : fdelay completed\n");
	sdelay(50, ms);
	printf("ending bar\n");
}

void main(){
	int a = 100;
	int b;
	printf("Starting main\n");
	bar();
	foo();
}	

