#include "cilktc.h"


task bar(void* b){
	printf("hey");
}

void main(){
	void* b;
	sdelay(0, "ms");
	bar(b);
	fdelay(5, "ms");
}
