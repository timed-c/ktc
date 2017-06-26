#include "cilktc-free.h"

void main(){
    int ov;
    setPort();
    sdelay(0, ms);
    while(1){
	critical{
	  computeA();
	}
	ov = fdelay(150, ms);
	togglePort();
    }
}
