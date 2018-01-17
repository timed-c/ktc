#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include <linux/sched.h>
#include <linux/types.h>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <fcntl.h>
#include <setjmp.h>



#include "ccsds.h"
#include "trxvu_uplink_sim.h"
#include "mist.h"

#define I2C_BIT_RATE 400000
#define I2C_TIMEOUT_RATE 100000


int deviceHandle;
sigjmp_buf myenv;
long strttme; 
FILE *fp;


int mistinitTime(){
	struct timeval tv;
	gettimeofday(&tv, NULL);
	strttme = tv.tv_sec;
	//printf("\nTC ret %d at %d\n", strttme);
	fp = fopen("log.txt", "w+");
	
}

void mistTimeInit(){}

void pushaux (heap_t *h, struct_tcmist rxCompleteCmd) {
    if (h->len + 1 >= h->size) {
        h->size = h->size ? h->size * 2 : 4;
        h->nodes = (struct_tcmist *)realloc(h->nodes, h->size * sizeof (struct_tcmist));
    }
    int i = h->len + 1;
    int j = i / 2;
    while (i > 1 && h->nodes[j].aTime > rxCompleteCmd.aTime) {
        h->nodes[i] = h->nodes[j];
        i = j;
        j = j / 2;
    }
    h->nodes[i].aTime = rxCompleteCmd.aTime;
    h->nodes[i].rx_length = rxCompleteCmd.rx_length;
  /*  for(j =0; j <rxCompleteCmd.rx_length; j++){
    	 h->nodes[i].rxFrameBuffer[j] = rxCompleteCmd.rxFrameBuffer[j];
    }*/
    h->len++;
}

void push(heap_t *h, struct_tcmist *rxCompleteCmd) {
	pushaux(h, *rxCompleteCmd);
}
void pop(heap_t *h,  struct_tcmist* rxCompleteCmd) {
    int i, j, k, inc;
    if (!h->len) {
	printf("prioq empty\n");
	rxCompleteCmd = NULL;
	return;
    }
    rxCompleteCmd->aTime =  h->nodes[1].aTime;
    rxCompleteCmd->rx_length = h->nodes[1].rx_length;
  /*  for(inc =0; inc <  h->nodes[1].rx_length; inc++){
          rxCompleteCmd->rxFrameBuffer[inc] =  h->nodes[1].rxFrameBuffer[inc];
    }*/
    h->nodes[1] = h->nodes[h->len];
    h->len--;
    i = 1;
    while (1) {
        k = i;
        j = 2 * i;
        if (j <= h->len && h->nodes[j].aTime < h->nodes[k].aTime) {
            k = j;
        }
        if (j + 1 <= h->len && h->nodes[j + 1].aTime < h->nodes[k].aTime) {
            k = j + 1;
        }
        if (k == i) {
            break;
        }
        h->nodes[i] = h->nodes[k];
        i = k;
    }
    h->nodes[i] = h->nodes[h->len + 1];

}

struct_tcmist* top(heap_t *h){
	if (!h->len) {
	 // return 0;
		return NULL;
    	}
	return (&(h->nodes[1]));
}


void executeTCAux(struct_tcmist timedCmd){
	struct timeval tv;
    	gettimeofday(&tv, NULL);	
	printf("\nEXE %d executed at %d\n", timedCmd.aTime-strttme, tv.tv_sec-strttme);
	fprintf(fp, "\nEXE : TC with time tag %d is executed at %d\n", timedCmd.aTime-strttme, tv.tv_sec-strttme);
}

void printTrace(){
	/*struct timeval tv;
    	gettimeofday(&tv, NULL);	
	printf("%d \n", tv.tv_sec-strttme);
	fprintf(fp, "%d \n", tv.tv_sec-strttme);*/
}

void printmistexecute(){
	struct timeval tv;
    	gettimeofday(&tv, NULL);
	printf("mistExecute :%d \n", tv.tv_sec-strttme);
	fprintf(fp, "mistExecute :%d \n", tv.tv_sec-strttme);

}

void printmistretrieve(){
	struct timeval tv;
    	gettimeofday(&tv, NULL);
	printf("mistRetrieve :%d \n", tv.tv_sec-strttme);
	fprintf(fp, "mistRetrieve :%d \n", tv.tv_sec-strttme);

}

int decodeTCMISTGetTime(uint8_t* packet){
	struct timeval tv;
	static int count = 0;
	if(PACKET_SERVICE_TYPE(packet) == 9){// || PACKET_SERVICE_SUBTYPE(packet) == 9){
		//return((packet[11]*256*256*256 + packet[12]*256*256 + packet[13]*256 + packet[14] + packet[15]/256) + 8215933);
		gettimeofday(&tv, NULL);
		count++;	
		if(count == 1){
			printf("\nTC ret %d at %d\n", tv.tv_sec- strttme, strttme + 40 - strttme);
			fprintf(fp, "\nTC ret %d at %d\n", tv.tv_sec- strttme, strttme + 40 - strttme);
			return(strttme + 40);
		}
		if(count == 2){
			printf("\nTC ret %d at %d\n", tv.tv_sec- strttme, strttme + 50 - strttme);
			fprintf(fp, "\nTC ret %d at %d\n", tv.tv_sec- strttme, strttme + 50 - strttme);
			return(strttme + 50);
		}
		if(count == 3){
			printf("\nTC ret %d at %d\n", tv.tv_sec- strttme, strttme + 90 - strttme);
			fprintf(fp, "\nTC ret %d at %d\n", tv.tv_sec- strttme, strttme + 90 - strttme);
			return(strttme+ 90);
		}
		if(count == 4){
			printf("\nTC ret %d at %d\n", tv.tv_sec- strttme, strttme + 110 - strttme);
			fprintf(fp, "\nTC ret %d at %d\n", tv.tv_sec- strttme, strttme + 110 - strttme);
			return(strttme + 110);
		}
		if(count == 5){
			printf("\nTC ret %d at %d\n", tv.tv_sec- strttme, strttme + 120 - strttme);
			fprintf(fp, "\nTC ret %d at %d\n", tv.tv_sec- strttme, strttme + 120 - strttme);
			return(strttme + 120);
		}
		
		
	}
	else{
		gettimeofday(&tv, NULL);
		printf("\nTC ret %d at %d\n", tv.tv_sec -strttme, tv.tv_sec - strttme);
		fprintf(fp, "\nTC ret %d at %d\n", tv.tv_sec -strttme, tv.tv_sec - strttme);	
		return (tv.tv_sec);
	}
}

int mistComputeADCS(){	
	static int i = 0;
	i ++;
	struct timeval tv;
    	gettimeofday(&tv, NULL);
	printf("mistADCS :%d \n", tv.tv_sec-strttme);
	fprintf(fp, "mistADCS :%d \n", tv.tv_sec-strttme);
	if(i == 150){
		fclose(fp);
		fp = fopen("log-aux.txt", "w+");
	}
}

int mistHK(){
	struct timeval tv;
    	gettimeofday(&tv, NULL);
	printf("mistHK : %d \n", tv.tv_sec-strttme);
	fprintf(fp, "mistHK : %d \n", tv.tv_sec-strttme);
	
	
}

int initTime(){
	struct timeval tv;
	gettimeofday(&tv, NULL);
	strttme = tv.tv_sec;
	printf("\nTC ret %d at %d\n", strttme);
	fprintf(fp,"\nTC retrieved at %d has time tag %d\n", strttme);
	
}


int i2cStart(int* dHand){
	int deviceI2CAddress = 0x08;
		int deviceHandle;
	// open device on /dev/i2c-0
	if ((deviceHandle = open("/dev/i2c-1", O_RDWR)) < 0) {
		printf("Error: Couldn't open device! %d\n", deviceHandle);
	}


	if (ioctl(deviceHandle, I2C_SLAVE, deviceI2CAddress) < 0) {
		printf("Error: Couldn't find device on address!\n");
	}  

	*dHand = deviceHandle;
	return 1;


}



void misti2cStart(){
	i2cStart(&deviceHandle);
}

void WDT_start(){}

