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

int ktc_swcet(char* fname,  struct timespec* start_time){
    static int i = 0;
    struct timespec now;
	struct timespec exectm;
	long tme = 0, newt;
	clock_gettime(CLOCK_REALTIME, &now);
	exectm = diff_timespec(now, *start_time);
    newt = timespec_to_unit(exectm, -3);
	if(newt > tme){
		tme = newt;
    }
	i++;
	if(i == 10){
       FILE *fp;
       fp = fopen(fname, "w");
       fprintf(fp, "%d", tme);
       fclose(fp);
	}
}
