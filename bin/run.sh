#!/bin/bash
rm a.out
sed -i -e 's/main(){/main(){sdelay(0, ms);/g' $1
sed -i -e 's/while(1){{/{sdelay(0, ms);/g' $1
./ktc --enable-ext0 $1 -lpthread
sed -i -e 's/(){sdelay(0, ms);/(){/g' $1
sed -i -e 's/while(1){sdelay(0, ms);/while(1){/g' $1
clear
rm *.dot
sudo ./a.out

