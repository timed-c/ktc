#Benchmark Suite for Programming Real-Time Systems#
This is a collection of programs that illustrates the programming of real-time system using _Ada_, _Real-Time Java (RTJ)_ and _Timed C_. The examples here illustrates the programming of the temporal requirements and concurrency in real-time system. 

##Software Required##
### Linux Platform ###
####Ada Compiler####
Run "apt-get install gnat" on the terminal 
####Real-Time Java####
Install JamaicaVM Personal Edition. For installation instruction click on below the link :
https://www.aicas.com/cms/en/downloads
####Timed C####
Install KTC compiler for Timed C. For installation instruction click on below the link :
https://github.com/timed-c/ktc/blob/master/README.md

##Compiling and Running Test Programs##
##Ada Program##
Compile : gnatmake _file.adb_
Run : ./file
##Timed C##
Compile : ./ktc --enable-ext0 _file.c_
Run : ./file 
##Real-Time Java##
Compile : jamaicac -d classes _file.java_
Run : jamaicavm -cp classes/ _file_

