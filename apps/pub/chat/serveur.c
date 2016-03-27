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
#include <errno.h>
#include <time.h>
#include "reseaux.c"	// Fonctions personnelles


int main(int argc, char **argv){

	/* ################################################################################ */
	/* #########################  DECLARATIONS DES VARIABLES  ######################### */
	/* ################################################################################ */

	/* Mon adresse, adresse distante */
	struct sockaddr_in monAdr, adrDist;

	/* Taille de mon adresse, taille de l'adresse distante */
	socklen_t taille_monAdr = sizeof(monAdr), taille_adrDist = sizeof(adrDist);

	/* Ma socket, socket distante */
	int maSock, sockDist;

	/* Nombre de caractères reçus */
	int nbCarRecu;

	/* Descripteur des sockets */
    fd_set descSock;
	
	/* Buffer pour le nom du client, message reçu, message a envoyé */
	char nomClient[TAILLE_PSEUDO_CLIENT], messageRecu[TAILLE_BUFFER_MESSAGE], messageAEnvoyer[TAILLE_BUFFER_MESSAGE];
	
	/* Tableau des clients */
	Client clients[MAX_CLIENTS];
	
	/* Nombre de clients actuel */
	int nbClients = 0;
	
	/* Max des descripteurs */
	int nbSurveille;

	/* Pour la date */
	char dateMessage[128];
    time_t temps;
    struct tm date;

	/* ################################################################################ */
	/* #############################  CORPS DU PROGRAMME  ############################# */
	/* ################################################################################ */

	if(argc == 1)
		maSock = socketServeur(TCP, 0);
	else
		maSock = socketServeur(TCP, atoi(argv[1]));
		
	nbSurveille = maSock;
	
	getsockname(maSock, (struct sockaddr *) &monAdr, &taille_monAdr);
	printf("Adresse : %s / Port : %u \n", inet_ntoa(monAdr.sin_addr), ntohs(monAdr.sin_port));

	/* Évite les processus zombies */
	signal(SIGCHLD, SIG_IGN);
	
	while(1){

		FD_ZERO(&descSock);
		FD_SET(maSock, &descSock);
		
		int i;
		for(i = 0; i < nbClients; i++){
			FD_SET(clients[i].numSocket, &descSock);
		}
		
		if((select(nbSurveille + 1, &descSock, NULL, NULL, NULL)) == -1){
			perror("Erreur select() ");
			close(maSock);
			return EXIT_FAILURE;
		}
		
		/* Nouveau client */
		if(FD_ISSET(maSock, &descSock)){
			
			if((sockDist = accept(maSock, (struct sockaddr*)&adrDist, &taille_adrDist)) == -1){
				perror("Erreur accept() ");
				continue;
			}

			if(nbClients == MAX_CLIENTS){
				if(send(sockDist, "Le serveur est plein, desole. \n", 31, 0) == -1){
					perror("Erreur send() ");
					exit(EXIT_FAILURE);
				}
				close(sockDist);
				continue;
			}
			
			/* Réinitialisation de la variable */
			memset(nomClient, 0, sizeof(nomClient));
			
			/* Récupération du pseudo du client */
			if((nbCarRecu = recv(sockDist, nomClient, sizeof(nomClient), 0)) == -1){
				perror("Erreur recv() ");
				continue;
			}

			/* Met à jour le max des descripteurs */
			nbSurveille = sockDist > nbSurveille ? sockDist : nbSurveille;
			
			FD_SET(sockDist, &descSock);
			
			Client c;
			c.numSocket = sockDist;

			/* Réinitialisation de la variable */
			memset(c.pseudo, 0, sizeof(c.pseudo));
			strncpy(c.pseudo, nomClient, strlen(nomClient));
			clients[nbClients] = c;
			
			nbClients++;

			/* Récupération de la date */
			time(&temps);
    		date = *localtime(&temps);
    		strftime(dateMessage, 128, "[%H:%M] >> ", &date);

			/* Réinitialisation de la variable */
			memset(messageAEnvoyer, 0, sizeof(messageAEnvoyer));
			
			strncpy(messageAEnvoyer, dateMessage, sizeof messageAEnvoyer - strlen(messageAEnvoyer));
			strncat(messageAEnvoyer, nomClient, sizeof messageAEnvoyer - strlen(messageAEnvoyer));
			strncat(messageAEnvoyer, " a rejoint le chat \n", sizeof messageAEnvoyer - strlen(messageAEnvoyer));
			printf("%s", messageAEnvoyer);
			envoyerMessageAuxClients(clients, c, nbClients, messageAEnvoyer, 1);
		}
		/* Nouveau message */
		else{
			int i;
			for(i = 0; i < nbClients; i++){
				if(FD_ISSET(clients[i].numSocket, &descSock)){
					Client client = clients[i];
					
					/* Réinitialisation de la variable */
					memset(messageRecu, 0, sizeof(messageRecu));
					
					/* Récupération du message du client */
					if((nbCarRecu = recv(client.numSocket, messageRecu, sizeof(messageRecu), 0)) == -1){
						perror("Erreur recv() ");
						continue;
					}
					
					/* Réinitialisation de la variable */
					memset(messageAEnvoyer, 0, sizeof(messageAEnvoyer));
					
					strncpy(messageAEnvoyer, messageRecu, strlen(messageRecu));
					
					/* Client déconnecté */
					if(nbCarRecu == 0){
						close(client.numSocket);
						memmove(clients + i, clients + i + 1, (nbClients - i - 1) * sizeof(Client));
						nbClients--;

						/* Récupération de la date */
						time(&temps);
			    		date = *localtime(&temps);
			    		strftime(dateMessage, 128, "[%H:%M] >> ", &date);

						/* Réinitialisation de la variable */
						memset(messageAEnvoyer, 0, sizeof(messageAEnvoyer));
						
						strncpy(messageAEnvoyer, dateMessage, sizeof messageAEnvoyer - strlen(messageAEnvoyer));
						strncat(messageAEnvoyer, client.pseudo, sizeof messageAEnvoyer - strlen(messageAEnvoyer));
						strncat(messageAEnvoyer, " s'est deconnecte \n", sizeof messageAEnvoyer - strlen(messageAEnvoyer));
						printf("%s", messageAEnvoyer);
						envoyerMessageAuxClients(clients, client, nbClients, messageAEnvoyer, 1);
					}
					/* Message du client */
					else{
						envoyerMessageAuxClients(clients, client, nbClients, messageAEnvoyer, 0);
					}
					break;
				}
			}
		}
	}
	
	int i;
	for(i = 0; i < nbClients; i++){
		close(clients[i].numSocket);
	}

	close(maSock);

	return EXIT_SUCCESS;
}
