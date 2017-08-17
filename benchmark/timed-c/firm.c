#include<stdio.h>
#include<cilktc.h>

int  main(){
	printf("testing firm\n");
	int i;
	int count = 0;
	int ov;
	while(1){
	   sdelay(0, ms);
	   //printf("done\n");
	   if(count % 3 < 0){
		for(i=0; i<1000000000; i++){}
	   }	
	   else{
		for(i=0; i<1000; i++){}	
	   }
	   fdelay(30, ms);
	   count++;
	}	
}

