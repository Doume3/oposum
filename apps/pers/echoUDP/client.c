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
		printf("Il faut 2 parametres (IP ou NDD et port).\n");
		return EXIT_FAILURE;
	}

	struct sockaddr_in adrDist;												// Adresse distante
	socklen_t taille_adrDist = sizeof(adrDist);								// Taille adresse distante
	int maSock;																// Ma socket
	char msgSend[2048];														// Buffer pour les messages envoyes
	char msgRecv[2048];														// Buffer pour les messages recus
	char *realIP;															// IP

	maSock = socketClient(UDP, realIP, atoi(argv[2]));

	if((realIP = getIPParNom(argv[1])) == NULL)
		return -1;
	
	adrDist.sin_family = AF_INET;											// Internet
	adrDist.sin_addr.s_addr = inet_addr(realIP);							// IP
	adrDist.sin_port = htons(atoi(argv[2]));								// Port

	while(1){
		fgets(msgSend, sizeof(msgSend), stdin);
		if(msgSend[0] == '\n') break;

		if(sendto(maSock, msgSend, strlen(msgSend), 0, (struct sockaddr *) &adrDist, taille_adrDist) == -1){
			perror("Erreur sendto() ");
			close(maSock);
			return EXIT_FAILURE;
		}

		memset(msgRecv, 0, sizeof(msgRecv)); 								// Réinitialise le tampon

		if(recvfrom(maSock, msgRecv, sizeof(msgRecv), 0, (struct sockaddr *) &adrDist, &taille_adrDist) == -1){
			perror("Erreur recvfrom() ");
			close(maSock);
			return EXIT_FAILURE;
		}

		printf("%s \n", msgRecv);
	}

	close(maSock);

	return EXIT_SUCCESS;
}
