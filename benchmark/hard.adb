with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;use Ada.Text_IO;
with Ada.Execution_Time.Timers; use Ada.Execution_Time.Timers;

procedure Hard is

   protected Overrun is 
       entry Stop_Task;
       procedure Handler(Tmr : in out Timer);
       procedure Reset(T1, T2: Time_Span);
   private 
	Leave : Boolean := False;
	First_Occurence : Boolean := True;
	WCET : Time_Span;
	WCET_Overrun : Time_Span;
   end Overrun;

   protected body Overrun is
	entry Stop_Task when Leave is
	begin 
	  Leave := False;
	  First_Occurence := True;
	end Stop_Task;

  	procedure Reset(T1, T2: Time_Span) is
	begin
	  Leave := False;
	  First_Occurence := True;
	  WCET := T1;
	  WCET_Overrun := T2;
	end Reset;

	procedure Handler(TM : in out Timer) is 
	begin
	  if First_Occurence then 
	     Set_Handler(TM, WCET_Overrun, Handler'Access);
	     Set_Priority(2, TM.T.all);
	     First_Occurence := False;
	  else
	     Leave := True;
	  end if;
	end Handler;
   end Overrun;


   task type Hard_Task is
   end Hard_Task;

   task body Hard_Task is 
	ID : aliased Task_ID := Current_Task;
	WCET_Error : Timer(ID'Access);
 	WCET : Time_Space := Microseconds(1250);
	WCET_Overrun : Time_Span := Microseconds(250);	 
	Bool : Boolean := False;
  begin 
	Overrun.Reset(WCET, WCET_Overrun);
	Set_Handler(WCET_Error, WCET, Overrun.Handler'Access);
	select
	  Overrun.Stop_Task;
	  Put_Line("Deadline Miss!");
	then abort 
	  loop 
	   Put("*");
	  end loop;
	end select;
	Cancel_Handler(WCET_Error, Bool);
  end Hard_Task;

  Task1 : Hard_Task;
  begin 
    null;
end Hard;











		

