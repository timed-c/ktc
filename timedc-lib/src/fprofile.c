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

struct log_struct{
    int src;
    unsigned long atime;
    unsigned long rtime;
    unsigned long jitter;
    unsigned long execution;
    unsigned long abort;
    int dst;
};


pthread_mutex_t mt;
extern int ktcpolicy;
jmp_buf ssenv;
#define gettid() syscall(__NR_gettid)

#define SCHED_DEADLINE	6

/* XXX use the proper syscall numbers */
#ifdef __x86_64__
#define __NR_sched_setattr		314
#define __NR_sched_getattr		315
#endif

#ifdef __i386__
#define __NR_sched_setattr		351
#define __NR_sched_getattr		352
#endif

#ifdef __arm__
#define __NR_sched_setattr		380
#define __NR_sched_getattr		381
#endif


 int sched_setattr(pid_t pid,
		  const struct sched_attr *attr,
		  unsigned int flags)
 {
    return syscall(__NR_sched_setattr, pid, attr, flags);
    //return sched_setscheduler(pid, attr, flags);
 }

int compare_qsort (const void * elem1, const void * elem2)
{
    int f = *((int*)elem1);
    int s = *((int*)elem2);
    if (f > s) return  1;
    if (f < s) return -1;
    return 0;
}
int compute_priority(int* array, int para){
    int i;
	for(i =0; i < 100; i++){
		if(array[i] == para)
			return i;
	}
}


int ktc_set_sched(int policy, int period, int priority, int deadline){
	struct sched_attr sa;
	int runtime = deadline;
	sa.size = sizeof(sa);
        sa.sched_flags = 0;
        sa.sched_nice = 0;
	if(policy == EDF){
        if(period == 0 ){
            return 0;
        }
		sa.sched_priority = 0;
		sa.sched_policy = SCHED_DEADLINE;
        //printf("deadline %d, period %d\n", deadline, period);
		sa.sched_runtime = deadline * 2000;
        sa.sched_deadline = deadline * 1000 * 1000 ;
		sa.sched_period =   deadline * 1000 * 1000 ;
	}
	if(policy == RR_RM){
		priority = compute_priority(list_pr, period);
		priority = sched_get_priority_max(SCHED_RR) - priority;
		sa.sched_priority = priority;
		sa.sched_policy = SCHED_RR;
		sa.sched_runtime = runtime;
		sa.sched_deadline = deadline;
		sa.sched_period = period;
	}
	if(policy == FIFO_RM){
        // printf("%d\n", priority);
		priority = (sched_get_priority_min(SCHED_FIFO)) + (10 - priority);
		sa.sched_priority = priority;
		sa.sched_policy = SCHED_FIFO;
		//sa.sched_runtime = runtime;
		//sa.sched_deadline = deadline;
		//sa.sched_period = period;
	}
	if(policy == FIFO_DM){
		priority = compute_priority(list_dl, deadline);
		priority = compute_priority(list_pr, period);
		priority = sched_get_priority_min(SCHED_RR) - priority;
		sa.sched_priority = priority;
		sa.sched_policy = SCHED_FIFO;
		sa.sched_runtime = runtime;
		sa.sched_deadline = deadline;
		sa.sched_period = period;
	}
	if(policy == RR_DM){
		priority = compute_priority(list_dl, deadline);
		priority = compute_priority(list_pr, period);
		priority = sched_get_priority_max(SCHED_RR) - priority;
		sa.sched_priority = priority;
		sa.sched_policy = SCHED_RR;
		sa.sched_runtime = runtime;
		sa.sched_deadline = deadline;
		sa.sched_period = period;
	}
	int err;
	int pid = getpid();
	int flag = 0;
	if(&sa == NULL){
		printf("this is null");
	}
    err = sched_setattr(0, &sa, flag);
	if(err < 0) {
         //printf("error %d \n", deadline);
		 perror("sched_setattr error");
	}
}

long ktc_gettime(int unit){
	struct timespec st;
	long ret;
	(void) clock_gettime(CLOCK_REALTIME, &st);
	ret = timespec_to_unit(st, unit);
	return ret;
}

void change_to_max_priority(int priority){
    struct sched_param param;
    int s;
    param.sched_priority = sched_get_priority_max(SCHED_FIFO);
    s = pthread_setschedparam(pthread_self(), SCHED_FIFO, &param);
    if (s != 0)
        printf("pthread_setschedparam");
}

/*
long ktc_sdelay_init(int intrval, int unit, struct timespec* start_time, int id){

	if(intrval < 0){
		(void) clock_gettime(CLOCK_REALTIME, start_time);
		return intrval;
	}
	 if(intrval == 0){
		struct timespec st, elapsed_time;
		st = *start_time;
                (void) clock_gettime(CLOCK_REALTIME, start_time);
		elapsed_time = diff_timespec(*start_time, st);
		return (timespec_to_unit(elapsed_time, unit));
        }
	struct timespec end_time, elapsed_time, wait_time, interval_time, et;
	interval_time = convert_to_timespec(intrval, unit);
	(void) clock_gettime(CLOCK_REALTIME, &end_time);
//	(void) clock_gettime(CLOCK_MONOTONIC, &end_time);
	elapsed_time = diff_timespec(end_time, (*start_time));
	//printf("Time Interval- %lld.%.9ld\n", (long long)(interval_time.tv_sec), (interval_time.tv_nsec)) ;
		//printf("Time Elapsed- %lld.%.9ld\n", (long long)(elapsed_time.tv_sec), (elapsed_time.tv_nsec)) ;
	if(cmp_timespec(interval_time, elapsed_time) == 1){
	//	printf("intr > elapsd\n");
		wait_time = add_timespec((*start_time), interval_time);
		clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
		//printf("Time Elapsed- %lld.%.9ld\n", (long long)(wait_time.tv_sec), (wait_time.tv_nsec)) ;
		*start_time = wait_time;
		//printf("Time At Timing Point - %lld.%.9ld\n", (long long)(start_time->tv_sec), (start_time->tv_nsec)) ;
		return 0;
	}
	if(cmp_timespec(interval_time, elapsed_time) == 0){
	//	 printf("intr == elapsd\n");
		wait_time = add_timespec((*start_time), interval_time);
		*start_time = wait_time;
		//printf("Time At Timing Point - %lld.%.9ld\n", (long long)(start_time->tv_sec), (start_time->tv_nsec)) ;
		return 0;
	}
	if(cmp_timespec(interval_time, elapsed_time) == -1){
	//	printf("intr < elapsd\n");
		wait_time = add_timespec((*start_time), interval_time);
		elapsed_time = diff_timespec(end_time, wait_time);
		*start_time = add_timespec(wait_time, elapsed_time);
		(void) clock_gettime(CLOCK_REALTIME, &et);
		//printf("Time At Timing Point - %lld.%.9ld\n", (long long)(start_time->tv_sec), (start_time->tv_nsec)) ;
		return (timespec_to_unit(elapsed_time, unit));
	}

	return 0;
}
*/
/*

long ktc_sdelay_init(int period, int deadline, int unit, struct timespec* start_time, int id){
    //printf("sdelay");
	if(period == -2103){
		return 0;
	}
	if(period == -1404){
		(void) clock_gettime(CLOCK_REALTIME, start_time);
		return (timespec_to_unit(*start_time, unit));
	}
	if(period < 0){
		(void) clock_gettime(CLOCK_REALTIME, start_time);
		return period;
	}
	if(period == 0){
		struct timespec st, elapsed_time;
		st = *start_time;
        (void) clock_gettime(CLOCK_REALTIME, start_time);
		elapsed_time = diff_timespec(*start_time, st);
		return (timespec_to_unit(elapsed_time, unit));
    }
    struct timespec interval_time, wait_time;
    interval_time = convert_to_timespec(period, unit);
    wait_time = add_timespec((*start_time), interval_time);
    clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
    *start_time = add_timespec((*start_time), interval_time);
	return 0;
}
*/

long ktc_sdelay_init(int period, int deadline, int unit, struct timespec* start_time, int id){
	//condition for gettime
	if(period == -2103){
		return 0;
	}
	if(period == -1404){
		(void) clock_gettime(CLOCK_REALTIME, start_time);
		return (timespec_to_unit(*start_time, unit));
	}
	if(period < 0){
		(void) clock_gettime(CLOCK_REALTIME, start_time);
		return period;
	}
	 if(period == 0){
		struct timespec st, elapsed_time;
		st = *start_time;
                (void) clock_gettime(CLOCK_REALTIME, start_time);
		elapsed_time = diff_timespec(*start_time, st);
		return (timespec_to_unit(elapsed_time, unit));
        }
	if(period == deadline){
		struct timespec end_time, elapsed_time, wait_time, interval_time, et;
		interval_time = convert_to_timespec(period, unit);
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
			elapsed_time = diff_timespec(end_time, wait_time); //elapsed_time here is the obershot
			//printf("Time Elapsed- %lld.%.9ld\n", (long long)(elapsed_time.tv_sec), (elapsed_time.tv_nsec)) ;
			*start_time = add_timespec(wait_time, elapsed_time);
			(void) clock_gettime(CLOCK_REALTIME, &et);
			return (timespec_to_unit(elapsed_time, unit));
		}
	}
	if(period > deadline){
		struct timespec end_time, elapsed_time, wait_time, interval_time, et, deadline_timespec, overshot_timespec;
		interval_time = convert_to_timespec(period, unit);
		deadline_timespec = convert_to_timespec(deadline, unit);
		(void) clock_gettime(CLOCK_REALTIME, &end_time);
		elapsed_time = diff_timespec(end_time, (*start_time));
		if(cmp_timespec(interval_time, elapsed_time) == 1){
			wait_time = add_timespec((*start_time), interval_time);
			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec); //elapsed_time here is the obershot
			*start_time = wait_time;
			return (timespec_to_unit(overshot_timespec, unit));
		}
		if(cmp_timespec(interval_time, elapsed_time) == 0){
			wait_time = add_timespec((*start_time), interval_time);
			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec);
			*start_time = wait_time;
			return (timespec_to_unit(overshot_timespec, unit));
		}
		if(cmp_timespec(interval_time, elapsed_time) == -1){
			wait_time = add_timespec((*start_time), interval_time);
			elapsed_time = diff_timespec(end_time, wait_time); //elapsed_time here is the obershot
			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			*start_time = add_timespec(wait_time, elapsed_time);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec);
			(void) clock_gettime(CLOCK_REALTIME, &et);
			return (timespec_to_unit(overshot_timespec, unit));
		}
	}
	if(period < deadline){
		struct timespec end_time, elapsed_time, wait_time, interval_time, et, deadline_timespec, overshot_timespec;
		interval_time = convert_to_timespec(period, unit);
		deadline_timespec = convert_to_timespec(deadline, unit);
		(void) clock_gettime(CLOCK_REALTIME, &end_time);
		elapsed_time = diff_timespec(end_time, (*start_time));
		if(cmp_timespec(interval_time, elapsed_time) == 1){
			wait_time = add_timespec((*start_time), interval_time);
			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec); //elapsed_time here is the obershot
			*start_time = wait_time;
			return (timespec_to_unit(overshot_timespec, unit));
		}
		if(cmp_timespec(interval_time, elapsed_time) == 0){
			wait_time = add_timespec((*start_time), interval_time);
			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec);
			*start_time = wait_time;
			return (timespec_to_unit(overshot_timespec, unit));
		}
		if(cmp_timespec(interval_time, elapsed_time) == -1){
			wait_time = add_timespec((*start_time), interval_time);
			elapsed_time = diff_timespec(end_time, wait_time); //elapsed_time here is the obershot
			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			*start_time = add_timespec(wait_time, elapsed_time);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec);
			(void) clock_gettime(CLOCK_REALTIME, &et);
			return (timespec_to_unit(overshot_timespec, unit));
		}
	}
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
   // printf("Timer Handle\n");
    if(tp->waiting != 1){
		tp->waiting = 0;
		siglongjmp((ssenv), 1);
	}
}

/*void  ktc_create_timer(timer_t* ktctimer, struct tp_struct* tp, int num){
	struct sigaction sa;
        struct sigevent timer_event;
	sigfillset(&sa.sa_mask);
        sa.sa_flags = SA_SIGINFO;
	sa.sa_sigaction = timer_signal_handler;

	if(sigaction((SIGRTMIN+10+num), &sa, NULL) < 0){
                perror("sigaction");
                exit(0);
        }
	tp->waiting = 0;
	tp->tmr = ktctimer;
	timer_event.sigev_notify = SIGEV_SIGNAL;
        timer_event.sigev_signo = SIGRTMIN+10+num;
        timer_event.sigev_value.sival_ptr = (void*) tp;

	if(timer_create(CLOCK_REALTIME, &timer_event, ktctimer) < 0){
                 perror("timer_create");
                 exit(0);
        }


}
*/



long ktc_block_signal(int n){
 /* sigset_t set;
    int i;
    sigemptyset(&set);
    for(i=0; i<30; i++){
         sigaddset(&set, SIGRTMIN+i);
    }*/
		sigset_t set;
	sigemptyset(&set);
	sigaddset(&set, SIGRTMIN+15);
    pthread_sigmask(SIG_BLOCK, &set, NULL);

}
long ktc_fdelay_init(int period, int interval, int unit, struct timespec* start_time, int id, int retjmp, int num, timer_t tid) {
    //printf("fdelay");
    struct timespec time_now, elapsed_time_ts, deadline_timespec, abs_deadline_ts ;
	int elapsed_time_int;
    long period_us;
	struct timespec wait_time, period_timespec;
	period_timespec = convert_to_timespec((period), unit);
	wait_time = add_timespec((*start_time), period_timespec);
    int prf_zero = 1;
	(void) clock_gettime(CLOCK_REALTIME, &time_now);
     sigset_t allsigs, mask;
	if(retjmp == 0){
        timer_delete(tid);
        clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
        if(period > interval){
			clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
		}	
				//elapsed_time_ts = diff_timespec(time_now, *start_time);
        //elapsed_time_int = timespec_to_unit(elapsed_time_ts, unit);
		deadline_timespec = convert_to_timespec((interval), unit);
		abs_deadline_ts =  add_timespec((*start_time), deadline_timespec);
		 *start_time =  add_timespec((*start_time), period_timespec);
		 (void) clock_gettime(CLOCK_REALTIME, &time_now);
		  elapsed_time_ts = diff_timespec(time_now, abs_deadline_ts);
		  elapsed_time_int = timespec_to_unit(elapsed_time_ts, unit);
         period_us = (period * pow(10, (unit + 6)));
		if(elapsed_time_int < 0 ){
		  //  *start_time =  add_timespec((*start_time), period_timespec);
          // printf("No interrupt handler 1\n");
			return 0;
		}
		else{
	      //  *start_time =  add_timespec((*start_time), period_timespec);
            period_us = (period * pow(10, (unit + 6)));
         //  printf("No interrupt handler 2\n");
			return (elapsed_time_int);
		}
	}
	else{
		// A case of next
		if(period < interval){
            elapsed_time_ts = diff_timespec(time_now, *start_time);
	        *start_time =  add_timespec((*start_time), period_timespec);
            elapsed_time_int = timespec_to_unit(elapsed_time_ts, unit);
             //fprintf(fp, "%d,", prf_zero);
           // printf("Interrupt handler 1\n");
			return -1;
		}
		else{
				timer_delete(tid);
		// A case of timer expiry
		    deadline_timespec = convert_to_timespec((interval), unit);
		    abs_deadline_ts =  add_timespec((*start_time), deadline_timespec);
		     *start_time =  add_timespec((*start_time), period_timespec);
			 (void) clock_gettime(CLOCK_REALTIME, &time_now);
              elapsed_time_ts = diff_timespec(time_now, abs_deadline_ts);
            //fp->abort = prf_zero;
             //fprintf(fp, "%d,", prf_zero);
             elapsed_time_int = timespec_to_unit(elapsed_time_ts, unit);
             //fprintf(fp, "%d,", prf_zero);
            // period_us = (period * pow(10, (unit + 6)));
             //printf("Interrupt handler 2\n");
		    return ((elapsed_time_int));
		}
	}


}
void  ktc_create_timer(timer_t* ktctimer, timer_t tid, struct tp_struct* tp, int num){
    int err;
    struct sigevent timer_event;
    struct itimerspec its;
    long long freq_nanosecs;
    sigset_t mask;
    struct sigaction sa;
	//printf("timer create\n");
    timer_t sid;
    if(tid != 0x0){
      //  printf("timer deleted \n");
        timer_delete(tid);
    }
	    num = 15;
        sa.sa_flags = SA_SIGINFO;
	    sa.sa_sigaction = timer_signal_handler;
        sigemptyset(&sa.sa_mask);
	    if(sigaction((SIGRTMIN+num), &sa, NULL) < 0){
                perror("sigaction");
                exit(0);
        }
	    tp->waiting = 0;
	    tp->tmr = ktctimer;
	    timer_event.sigev_notify = SIGEV_SIGNAL;
        timer_event.sigev_signo = SIGRTMIN+num;
        timer_event.sigev_value.sival_ptr = (void*) tp;
	    if(timer_create(CLOCK_REALTIME, &timer_event, ktctimer) < 0){
                 perror("timer_create");
                 exit(0);
        }
        sigemptyset(&mask);
        sigaddset(&mask, SIGRTMIN+num);
        if(pthread_sigmask(SIG_UNBLOCK, &mask, NULL) == -1){
               perror("sigprocmask");
               exit(0);
        }
       //printf("*sival_ptr = 0x%lx\n", (long) *ktctimer);
}

int ktc_fdelay_start_timer(int interval, int unit, timer_t ktctimer, struct timespec* start_time){
	struct timespec interval_timespec;
        struct itimerspec i;
        struct timespec val, time_now;
        sigset_t mask;
	    interval_timespec = convert_to_timespec(interval, unit);
        val = add_timespec((*start_time), interval_timespec);
        i.it_value = add_timespec((*start_time), interval_timespec);
        //i.it_value = interval_timespec;
        i.it_interval.tv_sec = 0;
        i.it_interval.tv_nsec = 0;
	    if(timer_settime(ktctimer, TIMER_ABSTIME, &i, NULL) < 0){
                                perror("timer_setitimer");
                                exit(0);
        }


       // printf("start_timer  0x%lx\n", (long) ktctimer);
        (void) clock_gettime(CLOCK_REALTIME, &time_now);
       // printf("Timer set for : %lld.%.9ld\n", (long long)(val.tv_sec), (val.tv_nsec));
      //  printf("Time now : %lld.%.9ld\n", (long long)(time_now.tv_sec), (time_now.tv_nsec));
	//(*start_time) = add_timespec( (*start_time), interval_timespec);
}

int ktc_critical_start(int num , struct timespec* stime){
   (void) clock_gettime(CLOCK_REALTIME, stime);
	num = 15;
	sigset_t mask;
	sigfillset(&mask);
    sigdelset(&mask, SIGRTMIN+num);
	if (pthread_sigmask(SIG_BLOCK, &mask, NULL) < 0) {
		perror ("sigprocmask");
		return 1;
	}
}

int ktc_critical_end(int num, struct timespec stime, int* cwcet ){
   struct timespec ctime, elapsed_time_ts;
    int elapsed_time_int;
	num=15;
    (void) clock_gettime(CLOCK_REALTIME, &ctime);
    elapsed_time_ts = diff_timespec(ctime, stime);
    elapsed_time_int = timespec_to_unit(elapsed_time_ts, -6);
    if(elapsed_time_int > *cwcet)
        *cwcet = elapsed_time_int;
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGRTMIN+num);
	if (pthread_sigmask(SIG_UNBLOCK, &mask, NULL) < 0) {
		perror ("sigprocmask");
		return 1;
	}
}


int mktc_critical_start(int num){
	sigset_t mask;
	num = 15;
	//sigfillset(&mask);
    //sigdelset(&mask, SIGRTMIN+num);
    sigemptyset(&mask);
    sigaddset(&mask, SIGRTMIN+num);
	if (pthread_sigmask(SIG_BLOCK, &mask, NULL) < 0) {
		perror ("sigprocmask");
		return 1;
	}
}

int mktc_critical_end(int num){
    sigset_t mask;
	num = 15;
    sigemptyset(&mask);
    sigaddset(&mask, SIGRTMIN+num);
	if (pthread_sigmask(SIG_UNBLOCK, &mask, NULL) < 0) {
		perror ("sigprocmask");
		return 1;
	}

}


cbm* ktc_htc_getmes(struct cab_ds* cab){
	cbm* p;
	p = cab->mrb;
	p->use = p->use + 1;
	return p;
}

void ktc_htc_unget (struct cab_ds* cab, cbm* buffer){
	buffer->use = buffer->use - 1;
	if((buffer->use == 0) && (buffer != cab->mrb)){
		buffer->nextc = cab->free;
		cab->free = buffer;
	}
}



/*
void creadFourSlotIntChan(int* data, int* value, int* slot, int *latest, int *reading, int type){
	int pair, index;
	pair = *latest;
	__sync_bool_compare_and_swap(reading, (*reading), pair);
	index = slot[pair];
	value = &(data[pair][index]);
}

void creadFourSlotDoubleChan(double* data, double* value, int* slot, int *latest, int *reading){
        int pair, index;
        pair = *latest;
        __sync_bool_compare_and_swap(reading, (*reading), pair);
        index = slot[pair];
        value = &(data[pair][index]);
}

void creadFourSlotIntChan(int* data, int* value, int* slot, int *latest, int *reading, int type){
        int pair, index;
        pair = *latest;
        __sync_bool_compare_and_swap(reading, (*reading), pair);
        index = slot[pair];
        value = &(data[pair][index]);
}

void creadFourSlotIntChan(int* data, int* value, int* slot, int *latest, int *reading, int type){
        int pair, index;
        pair = *latest;
        __sync_bool_compare_and_swap(reading, (*reading), pair);
        index = slot[pair];
        value = &(data[pair][index]);
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

struct cbm* ktc_htc_reserve(struct cab_ds* cab){
	struct cbm* p;
	p = cab->free;
	cab->free =p->nextc;
	return p;
}

void ktc_htc_putmes(struct cab_ds* cab, struct cbm* buffer){
	if(cab->mrb != NULL && cab->mrb->use == 0){
		cab->mrb->nextc = cab->free;
		cab->free = cab->mrb;
	}
	cab->mrb = buffer;

}

void  ktc_fifo_read(struct threadqueue *queue, void* fifolistt, int* fifocount, int* fifotail, void* data, int size, int d){

	int wt = 0;
	pthread_mutex_lock(&queue->mutex);
	while(*fifotail == *fifocount){
		if(wt != 0){
		//     pthread_cond_timedwait(&queue->cond, &queue->mutex, &wt);
		  //   *wt = 0;
		    // pthread_mutex_unlock(&queue->mutex);
		     return ;
		}
		else
		     pthread_cond_wait(&queue->cond, &queue->mutex);
	}

	memcpy(data, fifolistt+(*fifotail), size);

	(*fifotail)++;
	if((*fifotail) == 40)
		(*fifotail) = (*fifotail) % 40;
	pthread_mutex_unlock(&queue->mutex);
}

void ktc_fifo_write(struct threadqueue *queue, void* fifolistt, int* fifocount, int* fifotail, void* data, int size){
	if(*fifocount == 40)
		*fifocount = (*fifocount) % 40;
	pthread_mutex_lock(&queue->mutex);
	memcpy(fifolistt+(*fifocount), data, size);
	if(*fifotail == *fifocount)
		pthread_cond_broadcast(&queue->cond);
	(*fifocount)++;
	pthread_mutex_unlock(&queue->mutex);
}

int ktc_fifo_init(struct threadqueue *queue){
    int ret = 0;
    if (queue == NULL) {
        return -1;
    }
    memset(queue, 0, sizeof(struct threadqueue));
    ret = pthread_cond_init(&queue->cond, NULL);
    if (ret != 0) {
        return ret;
    }

    ret = pthread_mutex_init(&queue->mutex, NULL);
    if (ret != 0) {
        pthread_cond_destroy(&queue->cond);
        return ret;
    }

    return 0;
}

int nelem(struct threadqueue *queue, int* fifocount, int* fifotail){
	int elem;
	pthread_mutex_lock(&queue->mutex);
	elem = abs(*fifocount - (*fifotail));
	pthread_mutex_unlock(&queue->mutex);
	return elem;


}
void ktc_simpson(int* sdata, int* tdata){
	*tdata = *sdata;
}

void change_priority(int deadline, int priority){
    ktc_set_sched(ktcpolicy, deadline, priority, deadline);
}


long ktc_sdelay_init_profile(int deadline, int period, int unit, struct timespec* start_time, int id, struct log_struct* fp, int pid, int priority){
    int profile = 0;
	printf("sdelay\n");
    if(pid != 0)
        fp->abort = profile;
        //printf(fp, "%d,", profile);
	/*condition for gettime*/
	if(period == -2103){
		return 0;
	}
	if(period == -1404){
		(void) clock_gettime(CLOCK_REALTIME, start_time);
        change_priority(deadline, priority);
		return (timespec_to_unit(*start_time, unit));
	}
	if(period < 0){
		(void) clock_gettime(CLOCK_REALTIME, start_time);
          change_priority(deadline, priority);
		return period;
	}
	if(period == 0){
		struct timespec st, elapsed_time;
		st = *start_time;
        change_priority(deadline, priority);
        (void) clock_gettime(CLOCK_REALTIME, start_time);
		elapsed_time = diff_timespec(*start_time, st);
		return (timespec_to_unit(elapsed_time, unit));
    }
    struct timespec interval_time, wait_time;
    interval_time = convert_to_timespec(period, unit);
    wait_time = add_timespec((*start_time), interval_time);
    change_priority(deadline, priority);
    clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
    *start_time = add_timespec((*start_time), interval_time);
	return 0;
/*	if(period == deadline){
		struct timespec end_time, elapsed_time, wait_time, interval_time, et;
		interval_time = convert_to_timespec(period, unit);
		(void) clock_gettime(CLOCK_REALTIME, &end_time);
		elapsed_time = diff_timespec(end_time, (*start_time));
		if(cmp_timespec(interval_time, elapsed_time) == 1){
			wait_time = add_timespec((*start_time), interval_time);
			clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
			*start_time = wait_time;
              change_priority(priority);
			return 0;
		}
		if(cmp_timespec(interval_time, elapsed_time) == 0){
			wait_time = add_timespec((*start_time), interval_time);
			*start_time = wait_time;
              change_priority(priority);
			return 0;
		}
		if(cmp_timespec(interval_time, elapsed_time) == -1){
			wait_time = add_timespec((*start_time), interval_time);
			elapsed_time = diff_timespec(end_time, wait_time);
        //printf("Time Elapsed- %lld.%.9ld\n", (long long)(elapsed_time.tv_sec), (elapsed_time.tv_nsec)) ;
			*start_time = add_timespec(wait_time, elapsed_time);
			(void) clock_gettime(CLOCK_REALTIME, &et);
              change_priority(priority);
			return (timespec_to_unit(elapsed_time, unit));
		}
	}
	if(period > deadline){
		struct timespec end_time, elapsed_time, wait_time, interval_time, et, deadline_timespec, overshot_timespec;
		interval_time = convert_to_timespec(period, unit);
		deadline_timespec = convert_to_timespec(deadline, unit);
		(void) clock_gettime(CLOCK_REALTIME, &end_time);
		elapsed_time = diff_timespec(end_time, (*start_time));
		if(cmp_timespec(interval_time, elapsed_time) == 1){
			wait_time = add_timespec((*start_time), interval_time);
			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec);
 *start_time = wait_time;
              change_priority(priority);
			return (timespec_to_unit(overshot_timespec, unit));
		}
		if(cmp_timespec(interval_time, elapsed_time) == 0){
			wait_time = add_timespec((*start_time), interval_time);
			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec);
			*start_time = wait_time;
              change_priority(priority);
			return (timespec_to_unit(overshot_timespec, unit));
		}
		if(cmp_timespec(interval_time, elapsed_time) == -1){
			wait_time = add_timespec((*start_time), interval_time);
			elapsed_time = diff_timespec(end_time, wait_time);			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			*start_time = add_timespec(wait_time, elapsed_time);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec);
			(void) clock_gettime(CLOCK_REALTIME, &et);
              change_priority(priority);
			return (timespec_to_unit(overshot_timespec, unit));
		}
	}
	if(period < deadline){
		struct timespec end_time, elapsed_time, wait_time, interval_time, et, deadline_timespec, overshot_timespec;
		interval_time = convert_to_timespec(period, unit);
		deadline_timespec = convert_to_timespec(deadline, unit);
		(void) clock_gettime(CLOCK_REALTIME, &end_time);
		elapsed_time = diff_timespec(end_time, (*start_time));
		if(cmp_timespec(interval_time, elapsed_time) == 1){
			wait_time = add_timespec((*start_time), interval_time);
			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec);
			*start_time = wait_time;
              change_priority(priority);
			return (timespec_to_unit(overshot_timespec, unit));
		}
		if(cmp_timespec(interval_time, elapsed_time) == 0){
			wait_time = add_timespec((*start_time), interval_time);
			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec);
			*start_time = wait_time;
              change_priority(priority);
			return (timespec_to_unit(overshot_timespec, unit));
		}
		if(cmp_timespec(interval_time, elapsed_time) == -1){
			wait_time = add_timespec((*start_time), interval_time);
			elapsed_time = diff_timespec(end_time, wait_time);			deadline_timespec = add_timespec((*start_time), deadline_timespec);
			*start_time = add_timespec(wait_time, elapsed_time);
			overshot_timespec = diff_timespec(elapsed_time, deadline_timespec);
			(void) clock_gettime(CLOCK_REALTIME, &et);
              change_priority(priority);
			return (timespec_to_unit(overshot_timespec, unit));
		}
	}
      change_priority(priority);
	return 0;
    */
}



long ktc_fdelay_init_profile(int interval, int period, int unit, struct timespec* start_time, int id, int retjmp, int num, struct log_struct* fp, int pid, int priority, struct tp_struct* tp, timer_t tid, int cwcet){
    printf("fdelay %d\n", retjmp);
    struct timespec time_now, elapsed_time_ts;
	int elapsed_time_int;
    long period_us;
	struct timespec wait_time, period_timespec;
	period_timespec = convert_to_timespec(2*(period), unit);
	wait_time = add_timespec((*start_time), period_timespec);
    int prf_zero = 1;
	(void) clock_gettime(CLOCK_REALTIME, &time_now);
     sigset_t allsigs, mask;
   // printf("Entered fdelay\n");
   // printf("Wait time : %lld.%.9ld\n", (long long)(wait_time.tv_sec), (wait_time.tv_nsec));
    //printf("Time now : %lld.%.9ld\n", (long long)(time_now.tv_sec), (time_now.tv_nsec));
	if(retjmp == 0){
      //printf("here\n");
       // sigfillset(&allsigs);
		// sigdelset(&allsigs, SIGRTMIN+num);
        // printf("suspend\n");
       // sigsuspend(&allsigs);
        //printf("suspend\n");
        tp->waiting = 1;
        timer_delete(tid);
        clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
        if(period > interval){
			clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &wait_time, NULL);
		}
		(void) clock_gettime(CLOCK_REALTIME, &time_now);
		elapsed_time_ts = diff_timespec(time_now, *start_time);
        elapsed_time_int = timespec_to_unit(elapsed_time_ts, -6);
         period_us = (period * pow(10, (unit + 6)));
		if(elapsed_time_int < 0 ){
		    *start_time =  add_timespec((*start_time), period_timespec);
            if(pid != 0)
                fp->abort = 356 + cwcet;
            change_priority(period, priority);
            //printf("No interrupt handler\n");
			return 0;
		}
		else{
	        *start_time =  add_timespec((*start_time), period_timespec);
            period_us = (period * pow(10, (unit + 6)));
            if(pid != 0)
                fp->abort = 356 + cwcet;
            change_priority(period, priority);
            //printf("No interrupt handler\n");
			return elapsed_time_int;
		}
	}
	else{
		// A case of next
		if(period < interval){
            elapsed_time_ts = diff_timespec(time_now, *start_time);
	        *start_time =  add_timespec((*start_time), period_timespec);
            elapsed_time_int = timespec_to_unit(elapsed_time_ts, -6);
             //fprintf(fp, "%d,", prf_zero);
             fp->abort = 356 + cwcet;
            change_priority(period, priority);
            //printf("Interrupt handler\n");
			return -1;
		}
		else{
		// A case of timer expiry
             elapsed_time_ts = diff_timespec(time_now, *start_time);
			*start_time =  add_timespec((*start_time), period_timespec);
            //fp->abort = prf_zero;
             //fprintf(fp, "%d,", prf_zero);
             elapsed_time_int = timespec_to_unit(elapsed_time_ts, -6);
             //fprintf(fp, "%d,", prf_zero);
             period_us = (period * pow(10, (unit + 6)));
             if(elapsed_time_int > 0)
                fp->abort = 356 + cwcet;
             else
                 fp->abort = 356 + cwcet;
             change_priority(period, priority);
            printf("Interrupt handler\n");
			return 0;
		}
	}


}

