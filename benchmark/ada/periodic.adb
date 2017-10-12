with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;use Ada.Text_IO;
with Ada.Dispatching; use Ada.Dispatching;

procedure Periodic is
   Interval : Time_Span := Milliseconds(30);
   Next : Time;
begin
   Next := Clock + Interval;
   loop 
     Put_Line("Delay 30 ms" );
     delay until Next;
      Next := Next + Interval;
   end loop;
end Periodic;

