#include<stdio.h>
#include<cilktc.h>


int  main(){
	int a;
	foo();
	sdelay(10, ms);
	foo();
	sdelay(10, ms);
	sdelay(20, ms);
	sdelay(100, -9);
	foo();
	sdelay(300, ms);
	return 1;
}

task foo(){
	int a;
	while(1){
		sdelay(90, ms);
		sdelay(100, ms);
	}
}

