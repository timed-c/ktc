#!/bin/bash
cp $1 temp.c
sed -i -e 's/while(1){/while(1){sdelay(-2103, ms);/g' $1
sed -i -e 's/\(fifochannel\|BBB\)\([^;]*\)/\1 (\2)/g' 
../bin/ktc --enable-ext0 --link $1
mv temp.c $1

