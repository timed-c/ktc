#include<stdio.h>
#include<cilktc.h>

void sensor(){

	int num;	
	struct timespec ts;
	ts.tv_sec = 1;
        ts.tv_nsec = 5000000 ;
	srand(time(NULL));
	num = rand();
	if(num % 2 == 0){
		nanosleep(&ts, NULL);
	}
}
void controller(){
	setjmp(env);

}
void actuator(){}


int main(){

	struct timespec base_time, print_time;

	int count = 0;
	sdelay(0);
	while(1){
		/*test*/
		count ++;
	if(count == 1){
			clock_gettime(CLOCK_REALTIME, &print_time);
			base_time = print_time;		
		
		}
		print_time = diff_timespec(print_time, base_time);
		printf("Start Instance %d at %d secs and %lu ns\n", count, print_time.tv_sec, print_time.tv_nsec);
		/*test*/
		sensor();
		controller();
		actuator();
		if(sdelay(1)){
			printf("Deadline Miss\n");
	 }
		(void) clock_gettime(CLOCK_REALTIME, &print_time);	//testing
	}
	return 0;
}
