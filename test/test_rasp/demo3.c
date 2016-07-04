#include<stdio.h>
#include<cilktc.h>
#include<time.h>

#define BILLION 1000000000L
/*An example of a single block of soft delay with close finishing time.
	Soft Delay = 1.999 sec 
	Exec Time For Code between soft delays = 2 sec 
*/
int  main(){
	long long unsigned int diff, diff_ms;
	struct timespec st, et;
	clock_gettime(CLOCK_MONOTONIC, &st);
	sdelay(0, "ms");
	printf("Soft Delay 1.999 sec \nSleep 2 sec\n");
	sleep(2);
	sdelay(1999, "ms");
	clock_gettime(CLOCK_MONOTONIC, &et);
	diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
	diff_ms = diff/1000000;
	printf("elapsed time = %llu ms\n", (long long unsigned int) diff_ms);
	/*sleep(1);
	fdelay(2, "ms");*/
	return 1;
	
}

