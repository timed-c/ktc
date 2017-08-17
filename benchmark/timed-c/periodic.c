#include<stdio.h>
#include<cilktc.h>


int  main(){
	while(1){
	   printf("delay 30 ms\n");
	   sdelay(30, ms);
	}	
}

