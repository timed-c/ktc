#include<stdio.h>
#include<cilktc.h>
/*Available Var - not available due to while` cond*/

int  main(){
	int a, b;
	sdelay(2, ms);
	a = 10;
	b = 16;
	if(a)
		fdelay(b, ms);
	else 
		fdelay(a, ms);
	fdelay(10, ms);
	
}

