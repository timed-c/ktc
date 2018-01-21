 /*H**********************************************************************
* FILENAME :        trxvu_uplink_mod.ino          
*
* DESCRIPTION :
*       Arduino sketch for uplink radio simulator.
*
* AUTHOR :    Johan Enberg 
*
* MODIFIED :  Saranya Natarajam
*
*
*H*/

extern "C" {
  #include "debug2.h"
  #include "I2Cslave.h"
  #include "SlaveDefinitions.h"
  #include "parser.h"
  #include "SIM.h"
}


// Buffer variabels
uint8_t frameBuffer[FRAME_BUFFER_SIZE][MAX_FRAME_SIZE];
int frameSize[FRAME_BUFFER_SIZE];
int noFramePer[FRAME_BUFFER_SIZE];
uint8_t head = 0;
uint8_t tail = 0;
uint8_t noOfFrames = 0;
uint8_t count = 0;

// KISS receiving variabels
uint8_t receiveBuffer[MAX_KISS_FRAME_SIZE];
int receiveBufferIndex = 0;
uint8_t receiveChar;
bool receiveFrame = false;


void setup() {
  Serial.begin(9600);
  SerialUSB.begin(9600);
  debugSetup();

  I2C_setup(receiveCallback, transmitBeginCallback, transmitCompletedCallback);
   Serial.print("SIM");
}




void loop() {

  while (SerialUSB.available() > 0) {
          receiveChar = SerialUSB.read();
            Serial.print(receiveChar);
          if (receiveChar != ';'){
              receiveBuffer[receiveBufferIndex++] = receiveChar;
            
          }
          else {
              
              if (receiveFrame) {
                 Serial.println("end");
                  receiveFrame = false;
                  if (noOfFrames < FRAME_BUFFER_SIZE ) {
                      /*if(count % 4 == 0){
                      int error = parseReceivedFrame(receiveBuffer, receiveBufferIndex, frameBuffer[head], (frameSize + head));
                      if (error) {
                        receiveBufferIndex = 0;
                        break;
                        }
                        head++;
                        head = head % 40;
                        noOfFrames++;
                      }*/
                      for(int i=0; i<receiveBufferIndex;i++){
                              frameBuffer[head][i] = receiveBuffer[i];
                      }
                       *(frameSize + head) = receiveBufferIndex;
                      head++;
                      head = head % 40;
                      noOfFrames++;
                      receiveBufferIndex = 0;
                      
                  }
                  else {
                      receiveBufferIndex = 0;
                  }
              }
              else{
                  receiveFrame = true;
                  }
              }
          
    }
   
   printDebugs();
}


// Response buffer
uint8_t tcToSendBuffer[MAX_FRAME_SIZE];
uint8_t tcToSendLength;

/* 
 * Called when a message are received from I2C. 
 * In this case a commandcode on 1 byte. generates a response according to the command code
 * and puts the response and length in response buffer
 * @param data Pointer to data received
 * @param dataLength number of bytes received
 */
void receiveCallback (uint8_t *data, uint32_t dataLength) {
  int rem;
   
   //Serial.println(*data);
   //Serial.print("frame len");
   //Serial.println(dataLength);
  if(dataLength == 1) {
    switch(*data) {
        case GET_NO_FRAMES :                  tcToSendBuffer[0] = noOfFrames;
                                              tcToSendLength = 1;
                                              break;
        case GET_FRAME_LENGTH :           
                                              tcToSendBuffer[0] = frameSize[tail];
                                              tcToSendLength = 1;
                                              break;
        case GET_FRAME_FROM_RECEIVER_BUFFER : if(noOfFrames > 0){
                                                  for (int i = 0; i < frameSize[tail]; i++)
                                                   {tcToSendBuffer[i] = frameBuffer[tail][i];}
                                             
                                              tcToSendLength = frameSize[tail];
                                              }
                                              break;
                                             
        case REMOVE_FRAME_FROM_BUFFER :     for(int i =0; i< 1; i++){
                                                if (noOfFrames > 0) {
                                                    noOfFrames--;
                                                }
                                                frameSize[tail] = 0;
                                                tail++;
                                                tail = tail % 40;
                                               }
                                               break;
        default :                             break;
      } 
    } 
}


// when OBC does a transmit request
// decied what data to send to OBC
// MSP packet. instert data and packet size. (no bigger than buff size)
void transmitBeginCallback () {
    currentPacket.MSP_packet = tcToSendBuffer;
    currentPacket.packetSize = tcToSendLength;
     //Serial.println("transmitBeginCallback " );
  }


// callback when transmit is done to OBC
void transmitCompletedCallback() {
     // Serial.println("transmitCompletedCallback " );
  
}
