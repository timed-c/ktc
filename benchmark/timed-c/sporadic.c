#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>

int fifochannel barrier;
pthread_mutex_t mt;
struct timespec cur;	
int g = 1;

task sserver(){
	int random;
	int p = 1;
	long tm;
	printf("Sserver\n");
	while(1){
		random = rand();
		random = random % 10000;
		printf("%d\n", random);
		sdelay(random, ms);
		if(random > 3000){
		      tm = gettime(ms);
		      printf("time in ms is %ld", tm);
		     cwrite(barrier, p){printf("\n");}
		}
		sdelay(0, ms);		
	}
}

task stask(){
	int p;
	struct timespec c;
	printf("Stask\n");
	while(1){
		cread(barrier, p){printf("\n");}
		if(g == 0){
			g = 1;
			printf("Sporadic task released\n");
			printf("hey\n");	
			//sdelay(0, ms);
			//sdelay(7000, ms);
		}
	}
}

int  main(){
	//cinit(barrier, 1);
	sserver();
	sdelay(10, ms);
	stask();
}

