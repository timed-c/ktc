#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "cilktc.h"
#include "log.h"
FILE dfile;
void read_sensor_1();
void read_sensor_2();

task foo(void* itime)
{
  while(1){
    read_sensor_1();
    sdelay(5, ms);
    read_sensor_2();
    sdelay(10, ms);
  }
}

task bar(void* itime){
   printf("In bar\n");
}
int main(){
    int a;
	printf("In main\n");
    bar();
}
