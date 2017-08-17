/* Periodic thread in Java */

import javax.realtime.*;
import java.util.*;


public class Sporadic {


class Listener extends AsyncEventHandler {
	public Listener(){}
	public void handleAsyncEvent() {
		System.out.println("Event Occured");
	}
}


public void Main() {	
        Random random = new Random(System.currentTimeMillis());
	AsyncEvent event = new AsyncEvent(); 
	Listener lstnr = new Listener ();
	event.addHandler(lstnr);
	/* period: 30ms */
        RelativeTime period = new RelativeTime(3000 /* ms */, 0 /* ns */);

    	/* release parameters for sporadic thread: */
        SporadicParameters sporadicParameters = new SporadicParameters(period);
        sporadicParameters.setMitViolationBehavior(SporadicParameters.mitViolationExcept);
	sporadicParameters.setMinimumInterarrival(period);
      
        /* create periodic thread: */
        RealtimeThread realtimeThread = new RealtimeThread(null, sporadicParameters, null, null, null, null){	
	public void run() {	   
	  while(true){
		int gen = random.nextInt(5);
		if(gen > 5){
			waitForNextPeriod();
		}
		event.fire();
	 }
	}};

   	/* start periodic thread: */
    	realtimeThread.start();
}

public static void main(String[] args){
	Sporadic s = new Sporadic();
        s.Main();	
}

}

