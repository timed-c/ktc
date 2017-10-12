with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;use Ada.Text_IO;
with Ada.Dispatching.EDF; use Ada.Dispatching.EDF;

procedure Edf is
	Interval : Time_Span := Milliseconds(1000);
	Next : Time;
begin
	Next := Clock;
	Set_Deadline(Clock+Interval);
	for Iter in 0 .. 50 loop
			Put(Integer'Image(Iter));	
			Put_Line(":Delay 30 ms" );
			Next := Next + Interval;
			Delay_Until_And_Set_Deadline(Next, Interval);
	end loop;
end Edf;

