#include<stdio.h>
#include<cilktc.h>


int  main(){
	sdelay(0);
	sleep(1);
	sdelay(2, "ms");
	sleep(1);
	fdelay(2, "ms");
	return 1;
	
}

