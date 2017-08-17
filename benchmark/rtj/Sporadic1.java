/* Periodic thread in Java */

import javax.realtime.*;


public class Sporadic1 {
  public static void main(String[] args)
  {

    /* period: 30ms */
    RelativeTime period = new RelativeTime(30 /* ms */, 0 /* ns */);

    /* release parameters for periodic thread: */
    SporadicParameters sporadicParameters = new SporadicParameters(period);
    sporadicParameters.setMinimumInterarrival(period);
    sporadicParameters.setMitViolationBehavior(SporadicParameters.mitViolationExcept);
    /* create periodic thread: */
    RealtimeThread realtimeThread = new RealtimeThread(null, sporadicParameters)
    {
      public void run()
      {
        for (int n=1;n<50;n++)
        {
          
          System.out.println("Delay 30 ms :" + n);
	  try {
              Thread.sleep(30);
            } catch (InterruptedException ie) {
              //  ignore
            }

        }
      }
    };

    /* start periodic thread: */
    realtimeThread.start();
  }
}

