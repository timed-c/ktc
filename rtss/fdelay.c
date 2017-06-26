
#include "cilktc-free.h"

void main(){
    int ov;
    setPort();
    while(1){
	while(1){}
	ov = fdelay(100, ms);
	togglePort();
    }
}
