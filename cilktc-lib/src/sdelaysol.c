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
#include <pthread.h>

pthread_mutex_t mt;


long ktc_sdelay_init(int intrval, char* unit, struct timespec* start_time, int id){
	 if(intrval == 0){
		//printf("intr ==0");
		struct timespec st, elapsed_time;
		st = *start_time;
                (void) clock_gettime(CLOCK_REALTIME, start_time);
		elapsed_time = diff_timespec(*start_time, st);
		return (timespec_to_unit(elapsed_time, unit));
		//printf("Time At Timing Point - %lld.%.9ld\n", (long long)(start_time->tv_sec), (start_time->tv_nsec)) ;
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
		elapsed_time = diff_timespec(end_time, wait_time); /*elapsed_time here is the obershot*/
		*start_time = add_timespec(wait_time, elapsed_time);
		(void) clock_gettime(CLOCK_REALTIME, &et);
		//printf("Time At Timing Point - %lld.%.9ld\n", (long long)(start_time->tv_sec), (start_time->tv_nsec)) ;
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
	//printf("Timer Handle\n");
      if(tp->waiting != 1){
		tp->waiting = 0;
		siglongjmp(tp->env, 1);
	} 
}

void  ktc_create_timer(timer_t* ktctimer, struct tp_struct* tp, int num){
	struct sigaction sa;
        struct sigevent timer_event;
	sigfillset(&sa.sa_mask);
        sa.sa_flags = SA_SIGINFO;
	sa.sa_sigaction = timer_signal_handler;
	
	if(sigaction((SIGRTMIN+6+num), &sa, NULL) < 0){
                perror("sigaction");
                exit(0);
        }
	tp->waiting = 0;
	tp->tmr = ktctimer;
	timer_event.sigev_notify = SIGEV_SIGNAL;
        timer_event.sigev_signo = SIGRTMIN+6+num;
        timer_event.sigev_value.sival_ptr = (void*) tp;

	if(timer_create(CLOCK_REALTIME, &timer_event, ktctimer) < 0){
                 perror("timer_create");
                 exit(0);
        }


}

long ktc_fdelay_init(int interval, char* unit, struct timespec* start_time, int id, int retjmp, int num) {
	struct timespec time_now, elapsed_time_ts;
	int elapsed_time_int;
	if(retjmp == 0){
		sigset_t allsigs;
		sigfillset(&allsigs);
		sigdelset(&allsigs, SIGRTMIN+6+num);
        	sigsuspend(&allsigs);
		(void) clock_gettime(CLOCK_REALTIME, &time_now);
		 elapsed_time_ts = diff_timespec(time_now, *start_time);
        	elapsed_time_int = timespec_to_unit(elapsed_time_ts, unit);
		if(elapsed_time_int > 1 ){
			(void) clock_gettime(CLOCK_REALTIME, start_time);
			return elapsed_time_int;
		}
		else{
			(void) clock_gettime(CLOCK_REALTIME, start_time);

			return 1; 
		}
	}
	else{
		/* A case of next*/
		(void) clock_gettime(CLOCK_REALTIME, &time_now);
		elapsed_time_ts = diff_timespec(time_now, *start_time);
                elapsed_time_int = timespec_to_unit(elapsed_time_ts, unit);
		if(elapsed_time_int > 1 ){	
			(void) clock_gettime(CLOCK_REALTIME, start_time);
			return -1;
		}
		else{
		/* A case of timer expiry*/
			(void) clock_gettime(CLOCK_REALTIME, start_time);
			return 0;
		}
		
	}

}

int ktc_fdelay_start_timer(int interval, char* unit, timer_t ktctimer, struct timespec* start_time){
	struct timespec interval_timespec;
        struct itimerspec i;
	
	interval_timespec = convert_to_timespec(interval, unit);
        i.it_value = add_timespec((*start_time), interval_timespec);
        i.it_interval.tv_sec = 0;
        i.it_interval.tv_nsec = 0;
	 if(timer_settime(ktctimer, TIMER_ABSTIME, &i, NULL) < 0){
                                perror("timer_setitimer");
                                exit(0);
        }
	(*start_time) = add_timespec( (*start_time), interval_timespec); 
	
}

int ktc_critical_start(sigset_t* orig_mask){
	sigset_t maskall;
	sigfillset(&maskall);
	if (sigprocmask(SIG_BLOCK, &maskall, orig_mask) < 0) {
		perror ("sigprocmask");
		return 1;
	}
}

int ktc_critical_end(sigset_t* orig_mask){
	if (sigprocmask(SIG_SETMASK, orig_mask, NULL) < 0) {
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


void ktc_fifo_init(struct fifolist** chan){
	*chan =NULL;
	//printf("fifo init");
	if(pthread_mutex_init(&mt, NULL) != 0){
		//printf("mutx error");
	}
}  



int ktc_fifo_read_aux(struct fifolist** chan, int* data, pthread_mutex_t* mutx){
	
	struct fifolist* temp;
        struct timespec st, elapsed_time, tw;
	//printf("here\n");
	while(*chan == NULL){
	}
	//printf("Break");
	(void) clock_gettime(CLOCK_REALTIME, &st);
	sigset_t maskall;
        sigfillset(&maskall);
        if (sigprocmask(SIG_BLOCK, &maskall, NULL) < 0) {
                perror ("sigprocmask");
                return 1;
        }
	pthread_mutex_lock(mutx);
	temp = *chan;
	tw = temp->ts;
	*data = temp->data;
	*chan = temp->nextf;
        free(temp);
	pthread_mutex_unlock(mutx);
	if (sigprocmask(SIG_UNBLOCK, &maskall, NULL) < 0) {
		perror ("sigprocmask");
                return 1;
        }
	//printf("Out\n");
	(void) clock_gettime(CLOCK_REALTIME, &st);
	elapsed_time = diff_timespec(st, tw); 
	return(timespec_to_unit(elapsed_time, "micro"));
	
}


void ktc_fifo_write_aux(struct fifolist** chan, int data, pthread_mutex_t* mutx){
	struct fifolist* temp;
	struct fifolist* header;
	//printf("before mutex\n");
	pthread_mutex_lock(mutx);
	//printf("Acq\n");
	header = *chan;
	if(header != NULL){
		while(header->nextf != NULL){
			header = header->nextf;
		}
	
		temp = (struct fifolist*) malloc(sizeof(struct fifolist));
		temp->data = data;
		(void) clock_gettime(CLOCK_REALTIME, &(temp->ts));
		temp->nextf =  NULL;
		header->nextf = temp; 
	}	       
	else{
		temp = (struct fifolist*) malloc(sizeof(struct fifolist));
		temp->data = data;
                (void) clock_gettime(CLOCK_REALTIME, &(temp->ts));
                temp->nextf =  NULL;
                *chan= temp;

	}
	//printf("rel");
	pthread_mutex_unlock(mutx);
		
			//printf("%p\n", *chan);
}


int ktc_fifo_read(struct fifolist** chan, int* data){
        //printf("fifo read\n");
	ktc_fifo_read_aux(chan, data, &mt);
}

void ktc_fifo_write(struct fifolist** chan, int data){
        //printf("fifo write\n");
	ktc_fifo_write_aux(chan, data, &mt);
}

void ktc_simpson(int* sdata, int* tdata){
	*tdata = *sdata;
}
