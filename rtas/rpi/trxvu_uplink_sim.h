#ifndef _TRXVU_UPLINK_SIM_H
#define _TRXVU_UPLINK_SIM_H

#define TRXVU_SIM_UPLINK_ADRESS 8
#define MAX_SIZE_RXFRAME 200

#define SEND_COUNT_TC 0x21 // GET_NO_FRAMES
#define SEND_NEXT_TC_LENGTH 0x23 //GET_FRAME_LENGTH
#define SEND_NEXT_TC 0x22  //GET_FRAME_FROM_RECIEVE_BUFFER
#define SEND_REMOVE_TC 0x24 //REMOVE+FRAME_FROM_BUFFER

#include <stdlib.h>
#include <stdint.h>


typedef struct _simulator_trxvu_rx_frame{
    unsigned short rx_length;
    long absoluteTime;
    uint8_t* rx_framedata;
}SimulatorTrxvuRxFrame;


int simulatorTrxvu_rcGetFrameCount (int index, unsigned short *frameCount);
int simulatorTrxvu_rcGetCommandFrame (int index, SimulatorTrxvuRxFrame* rx_frame);


#endif
