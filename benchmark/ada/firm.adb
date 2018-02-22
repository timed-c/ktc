pragma Task_Dispatching_Policy(FIFO_Within_Priorities);

with Ada.Text_Io; use Ada.Text_Io;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Example1; use Example1;

procedure Firm is 
  task type Periodic_Firm is
      pragma Priority(5);
  end Periodic_Firm;
  task body Periodic_Firm is
     Next : Time;
     Interval : Time_Span := Milliseconds(1);  
  begin
     Next := Clock + Interval;
     loop
      select
        delay until Next;
	Put("-");
      then abort
        Sense;	
      end select;
      delay until Next;
      Next := Next + Interval;
     end loop;
  end Periodic_Firm;
  ftask : Periodic_Firm;
begin 
  Put_Line("Firm_Task!");
end Firm;

