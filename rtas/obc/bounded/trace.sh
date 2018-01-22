#!/bin/bash
grep -ir "mistADCS" log.txt > ADCS.txt
grep -ir "mistHK" log.txt > HK.txt
grep -ir "mistRetrieve" log.txt > RETRIEVE.txt
grep -ir "mistExecute" log.txt > EXECUTE.txt
grep -ir "TC ret" log.txt > TC-RETRIEVE.txt
grep -ir "EXE" log.txt > TC-EXECUTE.txt
