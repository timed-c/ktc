
with Ada.Real_Time;
with Ada.Text_Io;

with Generic_Timers;

package body Timers_Test is

   use Ada;
   use Real_Time;
   use Text_Io;

   -----------------------------------------------------------------------------
   -- Below are generic one shot Timers being tested                          --
   -----------------------------------------------------------------------------
   Three_Seconds : constant Time_Span := Real_Time.Milliseconds (3000);
   Three_Second_Timer_Id : constant String := "Three Second One Shot timer";

   procedure Action_Three is
   begin
      Put_Line ("Three (3) second one shot timer, Generic_Timers, expires");
   end Action_Three;

   Package Three_Second_One_Shot_Timer is new Generic_Timers (
                     True, Three_Second_Timer_Id, Three_Seconds, Action_Three);

   --------------------------------------------------------
   Five_Seconds : constant Time_Span := Real_Time.Milliseconds (5000);
   Five_Second_Timer_Id : constant String := "Five Second One Shot timer";

   procedure Action_Five is
   begin
      Put_Line ("Five (5) second one shot timer, Generic_Timers, expires");
   end Action_Five;

   Package Five_Second_One_Shot_Timer is new Generic_Timers (
                       True, Five_Second_Timer_Id, Five_Seconds, Action_Five);

  
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------

   procedure Start is
   begin
      Put_Line ("Timers Test begins");
      for Index in 1 .. 2 loop
         Three_Second_One_Shot_Timer.Start;
         Five_Second_One_Shot_Timer.Start;
         --delay 6.0;
      end loop;
   end Start;

   procedure Shutdown is
   begin
      Three_Second_One_Shot_Timer.Cancel;
      Five_Second_One_Shot_Timer.Cancel;
      Put_Line ("Timers testing ends");
   end Shutdown;

end Timers_Test;
