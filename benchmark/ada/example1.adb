with Ada.Text_Io; use Ada.Text_Io;

package body Example1 is
    procedure Sense is
    begin
	Dummy := 0;
 	Count := Count + 1;
	Put_Line ("Sense Start");
	Put_Line (Integer'Image(Count mod 2));	
	if Count mod 2 = 0 then
	   for I in Integer range 1 .. 10000000 loop
	      Dummy := Dummy + 1; 
	   end loop;
	   for I in Integer range 1 .. 10000000 loop
	      Dummy := Dummy + 1; 
	   end loop;
	else
	   for I in Integer range 1 .. 10 loop
	      Dummy := Dummy + 1; 
	    
	end if;
	 Put_Line ("Sense End");
    end Sense;
    function Handle_Deadline (N : Positive) return Positive is
    begin
	if Count mod 2 = 0 then
	   for I in Integer range 1 .. 10000000 loop
	      Dummy := Dummy + 1; 
	   end loop;
	   for I in Integer range 1 .. 10000000 loop
	      Dummy := Dummy + 1; 
	   end loop;
	else
	   for I in Integer range 1 .. 10 loop
	      Dummy := Dummy + 1; 
	   end loop; 
	end if;
	return Dummy;
    end Handle_Deadline;
end Example1;
