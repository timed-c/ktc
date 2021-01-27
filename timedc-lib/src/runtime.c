#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include <setjmp.h>
#include <pthread.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <stdbool.h>
#include <linux/sched.h>
#include <linux/types.h>
#include <cillib.h>
#include <string.h>
#include <errno.h>
#include <math.h>

int ktc_swcet(char* fname,  struct timespec* start_time, int* count, int tunit, int *tme){
    //printf("ktc_swcet %s", fname);
    struct timespec now, exec;
	long tme, est;
    FILE *fp;
    fp = fopen(fname, "r");
	fscanf(fp, "%ld", &est);
	fclose(fp);
	clock_gettime(CLOCK_REALTIME, &now);
	exec = diff_timespec(now, *start_time);
    tme = (timespec_to_unit(exec, tunit));
	printf("ktc_scwet %ld %ld\n", est, tme);
    if(est < tme)
		return (tme-est);
	else
		return 0;
}
