with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;use Ada.Text_IO;
with Ada.Dispatching; use Ada.Dispatching;

procedure Periodic is
   Interval : Time_Span := Milliseconds(30);
   Next : Time;
begin
   Next := Clock;
   for Iter in 0 .. 50 loop
     Put(Integer'Image(Iter));	
     Put_Line(":Delay 30 ms" );
     Next := Clock + Interval;
     delay until Next;
   end loop;
end Periodic;

