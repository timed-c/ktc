# KTC : A Source-To-Source Compiler for Timed C Programming Language 

## Introduction
***

**KTC** is a source-to-source compiler that compiles a Timed C file into a target specific C file. The current version of KTC supports translation of Timed C programs to real-time POSIX standard and FreeRTOS API. The KTC compiler has been tested to compile and run Timed C applications on Raspberry Pi running Raspian OS, Intel x86 processor running Ubuntu, an ARM based processor running FreeRTOS, and a PIC32 microcontroller running FreeRTOS.

## Building and Installing KTC
***
### A. Installing Dependencies
#### 1.Linux Based Operating System
The following steps have been tested on ubuntu 14.04LTS.

**(a.) OCaml dependencies**

Install the following packages using apt-get. 

	sudo apt-get install ocaml opam ocaml-findlib 	lablgtk2 mercurial ocaml-ocamlgraph
	
**(b.) CIL dependencies**

Follow the instructions at <https://github.com/cil-project/cil> to install and build CIL.

#### 2. MAC OSX 

The following steps have been tested on OSX El Capitan. 

**(a.) OCaml dependencies**

Install the following packages using MacPorts. 

	sudo port install ocaml opam ocaml-findlib lablgtk2 mercurial ocaml-ocamlgraph
**(b.) CIL dependencies**

Follow the instructions at <https://github.com/cil-project/cil> to install and build CIL.

**(c.) A C compiler that supports Real-Time POSIX standards** 

Mac OSX does not provide support for Real-Time POSIX APIs. To build a Timed C application for a linux based operating system download the Linux cross compiler for Mac OSX from <http://crossgcc.rts-software.org/doku.php> 


#### B. KTC Installation

(a.) Clone or download the source code from <https://github.com/timed-c/ktc.git>

(b.) Run **make** from the root directory (in this case, the ktc directory)

#### C. Compiling Timed C program

(a.) Go to the bin directory 

(b.) To view the various options, run ktc with the help command.

	./ktc --help
(c.) In Linux OS, to compile a Timed C file use the following command
	
	./ktc --enable-ext0 ../test/demo1.c
(d.) To compile and run a Timed C file use the following command
	
	./run.sh ../test/demo1.c
(e.) In Mac OSX, to compile a Timed C program KTC use the following command

	./ktc --enable-ext0 --gcc=x86_64-pc-linux-gcc ../	 test/demo1.c
If the path for the cross compiler has not be exported use the complete path in the *--gcc* option as shown below. 

	./ktc --enable-ext0 --gcc=/usr/local/gcc-4.5.2-for-	linux64/bin/i586-pc-linux-gcc ../test/demo1.c

#### D. Example Timed C programs 

(a.) The folder called *example* within the *ktc* directory contains the few example programs (**these example program are listed in the paper which is is currently under submission at the RTAS 2018 conference**). To compile and execute the program use the following command 

    ./run.sh <name-of-file>

For example the program implementing periodic loop using sdelay statement is compiled and executed using the following command 

    ./run.sh sdelay-overshot.c
	
## KTC For Raspberry Pi
	
***
#### A. Setting up the Raspberry Pi

(a.) Follow the instructions at <https://www.raspberrypi.org/help/quick-start-guide/> to install Raspbian OS on the raspberry pi. For a hassle free setup, make sure you have all the required components as mentioned in the link before you start. Use the official noobs installer to install raspbian. The instructions are available at <https://www.raspberrypi.org/help/noobs-setup/>

(b.)This is an optional step, one can download and install the Linux RT Prempt patch on the Raspbian OS. The Linux RT Prempt patch guarantees better real-time performance. Follow the instructions for installing the pre-compiled (RT patch Linux) given at <http://www.frank-durr.de/?p=203>

(c.) For MAC OSX, install the cross compiler for raspberry pi by following the instructions at <http://www.welzels.de/blog/en/arm-cross-compiling-with-mac-os-x/comment-page-1/>. 

(d.) For Linux OS, install the cross compiler for raspberry pi by following the instructions at <https://www.raspberrypi.org/documentation/linux/kernel/building.md> 

#### C. Compiling to Raspberry Pi Using KTC 

(a.) Go to the bin directory 

(b.) To cross compile Timed C for raspberry pi use the following command

	./ktc --enable-ext0 --rasp --gcc=arm-linux-gnueabihf-gcc ../test/demo1.c
	
If the path for the cross compiler has not be exported use the complete path in the *--gcc* option as shown below. 

	./ktc --enable-ext0 --rasp --gcc=/usr/local/linaro/arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-gcc ../test/demo1.c -w
	

## KTC for PIC32 Microcontroller using FreeRTOS.
***

#### A. Setting up FreeRTOS on PIC32 

(a.) Download the MPLAB XC Compiler from <http://www.microchip.com/mplab/compilers>. 

(b.) Download Microchip's Integrated Development Environment, MPLAB X IDE, from <http://www.microchip.com/mplab/mplab-x-ide>. Inorder to program your PIC32 microcontroller board using MPLAB you will also need either microchips's chipKIT PGM or PICkit 3 Programmer/Debugger.

(c.)FreeRTOS is downloaded as a part of the KTC environment from the github which contains the FreeRTOS code from <https://sourceforge.net/projects/freertos/files/latest/download?source=file>

(d.)Open the RTOSDEMO.X project on MPLAB from the FreeRTOS/Demo directory. Connect your PIC32 board and chipKIT PGM or PICkit 3 Programmer/Debugger to the computer and execute the demo application from MPLAB X IDE.

#### A. Compiling Timed C program to PIC32

(a.) Compile the Timed C file using the below command 

	./ktc --enable-ext1 --freertos --save-temps --gcc=/Applications/microchip/xc32/v1.42/bin/xc32-gcc <NAME-OF-C-FILE> -w 
(b.) Copy the .cil.c file to the MPLAB project and build it on the MPLAB IDE using MPLAB XC compiler.

	


	
	








	


