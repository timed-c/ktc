#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>


task tsk1(){
	spolicy(FIFO_RM);
	while(1){
	  printf("Task 1\n");
	  sdelay(100, ms);
	}

}

task tsk2(){
	spolicy(FIFO_RM);
	while(1){
	  printf("Task 2\n");
	  sdelay(200, ms);
	}

}



int  main(){
	tsk1();
	tsk2();

}

