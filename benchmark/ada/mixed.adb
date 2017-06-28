pragma Priority_Specific_Dispatching(FIFO_Within_Priorities, 10 , 16);
pragma Priority_Specific_Dispatching(Round_Robin_Within_Priorities, 2 , 9);
with Ada.Text_IO;use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Dispatching; use Ada.Dispatching;
with System;  use System;

procedure mixed is
  pragma Priority(System.Priority'Last);

task type Tsk1 is 
  pragma Priority(15); 
end Tsk1; 

task type Tsk2 is
  pragma Priority(14); 	
end tsk2;

task type Tsk3 is
   pragma Priority(3); 		
end Tsk3;

task type Tsk4 is
   pragma Priority(2); 		
end Tsk4;

task body Tsk1 is 
    Interval : Time_Span := Milliseconds(100);
    Next : Time;
begin
	Next := Clock;
	loop
	  Put_Line("Task 1");
	  Next := Next + Interval;
	  delay until Next;
	end loop;
end Tsk1;

task body Tsk2 is 
	Interval : Time_Span := Milliseconds(200);
	Next : Time;
begin
	Next := Clock;
	loop
	  Put_Line("Task 2");
	  Next := Next + Interval;
	  delay until Next;
	end loop;
end Tsk2;

task body Tsk3 is 
        Interval : Time_Span := Milliseconds(300);
	Next : Time;
begin
	Next := Clock;
	loop
	  Put_Line("Task 3");
	  Next := Next + Interval;
	  delay until Next;
	end loop;
end Tsk3;

task body Tsk4 is 
      Interval : Time_Span := Milliseconds(400);
      Next : Time;
begin
	Next := Clock;
	loop
	  Put_Line("Task 4");
	  Next := Next + Interval;
	  delay until Next;	  	
	end loop;
end Tsk4;

tk1 : tsk1;
tk2 : tsk2;
tk3 : tsk3;
tk4 : tsk4;

begin
   Put_Line("This is an example of mixed scheduling");

end mixed;

