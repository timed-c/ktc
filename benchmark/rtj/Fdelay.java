/* Periodic thread in Java */

import javax.realtime.*;

public class Fdelay {

class Task extends RealtimeThread {
	public Task () {

	}

	public void run() {
		while(true) {
			System.out.println("New Instance" );
			for(int i = 0; i < 100000000; i++) {}
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
		PeriodicParameters rel = new PeriodicParameters(new RelativeTime(30, 0)) ;
		System.out.println("Asyn" );
		setReleaseParameters(rel);
		if(sched instanceof RealtimeThread)
			((RealtimeThread)sched).schedulePeriodic();
	}
}

public void Main () {
    Task task = new Task ();
    DeadlineMissHandler dmh = new DeadlineMissHandler(task);


    /* period: 30ms */
    RelativeTime period = new RelativeTime(100 /* ms */, 0 /* ns */);

    /* release parameters for periodic thread: */
    PeriodicParameters periodicParameters = new PeriodicParameters(null,period, null,null,null, dmh);
    task.setReleaseParameters(periodicParameters);
    task.start();

}
  public static void main(String[] args)
  {
	Fdelay m = new Fdelay();
	m.Main();
  }
}
