
#include <time.h>

#define infty 0
void log_trace_init(const char* func, struct _IO_FILE *fp);
void log_trace_init_tp(struct _IO_FILE *fp, int tp, long* arrival_init, struct timespec itime);
void log_trace_arrival(FILE* fp, int tp, int interval, int res, long *last_arrival);
void log_trace_release(FILE* fp, long last_arrival, struct timespec itime, struct timespec* stime, int interval);
void log_trace_execution(FILE* fp, struct timespec stime);
void log_trace_end_id(FILE* fp, int id, struct timespec stime);
void log_trace_abort_time(FILE* fp);

struct log_struct{
    int src;
    unsigned long atime;
    unsigned long rtime;
    unsigned long jitter;
    unsigned long execution;
    unsigned long abort;
    int dst;
};

void plog_trace_init_tp(struct log_struct* fp, FILE* fptr, int tp, unsigned long* arrival_init, struct timespec itime);
void plog_trace_init(const char* func, struct _IO_FILE *fp);
void plog_trace_arrival(struct log_struct* fp, int tp, int interval, int res, unsigned long *last_arrival, struct timespec* itime);
void plog_trace_release(struct log_struct* fp, unsigned long last_arrival, struct timespec itime, struct timespec* stime, int interval);
void plog_trace_execution(struct log_struct* fp, struct timespec stime);
void plog_trace_end_id(struct log_struct* fp, int id, struct timespec stime);
void plog_trace_abort_time(int* fp);
void plog_write_to_file(FILE* fp, struct log_struct* ls);
