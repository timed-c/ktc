#!/bin/bash
../../bin/ktc --enable-ext0 --link $1 -w
if [ $? = 0 ]; then 
    rm *.dot
    sudo ./a.out  
else
    rm *.dot
    exit 0
fi
rm ./a.out

