#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include "reseaux.c" 														// Fonctions personnelles

int main(int argc, char **argv){

	if(argc != 3){
		printf("Il faut 2 parametres (IP et port).\n");
		return EXIT_FAILURE;
	}

	int maSock;																// Ma socket
	char msgSend[2048];														// Buffer pour les messages envoyes
	char msgRecv[2048];														// Buffer pour les messages recus
	char *realIP;															// IP

	if((realIP = getIPParNom(argv[1])) == NULL)
		return -1;

	maSock = socketClient(TCP, realIP, atoi(argv[2]));

	while(1){
		fgets(msgSend, sizeof(msgSend), stdin);
		if(msgSend[0] == '\n') break;

		if(send(maSock, msgSend, strlen(msgSend), 0) == -1){
			perror("Erreur send() ");
			close(maSock);
			return EXIT_FAILURE;
		}

		memset(msgRecv, 0, sizeof(msgRecv)); 								// Réinitialise le tampon

		if(recv(maSock, msgRecv, sizeof(msgRecv), 0) == -1){
			perror("Erreur recv() ");
			close(maSock);
			return EXIT_FAILURE;
		}

		printf("%s \n", msgRecv);
	}

	close(maSock);

	return EXIT_SUCCESS;
}
