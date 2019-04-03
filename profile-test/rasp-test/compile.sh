#!/bin/bash
name=$1
/home/saranya/Dokument/ktc/bin/ktc --gcc=arm-linux-gnueabihf-gcc --enable-ext2 --save-temps --rasp  $name -I. -L. -lplogs -lmrasp  -w --link
rm *.dot



