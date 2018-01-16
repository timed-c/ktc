#include<stdio.h>
#include<cilktc.h>
/*Timing point with integer resolution*/
int fifochannel(chan);

task foo(){
	int a;
	printf("read wait\n");
 	cread(chan, a);
	printf("Blocking done %d\n", a);
}

task bar(){
	int a=10;
	sleep(10);
 	cwrite(chan, a);
	printf("write done\n");
	gettime(ms);
	sdelay(0);
	sdelay(16, ms);
}



void main(){
	cinit(chan,0);
	nelem(chan);
	foo();
	bar();
}


