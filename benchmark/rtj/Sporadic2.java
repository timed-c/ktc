/* Periodic thread in Java */

import javax.realtime.*;
import java.util.*;


public class Sporadic {

class Sevent {
	public Sevent(){
	 AsyncEvent event = new AsyncEvent();
	} 
	public AsyncEvent event;
}

static Sevent sevent = null;

class Listener extends AsyncEventHandler {
	public void handleAsyncEvent() {
		System.out.println("Event Occured");
	}
}

class Server implements Runnable {
	Random random = new Random(System.currentTimeMillis());

	public void run() {
	   
	  while(true){
		int gen = random.nextInt(5);
		if(gen > 5){
			RealtimeThread.waitForNextPeriod();
		}
		
		sevent.event.fire();
	 }
	}

}


public void Main() {
	System.out.println("Event Occured");

	public AsyncEvent event = new AsyncEvent(); 
	Listener lstnr = new Listener ();
	sevent.event.addHandler(lstnr);
	/* period: 30ms */
        RelativeTime period = new RelativeTime(3000 /* ms */, 0 /* ns */);

    	/* release parameters for sporadic thread: */
        //SporadicParameters sporadicParameters = new SporadicParameters(period);
        //sporadicParameters.setMitViolationBehavior(SporadicParameters.mitViolationIgnore);
        PeriodicParameters sporadicParameters = new PeriodicParameters(period);

        /* create periodic thread: */
        RealtimeThread realtimeThread = new RealtimeThread(null, sporadicParameters, null, null, null, new Server()) ;

   	/* start periodic thread: */
    	realtimeThread.start();
}

public static void main(String[] args){
	Sporadic s = new Sporadic();
        s.Main();	
}

}

