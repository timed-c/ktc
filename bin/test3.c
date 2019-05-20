/*tasks with periodic loop*/
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <cilktc.h>

void qsort_large();
void qsort_small();
void mdeg2rad(int k);
void mrad2deg(int k);
void mSolveCubic(int k);
void musqrt(int k);

FILE dfile;

task tsk_foo(){
    stp(0, infty, ms);
    while(1){
        sdelay(30, ms);

    }
}


task tsk_bar(){
    stp(0, infty, ms);
    while(1){
        sdelay(20, ms);

    }

}

task tsk_boo(){
    stp(0, infty, ms);
    while(1){
        sdelay(10, ms);
    }
}




int main(int argc, char* argv[]){
    long unsigned int targ = 10;
    tsk_foo();
    tsk_bar();
    tsk_boo();
    printf("main--end\n");
}
