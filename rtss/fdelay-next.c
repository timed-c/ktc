#include<stdio.h>
#include<cilktc.h>

void main(){
    int ov;
    setPort();
    sdelay(0, "ms");
    while(1){
	compute();
	next;
	ov = fdelay(500, "ms");
	togglePort();
    }
}
