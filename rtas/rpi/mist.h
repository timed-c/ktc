#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <setjmp.h>
#include "cilktc.h"



typedef struct{
	long aTime;
	int rx_length;
}struct_tcmist;

typedef struct {
    struct_tcmist *nodes;
    int len;
    int size;
} heap_t;


void push (heap_t *h, struct_tcmist* rxCompleteCmd);
void pop(heap_t *h,  struct_tcmist* rxCompleteCmd);
struct_tcmist* top(heap_t *h);
void executeTCAux(struct_tcmist timedCmd);
int decodeTCMISTGetTime(uint8_t* packet);
int mistComputeADCS();
int mistHK();
int i2cStart(int *deviceHandle);
