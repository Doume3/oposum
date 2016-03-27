#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <time.h>
#include "reseaux.h" 														// Fonctions personnelles

/*
 * Description : obtient une IP à partir d'un nom de domaine
 * Entrées : nom
 * Sorties : l'IP correspondante, ou NULL en cas d'erreur (affiche par perror)
 * Exemple : getIPParNom("jhote.com");
 */
char* getIPParNom(const char nom[]){
	struct hostent *host;
	if((host = gethostbyname(nom)) == NULL){
		perror("Erreur gethostbyname() ");
		return NULL;
	}
	struct in_addr **ip = (struct in_addr **) host->h_addr_list;
	return inet_ntoa(*ip[0]);
}


/*
 * Description : ouvre et configure une socket pour un client
 * Entrées : protocole, nom du serveur (NDD/IP), numéro de port
 * Sorties : numéro de la socket, ou exit -1 en cas d'erreur (affiché par perror)
 * Exemple : socketClient(UDP, "120.23.21.58", 19999);
 */
int socketClient(Protocole protocole, const char nomServeur[], unsigned short int port){
	int numSocket;
	struct sockaddr_in client;

	// Création de la socket, STREAM ou DGRAM selon le protocole (TCP/UDP)
	if(protocole == TCP)
		numSocket = socket(AF_INET, SOCK_STREAM, 0);
	else
		numSocket = socket(AF_INET, SOCK_DGRAM, 0);
      
	if(numSocket < 0){
		perror("Erreur socket() ");
		exit(EXIT_FAILURE);
	}

	if(protocole == TCP){
		char *realIP;
		// Conversion du nom en IP
		if((realIP = getIPParNom(nomServeur)) == NULL)
			return -1;
		client.sin_family = AF_INET;
		client.sin_addr.s_addr = inet_addr(realIP);
		client.sin_port = htons(port);
		if(connect(numSocket, (struct sockaddr *) &client, sizeof client) == -1){
			perror("Erreur connect() ");
			exit(EXIT_FAILURE);
		}
	}

	return (numSocket);
}


/*
 * Description : ouvre et configure une socket pour un serveur
 * Entrées : protocole, numéro du port
 * Sorties : numéro de la socket, ou exit -1 en cas d'erreur (affiché par perror)
 *   En mode TCP, le serveur est prêt à accepter des connexions avec : msgSock = accept(num, NULL, NULL);
 *   En mode UDP, le socket est prêt pour lecture/écriture avec sendto/recvfrom.
 * Exemple : socketServeur(UDP, 19999);
 */
int socketServeur(Protocole protocole, unsigned short int port){
	int numSocket;
	struct sockaddr_in serveur;

	// Création de la socket, STREAM ou DGRAM selon le protocole (TCP/UDP)
	if (protocole == TCP)
		numSocket = socket(AF_INET, SOCK_STREAM, 0);
	else
		numSocket = socket(AF_INET, SOCK_DGRAM, 0);
	  
	if(numSocket < 0){
		perror("Erreur socket() ");
		exit(EXIT_FAILURE);
	}

	serveur.sin_family = AF_INET;
	serveur.sin_addr.s_addr = htonl(INADDR_ANY);
	serveur.sin_port = htons(port);

	if(bind(numSocket, (struct sockaddr *) &serveur, sizeof(serveur)) < 0){
		perror("Erreur bind() ");
		exit(EXIT_FAILURE);
	}

	if (protocole == TCP){
		if(listen(numSocket, 5) < 0){
			perror("Erreur listen() ");
			exit(EXIT_FAILURE);
		}
	}

	return (numSocket);
}


/* 
 * Description : affiche les informations d'une socket.
 * Entrées : le numéro de la socket
 * Sorties : sur stdout.
 */
void infosSocket(int numSocket){
	socklen_t taille_adrDist;
	struct sockaddr_in maSock, adrDist;
	taille_adrDist = sizeof(struct sockaddr_in);
	printf("Informations sur la socket n°%d \n", numSocket);
	if(getsockname(numSocket, (struct sockaddr *) &maSock, &taille_adrDist) != 0)
		printf("Problème sur partie locale de la socket\n");
	else
		printf("@IP locale:%s  port local:%d\n", inet_ntoa(maSock.sin_addr),
	ntohs(maSock.sin_port));

	/* On n'affiche qu'en cas de succès pour la partie distante */
	if (getpeername(numSocket, (struct sockaddr *) &adrDist, &taille_adrDist) == 0)
		printf("@IP distante:%s  port distant: %d \n",
	inet_ntoa(adrDist.sin_addr), ntohs(adrDist.sin_port));
}


/*
 * Description : envoi un message à tous les clients
 * Entrées : la liste des clients, l'émetteur, le nombre de clients connectés, le message, un booléen pour savoir si c'est un message serveur
 * Sorties : sur stdout
 */
void envoyerMessageAuxClients(Client *clients, Client emetteur, int nbClients, const char *message, int messageServeur){
	int i;
	char messageAEnvoyer[TAILLE_BUFFER_MESSAGE];

	/* Pour la date */
	char dateMessage[128];
    time_t temps;
    struct tm date;
	
	for(i = 0; i < nbClients; i++){

		/* Réinitialisation de la variable */
		memset(messageAEnvoyer, 0, sizeof(messageAEnvoyer));
	
		if(emetteur.numSocket != clients[i].numSocket){
		
			/* Si c'est un message client, on ajoute son nom devant le message */
			if(messageServeur == 0){

				/* Récupération de la date */
				time(&temps);
	    		date = *localtime(&temps);
	    		strftime(dateMessage, 128, "[%H:%M:%S] ", &date);
	    		strncpy(messageAEnvoyer, dateMessage, sizeof messageAEnvoyer - strlen(messageAEnvoyer));
				strncat(messageAEnvoyer, emetteur.pseudo, strlen(emetteur.pseudo));
				strncat(messageAEnvoyer, " : ", sizeof messageAEnvoyer - strlen(messageAEnvoyer));
			}
		
			strncat(messageAEnvoyer, message, sizeof messageAEnvoyer - strlen(messageAEnvoyer));

			if(send(clients[i].numSocket, messageAEnvoyer, strlen(messageAEnvoyer), 0) == -1){
				perror("Erreur send() ");
				exit(EXIT_FAILURE);
			}
		}
	}
}


