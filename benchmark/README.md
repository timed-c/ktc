# Benchmark Suite for Programming Real-Time Systems

Example of programs implementing the various aspects of real-time system in _Ada_, _Real-Time Java (RTJS)_, and _Timed C_.

## 1. Software Required

#### Ada Compiler
For linux-based operating system execute the following command on the terminal
        
        sudo apt-get install gnat
### Real-Time Java
Install JamaicaVM Personal Edition. Follow the instructions in https://www.aicas.com/cms/en/downloads

### Timed C
Install KTC compiler for Timed C. For the instruction in https://github.com/timed-c/ktc/blob/master/README.md

## 2.  Compiling and Running Test Programs
### 1. Ada Program
Go to the _ada_ folder
Compile : gnatmake _file.adb_
Run : ./file
## Timed C
Go to the _timed-c_ folder
Compile and Run: ./run.sh

## Real-Time Java
Go to the _rtj_ folder. Create a subfolder called  _classes_ 
Compile : jamaicac -d classes _file.java_
Run : jamaicavm -cp classes/ _file_


## 3. Description of the programs
| Program        | Description                 | Ada  | Timed C  |RTJS   |
| ------------- |-----------------------------  | -----|-----| -----|
|periodic       |periodic loop with soft deadline| supported| supported| supported|
|periodic_overrun|periodic loop implementing soft deadline  with overrun detection and phase correction| supported | supported | supported|
|firm            |periodic loop with firm deadline| supported| supported| supported|
|anytime   |implements an anytime algorithm that calculates value of pi| supported| supported| not implemented|
|sporadic_task|implements tasks that are released sporadically | supported | supported | supported|
|fixed_priority          |sets scheduling policy of tasks to rate monotonic (RM) FIFO| supported| supported| supported|
|round_robin        |sets scheduling policy of tasks to RM round robin (RR) | supported| supported| not supported|
|mixed         |sets scheduling policy of one task to  FIFO and other to RR| supported| supported| not supported|
|edf          |sets scheduling policy of tasks to EDF| not supported| supported|  not supported|


**Note that the _"not supported"_ real-time aspects in Ada is valid only for GCC GNAT. Some of these real-time aspects are supported by AdaCore. Similarly, the _"not supported"_ real-time aspects in RTJS is specific to JamaicaVM Personal Edition.**


