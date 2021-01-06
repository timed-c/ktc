#include<stdio.h>
#include<time.h>

int ktc_swcet(char* fname,  struct timespec* start_time){
    static int i = 0;
    struct timespec now, exec;
	long tme, newt;
	clock_gettime(CLOCK_REALTIME, &now);
	exec = diff_timespec(*start_time, now);
    newt = (timespec_to_unit(exec, -3));
	if(newt > tme)
		tme = newt
	i++;
	if(i == 100){
       FILE *fp;
       fp = fopen(fname, "w");
       fprintf(fp, "%d", tme);
       fclose(fp);
	}
}
