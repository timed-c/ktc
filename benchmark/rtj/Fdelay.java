/* Periodic thread in Java */

import javax.realtime.*;

public class Fdelay {

class Task extends RealtimeThread {
	public Task () {

	}

	public void run() {
		int count = 0;
		long now = System.currentTimeMillis();
		while(true) {
			System.out.println("New Instance 100000000" );
			/*100000000*/
			for(int i = 0; i < 10000000; i++) {System.out.println(i);}
	 		boolean ok = waitForNextPeriod();
			System.out.println(System.currentTimeMillis() - now);
			now = System.currentTimeMillis();
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
		PeriodicParameters rel = new PeriodicParameters(new RelativeTime(50, 0)) ;
		System.out.println("Asyn" );
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
	Fdelay m = new Fdelay();
	m.Main();
  }
}
