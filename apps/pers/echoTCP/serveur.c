#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <signal.h>
#include "reseaux.c" 														// Fonctions personnelles

int main(int argc, char **argv){

	struct sockaddr_in monAdr;												// Mon adresse
	struct sockaddr_in adrDist;												// Adresse distante
	socklen_t taille_monAdr = sizeof(monAdr);								// Taille mon adresse
	socklen_t taille_adrDist = sizeof(adrDist);								// Taille adresse distante
	int maSock;																// Ma socket
	int sockDist;															// Socket distante
	char msg[2048];															// Buffer pour les messages

	if(argc == 1)
		maSock = socketServeur(TCP, 0);
	else
		maSock = socketServeur(TCP, atoi(argv[1]));
	
	getsockname(maSock, (struct sockaddr *) &monAdr, &taille_monAdr);
	printf("Adresse : %s / Port : %u \n", inet_ntoa(monAdr.sin_addr), ntohs(monAdr.sin_port));

	signal(SIGCHLD, SIG_IGN); 												// Pour éviter les processus zombies
	
	while(1){
		if((sockDist = accept(maSock, (struct sockaddr*)&adrDist, &taille_adrDist)) == -1){
			perror("Erreur accept() ");
			close(maSock);
			close(sockDist);
			return EXIT_FAILURE;
		}
		if(fork() == 0){													// Mode concurrent
			close(maSock);
			while(1){
				memset(msg, 0, sizeof(msg)); 								// Réinitialise le tampon

				int nbCar;
				if((nbCar = recv(sockDist, msg, sizeof(msg), 0)) == -1){
					perror("Erreur recv() ");
					close(maSock);
					return EXIT_FAILURE;
				}
				else if(nbCar == 0)
					break;

				if(send(sockDist, msg, strlen(msg), 0) == -1){
					perror("Erreur send() ");
					close(maSock);
					return EXIT_FAILURE;
				}
			}
			close(sockDist);
			return EXIT_SUCCESS;
		}
		else
			close(sockDist);
	}

	close(maSock);

	return EXIT_SUCCESS;
}
