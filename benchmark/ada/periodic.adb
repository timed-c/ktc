with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;use Ada.Text_IO;
with Timers_Test;

procedure Periodic is
	Interval : Time_Span := Milliseconds(30);
	Next : Time;
begin
	Next := Clock;
	loop 
		Put_Line("Delay 30 ms");
		Next := Clock + Interval;
		delay until Next;
	end loop;
end Periodic;

