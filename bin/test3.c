/*tasks with periodic loop*/
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <cilktc.h>

FILE dfile;

task tsk_foo(){
    int i;
    for(i=0;i<50;i++){
        sdelay(300, ms);
    }
}


task tsk_bar(){

    int i;
    for(i=0; i<50;i++){
        sdelay(200, ms);
    }

}


task tsk_far(){
    int i;
    for(i=0; i<50;i++){
        fdelay(600, ms);
    }
}



int main(){
    long unsigned int targ = 10;
    tsk_foo();
    tsk_bar();
    tsk_far();
    printf("main--end\n");
}
