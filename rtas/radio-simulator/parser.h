#ifndef _PARSER_H
#define _PARSER_H


#include <stdint.h>

// NOTE! 
// If telecommand AX.25 info header is not used, TC_START_INDEX = 17, MINIMUM_KISS_FRAME_SIZE = 19
#define TC_START_INDEX 18
#define MINIMUM_KISS_FRAME_SIZE 20

// KISS Frame Markers
#define KISS_FEND 0xC0
#define KISS_FESC 0xDB
#define KISS_TFEND 0xDC
#define KISS_TFESC 0xDD


int parseReceivedFrame(uint8_t* data, int dataLength, uint8_t* tcBuffer, int* tcLength);


#endif
