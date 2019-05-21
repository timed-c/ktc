
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
#include <pthread.h>
#include <stdbool.h>
#include <linux/sched.h>
#include <linux/types.h>
/*#include  "../../FreeRTOSv9.0.0/FreeRTOS/Source/include/FreeRTOS.h"
#include  "../../FreeRTOSv9.0.0/FreeRTOS/Source/include/task.h"
#include "../../FreeRTOSv9.0.0/FreeRTOS/Source/include/timers.h"
*/

enum sched_policy{EDF, FIFO_RM, RR_RM, FIFO_DM, RR_DM};
int policy;
extern int setschedvar;
//#define spolicy(X) if( (X) == EDF) spolicy_edf(); else spolicy_other(); sleep(0)
#define spolicy(X) setschedvar = 1; policy =X; sdelay(-2103, ms);
#define task void* __attribute__((task))
#define sdelay(intr, ...) sdelay(intr, intr, ##__VA_ARGS__)
#define stp(pr, dl, unit) sdelay(pr, dl, unit)
#define ftp(pr, dl, unit) if (pr == 0) skipdelay;  fdelay(pr, dl, unit)
#define fdelay(intr, ...) fdelay(intr, intr, ##__VA_ARGS__)
#define gettime(unit)  ktc_gettime(unit);sdelay(-1404, 0)

#define invariant(c,i,...) __blockattribute__((invariant((c),(i),__VA_ARGS__)))
#define post(c) __attribute__((post((c))))
#define pre(c)  __attribute__((pre((c))))

#define SOFT_PERIODIC_LOOP(time, unit, ov, func) \
			while(1){\
				func();\
				 ov = sdelay(time, unit);\
			}
extern int period;
extern int runtime;
extern int deadline;

struct threadqueue {
	pthread_mutex_t mutex;
	pthread_cond_t cond;
};

#define critical if((void *__attribute__((critical)))0)
#define skipdelay if((void *__attribute__((next)))0) next()
#define exec_child(x) if(x == 0)
#define cread(chan, ptr)   if((void *__attribute__((read_block))) (sizeof(#chan) > &ptr)){sleep(0);}
#define cwrite(chan, ptr) if((void *__attribute__((write_block))) (sizeof(#chan) > &ptr)){sleep(0);}
//#define cinit(chan, val) int tempinitvarktc; if((void *__attribute__((init_block))) (sizeof(#chan) > &tempinitvarktc)){sleep(0);}
//cinit(chan, val) chan = pipe_new(sizeof(val), )
#define lvchannel __attribute__((lvchannel))
//#define fifochannel(c)  c ##ktclist[50]; int c ##ktccount; int c ##ktctail; struct threadqueue  __attribute__((fifochannel)) c
//# task if((void *__attribute__((task)))1)
#define fifochannel(c) c; pipe_t* c ##pipe; pipe_consumer_t* c ##cons; pipe_producer_t* c ##pros;
#define main(...) *dummyglobalvariable; int populatelist(int num){ if(num == 0){return 0;} qsort (list_dl, num, sizeof(int), compare_qsort); qsort (list_pr, num, sizeof(int), compare_qsort);return 1; } void main(__VA_ARGS__)
#define aperiodic(val, ms)  runtime = val; deadline = val; period = val; ktc_set_sched(policy, runtime, period, deadline);setschedvar = 0;
#define ms -3
#define ns -9
#define sec 0
#define us -6
#define infty 0


struct timespec diff_timespec(struct timespec, struct timespec);
struct timespec add_timespec(struct timespec, struct timespec);
int cmp_timespec(struct timespec, struct timespec);
struct timespec convert_to_timespec(long, int);
long timespec_to_unit(struct timespec val, int unit);

void *checked_dlsym(void *handle, const char *sym);
pid_t gettid();

void perf_init(pid_t pid);
uint64_t perf_get_cache_refs();
uint64_t perf_get_cache_miss();
void perf_deinit();
uint64_t tut_get_time();

struct timespec* timepecptr;
timer_t ftimer;
sigset_t sigtype;
int ktc_critical_end(sigset_t* orig_mask);
int ktc_critical_start(sigset_t* orig_mask);
int ktc_set_sched(int policy, int runtime, int deadline, int period) ;

void toggle_lock_tracking();

struct tp_struct{
        int waiting;
        jmp_buf env;
        timer_t* tmr;
};


bool boolvar;
struct tp_struct tp_struct_data;
int list_pr[500];
int list_dl[500];
void ktc_create_timer(timer_t* ktctimer,timer_t tid, struct tp_struct* tp, int num);
extern int ktc_start_time_init(struct timespec* start_time) ;
extern long ktc_sdelay_init_profile(int deadline, int period, int unit, struct timespec* start_time, int id, FILE* fp, int pid, int priority) ;
extern long ktc_sdelay_init(int deadline, int period, int unit, struct timespec* start_time, int id ) ;
extern long ktc_fdelay_init_profile(int interval,int period, int unit, struct timespec* start_time, int id, int num, int retjmp, FILE* fp, int pid, int priority);
extern long ktc_gettime(int unit);
extern long ktc_fdelay_init(int interval,int period, int unit, struct timespec* start_time, int id, int num, int retjmp);
extern long ktc_block_signal(int n);
sigjmp_buf buf_struct;


typedef struct cbm{
	int use;
	int data;
	struct cbm* nextc;
} cbm;

struct cab_ds{
	struct cbm* free;
	struct cbm* mrb;
	int maxcbm;

};

cbm cabmsgv;
struct cab_ds cabdsv;

struct fifolist{
	int data;
	struct timespec ts;
	struct fifolist* nextf;
	pthread_mutex_t mutx;
};


struct sched_attr {
	__u32 size;

	__u32 sched_policy;
	__u64 sched_flags;

	/* SCHED_NORMAL, SCHED_BATCH */
	__s32 sched_nice;

	/* SCHED_FIFO, SCHED_RR */
	__u32 sched_priority;

	/* SCHED_DEADLINE (nsec) */
	__u64 sched_runtime;
	__u64 sched_deadline;
	__u64 sched_period;
 };

struct sched_attr sae;
struct fifolist fifoex;
//struct log_struct lfile;

extern int compare_qsort (const void * elem1, const void * elem2);
extern int populatelist(int num);
struct cbm* ktc_htc_reserve(struct cab_ds* cab);
void ktc_htc_putmes(struct cab_ds* cab, struct cbm* buffer);
cbm* ktc_htc_getmes(struct cab_ds* cab);
void ktc_htc_unget (struct cab_ds* cab, cbm* buffer);
int ktc_fifo_init(struct threadqueue *queue);
void ktc_fifo_write(struct threadqueue *queue, void* fifolistt, int* fifocount, int* fifotail, void* data, int size);
void  ktc_fifo_read(struct threadqueue *queue, void* fifolistt, int* fifocount, int* fifotail, void* data, int size, struct timespec* wt);
void ktc_simpson(int* sdata, int* tdata);
#include <getopt.h>
size_t s;
struct option o;
static inline int sched_getattr(pid_t pid, struct sched_attr *attr, unsigned int size, unsigned int flags){return syscall(315, pid, attr, size, flags);}
/*
static inline int setjmpdummy(){
	sigsetjmp(buf_struct, 1);
}
*/

//#pragma cilnoremove("getoptdummy")

static inline int getoptdummy()
{
  int i;
  optarg = NULL;
  sscanf(NULL,"%d",&i);
  return getopt_long(0, NULL, NULL, NULL, NULL);
}

#define ARG_HAS_OPT 1

#define argument(argtype, argname, ...) \
argtype argname; \
int argname##got; \
struct ciltut_##argname { \
  char    *short_form; \
  char    *help_text; \
  char    *format; \
  argtype  def; \
  void    *requires; \
  int      has_opt; \
} __attribute__((ciltutarg, ##__VA_ARGS__)) _ciltut_##argname =

#define arg_assert(e) (void *__attribute__((ciltut_assert((e)))))0


#define autotest    __attribute__((autotest))
#define instrument  __attribute__((instrument))
#define input       __attribute__((input))
#define inputarr(s) __attribute__((inputarr(s)))
#define inputnt     __attribute__((inputnt))

void assign(uint64_t lhs, uint64_t op, int opk, uint64_t opv);
void assgn_bop(uint64_t lhs, uint64_t lhsv, int bop,
               uint64_t op1, int op1k, uint64_t op1v,
               uint64_t op2, int op2k, uint64_t op2v);
void assgn_uop(uint64_t lhs, uint64_t lhsv, int uop,
               uint64_t op, int opk, uint64_t opv);

void cond(int cid, int r, uint64_t op, int opk, uint64_t opv);
void cond_bop(int cid, int bop, int r,
              uint64_t op1, int op1k, uint64_t op1v,
              uint64_t op2, int op2k, uint64_t op2v);
void cond_uop(int cid, int uop, int r,
              uint64_t op, int opk, uint64_t opv);

void register_input(char *name, uint64_t addr, int bits);
void register_arr_input(char *name, uint64_t start, int sz, int cnt);
void register_nt_input(char *name, char *start);
//int ktc_sdelay_end(char const   *f , int l , int intrval , char *unit ) ;
//void ktc_sdelay_init(char const   *f , int l ) ;
int ktc_fdelay_start_timer(int interval, int unit, timer_t ktctimer, struct timespec* start_time);
pthread_t pthread_id_example;



/* log specfic*/
struct log_struct{
    int src;
    unsigned long atime;
    unsigned long rtime;
    unsigned long jitter;
    unsigned long execution;
    unsigned long abort;
    int dst;
};

struct minmax_struct{
    int msrc;
    unsigned long mbcet;
    unsigned long mwcet;
    unsigned long mjitter;
    unsigned long mabort;
    int mdst;
};

void log_trace_init(const char* func, struct _IO_FILE *fp);
void log_trace_init_tp(struct _IO_FILE *fp, int tp, long* arrival_init, struct timespec itime);
void log_trace_arrival(FILE* fp, int tp, int interval, int res, long *last_arrival);
void log_trace_release(FILE* fp, long last_arrival, struct timespec itime, struct timespec* stime, int interval);
void log_trace_execution(FILE* fp, struct timespec stime);
void log_trace_end_id(FILE* fp, int id, struct timespec stime);
void log_trace_abort_time(FILE* fp);

void plog_trace_init_tp(struct log_struct* fp, FILE* fptr, int tp, unsigned long* arrival_init, struct timespec itime);
void plog_trace_init(const char* func, struct _IO_FILE *fp);
void plog_trace_arrival(struct log_struct* fp, int tp, int interval, int res, unsigned long *last_arrival, struct timespec* itime);
void plog_trace_release(struct log_struct* fp, unsigned long last_arrival, struct timespec itime, struct timespec* stime, int interval);
void plog_trace_execution(struct log_struct* fp, struct timespec stime);
void plog_trace_end_id(struct log_struct* fp, int id, struct timespec stime);
void plog_trace_abort_time(int* fp);
void plog_write_to_file(FILE* fp, struct log_struct* ls, char* fname);
void plog_set_param(char* argv[]);

void mplog_trace_init_tp(struct minmax_struct* ls, FILE* fptr,  int tp, unsigned long* arrival_init, struct timespec* iptime);
void mplog_trace_arrival(struct log_struct* fp, int tp, int interval, int res, unsigned long *last_arrival, struct timespec* iptime);
void mplog_trace_release(struct log_struct* fp, unsigned long last_arrival, struct timespec* iptime, struct timespec* stime, int interval);
void mplog_trace_execution(struct log_struct* fp, struct timespec stime, struct timespec* iptime);
void mplog_write_to_file(FILE* fp, struct minmax_struct* ls, int k, char* fname);
void mplog_trace_end_id(struct log_struct* fp, int id, struct timespec stime);
void mplog_set_param(char* argv[]);
void mplog_trace_abort_time(struct minmax_struct* mm, struct log_struct* ls, int deadline, int* mkarray, int* mkmisses, int* mkcounter);


int ktc_kglobal;
int ktc_iterglobal;

/** FREERTOS**/
/*
TaskHandle_t tskhndl;
TimerHandle_t tmrhndl;
UBaseType_t idle_prio = tskIDLE_PRIORITY;
TickType_t tckvar;
TimerHandle_t ktc_timer_init_free();
long ktc_sdelay_init_free(int intrval, char* unit, TickType_t *start_time, int id);
void ktc_start_time_init_free(TickType_t *start_time);
#pragma cilnoremove("tmrhndl")
#pragma cilnoremove("tckvar")
#pragma cilnoremove("tskhdl")
#pragma cilnoremove("idle_prio")
#pragma cilnoremove("xTaskCreate")
#pragma cilnoremove("xTaskGetTickCount")
#pragma cilnoremove("vTaskDelayUntil")
#pragma cilnoremove("vTaskDelete")
#pragma cilnoremove("ktc_start_time_init_free")
#pragma cilnoremove("ktc_timer_init_free")
#pragma cilnoremove("ktc_sdelay_init_free")
/*FREERTOS*/

#pragma cilnoremove("compare_qsort")
#pragma cilnoremove("ktc_htc_reserve")
#pragma cilnoremove("ktc_htc_putmes")
#pragma cilnoremove("ktc_htc_getmes")
#pragma cilnoremove("ktc_htc_unget")
#pragma cilnoremove("cabmsgv")
#pragma cilnoremove("cabdsv")
#pragma cilnoremove("boolvar")
#pragma cilnoremove("fork")
#pragma cilnoremove("exec_child")
#pragma cilnoremove("pthread_id_example")
#pragma cilnoremove("sigtype")
#pragma cilnoremove("next")
#pragma cilnoremove("ktc_start_time_init")
#pragma cilnoremove("ktc_sdelay_init")
#pragma cilnoremove("ktc_fdelay_init")
#pragma cilnoremove("ktc_sdelay_init_profile")
#pragma cilnoremove("ktc_fdelay_init_profile")
#pragma cilnoremove("ktc_block_signal")
#pragma cilnoremove("timepecptr")
#pragma cilnoremove("env")
#pragma cilnoremove("ftimer")
#pragma cilnoremove("ktc_create_timer")
#pragma cilnoremove("tp_struct_data")
#pragma cilnoremove("__sigsetjmp")
#pragma cilnoremove("pthread_join")
#pragma cilnoremove("pthread_tryjoin_np")
#pragma cilnoremove("pthread_create")
#pragma cilnoremove("ktc_fdelay_start_timer")
#pragma cilnoremove("ktc_critical_end")
#pragma cilnoremove("ktc_critical_start")
#pragma cilnoremove("fifoex")
//#pragma cilnoremove("lfile")
#pragma cilnoremove("ktc_fifo_init")
#pragma cilnoremove("ktc_fifo_read")
#pragma cilnoremove("ktc_fifo_write")
#pragma cilnoremove("ktc_simpson")
#pragma cilnoremove("ktc_set_sched")
#pragma cilnoremove("ktc_gettime")
#pragma cilnoremove("list_dl")
#pragma cilnoremove("list_pr")
#pragma cilnoremove("populatelist")
#pragma cilnoremove("sched_getattr")
#pragma cilnoremove("log_trace_end_id")
#pragma cilnoremove("log_trace_abort_time")
#pragma cilnoremove("log_trace_release")
#pragma cilnoremove("log_trace_execution")
#pragma cilnoremove("log_trace_arrival")
#pragma cilnoremove("log_trace_init_tp")
#pragma cilnoremove("log_trace_init")
#pragma cilnoremove("mplog_set_param")
#pragma cilnoremove("mplog_trace_end_id")
#pragma cilnoremove("mplog_trace_abort_time")
#pragma cilnoremove("mplog_trace_release")
#pragma cilnoremove("mplog_trace_execution")
#pragma cilnoremove("mplog_trace_arrival")
#pragma cilnoremove("mplog_trace_init_tp")
#pragma cilnoremove("mplog_trace_init")
#pragma cilnoremove("mplog_write_to_file")
#pragma cilnoremove("clock_gettime")
#pragma cilnoremove("sae")
#pragma cilnoremove("fopen")
#pragma cilnoremove("fclose")
#pragma cilnoremove("plog_set_param")
#pragma cilnoremove("plog_trace_end_id")
#pragma cilnoremove("plog_trace_abort_time")
#pragma cilnoremove("plog_trace_release")
#pragma cilnoremove("plog_trace_execution")
#pragma cilnoremove("plog_trace_arrival")
#pragma cilnoremove("plog_trace_init_tp")
#pragma cilnoremove("plog_trace_init")
#pragma cilnoremove("plog_write_to_file")
#pragma cilnoremove("log_struct")
#pragma cilnoremove("minmax_struct")
extern int autotest_finished;
//extern int ktc_sdelay_end(char const   *f , int l , int intrval , char *unit ) ;
//extern long ktc_sdelay_init(char const   *f , int l, int intrval, char* unit, struct timespec* start_time ) ;
void gen_new_input();

void val_push(uint64_t v);
uint64_t val_pop(char *name);
void pop_array(char *name, char *base, int cnt, int sz);
void pop_nt(char * name, char *base);

void return_push(uint64_t p, uint64_t v);
void return_pop(uint64_t p, uint64_t v);

void autotest_reset();

//int ktc_sdelay_end(char const   *f , int l , int intrval , char *unit ) ;
//void ktc_sdelay_init(char const   *f , int l ) ;



