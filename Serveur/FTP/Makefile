all: serveurFTP clientFTP clean

serveurFTP: serveurFTP.o
	gcc -o serveurFTP serveurFTP.o

serveurFTP.o: serveurFTP.c
	gcc -o serveurFTP.o -c serveurFTP.c

clientFTP: clientFTP.o
	gcc -o clientFTP clientFTP.o

clientFTP.o: clientFTP.c
	gcc -o clientFTP.o -c clientFTP.c

clean:
	rm *.o *~