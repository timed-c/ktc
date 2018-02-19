/*A function implementing nested timing-points*/

#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>

int control(){
   int i;
   for(i = 0; i <1000000000; i++){}	
   printf("control completed\n");
}

#include "nested-timing-point.main"

