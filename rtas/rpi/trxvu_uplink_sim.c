#include "trxvu_uplink_sim.h"
#include <stdint.h>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>


uint8_t commandToRadio;

void printError( int error , int len);
void simulatorTrxvuRequestNextFrameLength(int index, uint8_t* length);


int simulatorTrxvu_rcGetFrameCount (int index, unsigned short *frameCount){
  commandToRadio = SEND_COUNT_TC;
  printError(write(index, &commandToRadio, 1), 1);
  printError(read(index, (uint8_t*) frameCount, 1), 1);
  //printError(I2C_write(index, &commandToRadio, 1));
  //printError(I2C_read(index, (uint8_t*) frameCount, 1));
  return 0;
}

int simulatorTrxvu_removeFrame (int index){


  printf("remove frame\n", index);
  commandToRadio = SEND_REMOVE_TC;
   printError(write(index,  &commandToRadio, 1), 1);
  //printError(I2C_write(index, &commandToRadio, 1));
  return 0;
}



uint8_t fromI2C[MAX_SIZE_RXFRAME] = {0};
int simulatorTrxvu_rcGetCommandFrame (int index, SimulatorTrxvuRxFrame* rx_frame){
  uint8_t lengthToRead = 0;
  simulatorTrxvuRequestNextFrameLength(index, &lengthToRead);
  rx_frame->rx_length = (unsigned short) lengthToRead;
  if (lengthToRead == 0) {
	 printf("No TC\n");
    return 0;
}
  
 
  commandToRadio = SEND_NEXT_TC;
   printError(write(index, &commandToRadio, 1), 1);
   printError(read(index, fromI2C, lengthToRead), lengthToRead);
  //printError(I2C_write(index, &commandToRadio, 1));
  //printError(I2C_read(index, fromI2C, lengthToRead));
  printf("reading from i2c: %d end\n" , lengthToRead);
  int i;
  for (i = 0; i < lengthToRead; i++) {
	  printf("%02d ",  fromI2C[i]);
	  rx_frame->rx_framedata[i] = fromI2C[i];
  }
  commandToRadio = SEND_REMOVE_TC;
  printError(write(index, &commandToRadio, 1), 1);
  //printError(I2C_write(index, &commandToRadio, 1));
  return 0;
}

void simulatorTrxvuRequestNextFrameLength(int index, uint8_t* length) {
  int err;
  commandToRadio = SEND_NEXT_TC_LENGTH;
  err = write(index, &commandToRadio, 1);
  printError(err, 1);
 
  printError(read(index, length, 1), 1);

 //printError(I2C_write(index, &commandToRadio, 1));
 //printError(I2C_read(index, length, 1));
}

void printError (int error, int len) {
  if (error != len) {
	  printf("print error %d %d \n", error, len);
  }
}

