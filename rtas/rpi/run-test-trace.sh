#!/bin/bash
rm mistrasp.c
sudo rm log.txt
cp $1 mistrasp.c
sudo make clean 
make
echo $?
if [ $? -eq 0 ]
then
	sudo ./mist 2> err
	grep -ir "mistADCS" log.txt > ADCS.txt
	grep -ir "mistHK" log.txt > HK.txt
	grep -ir "mistRetrieve" log.txt > RETRIEVE.txt
	grep -ir "mistExecute" log.txt > RETRIEVE.txt
	grep -ir "TC ret" log.txt > TC-RETRIEVE.txt
	grep -ir "EXE" log.txt > TC-EXECUTE.txt
else
	exit 0
fi