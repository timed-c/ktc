#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>

int fifochannel barrier;
pthread_mutex_t mt;

task sserver(){
	int random;
	int p = 1;
	while(1){
		random = rand();
		random = random % 10;
		printf("Gen %d\n", random);
		if(random > 5){
			sdelay(3000, ms);
			cwrite(barrier, p){printf("\n");}

		}
		sdelay(0, ms);		
	}
}

task stask(){
	int p;
	while(1){
		cread(barrier, p){printf("\n");}
		printf("Sporadic task released\n");
	}
}

int  main(){
	cinit(barrier, 1);
	sserver();
	stask();

}

