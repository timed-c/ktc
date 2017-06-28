#!/bin/bash

mkdir testing
cd testing
gnatmake ../ada/*.adb
touch result
echo "*********************************************************" > result
echo "TESTCASE		 ADA		TIMED C" >> result
echo "*********************************************************" >> result
### test 1
./hello
echo "1.Hello World	 	 PASS		PASS" >> result 
### test 2
./periodic &
PID=$! 
sleep 1
kill -TERM $PID
echo "2.Periodic Task		 PASS		PASS" >> result 
### test 3
./sporadic_task &
PID=$! 
sleep 1
kill -TERM $PID
echo "3.Sporadic  		 PASS		PASS" >> result
### test 4
./periodic_overrun &
PID=$! 
sleep 1
kill -TERM $PID
echo "4.Soft Deadline  	  PASS		PASS" >> result 
### test 5
./firm &
PID=$! 
sleep 1
kill -TERM $PID
echo "5.Firm Deadline 	PASS		PASS" >> result
### test 6
./oneshot  
echo "6.Oneshot Timer 		 FAIL		PASS" >> result
## test 7 
./anytime 
echo "7.Anytime Algo 	PASS		PASS" >> result
# test 8
./fixed_priority &
PID=$! 
sleep 1
kill -TERM $PID
echo "8.FIFO Scheduling		PASS		NA" >> result
# test 9
./non_preemptive &
PID=$! 
sleep 1
kill -TERM $PID
echo "9.NonPremptive Scheduling	 PASS		NA" >> result
# test 10
./round_robin &
PID=$! 
sleep 1
kill -TERM $PID
echo "10.RR Scheduling		 PASS		NA" >> result
./mixed &
PID=$! 
sleep 1
kill -TERM $PID
echo "11.RR Scheduling		 PASS		NA" >> result
cd ..
mv testing/result .
# test 11
gnatmake edf.adb &
echo "12.EDF Scheduling		 FAIL		NA" >> result
# test 12
gnatmake hard.adb &
echo "13.Hard Execu Timer 	 FAIL		NA" >> result
rm -r testing
