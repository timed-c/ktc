#include<stdio.h>
#include<cilktc.h>

task bar(){
	spolicy(EDF);
	printf("bar started\n");
	while(1){
	   printf("bar running\n");
	   sdelay(30, ms);
	}
}

task foo(){
	spolicy(EDF);
	printf("foo started\n");
	while(1){
	   printf("foo running\n");
	   sdelay(50, ms);
	   sdelay(15, ms);
	}
}

int  main(){
	bar();
	foo();
	printf("main\n");	
}



