import javax.realtime.*;
import classes.*;
public class Firm extends RealtimeThread {
  First obj = new First();
  class TimedOp implements Interruptible {
  public void run(AsynchronouslyInterruptedException ai)
  throws AsynchronouslyInterruptedException {
    obj.sense();
  }                  
  public void interruptAction(
    AsynchronouslyInterruptedException ai) {
    obj.handle_deadline();}
 }
 public void run(){
    RelativeTime intr = new RelativeTime(1, 0);
    Timed timed = new Timed(intr);
    TimedOp interuptible = new TimedOp();	
    while(true){
      timed.doInterruptible(interuptible);
      waitForNextPeriod();
    }
  }
  public static void main(String[] args){
    Firm fd = new Firm();
    RelativeTime period = new RelativeTime(30, 0);
    PeriodicParameters periodicParameters =
    new PeriodicParameters(null,period, null,null,null, null);
    fd.setReleaseParameters(periodicParameters);
    fd.start();
  }
}

