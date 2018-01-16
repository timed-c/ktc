#include<stdio.h>
#include<cilktc.h>
/*Timing point with integer resolution*/

task foo(){
	printf("Starting foo\n");
	while(1){
	 sdelay(50, ms);
	 printf("Release foo\n");
	}
}

task bar(){
	printf("Starting bar\n");
	while(1){
	 sdelay(100, ms);
	 printf("Release bar\n");	 
	}
}

void main(){
	int a = 100;
	int b;
	printf("Starting main\n");
	foo();
	bar();

}

