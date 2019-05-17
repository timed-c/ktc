/*tasks with periodic loop*/
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <cilktc.h>

#define infty 0
//extern int policy =1;
//extern int list_dl[500] ={4};
//extern int list_pr[500] ={4};
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

task tsk_far(){
    stp(0, infty, ms);
    while(1){
        sdelay(10, ms);

    }
}





int main(int argc, char* argv[]){
    tsk_foo();
    tsk_bar();
    tsk_far();
    printf("main--end\n");
}
