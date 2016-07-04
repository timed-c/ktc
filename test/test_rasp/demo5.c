#include<stdio.h>
#include<cilktc.h>
#include<time.h>

#define BILLION 1000000000L
/*An example of series of soft delays.
	BLOCK 1 : 
	Soft Delay = 10 sec 
	Exec Time For Code between soft delays = 3  sec
	BLOCK 2 :
        Soft Delay = 22.9 sec
        Exec Time For Code between soft delays = 23 sec
	BLOCK 3 :
        Soft Delay =  3 sec
        Exec Time For Code between soft delays = 3  sec

*/
int  main(){
	long long unsigned int diff, diff_ms;
	struct timespec st, et;
	clock_gettime(CLOCK_MONOTONIC, &st);
	sdelay(0, "ms");
	printf("BLOCK 1\nSoft Delay 20 sec \nSleep 10 sec\n");
	sleep(10);
	sdelay(20, "sec");
	clock_gettime(CLOCK_MONOTONIC, &et);
	diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
	diff_ms = diff/1000000;
	printf("Elapsed time = %llu ms\n", (long long unsigned int) diff_ms);

	clock_gettime(CLOCK_MONOTONIC, &st);
        printf("\nBLOCK 2\nSoft Delay 22.9 sec \nSleep 23 sec\n");
        sleep(23);
        sdelay(22.9, "sec");
        clock_gettime(CLOCK_MONOTONIC, &et);
        diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
        diff_ms = diff/1000000;
        printf("Elapsed time = %llu ms\n", (long long unsigned int) diff_ms);

	 clock_gettime(CLOCK_MONOTONIC, &st);
        printf("\nBLOCK 3\nSoft Delay 3 sec \nSleep 3 sec\n");
        sleep(3);
        sdelay(3, "sec");
        clock_gettime(CLOCK_MONOTONIC, &et);
        diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
        diff_ms = diff/1000000;
        printf("elapsed time = %llu ms\n", (long long unsigned int) diff_ms);
	/*sleep(1);
	fdelay(2, "ms");*/
	return 1;
	
}

