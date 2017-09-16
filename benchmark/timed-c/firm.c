#include<stdio.h>
#include<cilktc.h>

int  main(){
	printf("testing firm\n");
	int i;
	int count = 0;
	int ov;
	int now;
	int clock;
	while(1){
	   now = gettime(ms);
	   if(count % 3 < 0){
		for(i=0; i<1000000000; i++){}
	   }	
	   else{
		for(i=0; i<1000; i++){}	
	   }
	   
	   fdelay(100, ms);
	   count++; 
	   clock = gettime(ms);
	   printf("time elapsed : %d\n", clock - now);
	}	
}

