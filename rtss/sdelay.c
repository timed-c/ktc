
#include "cilktc-free.h"


void main(){
    int ov;
    setPort();
    while(1){
      sdelay(30, ms);
      togglePort();
    }
}
