pragma Task_Dispatching_Policy(EDF_Across_Priorities);
with Ada.Text_IO;use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
--with Ada.Dispatching; use Ada.Dispatching;
with Ada.Dispatching.EDF; use Ada.Dispatching.EDF;
with System;  use System;


procedure edf is 
  
task type A is 
  pragma Priority(5);
  pragma Relative_Deadline(Milliseconds(100));
end A;

task type B is 
  pragma Priority(5);
  pragma Relative_Deadline(Milliseconds(200));
end B;

task body A is 
  Next : Time;
  Period :Time_Span :=  Milliseconds(100);
  Deadline :Time_Span :=   Milliseconds(100);
  begin
   Next := Clock;
   loop 
     Put_Line("Task A");
     Next := Next + Period;
     Delay_Until_And_Set_Deadline(Next, Deadline);
  end loop;
end A;

task body B is 
  Next : Time;
  Period :Time_Span :=  Milliseconds(200);
  Deadline :Time_Span :=   Milliseconds(200);
  begin
   Next := Clock;
   loop 
     Put_Line("Task B");
     Next := Next + Period;
     Delay_Until_And_Set_Deadline(Next, Deadline);
  end loop; 
end B;

TaskA : A;
TaskB : B;

begin 
  null;
end edf;

    

