#!/bin/bash
cp $1 temp.c
sed -i -e 's/\(fifochannel\|BBB\)\([^;]*\)/\1 (\2)/g' 
../bin/ktc --enable-ext0 --link $1
mv temp.c $1

