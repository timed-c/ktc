#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>


int sensenode1(){
	return 1;
}

int sensenode2(){
	printf("sensenode2 executed\n");
}

void main(){
  int a = 0; 
  a = sensenode1(); 
  if(a != 0){
     skipdelay;
  }
  else{
     sensenode2();
  }
  fdelay(50, ms);
  printf("main end\n");
}   

