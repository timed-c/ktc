/* Periodic thread in Java */

import javax.realtime.PeriodicParameters;
import javax.realtime.RelativeTime;
import javax.realtime.RealtimeThread;

public class Periodic {
  public static void main(String[] args)
  {

    /* period: 30ms */
    RelativeTime period = new RelativeTime(30 /* ms */, 0 /* ns */);

    /* release parameters for periodic thread: */
    PeriodicParameters periodicParameters = new PeriodicParameters(null,period, null,null,null,null);

    /* create periodic thread: */
    RealtimeThread realtimeThread = new RealtimeThread(null, periodicParameters)
    {
      public void run()
      {
        for (int n=1;n<50;n++)
        {
          
          System.out.println("Delay 30 ms :" + n);
	  waitForNextPeriod();
        }
      }
    };

    /* start periodic thread: */
    realtimeThread.start();
  }
}

