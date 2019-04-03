#!/bin/sh

rm plog.o
rm libplogs.a
arm-linux-gnueabihf-gcc -c -I. plog.c
arm-linux-gnueabihf-ar -rc libplogs.a plog.o
