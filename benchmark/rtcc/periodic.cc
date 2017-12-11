/*psuedo code implementing periodic loop with soft deadline in Real Time Concurrent C
NOTE : This construct for soft delay is discussed as a future work in the RTCC paper */

void main(){
 while(1){
	every (30) (maxint)
		printf("delay 30 ms");
 }
}
