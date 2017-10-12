#include<stdio.h>
#include<cilktc.h>


int  main(){
	int ov;
        int i;
	while(1){
	   printf("delay 30 ms\n");
	   for(int i = 0; i < 10000; i++){printf("%d\n", i);}
	   ov = sdelay(30, ms);
	   if(ov > 0){
		printf("overshot\n");
		sdelay(30-ov%30, ms);
	   }
	}	
}

