#include<stdio.h>
#include<cilktc.h>
#include<time.h>
#include<unistd.h>

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
	struct timespec deadline;
	sdelay(0, "ms");
	clock_gettime(CLOCK_REALTIME, &st);
	printf("BLOCK 1\nSoft Delay 500 microsec \nSleep 400 microsec\n");
	usleep(400);
	sdelay(500, "micro");
	clock_gettime(CLOCK_REALTIME, &et);
	diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
	diff_ms = diff/1000;
	printf("elapsed time = %llu microseconds\n", (long long unsigned int) diff_ms);
	sdelay(0, "ms");
	clock_gettime(CLOCK_REALTIME, &st);
        printf("\nBLOCK 2\nSoft Delay 2 nanosecond  \nSleep 2000 microsecond\n");
        usleep(2000);
        sdelay(2000000, "ns");
        clock_gettime(CLOCK_REALTIME, &et);
        diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
        diff_ms = diff/1000;
        printf("elapsed time = %llu microsec\n", (long long unsigned int) diff_ms);
	//sdelay(0, "ms");
 	//clock_gettime(CLOCK_MONOTONIC, &st);
       // printf("\nBLOCK 3\nSoft delay for 3 sec \nCode between sdelay executes for 3 sec\n");
       // sleep(3);
       // sdelay(3, "sec");
       // clock_gettime(CLOCK_MONOTONIC, &et);
       // diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
       // diff_ms = diff/1000000;
       // printf("elapsed time = %llu ms\n", (long long unsigned int) diff_ms);
	/*sleep(1);
	fdelay(2, "ms");*/
	return 1;
	
}

