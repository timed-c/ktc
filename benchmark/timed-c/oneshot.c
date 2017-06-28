#include<stdio.h>
#include<cilktc.h>


int  main(){
     sdelay(0, ms);
     printf("Start one shot timer with period 30 ms\n");
     sdelay(30, ms);	
     printf("Timer Expired\n");
}

