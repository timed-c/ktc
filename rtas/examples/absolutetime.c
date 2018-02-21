/*The main function implements a delay until a specified absolute time using gettime*/

#include<stdio.h>
#include<cilktc.h>


int actuateAtTime(){
 long t;
 t = gettime(sec);
  printf("Executed acutate at %d\n", t+6);
 return(t+6);
}

int actuate(){
 long t;
 t = gettime(sec);
 printf("Actuate executed at %d\n", t);
	
}

#include "absolutetime.main"
