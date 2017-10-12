/* Periodic thread in Java */

import javax.realtime.*;


public class Sporadic_task {
  public static void main(String[] args)
  {

    /* period: 30ms */
    RelativeTime period = new RelativeTime(3000 /* ms */, 0 /* ns */);

    /* release parameters for periodic thread: */
    SporadicParameters sporadicParameters = new SporadicParameters(period);
    sporadicParameters.setMinimumInterarrival(period);
    sporadicParameters.setMitViolationBehavior(SporadicParameters.mitViolationExcept);
    /* create periodic thread: */
    RealtimeThread realtimeThread = new RealtimeThread(null, sporadicParameters)
    {
      public void run()
      {
        while(true)
        {
          
          System.out.println("Sporadic task released");
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

