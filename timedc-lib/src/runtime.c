#include<stdio.h>
#include<time.h>

int ktc_swcet(char* fname,  struct timespec* start_time){
    struct timespec now, exec;
	long tme, est;
    FILE *fp;
    fp = fopen(fname, "r");
	fscanf(fp, "%ld", &est);
	clock_gettime(CLOCK_REALTIME, &now);
	exec = diff_timespec(*start_time, now);
    tme = (timespec_to_unit(exec, -3));
    if(est > tme)
		return 1;
	else
		return 0;
}
