#include <stdlib.h>
#include <cilktc.h>
#include "mist.h"



heap_t* prioq;
struct_tcmist fifochannel tcChan;


task adcs(){
  spolicy(FIFO_RM);
  mistTimeInit();
  while(1){
    mistComputeADCS();
    sdelay(1, sec);
  }
}

task collectHK(){
  spolicy(FIFO_RM);
  while(1){
    mistHK();
    sdelay(30, sec);
  }
}

task retrieve(){
  unsigned char rxFrameB[200] = {0};
  SimulatorTrxvuRxFrame rxFrameCmd = {0, 0, rxFrameB};
  struct_tcmist tc;
  spolicy(FIFO_RM);
  while(1){
    printmistretrieve();
    printTrace();	
    simulatorTrxvu_rcGetCommandFrame(deviceHandle, &rxFrameCmd);
    if(rxFrameCmd.rx_length > 0){
	rxFrameCmd.absoluteTime= decodeTCMISTGetTime(rxFrameCmd.rx_framedata);
	tc.aTime = rxFrameCmd.absoluteTime;
	tc.rx_length = rxFrameCmd.rx_length;
     }
     else{
	tc.aTime = 0;
	tc.rx_length = 0;
     }
     if(tc.rx_length != 0){
	cwrite(tcChan, tc);
     }
     sdelay(3, sec);
  }
}

task executeTC(){
  struct_tcmist tc;
  struct_tcmist* tctop = NULL;
  long t = 0, tctime = 0;
  spolicy(FIFO_RM);
   aperiodic(4, sec);	
   while(1){
     printmistexecute();
     printTrace();		
    if(nelem(tcChan) != 0 
	 || prioq->len == 0 ){
	cread(tcChan, tc);
	push(prioq, &tc);
    }
    tctop = top(prioq);
    tctime = tctop->aTime;
    t = gettime(sec);
    sdelay(tctime - t, sec);
    pop(prioq, &tc);
    executeTCAux(tc);
 }
}


void main(){
   struct_tcmist tcData;
   cinit(tcChan, tcData);
   prioq= (heap_t *)calloc(1, sizeof (heap_t));
   mistinitTime();
   misti2cStart();
   adcs();
   retrieve();
   executeTC();
   collectHK();
   WDT_start();
}

