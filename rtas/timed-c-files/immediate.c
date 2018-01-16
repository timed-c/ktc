#include <stdlib.h>
#include <cilktc.h>
#include "mist.h"


#define INFINITY 2147483647
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
 struct_tcmist tc, tcnext;
 struct_tcmist* tctop = NULL;
 long t = 0, tctime = 0;
 spolicy(FIFO_RM);
 aperiodic(4000, ms);	
 while(1){
   printmistexecute();
   printTrace();
   tctop = top(prioq);
   if(tctop == NULL)
      tctime = INFINITY;
   else
      tctime = tctop->aTime;
   tcnext.rx_length = 0;
   t = gettime(sec);
   cread(tcChan, tcnext);
   skipdelay;
   fdelay(tctime-t, sec);
   if(tcnext.rx_length != 0){
     push(prioq, &tcnext);
   }
   tctop = top(prioq);
   t = gettime(sec);
   if(t >= tctop->aTime){
	pop(prioq, &tc);
	executeTCAux(tc);
   }
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

