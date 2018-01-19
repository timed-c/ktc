/*The main function implements a delay until a specified absolute time using gettime*/

#include<stdio.h>
#include<cilktc.h>


int acutateAtTime(){
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
int main(){
  long tcomp, tnow;
  tcomp = acutateAtTime();
  tnow = gettime(sec);
  printf("Time now %d\n", tnow);
  printf("Please wait......\n", tnow);
  sdelay(tcomp - tnow, sec);
  actuate();
}

