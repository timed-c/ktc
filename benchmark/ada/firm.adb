pragma Task_Dispatching_Policy(FIFO_Within_Priorities);

with Ada.Text_Io; use Ada.Text_Io;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;


procedure Firm is 
  task type Periodic_F is
      pragma Priority(5);
  end Periodic_F;
  task body Periodic_F is
     Now : Time;
     Release_Interval : Time_Span := Milliseconds(30); 
  begin
     Now := Clock;
     loop
      select
        delay until Now + Release_Interval;
        Put_Line ("Deadline overshot"); 
      then abort
      	for I in Integer range 1 .. 1000000000 loop
	   Put_Line (Integer'Image(I));
      	end loop;
      end select;
      delay until Now + Release_Interval;
      Now := Clock;
     end loop;
  end Periodic_F;
  ftask : Periodic_F;
begin 
  Put_Line("Firm_Task!");
end Firm;

