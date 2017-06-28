#include<stdio.h>
#include<cilktc.h>
#include<stdlib.h>
#include<math.h>
#define SEED 35791246
#define sec 0 


void main() {
	int i, count=0, niter=0;
	double x,y,z;
	double pi;
	srand(SEED);
	count = 0;
	pi = 3.14;
	sdelay(0, "ms");
	while(i < 10000000){
	       x = (double)rand()/RAND_MAX;
	       y = (double)rand()/RAND_MAX;
	       z = (x*x) + (y*y);
	       critical{
	       	    if(z<=1) count++;
		    niter++;
		}
		i++;
	}
	fdelay(60, "ms");
	pi = (double)count/niter*4;
	printf("Value of pi is %g for %d tries", pi, niter);
}
