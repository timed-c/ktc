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

#include "posix.main"
