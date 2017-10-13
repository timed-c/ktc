#include<stdio.h>
#include<cilktc.h>
/*Available Var -available inside if*/

int  main(){
	int a, b;
	sdelay(0);
	a = 10;
	b = 16;
	if(a)
	sdelay(b, ms);
	else 
	fdelay(a, ms);
	fdelay(10, ms);
	
}

void foo() {

sdelay(10, ms);
fdelay(20, ms);


}


void boo() {
   
   sdelay(9, ms);
   while(1){
   	fdelay(10, ms);
   }
}

