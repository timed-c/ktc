#include<stdio.h>
#include<cilktc.h>
#include<time.h>

#define BILLION 1000000000L

/*An example of a single block of firm delay.
        Firm Delay =  300 microsec
        Exec Time For Code between firm delays = 250sec
*/
int  main(){
	long long unsigned int diff, diff_ms;
	struct timespec st, et;
	clock_gettime(CLOCK_MONOTONIC, &st);
	sdelay(0, "ms");
	printf("Sleep for 1 ms\n");
	usleep(1000);
	printf("Next\n")
	next;
	printf("after next do not execute\n");
	sdelay(5, "ms");
	printf("Line after sdelay\n");
	clock_gettime(CLOCK_MONOTONIC, &et);
	diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
	diff_ms = diff/1000;
	printf("elapsed time = %llu microsec\n", (long long unsigned int) diff_ms);
	/*sleep(1);
	fdelay(2, "ms");*/
	return 1;
	
}

