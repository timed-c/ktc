#!/bin/bash
name=$1
../bin/ktc --enable-ext2 --save-temps $name -L. -llogs -lmbench  -w --link -g
./a.out
../bin/ktc --enable-ext3 --save-temps $name -L. -llogs -lmbench -w --link -g
/home/saranya/Dokument/tools/analysis_tool/timed-c-e2e-sched-analysis/build/nptest -r job.csv > output
cp job.rta.csv output.rta
cp job.csv input
/home/saranya/Dokument/tools/analysis_tool/timed-c-e2e-sched-analysis/sensitivity/progprog
