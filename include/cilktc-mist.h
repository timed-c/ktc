/* Pragma once instead of #ifndef + #define guards. */
#pragma once

#include <stdint.h>
#include <setjmp.h>
#include <pthread.h>
#include <stdlib.h>
#include <signal.h>
#include <pthread.h>
#include <stdbool.h>
#include  <freertos/FreeRTOS.h>
#include <freertos/timers.h>
#include <freertos/queue.h>
#include  <freertos/task.h>

#include<at91/utility/trace.h>
#include<at91/peripherals/cp15/cp15.h>
#include<at91/utility/exithandler.h>
#include<at91/commons.h>

#include<stdlib.h>

#define MAX 5

typedef portTickType TickType_t;
typedef xQueueHandle QueueHandle_t;
typedef xTimerHandle TimerHandle_t;
typedef xTaskHandle TaskHandle_t;
typedef portBASE_TYPE UBaseType_t;
typedef void * xQueueHandle;

#define SEC_TO_NANO 1000000000
#define MILLI_TO_NANO 1000000
#define MICRO_TO_NANO 1000
#define MILLI 1000
#define MICRO 1000000
#define NANO  1000000000

/*
#define ms -3
#define ns -9
#define sec 0
#define us -6
*/
#define ms "ms"
#define ns "ns"
#define sec "sec"
#define us "us"

#define CONSTRUCTOR __attribute__((constructor))


#define ExactRGB(r,g,b) __attribute__((ExactRGB((r),(g),(b))))
#define LowerRGB(r,g,b) __attribute__((LowerRGB((r),(g),(b))))
#define UpperRGB(r,g,b) __attribute__((UpperRGB((r),(g),(b))))

#define AddRGB(x,r,g,b) (typeof(x) ExactRGB(r,g,b))x


#define red   __attribute__((red))
#define green __attribute__((green))
#define blue  __attribute__((blue))
#define AddColor(c,x) (typeof(x) c)x
#define task void* __attribute__((task))

#define cache_report if((void *__attribute__((cache_report)))0)

//#define sdelay(c)    printf("%d", c)

#define invariant(c,i,...) __blockattribute__((invariant((c),(i),__VA_ARGS__)))
#define post(c) __attribute__((post((c))))
#define pre(c)  __attribute__((pre((c))))

#define critical if((void *__attribute__((critical)))0)
#define next if((void *__attribute__((next)))0) next()
#define skipdelay skipdelay()
#define exec_child(x) if(x == 0)
//#define cread(chan, ptr); if((void *__attribute__((read_block))) (sizeof(#chan) > &ptr)) {sleep(0);}
#define cread(chan, ptr)   xQueueReceive( chan, &( ptr ), ( portMAX_DELAY ))
#define cread_wait(chan, ptr, tme, unit) TickType_t ktc_tick_of_time_var = ktc_tick_of_time(tme, unit); xQueueReceive( chan, &( ptr ), ktc_tick_of_time_var )
#define cwrite(chan, ptr)   xQueueSend(chan, &( ptr ), 0)
#define cinit(chan, val) chan = xQueueCreate(20, sizeof(val) )
#define cinit_size(chan, val, size) chan = xQueueCreate(size, sizeof(val) )
#define cread_wait(chan, ptr, val)   xQueueReceive( chan, &( ptr ), (val * portTICK_RATE_MS))
//#define main() populatelist(int num){ if(num == 0){return 0;} qsort (list_dl, num, sizeof(int), compare_qsort); qsort (list_pr, num, sizeof(int), compare_qsort); } void main()
//#define aperiodic(x, ms)  printf("");sdelay(x, ms); int i =0; while(i){sdelay(0, ms);} printf("aperiodic\n")
void ktc_fdelay();
#define fdelay(val, unit) ktc_fdelay()
//#define WDT_start()  WDT_start();vTaskStartScheduler();
extern int period;
extern int deadline;
extern int runtime;

#define aperiodic(x, ms) runtime = x; deadline = x; period = x; ktc_set_sched(policy, runtime, period, deadline)
//#define cwrite(chan, ptrw); if((void *__attribute__((write_block))) (sizeof(#chan) > ptrw)) {sleep(0);}
//#define cinit(chan, val); if((void *__attribute__((init_block))) (sizeof(#chan) > val)) {sleep(0);}

extern   TickType_t start_time ;
void skipdelay();
#define lvchannel __attribute__((lvchannel))
#//define fifochannel  __attribute__((fifochannel))
#define gettime(ms)  ktc_gettime(&start_time, #ms)
//#define prioritychannel xQueueHandle
#define fifochannel sardummy; xQueueHandle

enum sched_policy{EDF, FIFO_RM, RR_RM, FIFO_DM, RR_DM};
int policy;

#define spolicy(X) policy =X; sdelay(0, ms);
#define spriority(prio) vTaskPrioritySet(NULL, prio)
void toggle_lock_tracking();

int list_pr[500] = {4};
int list_dl[500] = {4};
/*
struct tp_struct{
        int waiting;
        jmp_buf env;
        timer_t* tmr;
};
bool boolvar;
struct tp_struct tp_struct_data;

void ktc_create_timer(timer_t* ktctimer, struct tp_struct* tp);
extern int ktc_start_time_init(struct timespec* start_time) ;
extern long ktc_sdelay_init(int intrval, char* unit, struct timespec* start_time, int id ) ;
extern long ktc_fdelay_init(int intrval, char* unit, struct timespec* start_time, int id ) ;

*/


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


QueueHandle_t xQueue;

struct cbm* ktc_htc_reserve(struct cab_ds* cab);
void ktc_htc_putmes(struct cab_ds* cab, struct cbm* buffer);
cbm* ktc_htc_getmes(struct cab_ds* cab);
void ktc_htc_unget (struct cab_ds* cab, cbm* buffer);
void ktc_fifo_init(QueueHandle_t* xqueue);
int ktc_fifo_read(QueueHandle_t* xqueue, int* data);
void ktc_fifo_write(QueueHandle_t* xqueue, int data);



/** FREERTOS**/
typedef struct timer_env {
	char* tname;
	jmp_buf envn;
}timer_env;


TaskHandle_t tskhndl;
TimerHandle_t tmrhndl;
UBaseType_t idle_prio = tskIDLE_PRIORITY + 2 ;
TickType_t tckvar;
TimerHandle_t ktc_timer_init_free(struct timer_env* ptrtenv);
long ktc_sdelay_init_free(int intrval, char* unit, TickType_t *start_time, int id);
void ktc_start_time_init_free(TickType_t *start_time);
int ktc_fdelay_start_timer_free(int interval, char* unit,TimerHandle_t  ktctimer, TickType_t start_time);
long ktc_fdelay_init_free(int interval, char* unit, TickType_t* start_time, TimerHandle_t  ktctimer, int retjmp, int id);
long ktc_gettime(TickType_t* start_time, char unit);
extern struct timer_env* timer_env_array[50];
extern int compare_qsort (const void * elem1, const void * elem2);
extern void populatelist(int num);


#define infty 0
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


void mplog_trace_init_tp(struct minmax_struct* fp, int fptr, int tp, unsigned long* arrival_init, TickType_t* itime);
void mplog_trace_init(const char* func, int *fp);
void mplog_trace_arrival(struct log_struct* fp, int tp, int interval, int res, unsigned long *last_arrival, TickType_t* itime);
void mplog_trace_release(struct log_struct* fp, unsigned long last_arrival, TickType_t* itime, TickType_t* stime, int interval);
void mplog_trace_execution(struct log_struct* fp, TickType_t stime, TickType_t* iptime);
void mplog_trace_end_id(struct log_struct* fp, int id, TickType_t time);
void mplog_trace_abort_time(struct minmax_struct* mm, struct log_struct* ls, int deadline, int* mkarray, int* mkmisses, int* mkcounter);
void mplog_write_to_file(int fp, struct minmax_struct* ls, int k, char* fname);

#pragma cilnoremove("log_struct")
#pragma cilnoremove("minmax_struct")
#pragma cilnoremove("mplog_trace_init_tp")
#pragma cilnoremove("mplog_trace_init")
#pragma cilnoremove("mplog_trace_arrival")
#pragma cilnoremove("mplog_trace_release")
#pragma cilnoremove("mplog_trace_execution")
#pragma cilnoremove("mplog_trace_end_id")
#pragma cilnoremove("mplog_trace_abort_time")
#pragma cilnoremove("mplog_write_to_file")
#pragma cilnoremove("fopen")
#pragma cilnoremove("fclose")
#pragma cilnoremove("list_dl")
#pragma cilnoremove("list_pr")
#pragma cilnoremove("populatelist")
#pragma cilnoremove("timer_env_array");
#pragma cilnoremove("taskYIELD");
#pragma cilnoremove("taskEXIT_CRITICAL")
#pragma cilnoremove("taskENTER_CRITICAL")
#pragma cilnoremove("timer_env_array");
#pragma cilnoremove("tmrhndl")
#pragma cilnoremove("tckvar")
#pragma cilnoremove("tskhdl")
#pragma cilnoremove("idle_prio")
#pragma cilnoremove("xTaskGenericCreate")
#pragma cilnoremove("xTaskGetTickCount")
#pragma cilnoremove("vTaskDelayUntil")
#pragma cilnoremove("vTaskDelete")
#pragma cilnoremove("ktc_start_time_init_free")
#pragma cilnoremove("ktc_timer_init_free")
#pragma cilnoremove("ktc_sdelay_init_free")
#pragma cilnoremove("setjmp");
#pragma cilnoremove("ktc_fdelay_init_free");
#pragma cilnoremove("ktc_fdelay_start_timer_free");
#pragma cilnoremove("ktc_fifo_init")
#pragma cilnoremove("ktc_fifo_read")
#pragma cilnoremove("ktc_fifo_write")
#pragma cilnoremove("fifodt")
#pragma cilnoremove("xQueue")
#pragma cilnoremove("MAX")
/*FREERTOS*/



