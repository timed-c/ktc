#include<cilktc-free.h>
#include<queue.h>

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


long ktc_sdelay_init_free(int intrval, char* unit, TickType_t *start_time, int id){
	TickType_t temp, time_perid, time_now, time_elaps;
	long time_in_ms, ret;
	if(intrval == 0){
 		*start_time = xTaskGetTickCount();
		return 0; 
	}
	time_in_ms = convert_to_ms(intrval, unit);
	time_perid = time_in_ms/portTICK_PERIOD_MS;
	time_now = xTaskGetTickCount();
	time_elaps = time_now - (*start_time);
	if(time_elaps < time_perid){
		temp = time_perid + (*start_time);
		ret = 0;
	}	
	else{
		temp = (time_elaps - time_perid) + (*start_time + time_perid);
		ret = (time_elaps - time_perid);
	}
	vTaskDelayUntil(start_time, time_perid);
	*start_time = temp;
	return ret;
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
		xTimerStop( ktctimer, 50 );
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
			xTimerStop( ktctimer, 50 );
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
				xTimerStop( ktctimer, 50 );
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


