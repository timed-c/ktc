#include<stdio.h>
#include<time.h>

int ktc_swcet(char* fname,  struct timespec* start_time){
    int exec = 0;
    struct timespec now, exec;
	long tme;
    FILE *fp;
    fp = fopen(fname, "r");
	fscanf(fp, "%d", &est);
	clock_gettime(CLOCK_REALTIME, &now);
	exec = diff_timespec(*start_time, st);
    tme = (timespec_to_unit(exec, -3));
    if(est > exec)
		return 1;
	else
		return 0;
}
