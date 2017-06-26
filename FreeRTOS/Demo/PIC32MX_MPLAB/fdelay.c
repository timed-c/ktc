#include<cilktc-free.h>

UBaseType_t idle_prio_free = tskIDLE_PRIORITY;


void ktc_start_time_init_free(TickType_t *start_time){
	*start_time = xTaskGetTickCount();
}

void vTimerCallback( TimerHandle_t xTimer ){ 
	int i;
	int tflag;
	struct timer_env* trgt;
	for(i=0; i<10; i++){
		if(timer_env_array[i] != NULL){
			tflag = strcmp( pcTimerGetName( xTimer ), timer_env_array[i]->tname);
			if(tflag == 0){
				trgt = timer_env_array[i];
				break;
			}	
		}
	}
	 xTimerStop(xTimer, 0 );
	longjmp(timer_env_array[i]->envn, 1);
}

TimerHandle_t ktc_timer_init_free(struct timer_env* ptrtenv){
	TimerHandle_t ret;
	static int i = 0;
	struct timer_env* temp;
	ret = xTimerCreate(ptrtenv->tname, 100 ,pdTRUE, ( void * ) 0, vTimerCallback);
	timer_env_array[i] = ptrtenv;
	i++; 
	return ret;
}


long ktc_sdelay_init_free(int intrval, char* unit, TickType_t *start_time, int id){
	TickType_t temp, time_perid, time_now, time_elaps;
	long time_in_ms, ret;
	time_in_ms = convert_to_ms(intrval, unit);
	time_perid = time_in_ms/portTICK_PERIOD_MS;
	time_now = xTaskGetTickCount();
	time_elaps = time_now - (*start_time);
	if(time_elaps < time_perid){
		temp = time_perid + (*start_time);
		vTaskDelayUntil(start_time, time_perid);
	        *start_time = temp;
		ret = 0;
	        return ret;
	}	
	else{
		temp = (time_elaps - time_perid) + (*start_time + time_perid);
		 *start_time = temp
		ret = (time_elaps - time_perid);
	}

}

int ktc_fdelay_start_timer_free(int interval, char* unit,TimerHandle_t  ktctimer, TickType_t start_time){
	TickType_t time_now, time_elsp, time_perid, new_perid;
	time_now = xTaskGetTickCount();
	time_elsp = start_time - time_now;
	time_perid = convert_to_ms(interval, unit);
	new_perid = time_perid - time_elsp;
	if( xTimerIsTimerActive( ktctimer ) != pdFALSE ){
		xTimerDelete( ktctimer, 50 );
    	}
   	else{
		if((xTimerChangePeriod(ktctimer, new_perid, 50 )) == pdPASS ){}
		else{
			printf("Timer Command could not be delivered\n");
		}
	} 
}

long ktc_fdelay_init_free(int interval, char* unit, TickType_t* start_time, TimerHandle_t  ktctimer, int id) {
	TickType_t time_perid, temp;
	time_perid = convert_to_ms(interval, unit);
	temp =  time_perid + (*start_time);
	xTimerStop( ktctimer, 50 );
	vTaskDelayUntil(start_time, time_perid);
	*start_time = temp;
}
