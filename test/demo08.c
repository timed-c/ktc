#include<stdio.h>
#include<cilktc.h>
/*Available Var - not available due to while` cond*/

int  main(){
	int a, b;
	sdelay(0, ms);
	a = 10;
	//for(a = 0; a < 500000000; a++){}
	sleep(6);
	b = sdelay(10, ms);
	printf("end %d", b);
	
}

