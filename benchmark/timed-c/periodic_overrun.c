#include<stdio.h>
#include<cilktc.h>


int  main(){
	int ov;
	while(1){
	   printf("delay 30 ms\n");
	   sleep(1);
	   ov = sdelay(30, ms);
	   if(ov > 0){
		printf("overshot\n");
		sdelay(30-ov%30, ms);
	   }
	}	
}

