#!/bin/bash
rm log
#texeutable test
test_execute()
{
./ktccompile $1 2> log
 if [ $? = 0 ]; then
    ./a.out &> log
    if [ $? = 0 ]; then
       echo $1 passed
    else
       echo $1 failed
    fi
    rm *.cil.c
    rm *.i
    rm *.dot
    rm a.out
 else
    echo $1 failed
 fi
 return 0
}

test_error()
{
../bin/ktc --enable-ext0 --link --save-temps $1 2> log
 if [ $? = 1 ]; then
    echo $1 passed
 else
    echo $1 failed
 fi
 return 0
}

#test 01
test_execute demo01.c
#test 02
test_error demo02.c
#test 03
test_error demo03.c
#test 04
test_error demo04.c
#test 05
test_error demo05.c
#test 06
test_error demo06.c
#test 07
test_execute demo07.c
#test 08
test_error demo08.c
#test 09
test_error demo09.c
#test 10
test_execute demo10.c
#test 11
test_error demo11.c
#test 10
test_execute demo12.c



