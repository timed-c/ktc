/* Periodic thread in Java */

import javax.realtime.*;

public class Firm extends RealtimeThread {

	class TimedOp implements Interruptible {
		public void run(AsynchronouslyInterruptedException aie)
		throws AsynchronouslyInterruptedException {
		for(int i =0; i<1000000000; i++){System.out.println(i);}
		System.out.println("Completed");
		}
	public void interruptAction(AsynchronouslyInterruptedException aie) {
		System.out.println("Deadline overshot");
		}

	}
	public void run(){
		RelativeTime intr = new RelativeTime(30, 0);
		Timed timed = new Timed(intr);
		TimedOp interuptible = new TimedOp();
		long now;
		
		while(true){
		  //now = System.currentTimeMillis();
		  timed.doInterruptible(interuptible);
		  waitForNextPeriod();
		  //System.out.print("Time Elapsed: ");
		  //System.out.println(System.currentTimeMillis() - now);
		}
	}
	
	public static void main(String[] args) {
		Firm fd = new Firm();
		RelativeTime period = new RelativeTime(30, 0);
		PeriodicParameters periodicParameters =
			 new PeriodicParameters(null,period, null,null,null, null);
		fd.setReleaseParameters(periodicParameters);
		fd.start();
	}
}




