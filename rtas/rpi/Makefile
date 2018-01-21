all: mist

mist: mistrasp.o trxvu_uplink_sim.o mistauxnew.o
	gcc -g -w mistrasp.o trxvu_uplink_sim.o mistauxnew.o -o mist  -L. -lm -lktc  -lrt -lpthread   2> err
main.o: mistrasp.c
	gcc -g -w -c mistrasp.c 2> err 

mistauxnew.o: mistauxnew.c
	gcc -g -w -c mistauxnew.c  2> err 

clean:
	rm *o mist
