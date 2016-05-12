#define _GNU_SOURCE   
#include <stdint.h>   
#include <pthread.h>  
#include <dlfcn.h>    
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <cilktc.h>
#include<signal.h>
#include <time.h>
sigset_t oldmask, newmask;


long ktc_sdelay_init(int intrval, char* unit, struct timespec* start_time){
	struct timespec end_time, elapsed_time, wait_time, interval_time;
	interval_time = convert_to_timespec(intrval, unit);
	(void) clock_gettime(CLOCK_REALTIME, &end_time);
	elapsed_time = diff_timespec(end_time, (*start_time));
	if(cmp_timespec(interval_time, elapsed_time) == 1){
		wait_time = add_timespec((*start_time), interval_time);
		clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
		*start_time = wait_time;
		return 0;
	}
	if(cmp_timespec(interval_time, elapsed_time) == 0){
		wait_time = add_timespec((*start_time), interval_time);
		*start_time = wait_time;
		return 0;
	}
	if(cmp_timespec(interval_time, elapsed_time) == -1){
		wait_time = add_timespec((*start_time), interval_time);
		elapsed_time = diff_timespec(end_time, wait_time); /*elapsed_time here is the obershot*/
		*start_time = add_timespec(wait_time, elapsed_time);
		return (timespec_to_unit(elapsed_time, unit));
	}
 /* printf("init:\n");
  sigfillset(&newmask);
  sigprocmask(SIG_SETMASK, &newmask, &oldmask);
  (void) clock_gettime(CLOCK_REALTIME, &start_time); 
   return;*/
	return 0;
}

int ktc_start_time_init(struct timespec* start_time)
{
	(void) clock_gettime(CLOCK_REALTIME, start_time);
	return 0; 
}
/*
void main(){
	struct timespec start_time;
	char* f ="hey";
	int l = 100;
	int intrvl = 12;
	char* unit = "NULL";
	ktc_sdelay_init(f,l,intrvl,unit, &start_time);
}
*/

void timer_signal_handler(int sig, siginfo_t *extra, void *cruft){
       
}

void  create_timer(timer_t* ktctimer){
	struct sigaction sa;
        struct sigevent timer_event;
	sigfillset(&sa.sa_mask);
        sa.sa_flags = SA_SIGINFO;
	sa.sa_sigaction = timer_signal_handler;
	
	if(sigaction(SIGRTMIN, &sa, NULL) < 0){
                perror("sigaction");
                exit(0);
        }

	timer_event.sigev_notify = SIGEV_SIGNAL;
        timer_event.sigev_signo = SIGRTMIN;
        timer_event.sigev_value.sival_ptr = (void*) ktctimer;

	if(timer_create(CLOCK_REALTIME, &timer_event, ktctimer) < 0){
                 perror("timer_create");
                 exit(0);
        }


}

long ktc_fdelay_init(int interval, char* unit, struct timespec* start_time) {
}
