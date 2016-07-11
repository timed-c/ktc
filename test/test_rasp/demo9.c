#include<stdio.h>
#include<cilktc.h>
#include<time.h>
#include<unistd.h>

#define BILLION 1000000000L
/*	
While loop of sdelay without deadline misses, i.e., timing block executes for time lesser than delay
*/
int  main(){
	long long unsigned int diff, diff_ms;
	struct timespec st, et;
	struct timespec deadline;
	int i = 0;
	sdelay(0, "ms");
	clock_gettime(CLOCK_REALTIME, &st);
	diff =  BILLION * (st.tv_sec - st.tv_sec) + st.tv_nsec - st.tv_nsec;
	diff_ms = diff/1000000;
        printf("Time = %llu\n", (long long unsigned int) diff_ms);	
	for(i=0; i<10; i++){
		printf("BLOCK %d\n", i);
		usleep(5000);
		sdelay(8, "ms");
		clock_gettime(CLOCK_REALTIME, &et);
		diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
		diff_ms = diff/1000000;
		printf("Time = %llu\n", (long long unsigned int) diff_ms);
	}

	return 1;
	
}

