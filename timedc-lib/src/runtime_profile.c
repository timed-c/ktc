#include<stdio.h>
#include<time.h>
#include <cillib.h>

int ktc_swcet(char* fname,  struct timespec* start_time){
    static int i = 0;
    struct timespec now;
	struct timespec exectm;
	long tme = 0, newt;
	clock_gettime(CLOCK_REALTIME, &now);
	exectm = diff_timespec(now, *start_time);
    newt = timespec_to_unit((diff_timespec(now, *start_time)), -3);
	if(newt > tme){
		tme = newt;
    }
	i++;
	if(i == 100){
       FILE *fp;
       fp = fopen(fname, "w");
       fprintf(fp, "%d", tme);
       fclose(fp);
	}
}
