#include<stdio.h>
#include<cilktc.h>
/*Available Var - available due if cond*/

int  main(){
	int a, b;
	sdelay(0);
	a = 10;
	if(a> 10){
	  fdelay(3, "ms");
	}
	else
	   fdelay(4, "ms");
	sdelay(b, "ms");
	
}

