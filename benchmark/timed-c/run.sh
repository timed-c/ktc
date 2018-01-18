#!/bin/bash
cp $1 temp.c
sed -i -e 's/\(fifochannel\|BBB\)\([^;]*\)/\1 (\2)/g' $1
rm a.out
../../bin/ktc --enable-ext0 $1 --link -w
mv temp.c $1
rm *.dot
sudo ./a.out
