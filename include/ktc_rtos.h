#include "include_FREERTOS/FreeRTOS.h"
#include "include_FREERTOS/task.h"

TickType_t *start_time;
#pragma cilnoremove("start_time")
#pragma cilnoremove("vTaskDelayUntil")
#pragma cilnoremove("vPortEnterCritical")
#pragma cilnoremove("vPortExitCritical")
#pragma cilnoremove("portENTER_CRITICAL")
#pragma cilnoremove("portEXIT_CRITICAL")
