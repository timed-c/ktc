#ifndef SIM_H
#define SIM_H

// Commands
#define GET_NO_FRAMES 0x21
#define GET_FRAME_LENGTH 0x23
#define GET_FRAME_FROM_RECEIVER_BUFFER 0x22
#define REMOVE_FRAME_FROM_BUFFER 0x24

// Buffer sizes

#define MAX_FRAME_SIZE 200
#define FRAME_BUFFER_SIZE 40

// Recive buffer
#define MAX_KISS_FRAME_SIZE 230

#endif //SIM_H
