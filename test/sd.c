#include<stdio.h>
#include<cilktc.h>

int callme(){
	int x;
	x = 10;
	sdelay(x);
	return 1;
}

int  main(){
/*	int a, b;
	sdelay(1);
	a = 10;
	if(a>b){
	b = 10;
	fdelay(2);	
	}
	else 
	fdelay(3);
	b =11;
	while( a-b > b)
		fdelay(2);
	return 1;
	int a, b, c;
	a = 0;
	c = 10 -a ;
	sdelay(0);
	if(c > 1){
	  sdelay(0);
	  b = callme1();
	}
	fdelay(0);

            */
/*	int a;
	callme(); 
	sdelay(0);
	if(a){
	  a = 1;
	 fdelay(0);
	}
	else
	  sdelay(0);
	fdelay(0);
	return 1;*/
	sdelay(0);
	callme();
	fdelay(0);
}

