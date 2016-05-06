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
#include "reseaux.c"	// Fonctions personnelles

#define TAILLE_BUFFER_FICHIER 2048

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

	/* Nom du fichier à renvoyer */
	char nomFichier[256];

	/* Taille du fichier à renvoyer */
	char tailleFichier[32];

	/* Contenu du fichier à renvoyer */
	char contenuFichier[TAILLE_BUFFER_FICHIER];

	/* Fichier à renvoyer */
	FILE* fichier = NULL;

	/* Accusé de récéption */
	char ack[16];

	/* Nombre de caractères lu, total envoyé, envoyé */
	int nbCarLu, nbCarEnvTotal, nbCarEnv;

	/* ################################################################################ */
	/* #############################  CORPS DU PROGRAMME  ############################# */
	/* ################################################################################ */

	if(argc == 1)
		maSock = socketServeur(TCP, 0);
	else
		maSock = socketServeur(TCP, atoi(argv[1]));
	
	getsockname(maSock, (struct sockaddr *) &monAdr, &taille_monAdr);
	printf("Adresse : %s / Port : %u \n", inet_ntoa(monAdr.sin_addr), ntohs(monAdr.sin_port));

	/* Évite les processus zombies */
	signal(SIGCHLD, SIG_IGN);
	
	while(1){

		if((sockDist = accept(maSock, (struct sockaddr*)&adrDist, &taille_adrDist)) == -1){
			perror("Erreur accept() ");
			close(maSock);
			close(sockDist);
			return EXIT_FAILURE;
		}

		/* Mode concurrent (1 client = 1 processus fils) */
		if(fork() == 0){
			close(maSock);
			printf("Il y a un nouveau client (%d) \n", getpid());
			
			/* Tant que le client n'envoi pas de chaine vide */
			while(1){

				/* Réinitialisation de la variable */
				memset(nomFichier, 0, sizeof(nomFichier));

				/* Récupération du nom du fichier à renvoyer */
				if((nbCarRecu = recv(sockDist, nomFichier, sizeof(nomFichier), 0)) == -1){
					perror("Erreur recv() ");
					close(maSock);
					return EXIT_FAILURE;
				}
				/* Sort du while si on reçoit une chaine vide */
				else if(nbCarRecu == 0) break;
		
				printf("Le client %d veut telecharger le fichier %s \n", getpid(), nomFichier);
				
				/* Si on ne peut pas accéder au fichier, 1er send = -1 et 2iem send = erreur rencontrée */
				if((fichier = fopen(nomFichier, "rb")) == NULL){
					strcpy(tailleFichier, "-1");
					strcpy(contenuFichier, strerror(errno));
				}
				/* S'il n'y a pas d'erreur, 1er send = taille */
				else{
					fseek(fichier, 0, SEEK_END);
					sprintf(tailleFichier, "%ld", ftell(fichier));
				}
				
				/* 1er send (tailleFichier ou -1)*/
				if(send(sockDist, tailleFichier, sizeof(tailleFichier), 0) == -1){
					perror("Erreur send() tailleFichier ");
					close(maSock);
					return EXIT_FAILURE;
				}
				else{

					/* Accusé de récéption du 1er send (0 si tout va bien) */
					if(recv(sockDist, ack, sizeof(ack), 0) == -1){
						perror("Erreur recv() ");
						close(maSock);
						return EXIT_FAILURE;
					}
					else if(strcmp(ack, "0") == 0){

						nbCarEnvTotal = 0;
						
						/* Tant que le fichier n'est pas totalement envoyé */
						do{

							if(strcmp(tailleFichier, "-1") != 0){

								/* Réinitialisation de la variable */
								memset(contenuFichier, 0, sizeof(contenuFichier));

								/* On se place à l'endroit où il faut lire */
								fseek(fichier, nbCarEnvTotal, SEEK_SET);

								/* Mise en tampon tant qu'il n'est pas plein ou que ce soit la fin du fichier */
								nbCarLu = fread(contenuFichier, 1, sizeof(contenuFichier), fichier);
							}
							
							/* 2iem send (contenuFichier ou l'erreur du fopen) */
							if((nbCarEnv = send(sockDist, contenuFichier, nbCarLu, 0)) == -1){
								perror("Erreur send() contenuFichier ");
								close(maSock);
								return EXIT_FAILURE;
							}

							nbCarEnvTotal = nbCarEnvTotal + nbCarEnv;

							printf("%d/%d octets transferes\n", nbCarEnvTotal, atoi(tailleFichier));

						}while(nbCarEnvTotal < atoi(tailleFichier));

						fclose(fichier);

						printf("Le fichier %s a bien ete transmis. \n", nomFichier);
					}
				}
			}
			close(sockDist);
			return EXIT_SUCCESS;
		}
		close(sockDist);
	}

	close(maSock);

	return EXIT_SUCCESS;
}