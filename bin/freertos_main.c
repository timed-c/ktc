#include "cilktc-free.h"
#include "queue.h"
#include "partest.h"
/* Priorities at which the tasks are created. */
#define mainQUEUE_RECEIVE_TASK_PRIORITY		( tskIDLE_PRIORITY + 2 )
#define	mainQUEUE_SEND_TASK_PRIORITY		( tskIDLE_PRIORITY + 1 )

/* The rate at which data is sent to the queue.  The 200ms value is converted
to ticks using the portTICK_PERIOD_MS constant. */
#define mainQUEUE_SEND_FREQUENCY_MS			( 200 / portTICK_PERIOD_MS )

/* The number of items the queue can hold.  This is 1 as the receive task
will remove items as they are added, meaning the send task should always find
the queue empty. */
#define mainQUEUE_LENGTH					( 1 )

/* Values passed to the two tasks just to check the task parameter
functionality. */
#define mainQUEUE_SEND_PARAMETER			( 0x1111UL )
#define mainQUEUE_RECEIVE_PARAMETER			( 0x22UL )

/* The period of the blinky software timer.  The period is specified in ms and
converted to ticks using the portTICK_PERIOD_MS constant. */
#define mainBLINKY_TIMER_PERIOD				( 50 / portTICK_PERIOD_MS )

/* The LED used by the communicating tasks and the blinky timer respectively. */
#define mainTASKS_LED						( 0 )
#define mainTIMER_LED						( 1 )

/* Misc. */
#define mainDONT_BLOCK						( 0 )



/* The queue used by both tasks. */
static QueueHandle_t xQueue = NULL;

/*priority varaiable*/
UBaseType_t idle_prio;

task prvQueueSendTask( void *pvParameters ){
TickType_t xNextWakeTime;
const unsigned long ulValueToSend = 100UL;

	/* Check the task parameter is as expected. */
	configASSERT( ( ( unsigned long ) pvParameters ) == mainQUEUE_SEND_PARAMETER );

	/* Initialise xNextWakeTime - this only needs to be done once. */
//	xNextWakeTime = xTaskGetTickCount();
	sdelay(0, "ms");

	for( ;; )
	{
		/* Place this task in the blocked state until it is time to run again.
		The block time is specified in ticks, the constant used converts ticks
		to ms.  While in the Blocked state this task will not consume any CPU
		time. */
	//	vTaskDelayUntil( &xNextWakeTime, mainQUEUE_SEND_FREQUENCY_MS );
		sdelay(0,"ms");
		/* Send to the queue - causing the queue receive task to unblock and
		toggle the LED.  0 is used as the block time so the sending operation
		will not block - it shouldn't need to block as the queue should always
		be empty at this point in the code. */
		xQueueSend( xQueue, &ulValueToSend, 0U );
		
	}
}
/*-----------------------------------------------------------*/

task prvQueueReceiveTask( void *pvParameters )
{
unsigned long ulReceivedValue;

	/* Check the task parameter is as expected. */
	configASSERT( ( ( unsigned long ) pvParameters ) == mainQUEUE_RECEIVE_PARAMETER );

	sdelay(100, "ms");
	vParTestToggleLED( mainTIMER_LED);
	for( ;; )
	{
		/* Wait until something arrives in the queue - this task will block
		indefinitely provided INCLUDE_vTaskSuspend is set to 1 in
		FreeRTOSConfig.h. */
		xQueueReceive( xQueue, &ulReceivedValue, portMAX_DELAY );

		/*  To get here something must have been received from the queue, but
		is it the expected value?  If it is, toggle the LED. */
		if( ulReceivedValue == 100UL )
		{
			vParTestToggleLED( mainTASKS_LED );
			ulReceivedValue = 0U;
		}
		fdelay(200, "ms");
		
		
	}
}

void main_blinky( void )
{

	void* funparam;
	/* Create the queue. */
	xQueue = xQueueCreate( mainQUEUE_LENGTH, sizeof( unsigned long ) );

	if( xQueue != NULL )
	{
		funparam = (void*) mainQUEUE_RECEIVE_PARAMETER;
		idle_prio = mainQUEUE_RECEIVE_TASK_PRIORITY;
		prvQueueReceiveTask(funparam);
		funparam = (void*) mainQUEUE_SEND_PARAMETER;
	        idle_prio = mainQUEUE_SEND_TASK_PRIORITY;
		prvQueueSendTask(funparam);
		vTaskStartScheduler();
	}	
	for( ;; );
}




	
		
