#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <libgen.h>
#include "reseaux.c"	// Fonctions personnelles


int main(int argc, char **argv){

	if(argc != 4){
		printf("Il faut 3 parametres (IP, port, pseudo).\n");
		return EXIT_FAILURE;
	}

	/* ################################################################################ */
	/* #########################  DECLARATIONS DES VARIABLES  ######################### */
	/* ################################################################################ */

	/* IP du serveur */
	char *realIP;

	/* Ma socket */
	int maSock;

	/* Descripteur des sockets */
    fd_set descSock;
    
    /* Buffer pour le message reçu, message a envoyé */
	char messageRecu[TAILLE_BUFFER_MESSAGE], messageAEnvoyer[TAILLE_BUFFER_MESSAGE];
	
	/* Nombre de caractères reçus */
	int nbCarRecu;


	/* ################################################################################ */
	/* #############################  CORPS DU PROGRAMME  ############################# */
	/* ################################################################################ */

	/* Récupération de l'IP du serveur */
	if((realIP = getIPParNom(argv[1])) == NULL)
		return EXIT_FAILURE;

	maSock = socketClient(TCP, realIP, atoi(argv[2]));
	
	/* Envoi le pseudo du client */
	if(send(maSock, argv[3], strlen(argv[3]), 0) == -1){
		perror("Erreur send() ");
		close(maSock);
		return EXIT_FAILURE;
	}

	while(1){
	
		FD_ZERO(&descSock);

		FD_SET(STDIN_FILENO, &descSock);

		FD_SET(maSock, &descSock);

		if(select(maSock + 1, &descSock, NULL, NULL, NULL) == -1){
			perror("Erreur select() ");
			close(maSock);
			return EXIT_FAILURE;
		}

		if(FD_ISSET(STDIN_FILENO, &descSock)){
			fgets(messageAEnvoyer, sizeof(messageAEnvoyer), stdin);

			/* Sort du while si on envoi une chaine vide */
			if(messageAEnvoyer[0] == '\n') break;
			
			/* Envoi le message du client */
			if(send(maSock, messageAEnvoyer, strlen(messageAEnvoyer), 0) == -1){
				perror("Erreur send() ");
				close(maSock);
				return EXIT_FAILURE;
			}
		}
		else if(FD_ISSET(maSock, &descSock)){

			/* Réinitialisation de la variable */
			memset(messageRecu, 0, sizeof(messageRecu));
		
			/* Récupération d'un message client */
			if((nbCarRecu = recv(maSock, messageRecu, sizeof(messageRecu), 0)) == -1){
				perror("Erreur recv() ");
				close(maSock);
				return EXIT_FAILURE;
			}

			if(nbCarRecu == 0){
				printf("Le serveur a coupe la connexion !\n");
				break;
			}

			printf("%s", messageRecu);
		}
	}

	close(maSock);

	return EXIT_SUCCESS;
}
