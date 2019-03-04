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

task tsk_foo(){
    int i;
    for(i=0;i<50;i++){
        mrad2deg(50);
        sdelay(30, ms);
    }
}


task tsk_bar(){

    int i;
    for(i=0; i<50;i++){
        basicmath_small();
        sdelay(20, ms);
    }

}


task tsk_far(){
    int i;
    for(i=0; i<50;i++){
         rad2deg(100);
        sdelay(60, ms);
    }
}



int main(){
    long unsigned int targ = 10;
    tsk_foo();
    tsk_bar();
    tsk_far();
    printf("main--end\n");
}
