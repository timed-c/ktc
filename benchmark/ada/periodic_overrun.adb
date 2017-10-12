with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;use Ada.Text_IO;


procedure Periodic_overrun is
 Interval : Time_Span := Milliseconds(30);
 Next : Time;
 Now :Time;
begin
 Next := Clock + Interval;
 loop 
   Put_Line("Delay 30 ms");
   for I in Integer range 1 .. 10000 loop
   Put_Line (Integer'Image(I));
   end loop;
   delay until Next;
   Now := Clock;
   if(Now > Next) then
     Put_Line ("Deadline overshoot");
      while Now > Next loop 
	  Next := Next +Interval;
      end loop;
   else
       Next := Next + Interval;
   end if;
  end loop;
end Periodic_overrun;

