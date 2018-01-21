#!/bin/bash
rm mistrasp.c
sudo rm *.txt
cp $1 mistrasp.c
sudo make clean 
make
echo $?
if [ $? -eq 0 ]
then
	sudo ./mist 2> err
else
	exit 0
fi
