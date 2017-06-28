with Ada.Text_IO;use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Numerics.Discrete_Random;


procedure sporadic_task is

protected sporadic is
	procedure release;
	entry next_release;
private 
	barrier : Boolean;
	min_int : Time_Span := Milliseconds(3000);
	last_release : Time;

end sporadic;

protected body sporadic is
	procedure release is
		current : Time := Clock;
	begin
		if current - last_release > min_int then
			--Put_Line("Interrupt:");
			barrier := True;
			last_release := Clock;
		end if;
	end release;

entry next_release when barrier is 
	begin 
		barrier := False;
	end next_release;
end sporadic;



task type sptask is
end sptask; 

task type sserver is	
end sserver;


task body sptask is 
begin
	loop
	  sporadic.next_release;
	  Put_Line("Sporadic Task Released");
	end loop;
end sptask;

task body sserver is
	subtype Die is Integer range 1 .. 10;
	package Random_Die is new Ada.Numerics.Discrete_Random (Die);
	use Random_Die;
	G : Generator;
	now : Time;
	intrval : Time_Span := Milliseconds(3000);
begin
   Reset (G);   
   now := Clock; 
   loop
	if Random(G) > 5 then 
      		delay until (now + intrval);
	end if;
	now := Clock;
      sporadic.release;
   end loop;
end sserver;

task1 : sptask;
server :sserver;
begin

   Put_Line("This is an example of spoardic tasks");

end sporadic_task;

