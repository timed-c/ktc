#define _GNU_SOURCE   
#include <stdint.h>   
#include <pthread.h>  
#include <dlfcn.h>    
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <cilktc.h>
#include<signal.h>
#include<setjmp.h>
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
     struct tp_struct* tp ;
	tp =  (struct tp_struct*) extra->si_value.sival_ptr;
	printf("Timer Handle\n");
      if(tp->waiting != 1){
		tp->waiting = 0;
		siglongjmp(tp->env, 1);
	} 
}

void  create_timer(timer_t* ktctimer, struct tp_struct* tp){
	struct sigaction sa;
        struct sigevent timer_event;
	sigfillset(&sa.sa_mask);
        sa.sa_flags = SA_SIGINFO;
	sa.sa_sigaction = timer_signal_handler;
	
	if(sigaction(SIGRTMIN, &sa, NULL) < 0){
                perror("sigaction");
                exit(0);
        }
	tp->waiting = 0;
	tp->tmr = ktctimer;
	timer_event.sigev_notify = SIGEV_SIGNAL;
        timer_event.sigev_signo = SIGRTMIN;
        timer_event.sigev_value.sival_ptr = (void*) tp;

	if(timer_create(CLOCK_REALTIME, &timer_event, ktctimer) < 0){
                 perror("timer_create");
                 exit(0);
        }


}

long ktc_fdelay_init(int interval, char* unit, struct timespec* start_time) {
	sigset_t allsigs;
	sigfillset(&allsigs);
	sigdelset(&allsigs, SIGRTMIN);
        sigsuspend(&allsigs);

}

int start_timer_fdelay(int interval, char* unit, timer_t ktctimer, struct timespec start_time){
	struct timespec interval_timespec;
        struct itimerspec i;
	
	interval_timespec = convert_to_timespec(3, "ms");
        i.it_value = add_timespec(start_time, interval_timespec);
        i.it_interval.tv_sec = 0;
        i.it_interval.tv_nsec = 0;
	 if(timer_settime(ktctimer, TIMER_ABSTIME, &i, NULL) < 0){
                                perror("timer_setitimer");
                                exit(0);
        }
	
}

/* 
void main(){
	struct tp_struct tp;
	int ret_jmp;
	timer_t ktctimer;
	struct timespec start_time, interval_timespec;
	struct itimerspec i;
	create_timer(&ktctimer, &tp);
	
	ret_jmp = __sigsetjmp(tp.env, 1);
	interval_timespec = convert_to_timespec(3, "ms");
	ktc_start_time_init(&start_time);
	start_timer_fdelay(3, "ms", ktctimer, start_time);
	i.it_value = add_timespec(start_time, interval_timespec);
        i.it_interval.tv_sec = 0;
	i.it_interval.tv_nsec = 0;
	printf("jgd0"); 
	if(timer_settime(ktctimer, TIMER_ABSTIME, &i, NULL) < 0){  
                                perror("timer_setitimer");
                                exit(0);
        }
	printf("sleeping\n");
	sleep(1);
	tp.waiting = 1;	
	ktc_fdelay_init(3, "ms", &start_time);
}*/
