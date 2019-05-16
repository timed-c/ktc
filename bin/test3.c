/*tasks with periodic loop*/
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <cilktc.h>

FILE dfile;

task tsk_foo(){
    int i;
    while(1){
        sdelay(300, ms);
    }
}


task tsk_bar(){

    int i;
    while(1){
        sdelay(200, ms);
    }

}


task tsk_far(){
    int i;
    while(1){
        sdelay(600, ms);
    }
}



int main(int argc, char* argv[]){
    long unsigned int targ = 10;
    tsk_foo();
    tsk_bar();
    tsk_far();
    printf("main--end\n");
}
