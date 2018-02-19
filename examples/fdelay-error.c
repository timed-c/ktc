#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>

void computeA(){}

void computeB(){}

int foo(){
  return 1;
}

void main(){
   int x;
    x = foo(); 
    if(x){
       computeA();
       fdelay(10, us);
    }
    else{
        computeB();
        fdelay(50, us);
   }
}
