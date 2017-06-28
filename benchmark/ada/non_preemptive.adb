pragma Task_Dispatching_Policy(Non_Preemptive_FIFO_Within_Priorities);
with Ada.Text_IO;use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Dispatching; use Ada.Dispatching;
with System;  use System;

procedure non_preemptive is
  pragma Priority(System.Priority'Last);
protected release_manager is
  procedure release(num : in Integer);
  entry t1_release;
  entry t2_release;
  entry t3_release;
private 
  t1 : Boolean;
  t2 : Boolean;
  t3 : Boolean;
  min_int : Time_Span := Milliseconds(3000);
  last_release : Time;
end release_manager;

protected body release_manager is
  procedure release(num : in Integer ) is
  begin
     if num = 3 then 
       t1 := True;
       t3 := True;
    else
       t1 := True;
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

    entry t3_release when t3 is 
      begin 
	t3 := False;
    end t3_release;

end release_manager;



task type tsk1 is
  
  pragma Priority(System.Priority'Last - 1); 
end tsk1; 

task type tsk2 is
  
  pragma Priority(System.Priority'Last - 2); 	
end tsk2;

task type tsk3 is
   
   pragma Priority(System.Priority'Last - 2); 		
end tsk3;

task type server is
   
   pragma Priority(System.Priority'Last);
end server;

task body tsk1 is 
begin
	loop
	  release_manager.t1_release;
	  Put_Line("tsk1 released");
	end loop;
end tsk1;

task body tsk2 is 
begin
	loop
	  release_manager.t2_release;
	  Put_Line("tsk2 released");
	end loop;
end tsk2;

task body tsk3 is 
begin
	loop
	  release_manager.t3_release;
	  Put_Line("tsk3 released");
	end loop;
end tsk3;


task body server is
  current : Time := Clock;
  interval: Time_Span := Milliseconds(300);
begin
    loop
      release_manager.release(3);
      delay until current + interval;
      current := Clock;
      release_manager.release(2);
      delay until current + interval;
      current := Clock;
    end loop;
end server;

tk1 : tsk1;
tk2 : tsk2;
tk3 : tsk3;
ss  : server;

begin
   Put_Line("This is an example of rate monotonic fixed priority scheduling");

end non_preemptive;

