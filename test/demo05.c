#include<stdio.h>
#include<cilktc.h>
/*Available Var -available inside if*/

int  main(){
	int a, b;
	sdelay(4, ms);
	a = 10;
	b = 16;
	if(a)
		sdelay(b, ms);
	else 
		fdelay(a, ms);
	
}

