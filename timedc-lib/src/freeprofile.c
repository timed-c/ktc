#include<cilktc-free.h>
#include<queue.h>
#include<timers.h>

/* The rate at which data is sent to the queue.  The 200ms value is converted
to ticks using the portTICK_PERIOD_MS constant. */
#define mainQUEUE_SEND_FREQUENCY_MS			( 100 / portTICK_PERIOD_MS )

/* The number of items the queue can hold.  This is 1 as the receive task
will remove items as they are added, meaning the send task should always find
the queue empty. */
#define mainQUEUE_LENGTH					( 200 )



extern void countClapAuxOff();
extern void control1Aux();
extern void countClapAux();
extern void control1AuxOff();

struct timer_env* timer_env_array[50] ;
jmp_buf bufinC;
struct qdata{
	int data;
	TickType_t time;
};

int timerExpired = 0;
struct timer_env* trgt;

#define INCLUDE_vTaskSuspend	1

UBaseType_t idle_prio_free = tskIDLE_PRIORITY;
/* The queue used by both tasks. */

void ktc_start_time_init_free(TickType_t *start_time){
	*start_time = xTaskGetTickCount();
}


int pHook(void* b){

}
void vfTimerCallback( TimerHandle_t xTimer ){

	int i;
	int tflag;
	struct timer_env* temp;
	for(i=0; i<10; i++){
		temp = timer_env_array[i];
		tflag = strcmp( pcTimerGetName( xTimer ), temp->tname);
		if(tflag == 0){
			trgt = temp;
			timerExpired = 1;
				//longjmp(temp->envn, 1);
			break;
		}
	}
}

TimerHandle_t ktc_timer_init_free(struct timer_env* ptrtenv){
	TimerHandle_t ret;
	static int i = 0;
	struct timer_env* temp;
	ret = xTimerCreate(ptrtenv->tname, (50000/portTICK_PERIOD_MS), pdFALSE, ( void * ) 0, vfTimerCallback);
	timer_env_array[i] = ptrtenv;
	i++;
	return ret;
}


long ktc_sdelay_init_free(int intrval, char* unit, TickType_t *last_arrival_time, int id){
	TickType_t temp;
    time_in_ms = convert_to_ms(intrval, unit);
	time_perid = time_in_ms/portTICK_PERIOD_MS;
    *last_arrival_time = *last_arrival_time + time_perid;
    temp = *last_arrival_time;
	vTaskDelayUntil(last_arrival_time, time_perid);
    *last_arrival_time = temp;
}
/* mistake here in conversion from ms to ticks*/

int ktc_fdelay_start_timer_free(int interval, char* unit,TimerHandle_t  ktctimer, TickType_t start_time){
	TickType_t time_now, time_elsp, time_perid, new_perid;
	time_now = xTaskGetTickCount();
	time_elsp = start_time - time_now;
	time_perid = interval/portTICK_PERIOD_MS;
	new_perid = time_perid - time_elsp;
	int ret ;
	if( xTimerIsTimerActive( ktctimer ) != pdFALSE ){
		xTimerDelete( ktctimer, 50 );
	}
	if((xTimerChangePeriod(ktctimer, time_perid, 50)) == pdPASS ){
		//control1Aux();
		//control1AuxOff();
		//countClapAuxOff();
		ret = 1;
	}
	else{
		ret = 0;
		printf("Timer Command could not be delivered\n");
	}

	return ret;
}

long ktc_fdelay_init_free(int interval, char* unit, TickType_t* start_time, TimerHandle_t  ktctimer, int retjmp,  int id) {
	TickType_t time_perid, temp;
	int overshot;
	time_perid = interval/portTICK_PERIOD_MS;
	temp =  time_perid + (*start_time);
	if(retjmp == 0){
		if( xTimerIsTimerActive( ktctimer ) != pdFALSE ){
		xTimerDelete( ktctimer, 50 );
		}
		vTaskDelayUntil(start_time, time_perid);
		*start_time = temp;
		overshot = (xTaskGetTickCount()) - (*start_time) ;
		if(overshot < 0)
			return 1;
		else
			return overshot;
	}
	else{
			*start_time =  xTaskGetTickCount();
			if(temp >  xTaskGetTickCount()){
				if( xTimerIsTimerActive( ktctimer ) != pdFALSE ){
				xTimerDelete( ktctimer, 50 );
			}
				return -1;
			}
			else{
				return 0;
			}
	}


}

void ktc_fifo_init(QueueHandle_t* xqueue){
	       *xqueue = xQueueCreate( mainQUEUE_LENGTH, sizeof( int ) );

}

int ktc_fifo_read(QueueHandle_t* xqueue, int* data){
	struct qdata qdReceivedValue;
	TickType_t time_now, time_elsp;
	int ret;
	xQueueReceive(*xqueue, &qdReceivedValue, portMAX_DELAY);
	*data = qdReceivedValue.data;
	time_now = xTaskGetTickCount();
	time_elsp = qdReceivedValue.time  - time_now;
	ret = portTICK_PERIOD_MS  * time_elsp;
	return(ret);
}

int ktc_fifo_read_timer(QueueHandle_t* xqueue, int* data){
	struct qdata qdReceivedValue;
	TickType_t time_now, time_elsp;
	TickType_t time_perid;
	BaseType_t ret;
	time_perid = 500/portTICK_PERIOD_MS;
	ret = xQueueReceive(*xqueue, &qdReceivedValue, time_perid);
	if(ret ==pdTRUE ){
		*data = qdReceivedValue.data;
		return 1;
	}
	else
		return 0;
}


void ktc_fifo_write(QueueHandle_t* xqueue, int data){
	struct qdata qdValueToSend;
	qdValueToSend.data = data;
	qdValueToSend.time = xTaskGetTickCount();
	xQueueSendToBack(*xqueue, &qdValueToSend, 50);
	int temp = uxQueueMessagesWaiting(*xqueue );



}



/*logs library*/
struct timespec log_diff_ticktype(TickType_t start, TickType_t end)
{
    return (end - start);
}

long log_ticktype_to_ms(TickType_t ttime){
    return (ttime * portTICK_PERIOD_MS);
}

long log_ticktype_to_us(TickType_t ttime){
    return (ttime * portTICK_PERIOD_MS * 1000);
}




void log_trace_init(const char* func, struct _IO_FILE* fp){
    fp = fopen(func, "w");
    fprintf(fp, "SRC, ARRIVAL, RELEASE, EXECUTION, ABORT \n");
    printf("%p\n", (struct _IO_FILE *) fp);
    if(fp == NULL)
        printf("error in file--trace-init");
}


void mplog_trace_init_tp(struct minmax_struct* fp, FILE* fptr, int tp, unsigned long* arrival_init, TickType_t* itime){
    long arrival_time, release_time;
    TickType_t ctime, rtime;
    int i;
    ctime = xTaskGetTickCount();
    arrival_time = 0;
    *arrival_init = arrival_time;
    *itime = xTaskGetTickCount();
    for(i=0; i<50; i++){
         ls[i].msrc = -1;
         ls[i].mbcet = 1000000;
         ls[i].mwcet = -1;
         ls[i].mjitter = -1;
         ls[i].mabort = -1;
         ls[i].mdst = -1;
    }
}

void plog_trace_arrival(struct log_struct* fp, int tp, int interval, int res, unsigned long *last_arrival, TickType_t * iptime){
    //printf("arival time %ld\n", log_timespec_to_us(*iptime));
    struct timespec ctime;
    ctime =  xTaskGetTickCount();
    long current_arrival = (*last_arrival) + (interval * pow(10, (res + 6)));
    if(tp != -1){
        fp->src = tp;
        fp->atime = current_arrival;
    }
    *last_arrival = current_arrival;
}

void plog_trace_release(struct log_struct* fp, unsigned long last_arrival, TickType_t* iptime, TickType_t* stime, int interval){
    long release_time, jitter, absjitter;
    TickType_t* ctime, rtime;
    ctime =  xTaskGetTickCount();
    rtime = log_diff_ticktype(*iptime, ctime);
    release_time = (log_ticktype_to_us(rtime)); //+ (last_arrival);
    jitter = release_time - last_arrival ;
    if(jitter < 0){
        absjitter = -1 * jitter;
    }
    else{
        absjitter = jitter;
    }
    fp->rtime = release_time;
    fp->jitter = absjitter;
    *stime = ctime;
}

void plog_trace_execution(struct log_struct* fp, struct timespec stime, struct timespec* iptime){
    long execution_time, ctime_us, stime_us;
    TickType_t ctime, exetime;
    struct log_struct* prev;
    ctime = xTaskGetTickCount();
    execution_time = log_timetype_to_us(exetime);
    stime_us = log_timetype_to_us(stime);
    ctime_us = log_timetype_to_us(ctime);
    if(stime_us != 0)
        fp->execution = (ctime_us - stime_us);
}

void plog_write_to_file(FILE* fp, struct minmax_struct* ls, int k, char* fname){
    int i;
    for(i=0;i<50;i++){
        if(ls[i].msrc != -1 && ls[i].mdst != -1){
            fprintf(fp, "%d,%ld,%ld,%ld,%ld,%d\n", ls[i].msrc, ls[i].mbcet, ls[i].mwcet, ls[i].mjitter, ls[i].mabort, ls[i].mdst);
        }
    }
}

void plog_trace_end_id(struct log_struct* fp, int id, struct timespec stime){
    fp->dst = id;
}

void plog_trace_abort_time(struct minmax_struct* mm, struct log_struct* ls, int deadline, int* mkarray, int* mkmisses, int* mkcounter){
        int i, j, kcount;
        int index = (*mkcounter) % (3);
        if((ls->rtime + ls->execution) > (ls->atime + deadline))
            mkarray[index] = 1;
        else
             mkarray[index] = 0;
        kcount = 0;
        for(j=0; j<3; j++){
            if(mkarray[index] > 0)
                kcount++;
        }
        if(kcount > (*mkmisses))
            *mkmisses = kcount;
        *mkcounter = *mkcounter+1;
        //printf("%d,%ld,%ld,%ld,%ld,%ld,%d\n", ls->src, ls->atime, ls->rtime, ls->jitter, ls->execution, ls->abort, ls->dst);
        for(i =0; i<50; i++){
            if(mm[i].msrc == ls->src && mm[i].mdst == ls->dst){
                if(mm[i].mbcet > ls->execution)
                    mm[i].mbcet = ls->execution;
                if(mm[i].mwcet  < ls->execution)
                    mm[i].mwcet = ls->execution;
                if(mm[i].mjitter < ls->jitter)
                    mm[i].mjitter = ls->jitter;
                if(mm[i].mabort < ls->abort)
                    mm[i].mabort = ls->abort;
                break;
            }
            else{
                if(mm[i].msrc == -1 && mm[i].mdst == -1){
                    //printf("trace abort %d %d\n", ls->src, ls->dst);
                    mm[i].msrc = ls->src;
                    mm[i].mdst = ls->dst;
                    mm[i].mbcet = ls->execution;
                    mm[i].mwcet = ls->execution;
                    mm[i].mjitter = ls->jitter;
                    mm[i].mabort = ls->abort;
                    break;
                }
            }
        }
}

