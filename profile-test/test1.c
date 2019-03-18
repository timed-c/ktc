/*tasks with periodic loop*/
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "cilktc.h"
#include "log.h"
#include "snipmath.h"

void qsort_large();
void qsort_small();
void mdeg2rad(int k);
void mrad2deg(int k);
void mSolveCubic(int k);
void musqrt(int k);

FILE dfile;
/*
task tsk_foo(){
    int i;
    for(i=0;i<50;i++){
        mrad2deg(50);
        sdelay(300, ms);
    }
}


task tsk_bar(){
    int i;
    for(i=0; i<50;i++){
        basicmath_small();
        sdelay(200, ms);
    }

}
*/

task tsk_far(){
    int i =0;
    sdelay(0, ms);
    while(i < 50){
        critical{
          rad2deg(100);
        }
        fdelay(60, ms);
        i++;
    }
}



int main(){
    long unsigned int targ = 10;
   // tsk_foo();
   // tsk_bar();
    tsk_far();
    printf("main--end\n");
}
