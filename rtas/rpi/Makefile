all: mist

mist: mistrasp.o trxvu_uplink_sim.o mistauxnew.o
	gcc -g -w mistrasp.o trxvu_uplink_sim.o mistauxnew.o -o mist  -L. -lm -lktc  -lrt -lpthread  -w 
main.o: mistrasp.c
	gcc -g -w -c mistrasp.c 

mistauxnew.o: mistauxnew.c
	gcc -g -w -c mistauxnew.c 

clean:
	rm *o mist
