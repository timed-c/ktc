/*
 * I2Cslave.h
 * 
 * I2C-code for Arduino DUE. 
 * Based on the Arduino standard-lib Wire.h.
 * 
 * Author: Johan Sjöblom
 */

#ifndef I2C_SLAVE_H
#define I2C_SLAVE_H

// Include Atmel CMSIS driver
#include <include/twi.h>

//#include "Stream.h"
#include "variant.h"

 // WIRE_HAS_END means Wire has end()
#define WIRE_HAS_END 1

void I2C_setup(
  void (*receiveCallback)(uint8_t* data, uint32_t dataSize), 
  void (*transmitBeginCallback)(void), 
  void (*transmitCompleteCallback)(void));
void registerDebug(void (*debug)(uint32_t));

typedef struct {
  volatile uint8_t *MSP_packet;
  uint32_t packetSize;
} MSP_packetInfo;
extern MSP_packetInfo currentPacket; //defined in I2Cslave.c
  
#endif

