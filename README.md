# KTC : A Source-To-Source Compiler For TIMED-C 

##Introduction 
***

**KTC** is a source-to-source compiler for the timed-C programming language. It takes timed-C code as input, performs source-to-source transformation (depending on the specified target platform), spits out a C code which can then be compiled using a target specific compiler. The current version of KTC supports translation of timed-c to real-time POSIX standard. The KTC compiler is currently being tested to compile and run timed-C applications on Raspberry Pi and Intel x86 processor running Linux based operating systems.

##Building and Installing KTC
***
### A. Installing Dependencies
####1. MAC OSX 
The following steps have been tested on OSX El Capitan. 

 
**(a) OCaml Dependencies**

Install the following packages using MacPorts. Some of these packages are needed to install and run C Intermediate Language(CIL).

	sudo port install ocaml opam ocaml-findlib lablgtk2 	mercurial ocaml-ocamlgraph
	
**(b) CIL Dependencies**

Follow instructions at <https://github.com/cil-project/cil> to install and build CIL.

**(c) A C compiler that supports RT-POSIX standards** 

Mac OSX does not support RT-POSIX standard, hence inorder to translate timed-C to POSIX download the Linux cross compiler for Mac OSX from <http://crossgcc.rts-software.org/doku.php> 

####2.Linux based OS 
The following steps have been tested on ubuntu 14.04LTS.
 
**(a) OCaml Dependencies**
	
Install the following packages using apt-get. Some of these packages are needed to install and run C Intermediate Language(CIL).

	sudo apt-get install ocaml opam ocaml-findlib 	lablgtk2 mercurial ocaml-ocamlgraph
	
**(b) CIL Dependencies**

Follow instructions at <https://github.com/cil-project/cil> to install and build CIL.

#### B. KTC Installation

(a) Clone or download the source code from <https://github.com/timed-c/ktc.git>

(b) Run **make** from the root directory (in this case, the ktc directory)



#### C. Executing KTC 

(a) Go to the bin directory 

(b) To view the various options, run ktc with the help command.

	./ktc --help

(c) In Linux OS, to run and test KTC use the following command
	
	./ktc --enable-ext0 ../test/demo1.c
	
(d) In Mac OSX, to run and test KTC use the following command

	./ktc --enable-ext0 --gcc=x86_64-pc-linux-gcc ../	 test/demo1.c
If you have not exported the path for the cross compiler, you will have to use the complete path in the *--gcc* option as below. 

	./ktc --enable-ext0 --gcc=/usr/local/gcc-4.5.2-for-	linux64/bin/i586-pc-linux-gcc ../test/demo1.c
	
##KTC For Raspberry Pi
	
***
#### A. Setting up the Raspberry Pi

(a) Follow the instructions at <https://www.raspberrypi.org/help/quick-start-guide/> to install Raspbian OS on the raspberry pi. For a hassle free setup, make sure you have all the required components as mentioned in the link before you start. Use the official noobs installer to install raspbian. The instructions are avaialable at <https://www.raspberrypi.org/help/noobs-setup/>

(b)This is an optional step, one can download and install the Linux RT Prempt patch over the Raspbian OS. The Linux RT Prempt patch guarantees better real-time performance.Follow the instructions for installing the pre-compiled (RT patch Linux) given at <http://www.frank-durr.de/?p=203>

(c) For MAC OSX, install the cross compiler for raspberry pi by following the instructions at <http://www.welzels.de/blog/en/arm-cross-compiling-with-mac-os-x/comment-page-1/>. 

(d) For Linux OS, install the cross compiler for raspberry pi by following the instructions at <https://www.raspberrypi.org/documentation/linux/kernel/building.md> 

#### C. Compiling to Raspberry Pi Using KTC 

(a) Go to the bin directory 

(b) To cross compile timed-C file to run on raspberry pi run use the following command

	./ktc --enable-ext0 --gcc=arm-linux-gnueabihf-gcc ../test/demo1.c
	
If you have not exported the path for the cross compiler, you will have to use the complete path in the *--gcc* option as below. 

	./ktc --enable-ext0 --gcc=/usr/local/linaro/arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-gcc ../test/demo1.c







	