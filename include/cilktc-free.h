
#include <stdint.h>
#include <setjmp.h>
#include <stdbool.h>
#include  "FreeRTOS.h"
#include  "task.h"
#include "timers.h"

#define SEC_TO_NANO 1000000000
#define MILLI_TO_NANO 1000000
#define MICRO_TO_NANO 1000
#define MILLI 1000
#define MICRO 1000000 
#define NANO  1000000000

#define task void* __attribute__((task))
#define critical if((void *__attribute__((critical)))0)
#define next if((void *__attribute__((next)))0) next()
#define exec_child(x) if(x == 0)
#define cread(chan, ptr)   if((void *__attribute__((read_block))) (sizeof(#chan) > sizeof(#ptr))) 
#define cwrite(chan, ptrw) if((void *__attribute__((write_block))) (sizeof(#chan) > ptrw))
#define cinit(chan, val) if((void *__attribute__((init_block))) (sizeof(#chan) > val)){printf("dmmyStmt");}
#define lvchannel __attribute__((lvchannel))


struct timespec diff_timespec(struct timespec, struct timespec);
struct timespec add_timespec(struct timespec, struct timespec);
int cmp_timespec(struct timespec, struct timespec);
long convert_timespec_to_ms(struct timespec);
long convert_to_ms(long, char*);
struct timespec convert_to_timespec(long, char*);
long timespec_to_unit(struct timespec val, char* unit);

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

struct cbm* ktc_htc_reserve(struct cab_ds* cab);
void ktc_htc_putmes(struct cab_ds* cab, struct cbm* buffer);
cbm* ktc_htc_getmes(struct cab_ds* cab);
void ktc_htc_unget (struct cab_ds* cab, cbm* buffer);


/** FREERTOS**/
typedef struct timer_env {
	char* tname;
	jmp_buf envn;
}timer_env;
TaskHandle_t tskhndl;
TimerHandle_t tmrhndl;
extern UBaseType_t idle_prio_free;
TickType_t tckvar;
TimerHandle_t ktc_timer_init_free(struct timer_env* ptrtenv);
long ktc_sdelay_init_free(int intrval, char* unit, TickType_t *start_time, int id);
void ktc_start_time_init_free(TickType_t *start_time);
int ktc_fdelay_start_timer_free(int interval, char* unit,TimerHandle_t  ktctimer, TickType_t start_time);
long ktc_fdelay_init_free(int interval, char* unit, TickType_t* start_time, TimerHandle_t  ktctimer, int id);
extern struct timer_env* timer_env_array[10];

#pragma cilnoremove("timer_env_array");
#pragma cilnoremove("taskEXIT_CRITICAL")
#pragma cilnoremove("taskENTER_CRITICAL")
#pragma cilnoremove("timer_env_array");
#pragma cilnoremove("tmrhndl")
#pragma cilnoremove("tckvar")
#pragma cilnoremove("tskhdl")
#pragma cilnoremove("idle_prio_free")
#pragma cilnoremove("xTaskCreate")
#pragma cilnoremove("xTaskGetTickCount")
#pragma cilnoremove("vTaskDelayUntil")
#pragma cilnoremove("vTaskDelete")
#pragma cilnoremove("ktc_start_time_init_free")
#pragma cilnoremove("ktc_timer_init_free")
#pragma cilnoremove("ktc_sdelay_init_free")
#pragma cilnoremove("setjmp");
#pragma cilnoremove("ktc_fdelay_init_free");
#pragma cilnoremove("ktc_fdelay_start_timer_free");
/*FREERTOS*/




