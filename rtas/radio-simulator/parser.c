#include "parser.h"
#include <stdlib.h>
#include <stdint.h>
#include "debug2.h"

/* 
 *  Restores KISS special characters in KISS frame. 
 *  @param data pointer to KISS frame
 *  @param dataLength Pointer to KISS frame length
 */
void parseKiss(uint8_t* data, int* dataLength) {

  int index = 0;
  for (int i = 0; i < *dataLength; i++) {
    if (data[i] == KISS_FESC) {
       switch(data[i + 1]) {
          case(KISS_TFEND) : data[index++] = KISS_FEND;
                             i++;
                             break;
          case(KISS_TFESC) : data[index++] = KISS_FESC;
                             i++;
                             break;
          default          : data[index++] = data[i];
       }
    }
    else {
        data[index++] = data[i];
    }
  }
  *dataLength = index;     
}



/*
 * Removes AX25 telecommand header and KISS header from data, extracts the telecommand
 * @param data Reveived KISS frame from where to extract telecommand
 * @param dataLength The total length of the KISS frame 
 * @param tcBuffer Pointer to adress where to write the ectracted telecommand
 * @param tcLength Pointer to adress where to write the lengt of the telecommand
 * @return ErrorCode
 * 0 no Error
 * -1 datalength to small
 * -2 no data in frame, only header
 */

int parseReceivedFrame(uint8_t* data, int dataLength, uint8_t* tcBuffer, int* tcLength) {

  parseKiss(data, &dataLength);

  if (dataLength < MINIMUM_KISS_FRAME_SIZE)
    return -1;
    
  int index = 0;
  for (int i = TC_START_INDEX; i < dataLength; i++) {
    tcBuffer[index++] = data[i];
  }

  if (index == 0)
    return -2;

  *tcLength = index;

  return 0;  
}









  
