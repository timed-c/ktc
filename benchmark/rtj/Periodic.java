import javax.realtime.PeriodicParameters;
import javax.realtime.RelativeTime;
import javax.realtime.RealtimeThread;

public class Periodic {
 public static void main(String[] args)
 {
   RelativeTime period = new RelativeTime(30 /* ms */, 0 /* ns */);
   PeriodicParameters periodicParameters = new PeriodicParameters(null,period, null,null,null,null);
   RealtimeThread realtimeThread = new RealtimeThread()
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
    realtimeThread.setReleaseParameters(periodicParameters);
    realtimeThread.start();
  }
}

