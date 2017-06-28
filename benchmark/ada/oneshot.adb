with Ada.Exceptions;
with Ada.Text_Io;

with Timers_Test;

procedure oneshot is

   use Ada;
   use Text_Io;

begin

   Put_Line ("All Timers Test");

   Timers_Test.Start;
   --delay 60.0;
   Timers_Test.Shutdown;

exception
   when Error : others =>
      Put_Line ("Testing fails for because of ==> " &
                                     Exceptions.Exception_Information (Error));
end oneshot;

