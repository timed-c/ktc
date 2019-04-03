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


task tsk_1(){
    while(1){
    sdelay(1, ms);
    }
}

task tsk_2(){
    while(1){
    sdelay(2, ms);
    }
}

task tsk_5(){
    while(1){
    sdelay(5, ms);
    }
}

task tsk_10(){
    while(1){
    sdelay(10, ms);
    }
}

task tsk_20(){
    while(1){
    sdelay(20, ms);
    }
}

task tsk_50(){
    while(1){
    sdelay(50, ms);
    }
}

task tsk_100(){
    while(1){
    sdelay(100, ms);
    }
}

task tsk_200(){
    while(1){
    sdelay(200, ms);
    }
}

task tsk_1000(){
    while(1){
    sdelay(1000, ms);
    }
}



int main(){
    long unsigned int targ = 10;
    tsk_1();
    tsk_2();
    tsk_5();
    tsk_10();
    tsk_20();
    tsk_50();
    tsk_100();
    tsk_200();
    tsk_1000();

    printf("main--end\n");
}
