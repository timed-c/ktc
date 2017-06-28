package body Generic_Timers is

   use Ada;

   protected Events is
      procedure Handler (Event: in out Real_Time.Timing_Events.Timing_Event);
   end Events;

   protected body Events is
      procedure Handler (Event: in out Real_Time.Timing_Events.Timing_Event) is
      begin
         Action;
         if not One_Shot then
            Start;  -- periodic timer continues
         end if;
      end Handler;
   end Events;

   procedure Start is
      use type Ada.Real_Time.Timing_Events.Timing_Event_Handler;
   begin
      if Real_Time.Timing_Events.Current_Handler (The_Event) = null then
         Real_Time.Timing_Events.Set_Handler (The_Event, For_Duration, Events.Handler'access);
      else
         raise Timer_Error with Timer_Name & " started already";
      end if;
   end Start;

   procedure Stop is
      Success : Boolean := False;
      use type Ada.Real_Time.Timing_Events.Timing_Event_Handler;
   begin
      if Real_Time.Timing_Events.Current_Handler (The_Event) /= null then
         Real_Time.Timing_Events.Cancel_Handler (The_Event, Success);
         if not Success then
            raise Timer_Error with "fails to cancel " & Timer_Name;
         end if;
      end if;
   end Stop;

   procedure Cancel renames Stop;

end Generic_Timers;




