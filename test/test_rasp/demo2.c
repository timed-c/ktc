#include<stdio.h>
#include<cilktc.h>
#include<time.h>

#define BILLION 1000000000L

/*An example of a single block of firm delay.
        Firm Delay = 10 ms
        Exec Time For Code between firm delays = 2 sec
*/
int  main(){
	long long unsigned int diff, diff_ms;
	struct timespec st, et;
	clock_gettime(CLOCK_MONOTONIC, &st);
	sdelay(0, "ms");
	printf("Firm delay for 10  ms \nCode between fdelay executes for 2 sec \n");
	sleep(2);
	fdelay(10, "ms");
	clock_gettime(CLOCK_MONOTONIC, &et);
	diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
	diff_ms = diff/1000000;
	printf("elapsed time = %llu ms\n", (long long unsigned int) diff_ms);
	/*sleep(1);
	fdelay(2, "ms");*/
	return 1;
	
}

