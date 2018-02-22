# Benchmark Suite for Programming Real-Time Systems

Example of programs implementing the various aspects of real-time system in _Ada_, _Real-Time Java (RTJS)_, and _Timed C_.

## 1. Software Required

### Ada Compiler
For linux-based operating system execute the following command on the terminal
        
        sudo apt-get install gnat
### Real-Time Java
Install JamaicaVM Personal Edition. Follow the instructions in https://www.aicas.com/cms/en/downloads

### Time C
Install KTC compiler for Timed C. For the instruction in https://github.com/timed-c/ktc/blob/master/README.md

## 2.  Compiling and Running Test Programs
### Ada Program
Go to the _ada_ folder

Compile : gnatmake _file.adb_

Run : ./file
### Timed C
Go to the _timed-c_ folder

Compile and Run: ./run.sh _file.c_

### Real-Time Java
Go to the _rtj_ folder. Create a subfolder called  _classes_ 

Compile : jamaicac -d classes _file.java_

Run : jamaicavm -cp classes/ _file_


## 3. Description of the programs
| Program        | Description                 | Ada  | Timed C  |RTJS   |RTCC  |
| ------------- |-----------------------------  | -----|-----| -----| -----|
|periodic       |periodic loop with soft deadline| supported| supported| supported|  supported|
|periodic_overrun|periodic loop implementing soft deadline  with overrun detection and phase correction| supported | supported | supported| supported|
|firm            |periodic loop with firm deadline| supported| supported| supported| supported|
|anytime   |implements an anytime algorithm that calculates value of pi| supported| supported| not implemented| supported|
|sporadic_task|implements tasks that are released sporadically | supported | supported | supported| not implemented|
|fixed_priority          |sets scheduling policy of tasks to rate monotonic (RM) FIFO| supported| supported| supported| not implemented|
|round_robin        |sets scheduling policy of tasks to RM round robin (RR) | supported| supported| not supported|  not implemented|
|mixed         |sets scheduling policy of one task to  FIFO and other to RR| supported| supported| not supported| not implemented|
|edf          |sets scheduling policy of tasks to EDF| not supported| supported|  not supported| not supported|


**Note that the _"not supported"_ real-time aspects in Ada is valid only for GCC GNAT. Some of these real-time aspects are supported by AdaCore. Similarly, the _"not supported"_ real-time aspects in RTJS is specific to JamaicaVM Personal Edition.**

### Real-Time Concurrent C (RTCC)
*In the sub-folder RTCC, there are four pseudo-codes of RTCC programs. The files _periodic.cc_, _firm.cc_, and _hard.cc_ contain pseudo-code implementing periodic loop with soft, firm, and hard deadlines respectively. The _process.cc_ is a  pseudo-code from the Concurrent C paper from Gehani and Roome implementing dining philosopher problem. This code lists how processes are created in RTCC and has been modified to include constructs for specifying priority. The only resource for RTCC is the paper "Real-time Concurrent C: A language for programming dynamic real-time systems". In this benchmark we only include those programs that paper states to support.
