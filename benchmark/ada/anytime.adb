with Ada.Text_Io; use Ada.Text_Io;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Numerics.Float_Random;

procedure Anytime is 

 protected Pi_Increment is
    procedure Increment(z: in float; count: in out float; iter: in out float);
 end Pi_Increment; 

protected body Pi_Increment is
    procedure  Increment(z: in float; count: in out float; iter: in out float) is 
    begin
      if z <= 1.0 then 
	count := count + 1.0; 
     else 
       count := count; 
     end if;
      iter := iter + 1.0;
    end Increment;
end Pi_Increment;
   
task type Calculate_Pi is
end Calculate_Pi;

task body Calculate_Pi is
  use Ada.Numerics.Float_Random;
  G : Generator;
  Now : Time;
  Interval : Time_Span := Milliseconds(3000);
  X : float;
  Y : float;
  Z : float;
  Pi : float := 3.14;
  Cnt : float := 0.0;
  Itr : float := 0.0; 
  begin
  Now := Clock;
  Reset(G, 1);
    select
      delay until Now + Interval;
      Pi := (Cnt/Itr)*3.14;  
      Put_Line(Float'Image(Pi));
    then abort
       loop
	X := Random(G);
        Y := Random(G);
	Z := X*X + Y*Y;
	Pi_Increment.Increment(Z, Cnt, Itr);
       end loop;      
    end select;
end Calculate_Pi;

Pi : Calculate_Pi;

begin 
  Put_Line("Calculate Pi");
end Anytime;

