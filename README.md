						KTC : A source-to-source Compiler for TIMED-C 
							*****IN-PROGRESS*******

1. Intro
2. Building and Installing
3. Using KTC to compile timed-c code to run on Raspberry Pi


1. Intro:
------

KTC is a source-to-source compiler for the timed-C programming language. It takes timed-C code as input, performs source-to-source transformation (depending on the specified target platform), spits out a C code which then can be compiled using 
a compiler that supports the target platform. The current version of KTC supports POSIX based hardwares. There is ongoing testing for Raspberry Pi running Linux-RT and Intel x86 processor running on Ubuntu.  

2. Building and Installing KTC:
------------------------

2a. Dependencies
 
    . Ocaml Dependencies :

      -	sudo port install ocaml ocaml-findlib lablgtk2 mercurial ocaml-ocamlgraph 
        (Use macports for MAC OSX)

      - opam port install ocamlbuild

    . CIL 

     - Build and install from https://github.com/cil-project/cil

    . Cross Compiler ToolChain (MAC OSX)

     - Download the mac osx to linux cross compiler tool from http://crossgcc.rts-software.org/doku.php?id=compiling_for_linux

2b. KTC Installation

    . Clone or Download from https://github.com/timed-c/ktc.git

    . Go to the root directory, in this case ktc, and run the sudo make -r command

    . The ktc exectable will be created in the bin directory.

2c. Executing KTC

    . Go to bin directory 

    . Execute the following command to test the application 
	
	./ktc --enable-ext0 --save-temps  --gcc=x86_64-pc-linux-gcc  ../test/demo1.c (MAC OSX)
	
	./ktc --enable-ext0 --save-temps ../test/demo1.c (Linux)


2d. Test Suites


3. Using KTC to compile timed-c code to run on Raspberry Pi
----------------------------------
	
  . Install Raspbian 

     - To install raspbian on Raspberry Pi follow the instructions in https://www.raspberrypi.org/help/quick-start-guide/

  . Install RT Preempt patch on a Raspberry Pi (for better real-time performance)   

     - Download and follow the instruction to install pre-complied RT preempt patched kernel from http://www.frank-durr.de/?p=203 
 . Install cross compiler for raspberry pi 

      - Follow the instruction under cross compiler section in https://www.raspberrypi.org/documentation/linux/kernel/building.md	(Ubuntu)

      - Follow the instruction under cross compiler section in http://www.welzels.de/blog/en/arm-cross-compiling-with-mac-os-x/comment-page-1/ (MAC OS)

  . Running KTC

      - Execute the following command to test the application 
	
	./ktc --enable-ext0 --save-temps  --gcc=arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-ld ../test/demo1.c (MAC OSX)

