/* Pseudo RTCC code implementing periodic lopp with firm deadline */

void main(){
    while(1){
        every (100) 
	    sense();	
  	else 
            handle_deadline();
} 
