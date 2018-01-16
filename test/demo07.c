#include<stdio.h>
#include<cilktc.h>
/*Available Var -available inside if*/

void bar(){
	while(1){}
	fdelay(10, ms);	
	printf("bar end\n");
}

int  main(){
	int a, b;
	bar();
}

