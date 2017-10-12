/* Periodic thread in Java */

import javax.realtime.*;

public class Periodic_overrun {

class Task extends RealtimeThread {
	public Task () {

	}

	public void run() {	
		while(true) {	
			for(int i = 0; i < 1000000000; i++) { System.out.println("" +i);}
	 		boolean ok = waitForNextPeriod();	
		}

	}

}


class DeadlineMissHandler extends AsyncEventHandler {
	private Schedulable sched = null;
	public DeadlineMissHandler( Schedulable sched){
		super(new PriorityParameters(PriorityScheduler.instance().getMaxPriority()), null, null, null, null, null);
		this.sched = sched;
	}
	public void handleAsyncEvent() {
		//Handle deadline miss here 
                 System.out.println("Deadline overshoot\n");
		PeriodicParameters rel = new PeriodicParameters(new RelativeTime(50, 0)) ;
		setReleaseParameters(rel);
		if(sched instanceof RealtimeThread)
			((RealtimeThread)sched).schedulePeriodic();
	}
}

public void Main () {
    Task task = new Task ();
    DeadlineMissHandler dmh = new DeadlineMissHandler(task);

    int priority = PriorityScheduler.instance().getMaxPriority();
   
    /* period: 30ms */
    RelativeTime period = new RelativeTime(50 /* ms */, 0 /* ns */);
    RelativeTime deadline = new RelativeTime(50 /* ms */, 0 /* ns */);
  


    /* release parameters for periodic thread: */
    PeriodicParameters periodicParameters = new PeriodicParameters(null,period, null,deadline,null, dmh);
    task.setReleaseParameters(periodicParameters);
    task.setPriority(priority);
    task.start();

}
  public static void main(String[] args)
  {
	Periodic_overrun m = new Periodic_overrun();
	m.Main();
  }
}
