all: serveurChat clientChat clean

serveurChat: serveurChat.o
	gcc -o serveurChat serveurChat.o

serveurChat.o: serveurChat.c
	gcc -o serveurChat.o -c serveurChat.c

clientChat: clientChat.o
	gcc -o clientChat clientChat.o

clientChat.o: clientChat.c
	gcc -o clientChat.o -c clientChat.c

clean:
	rm *.o *~