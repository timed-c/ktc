#!/bin/bash
cp $1 temp.c
../bin/ktc --enable-ext0 --link $1 -w
if [ $? = 0 ]; then 
    rm *.dot
    mv temp.c $1
    sudo ./a.out  
else
    rm *.dot
    exit 0
fi
rm ./a.out

