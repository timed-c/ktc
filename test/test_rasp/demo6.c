#include<stdio.h>
#include<cilktc.h>
#include<time.h>
#include<unistd.h>

#define BILLION 1000000000L
/*An example of series of soft and firm delays.
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
	clock_gettime(CLOCK_REALTIME, &st);
	sdelay(0, "ms");
	printf("BLOCK 1\nSoft Delay 2 ms \nSleep 3 ms\n");
	usleep(3000);
	sdelay(2, "ms");
	clock_gettime(CLOCK_REALTIME, &et);
	diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
	diff_ms = diff/1000000;
	printf("Elapsed time = %llu ms\n", (long long unsigned int) diff_ms);

        st = et;
	printf("\nBLOCK 2\nSoft Delay 8ms  \nSleep 5 ms\n");
        usleep(5000);
        fdelay(8, "ms");
        clock_gettime(CLOCK_REALTIME, &et);
        diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
        diff_ms = diff/1000000;
        printf("Elapsed time = %llu ms\n", (long long unsigned int) diff_ms);
	clock_gettime(CLOCK_REALTIME, &st);
	printf("\nBLOCK 3\nSoft Delay 8000 microsec \nSleep 2000 microsec \n");
        usleep(2000);
        sdelay(8000, "micro");
        clock_gettime(CLOCK_REALTIME, &et);
        diff =  BILLION * (et.tv_sec - st.tv_sec) + et.tv_nsec - st.tv_nsec;
        diff_ms = diff/1000;
        printf("elapsed time = %llu microsec\n", (long long unsigned int) diff_ms);
	/*sleep(1);
	fdelay(2, "ms");*/
	return 1;
	
}

