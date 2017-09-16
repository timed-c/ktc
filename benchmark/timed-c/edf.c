#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>


task tsk1(){
	spolicy(EDF);
	while(1){
	  printf("Task 1\n");
	  sdelay(100, ms);
	}

}

task tsk2(){
	spolicy(EDF);
	while(1){
	  printf("Task 2\n");
	  sdelay(20, ms);
	}

}

int  main(){
	tsk1();
	tsk2();
}

