
#include <stdint.h>
#include <setjmp.h>
#include <pthread.h>
#include <stdlib.h>
#include <signal.h>
#include <pthread.h>
#include <stdbool.h>
#include <freertos/FreeRTOS.h>
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

#define FIFOCHANNEL_MAXDELAY portMAX_DELAY
#define fifochannel  xQueueHandle
#define task void* __attribute__((task))

#define cinit(chan, val) chan = xQueueCreate(25, sizeof(val))
#define cread(chan, ptr)   xQueueReceive( chan, &( ptr ), ( portMAX_DELAY ))
#define cread_wait(chan, ptr, val)   xQueueReceive( chan, &( ptr ), val)
#define cwrite(chan, ptr)   xQueueSend( chan, &( ptr ), 0)
#define gettime(ms)  ktc_gettime(&start_time)
#define spriority(prio) vTaskPrioritySet(NULL, prio)




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
long ktc_gettime(TickType_t* start_time);
extern struct timer_env* timer_env_array[50];
extern int compare_qsort (const void * elem1, const void * elem2);
extern void populatelist(int num);

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

 
