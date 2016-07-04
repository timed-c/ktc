						KTC : A Source to Source Compiler for TIMED-C 
							*****IN-PROGRESS*******

1. Intro
2. Building and Installing
3. Files
4. Bugs and Feedback
5. Citation

1. Intro:
------

KTC is a source-to-source compiler for the timed-C programming language. It takes timed-C code as input, performs source-to-source transformation(depending on the specified target platform), spits out a C code which then can be compiled using 
a compiler that supports the target platform. The current version of KTC supports POSIX based hardwares. There is ongoing testingfor raspbery pi running Linux-RT and intel x86 processor running on Ubuntu.  

2. Building and Installing KTC:
------------------------

2a. Dependencies 
    . Ocaml Dependencies :
      -	sudo install ocaml ocaml-findlib lablgl lablgtk lablgtk2 mercurial  ocaml-ocamlgraph 
        (Use macports for MACOS)
      - opam install ocamlbuild
    . CIL 
     - Build and install from https://github.com/cil-project/cil

2b. KTC Installation



2c. Executing KTC
2d. Test Suites


3. Using KTC to compile timed-c code to run on Raspberry Pi
----------------------------------
	
  . Install Raspbian 
     - To install raspbian on Raspberry Pi follow the instructions in https://www.raspberrypi.org/help/quick-start-guide/
  . Install RT Preempt patch on a Raspberry Pi (for better real-time performance)   
     - Download and follow the instruction to install pre-complied RT preempt patched kernel from http://www.frank-durr.de/?p=203  . Install cross compiler for raspberry pi 
      - Follow the instruction under cross compiler section in https://www.raspberrypi.org/documentation/linux/kernel/building.md	(Ubuntu)
      - Follow the instruction under cross compiler section in http://www.welzels.de/blog/en/arm-cross-compiling-with-mac-os-x/comment-page-1/ (MAC OS)


