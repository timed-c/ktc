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
		if(random > 5){
			sdelay(3000, ms);
			cwrite(barrier, p);

		}	
	}
}

task stask(){
	int p;
	while(1){
		cread(barrier, p);
		printf("Sporadic task released\n");
	}
}

int  main(){
	cinit(barrier, 1);
	sserver();
	stask();

}

