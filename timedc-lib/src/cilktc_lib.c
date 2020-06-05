#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <string.h>
#include <math.h>

#define SEC_TO_NANO 1000000000
#define MILLI_TO_NANO 1000000
#define MICRO_TO_NANO 1000
#define MILLI 1000
#define MICRO 1000000 
#define NANO  1000000000

long timespec_to_unit(struct timespec val, int unit){
	int unit_ns =  9;
	int unit_sec = 0;
	unit_ns = unit_ns + unit;
	unit_sec = unit_sec - unit;
	//printf("Time Elapsed- %lld.%.9ld\n", (long long)(val.tv_sec), (val.tv_nsec)) ;
	return(val.tv_sec * (pow(10.0, unit_sec))  + round((float)val.tv_nsec/pow(10.0, unit_ns)));

	/* Example of conversion
        seconds : unit = 0 
                return(val.tv_sec  + val.tv_nsec/1000000000);
        milliseconds: unit = -                
		return(val.tv_sec*1000 + val.tv_nsec/1000000);
        microseconds : unit = -6
                return(val.tv_sec*1000000 + val.tv_nsec/1000);
        nanoseconds : unit = -9
                return(val.tv_sec*1000000000 + val.tv_nsec);
	*/
        
}

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
struct timespec add_timespec(struct timespec time1, struct timespec time2){
        struct timespec result;
        result.tv_sec = time1.tv_sec + time2.tv_sec;
        result.tv_nsec = time1.tv_nsec + time2.tv_nsec;
        if(result.tv_nsec >= NANO){
                result.tv_sec++;
                result.tv_nsec = result.tv_nsec-NANO;

        }
        return(result);
}

/** Compares two timespec value 
Return Value :	time1 < time2 -1
    	 	time1 > time2  1
    		time1 = time2  
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

/*Converts user specified interval from long value to timespec value 
	for computation in C*/
struct timespec convert_to_timespec(long interval, int unit){
        struct timespec temp;
	int abs_unit = abs(unit);
	if(unit < 0){
		temp.tv_sec = (interval/pow(10, abs_unit));
		temp.tv_nsec = (interval % (int)pow(10, abs_unit)) * (pow(10, 9 + unit));
	}
	if( unit == 0){
		temp.tv_sec = interval;
		temp.tv_nsec = 0;
	}
 	return temp;
}


