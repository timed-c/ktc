import javax.realtime.*;
public class Firm extends RealtimeThread {
  First obj = new First();
  class TimedOp implements Interruptible {
  public void run(AsynchronouslyInterruptedException ai)
  throws AsynchronouslyInterruptedException {
    obj.sense();//read from sensor 
  }                  
  public void interruptAction(
    AsynchronouslyInterruptedException ai) { 
 }}
 public void run(){
    RelativeTime intr = new RelativeTime(30, 0);
    Timed timed = new Timed(intr);
    TimedOp interuptible = new TimedOp();	
    while(true){
      timed.doInterruptible(interuptible);
      waitForNextPeriod();
    }
  }
  public static void main(String[] args){
    Firm fd = new Firm();
    RelativeTime period = new RelativeTime(30,0);
    PeriodicParameters periodicParameters =
    new PeriodicParameters(null,period, null,null,null, null);
    fd.setReleaseParameters(periodicParameters);
    fd.start();
  }
}

