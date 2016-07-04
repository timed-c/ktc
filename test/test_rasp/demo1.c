#include<stdio.h>
#include<cilktc.h>
#include<time.h>

#define BILLION 1000000000L
/*An example of a single block of soft delay.
	Soft Delay = 3 ms 
	Exec Time For Code between soft delays = 1 sec 
*/
int  main(){
	long long unsigned int diff, diff_ms;
	struct timespec diff_ts;
	struct timespec st, et;
	clock_gettime(CLOCK_MONOTONIC, &st);
	sdelay(0, "ms");
	//printf("Soft delay for 3 ms \nCode between sdelay executes for 1 sec\n");
	printf("Soft Delay 3 ms. \nSleep for 1 sec.\n");
	sleep(1);
	sdelay(3, "ms");
	clock_gettime(CLOCK_MONOTONIC, &et);
	diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;	
	diff_ms = diff/1000000;
	printf("Elapsed time = %llu ms\n", (long long unsigned int) diff_ms);
	/*sleep(1);
	fdelay(2, "ms");*/
	return 1;
	
}

