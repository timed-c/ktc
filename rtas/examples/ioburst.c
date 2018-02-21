
#include<stdio.h>
#include<cilktc.h>

void do_work(int x){
  int i;
  static int count = 0;
  count ++; 
  //for(i = 0; i< 100000000; i++) {}  
}

int block_io_read(){
  static int count = 0; 
  count++;
  return count;
}

task foo(){
   int x;
   int p;
   while(1){
     x = block_io_read(); 
     handle_input(x);
     sdelay(20, ms);
  }
}

task handle_input(int x){
   printf("START handle_input: %d\n", x);
  int p = x;
  do_work(p);
  sdelay(100, ms);
  printf("END handle input %d\n", p);
}

void main(){
  foo();
}
