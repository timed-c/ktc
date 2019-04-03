#include<stdio.h>
#include<string.h>
#include<time.h>
#include<math.h>
#include<log.h>



int global_res = 1;
struct timespec log_diff_timespec(struct timespec start, struct timespec end)
{
	struct timespec temp;
	if ((end.tv_nsec-start.tv_nsec)<0) {
		temp.tv_sec = end.tv_sec-start.tv_sec-1;
		temp.tv_nsec = 1000000000+end.tv_nsec-start.tv_nsec;
	} else {
		temp.tv_sec = end.tv_sec-start.tv_sec;
		temp.tv_nsec = end.tv_nsec-start.tv_nsec;
	}
	return temp;
}

long log_timespec_to_ms(struct timespec ttime){

    return ttime.tv_sec*1000 + ttime.tv_nsec/1000000;
}

long log_timespec_to_us(struct timespec ttime){

    return ttime.tv_sec*1000000 + ttime.tv_nsec/1000;
}

void log_trace_init(const char* func, struct _IO_FILE* fp){
    fp = fopen(func, "w");
    fprintf(fp, "SRC, ARRIVAL, RELEASE, EXECUTION, ABORT \n");
    printf("%p\n", (struct _IO_FILE *) fp);
    if(fp == NULL)
        printf("error in file--trace-init");
}

void plog_trace_init_tp(struct log_struct* fp, FILE* fptr, int tp, unsigned long* arrival_init, struct timespec itime){
    long arrival_time, release_time;
    struct timespec ctime, rtime;
    clock_gettime(CLOCK_REALTIME, &ctime);
    arrival_time = 0;
    *arrival_init = arrival_time;
    fprintf(fptr, "SRC,ARRIVAL,RELEASE,JITTER,EXECUTION,ABORT,DST\n");
    fclose(fptr);
}


void plog_trace_arrival(struct log_struct* fp, int tp, int interval, int res, unsigned long *last_arrival){
    if(interval != -1404){
        long current_arrival = (*last_arrival) + (interval * pow(10, (res + 6)));
        if(tp != -1){
            fp->src = tp;
            fp->atime = current_arrival;
        }
        *last_arrival = current_arrival;
    }
}

void plog_trace_release(struct log_struct* fp, unsigned long last_arrival, struct timespec itime, struct timespec* stime, int interval){
    if(interval == -1404){
        struct timespec ctime, rtime;
        clock_gettime(CLOCK_REALTIME, &ctime);
       // *itime = ctime;
    }
    if(interval != -1404){
        long release_time, jitter;
        struct timespec ctime, rtime;
        clock_gettime(CLOCK_REALTIME, &ctime);
        rtime = log_diff_timespec(itime, ctime);
        release_time = (log_timespec_to_us(rtime)); //+ (last_arrival);
        jitter = release_time - last_arrival ;
        fp->rtime = release_time;
        fp->jitter = jitter;
        *stime = ctime;
    }
}

void plog_trace_execution(struct log_struct* fp, struct timespec stime){
    long execution_time, ctime_us, stime_us;
    struct timespec ctime, exetime;
    clock_gettime(CLOCK_REALTIME, &ctime);
    //exetime = log_diff_timespec(stime, ctime);
    execution_time = log_timespec_to_us(exetime);
    stime_us = log_timespec_to_us(stime);
    ctime_us = log_timespec_to_us(ctime);
    if(stime_us != 0)
        fp->execution = (ctime_us - stime_us);
}

void plog_write_to_file(FILE* fp, struct log_struct* ls){
    int i;
    //printf("printed\n");
   //  printf("printing....\n");
    for(i=2; i<99; i++){
       fprintf(fp, "%d,%ld,%ld,%ld,%ld,%ld,%d\n", ls[i].src, ls[i].atime, ls[i].rtime, ls[i].jitter, ls[i].execution, ls[i].abort, ls[i].dst);
    }
    printf("printed-end\n");

}

void plog_trace_end_id(struct log_struct* fp, int id, struct timespec stime){
    fp->dst = id;
}


void plog_trace_abort_time(struct log_struct* fp){
}

/*

void foo(FILE* fp, struct timespec itime, int offset){
    long last_arrival;
    long i;
    struct timespec start_exe;
    log_trace_init_tp(fp, 0, &last_arrival,(itime));
    printf("sdelay #1 5 -3 \n");
    log_trace_arrival(fp, 1, 5, -3, &last_arrival);
    for(i=0; i<1000000; i++){}
    log_trace_release(fp, last_arrival, (itime), &start_exe);
    printf("code");
    for(i=0; i<1000000000; i++){}
    log_trace_execution(fp, start_exe);
}

void main(){
    char name[50];
    FILE* foo_file;
    struct timespec trace_init_time;
    foo_file = log_trace_init(__func__);
    clock_gettime(CLOCK_REALTIME, &trace_init_time);
    foo(foo_file, trace_init_time, 0);
}
*/

