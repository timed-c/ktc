/*A function implementing an anytime algorithm by using fdelay and critical. Note the function computeAnytime implements a dummy anytime algorithm.  This is done to purely check the timing aspect of the computePath function. However, the function computeAnytime can be used as a template. For an actual implementation of an anytime algorithm please refer to the benchmark section*/

#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>

void computeAnytime(int* b, int* a){
   int i, n;
   time_t t;
   srand((unsigned) time(&t));
   int dly = rand()%10;
   for(i = 0; i < 10000000 * dly; i++) {}
   for(i = 0; i < 100; i++){
	b[i] = a[i];
   }
  printf("anytime\n");
   
}

int initialize(int* a){
    int i;
    for(i = 0; i < 100; i ++){
	a[i] = 0;
    }
}

#include "anytime.compute"

int main(){
  int a[100];
  computePath(a);
  printf("end\n");

}



