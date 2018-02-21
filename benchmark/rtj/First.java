import javax.realtime.*;
public class First {
   public void sense() {
	for(int i =0; i<100000000; i++){}
      
   }
   public void handle_deadline(){
  	System.out.println("Deadline overshot");
   }
}
