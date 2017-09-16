import java.lang.reflect.*;
import javax.realtime.*;

public class FindScheduler {
  public static Scheduler findScheduler(String policy){
    String key = "javax.realtime.scheduler." + policy;
    String className = System.getProperty(key);

    if(className == null)
      //  No system property for this scheduling policy
      return null;

    Class schedClass;
    try {
      schedClass = Class.forName(className);
      if(schedClass == null)  
        //  The scheduler class was not found
        return null;
      else {
        //  Get a reference for the scheduler's
        //  instance() method. (with no parameters)
        Method instance = schedClass.getMethod("instance", null);
        //  instance() is static, so it doesn't need
        //  an object parameter, and it takes no args,
        //  so the parameters for instance.invoke() are
        //  null, null.
        //  The instance method in Scheduler will
        //  return a reference to a singleton instance
        //  of that class.
        return (Scheduler)instance.invoke(null, null);
      }
    } catch (ClassNotFoundException nF){
      //  Thrown by forName()
      return null;
    } catch (NoSuchMethodException nS) {
      //  Thrown by getMethod.
      //  This is a sign of a mal-formed Scheduler class
      return null;
    } catch (SecurityException security) {
      //  This is a runtime exception.
      //  It is thrown by the security manager, perhaps
      //  when it checked for our authority to load a 
      //  class.
      throw security;
    } catch (IllegalAccessException access){
      //  Thrown by forName method if the scheduler
      //  class is not public, or by invoke() if the
      //  method is inaccessible (which it should be.)
      return null;
    } catch (IllegalArgumentException arg) {
      //  Since we don't pass arguments, and the
      //  instance() method does not expect arguments
      //  we should never get here.
      return null;
    } catch (InvocationTargetException target) {
      //  Some exception was thrown by instance().
      //  That exception is wrapped by target.
      //  instance() doesn't throw any checked exceptions
      //  so we should never get here.
      return null;
    }
  }
}
