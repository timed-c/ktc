pragma Task_Dispatching_Policy(Round_Robin_Within_Priorities);
with Ada.Text_IO;use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Dispatching; use Ada.Dispatching;
--with Ada.Dispatching.Round_Robin; use Ada.Dispatching.Round_Robin;
with System;  use System;

procedure round_robin is
  pragma Priority(System.Priority'Last);
protected release_manager is
  procedure release(num : in Integer);
  entry t1_release;
  entry t2_release;
private 
  t1 : Boolean;
  t2 : Boolean;
end release_manager;

protected body release_manager is
  procedure release(num : in Integer ) is
  begin
     if num = 1 then 
       t1 := True;
    else
       t2 := True;
    end if;
    end release;

    entry t1_release when t1 is 
      begin 
	t1 := False;
    end t1_release;

    entry t2_release when t2 is 
      begin 
	t2 := False;
    end t2_release;

end release_manager;



task type tsk1 is
  
  pragma Priority(System.Priority'Last - 5); 
end tsk1; 

task type tsk2 is
  
  pragma Priority(System.Priority'Last - 5); 	
end tsk2;

task type server is
   
   pragma Priority(System.Priority'Last);
end server;

task body tsk1 is
    current : Time := Clock;
    interval: Time_Span := Milliseconds(200); 
    next : Time;
begin
	release_manager.t1_release;
        next := current + interval;
	loop
	   Put_Line("tsk1");
           delay until next;
           next := next + interval;
	end loop;
end tsk1;

task body tsk2 is
    current : Time := Clock;
    interval: Time_Span := Milliseconds(200); 
    next : Time;
begin
	release_manager.t2_release;
        next := current + interval;
	loop
	   Put_Line("tsk2");
           delay until next;
           next := next + interval;
	end loop;
end tsk2;


task body server is
begin
      release_manager.release(1);
      release_manager.release(2);
end server;

tk1 : tsk1;
tk2 : tsk2;
ss  : server;

begin
   Put_Line("This is an example of round robin scheduling");
end round_robin;

