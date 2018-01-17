#!/bin/bash
rm a.out
../../bin/ktc --enable-ext0 $1 --link
rm *.dot
sudo ./a.out

