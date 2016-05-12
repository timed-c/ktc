
#define _GNU_SOURCE
#include <stdint.h>
#include <pthread.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <cilktc.h>
#include<signal.h>

sigset_t oldmask, newmask;


long ktc_sdelay_init(char const *f, int l, int intrval, char* unit, struct timespec* start_time){
        struct timespec end_time, elapsed_time, wait_time, interval_time;
        interval_time = convert_to_timespec(intrval, unit);
        (void) clock_gettime(CLOCK_REALTIME, &end_time);
        elapsed_time = diff_timespec(end_time, (*start_time));
        if(cmp_timespec(interval_time, elapsed_time) == 1){
                wait_time = add_timespec((*start_time), interval_time);
                clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
                (void) clock_gettime(CLOCK_REALTIME, start_time);
                return 0;
        }
        if(cmp_timespec(interval_time, elapsed_time) == 0){
                (void) clock_gettime(CLOCK_REALTIME, start_time);
                return 0;
        }
        if(cmp_timespec(interval_time, elapsed_time) == -1){
                wait_time = add_timespec((*start_time), interval_time);
                elapsed_time = diff_timespec(end_time, wait_time);
                 (void) clock_gettime(CLOCK_REALTIME, start_time);
                return (timespec_to_unit(elapsed_time, unit));
        }
 /* printf("init:\n");
  sigfillset(&newmask);
  sigprocmask(SIG_SETMASK, &newmask, &oldmask);
  (void) clock_gettime(CLOCK_REALTIME, &start_time);
   return;*/
        return 0;
}

int ktc_sdelay_end(char const *f, int l, int intrval, char* unit)
{
        return 0;
}
