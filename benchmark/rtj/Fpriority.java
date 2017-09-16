import javax.realtime.*;

public class Fpriority {
  static public void main(String [] args){
    Scheduler scheduler = FindScheduler.findScheduler("EDFScheduler");
    if(scheduler == null){
      System.out.println("No least laxity scheduler was found");
    } else {
      RealtimeThread rtt = new RealtimeThread(
          null,					    //	Default scheduling Parameters
          new PeriodicParameters(
              null,				    // Begin running at start()
              new RelativeTime(250, 0),	            //	Period is 1/4 sec
              new RelativeTime(25, 0),	            //	Cost is 1/40 sec
                  new RelativeTime(200, 0),	    //	Deadline is 1/5 sec
              null,				    //	No overrun handler
              null),				    //	No miss handler
              null,				    //	Default memory parameters
              null,				    //	Default memory area
              null,				    //	Default processing group
              new Runnable (){		            //	Logic
            public void run() {
              System.out.println("Running least laxity");
            }
          });
      rtt.setScheduler(scheduler);
      rtt.start();
      try{
        rtt.join();
      } catch(Exception e) {}
    }
  }
}
