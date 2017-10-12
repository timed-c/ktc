pragma Task_Dispatching_Policy(FIFO_Within_Priorities);

with Ada.Text_Io; use Ada.Text_Io;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;


procedure Firm is 
  task type Periodic_Firm is
      pragma Priority(5);
  end Periodic_Firm;
  task body Periodic_Firm is
     Next : Time;
     Interval : Time_Span := Milliseconds(30); 
  begin
     Next := Clock + Interval;
     loop
      select
        delay until Next; 
        Put_Line ("Deadline Overshot");
      then abort
      	for I in Integer range 1 .. 1000000000 loop
	   Put_Line (Integer'Image(I));
      	end loop;
      end select;
      delay until Next;
      Next := Next + Interval;
     end loop;
  end Periodic_Firm;
  ftask : Periodic_Firm;
begin 
  Put_Line("Firm_Task!");
end Firm;

