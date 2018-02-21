#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 700
#include<stdio.h>
#include<unistd.h>
#include<time.h>
#include<signal.h>
#include<stdarg.h>
#include<string.h>
#include<setjmp.h>
#include<sched.h>


#define SEC_TO_NANO 1000000000
#define MILLI_TO_NANO 1000000
#define MICRO_TO_NANO 1000
#define MILLI 1000
#define MICRO 1000000 
#define NANO  1000000000


int waiting_for_signal;
jmp_buf env;

/*Function responsible for performing the operation of the sensors*/
void sensor(){

	int num;	
	struct timespec ts;
	ts.tv_sec = 1;
        ts.tv_nsec = 5000000 ;
	srand(time(NULL));
	num = rand();
	if(num % 2 == 0){
		nanosleep(&ts, NULL);
	}
}
/*Function responsible for executing the control strategy */
void controller(){}

/*Function responsible for implementing the control decision*/
void actuate(){}
void sense(){int i;
	for(i =0 ;i <1000000000; i++){printf("%d\n", i);}}
void compute(){}
void handle_deadline(){printf("deadline overshot");}

/* Computes the difference between two timespec values, returns (time1-time2)*/
struct timespec diff_timespec(struct timespec time1, struct timespec time2){
	struct timespec result;
	if((time1.tv_sec < time2.tv_sec) ||
		((time1.tv_sec == time2.tv_sec) && 
			(time1.tv_nsec <= time2.tv_nsec))){
				result.tv_sec = result.tv_nsec = 0;
	}
	else{
		result.tv_sec = time1.tv_sec - time2.tv_sec;
		if(time1.tv_nsec < time2.tv_nsec){
			result.tv_nsec = time1.tv_nsec + 1000000000 - time2.tv_nsec;
			result.tv_sec--;
		}
		else{
			result.tv_nsec = time1.tv_nsec - time2.tv_nsec;

		}
	}
	return(result);
}

/* Function to add two timespec values*/
struct timespec add_timespec(struct timespec* tt, struct timespec time1, struct timespec time2){
        struct timespec result;
        result.tv_sec = time1.tv_sec + time2.tv_sec;
        result.tv_nsec = time1.tv_nsec + time2.tv_nsec;
        if(result.tv_nsec >= NANO){
                result.tv_sec++;
                result.tv_nsec = result.tv_nsec-NANO;

        }
	*tt = result;
        return(result);
}

/** Compares two timespec value 
Return Value :	time1 < time2 -1
    	 	time1 > time2  1
    		time1 = time2  0
**/
int cmp_timespec(struct timespec time1, struct timespec time2){
        if(time1.tv_sec < time2.tv_sec){
                return(-1);
        }
        else if(time1.tv_sec > time2.tv_sec){
                return(1);
        }
        else if(time1.tv_nsec < time2.tv_nsec){
                return(-1);
        }
        else if(time1.tv_nsec > time2.tv_nsec){
                return(1);
        }
        else
                return 0;
}

/* Converts timespec value to user readable long (millisecond) value*/
long convert_timespec_to_ms(struct timespec val){
		return(val.tv_sec*1000 + val.tv_nsec/1000000);
}

/*Converts time from seconds/microseconds/nanoseconds to milliseconds*/
long convert_to_ms(long interval, char* unit){
        if(!strcmp(unit, "sec")){
		return(interval * 1000);
	}
        if(!strcmp(unit, "ms")){
		return(interval);
        }
        if(!strcmp(unit, "micro")){
		return(interval/1000);
        }
        if(!strcmp(unit, "ns")){
		return(interval/1000000);
        }

}

/*Converts user specified interval from long (seconds/milliseonds/microseconds/nanoseconds value to timespec value for computation in C*/
struct timespec convert_to_timespec(struct timespec*tt, long interval, char* unit){
        struct timespec temp;
        if(!strcmp(unit, "sec")){
                temp.tv_sec = interval;
                temp.tv_nsec = 0;

        }
        if(!strcmp(unit, "ms")){
                temp.tv_sec = interval/MILLI;
                temp.tv_nsec = (interval % MILLI)*(MILLI_TO_NANO);
        }
        if(!strcmp(unit, "micro")){
                temp.tv_sec = interval/MICRO;
                temp.tv_nsec = (interval % MICRO)*(MICRO_TO_NANO);
        }
        if(!strcmp(unit, "ns")){
                temp.tv_sec = interval/NANO;
                temp.tv_nsec = (interval % NANO);
        }
        *tt = temp;
        return temp;
}




int waiting_for_signal;
jmp_buf env;
void timer_signal_handler(int sig, siginfo_t *extra, void *cruft){
 static int count = 0;
 count++;
 if(waiting_for_signal == 1){
   siglongjmp(env, count);
 }
 waiting_for_signal = 0;
}
void main(){
 struct timespec start_time, interval_timespec;
 long interval;
 char* unit;
 int  ret_jmp;
 struct itimerspec i;
 struct sigaction sa;
 struct sigevent timer_event;
 timer_t mytimer;
 convert_to_timespec(&interval_timespec, 30, "ms");
 sa.sa_flags = SA_SIGINFO;
 sa.sa_sigaction = timer_signal_handler;
 if(sigaction(SIGRTMIN, &sa, NULL) < 0){
   perror("sigaction");
   exit(0);
 }
 timer_event.sigev_notify = SIGEV_SIGNAL;
 timer_event.sigev_signo = SIGRTMIN;
 timer_event.sigev_value.sival_ptr = (void*) &mytimer;
 if(timer_create(CLOCK_REALTIME, &timer_event, &mytimer) < 0){
   perror("timer_create");
   exit(0);
 }
 (void) clock_gettime(CLOCK_REALTIME, &start_time);	
  add_timespec(&(i.it_value ), start_time, interval_timespec);
  i.it_interval.tv_sec = 0;
  i.it_interval.tv_nsec = 0;
  if(timer_settime(mytimer, TIMER_ABSTIME, &i, NULL) < 0 ){
    perror("timer_setitimer");
    exit(0);
  }
  while(1){
    ret_jmp = sigsetjmp(env, 1);
    waiting_for_signal = 1;
    if(ret_jmp != 0){
	 handle_deadline();
         goto JMP;
     }
  sense();
JMP:
   clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &i.it_value, NULL);
   waiting_for_signal = 0;
   add_timespec(&(i.it_value ), i.it_value, interval_timespec);
   i.it_interval.tv_sec = 0;
   i.it_interval.tv_nsec = 0;
   timer_settime(mytimer, TIMER_ABSTIME, &i, NULL); 
  }}
