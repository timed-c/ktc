with Ada.Text_Io; use Ada.Text_Io;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Ada.Real_Time; use Ada.Real_Time;

procedure Firm is 
	
task type Periodic_F is
end Periodic_F;

task body Periodic_F is
  Now : Time;
  Release_Interval : Time_Span := Milliseconds(30);
  Count : Integer := 0;
begin
  Now := Clock;
  loop
    select
      delay until Now + Release_Interval;
      Put_Line ("Deadline overshot");
    then abort
      if Count mod 3 > 0 then 
      	for I in Integer range 1 .. 1000000000 loop
	  null; 
      	end loop;
      else 
	for I in Integer range 1 .. 1000 loop
	  null; 
      	end loop;
      end if;
    end select;
    Now := Clock;
    Count := Count + 1;
  end loop;
end Periodic_F;

ftask : Periodic_F;

begin 
  Put_Line("Firm_Task!");
end Firm;

