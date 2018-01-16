#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>


typedef struct{
	long aTime;
	int rx_length;
}struct_tcmist;

typedef struct {
    struct_tcmist *nodes;
    int len;
    int size;
} heap_t;


extern int deviceHandle;
#define SEND_COUNT_TC 0x21 // GET_NO_FRAMES
#define SEND_NEXT_TC_LENGTH 0x23 //GET_FRAME_LENGTH
#define SEND_NEXT_TC 0x22  //GET_FRAME_FROM_RECIEVE_BUFFER
#define SEND_REMOVE_TC 0x24 //REMOVE+FRAME_FROM_BUFFER


typedef struct _simulator_trxvu_rx_frame{
    unsigned short rx_length;
    long absoluteTime;
    uint8_t* rx_framedata;
}SimulatorTrxvuRxFrame;


int simulatorTrxvu_rcGetFrameCount (int index, unsigned short *frameCount);
int simulatorTrxvu_rcGetCommandFrame (int index, SimulatorTrxvuRxFrame* rx_frame);




void push (heap_t *h, struct_tcmist* rxCompleteCmd);
void pop(heap_t *h,  struct_tcmist* rxCompleteCmd);
struct_tcmist* top(heap_t *h);
void executeTCAux(struct_tcmist timedCmd);
int decodeTCMISTGetTime(uint8_t* packet);
int mistComputeADCS();
int mistHK();
void mistTimeInit();
int initTime();
int printTrace();
void misti2cStart();

