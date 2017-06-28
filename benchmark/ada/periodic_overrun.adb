with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;use Ada.Text_IO;
with Timers_Test;

procedure Periodic_overrun is
 Interval : Time_Span := Milliseconds(30);
 Dlay : Time_Span;
 Next : Time;
 Now :Time;
begin
 Next := Clock;
 loop 
   Put_Line("Delay 30 ms");
   Next := Clock + Interval; 
   Now := Clock;
   if Now > Next then
      Put_Line("overshoot");
      Dlay := Interval - (Interval - (Clock - Next));
      delay until Clock + Dlay;
   else
     delay until Next;
   end if;
  end loop;
end Periodic_overrun;

