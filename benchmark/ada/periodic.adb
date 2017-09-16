with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;use Ada.Text_IO;

procedure Periodic is
	Interval : Time_Span := Milliseconds(1000);
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

