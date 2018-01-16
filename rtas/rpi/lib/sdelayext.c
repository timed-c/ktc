#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include <linux/sched.h>
#include <linux/types.h>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <fcntl.h>
#include <setjmp.h>
#include </home/pi/Desktop/mist-rasp/mist.h>

extern long strttme;


int mistinitTime(){
	struct timeval tv;
	gettimeofday(&tv, NULL);
	strttme = tv.tv_sec;
	printf("\nTC ret %d at %d\n", strttme);
	
}
