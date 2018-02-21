with Ada.Text_Io; use Ada.Text_Io;

package body Example1 is
    procedure Sense is
    begin
	for I in Integer range 1 .. 1000000000 loop
	   Put_Line (Integer'Image(I));  
	end loop; 
    end Sense;
    procedure Handle_Deadline is
    begin
	Put_Line ("Deadline Overshot");
    end Handle_Deadline;
end Example1;
