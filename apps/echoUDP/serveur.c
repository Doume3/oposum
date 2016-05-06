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

	struct sockaddr_in monAdr; 												// Mon adresse
	struct sockaddr_in adrDist;												// Adresse distante
	socklen_t taille_monAdr = sizeof(monAdr);								// Taille mon adresse
	socklen_t taille_adrDist = sizeof(adrDist);								// Taille adresse distante
	int maSock;																// Ma socket
	char msg[2048];															// Buffer pour les messages

	if(argc == 1)
		maSock = socketServeur(UDP, 0);
	else
		maSock = socketServeur(UDP, atoi(argv[1]));

	getsockname(maSock, (struct sockaddr *) &monAdr, &taille_monAdr);
	printf("IP : %s / Port : %u \n", inet_ntoa(monAdr.sin_addr), ntohs(monAdr.sin_port));

	while(1){
		memset(msg, 0, sizeof(msg)); 										// Réinitialise le tampon

		if(recvfrom(maSock, msg, sizeof(msg), 0, (struct sockaddr *) &adrDist, &taille_adrDist) == -1){
			perror("Erreur recvfrom() ");
			close(maSock);
			return EXIT_FAILURE;
		}

		if(sendto(maSock, msg, strlen(msg), 0, (struct sockaddr *) &adrDist, taille_adrDist) == -1){
			perror("Erreur sendto() ");
			close(maSock);
			return EXIT_FAILURE;
		}
	}

	close(maSock);

	return EXIT_SUCCESS;
}
