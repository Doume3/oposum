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

#define TAILLE_BUFFER_FICHIER 2048

int main(int argc, char **argv){

	if(argc != 3){
		printf("Il faut 2 parametres (IP et port).\n");
		return EXIT_FAILURE;
	}

	/* ################################################################################ */
	/* #########################  DECLARATIONS DES VARIABLES  ######################### */
	/* ################################################################################ */

	/* IP du serveur */
	char *realIP;

	/* Ma socket */
	int maSock;

	/* Chaine des fichiers demander */
	char chaineFichiers[2048];

	/* Taille du fichier demander */
	char tailleFichier[32];

	/* Contenu du fichier demander */
	char contenuFichier[TAILLE_BUFFER_FICHIER];

	/* Tableau des noms des fichiers à demander */
	char *tableauNomsFichiers;

	/* Accusé de récéption */
	char ack[16];

	/* Fichier à remplir */
	FILE* fichier = NULL;

	/* Nombre total de caractères reçus, nombre de caractères reçus */
	int nbCarRecuTotal, nbCarRecu;

	/* ################################################################################ */
	/* #############################  CORPS DU PROGRAMME  ############################# */
	/* ################################################################################ */

	/* Récupération de l'IP du serveur */
	if((realIP = getIPParNom(argv[1])) == NULL)
		return EXIT_FAILURE;

	maSock = socketClient(TCP, realIP, atoi(argv[2]));

	/* Tant que l'on envoi pas une chaine vide */
	while(1){

		/* Réinitialisation de la variable */
		memset(chaineFichiers, 0, sizeof(chaineFichiers));

		printf("\nSaisissez la liste des fichiers a telecharger (peut etre sous forme de chemin) : \n");

		/* On demande la liste des fichiers à télécharger */
		fgets(chaineFichiers, sizeof(chaineFichiers), stdin);

		/* Sort du while si on envoi une chaine vide */
		if(chaineFichiers[0] == '\n') break;

		/* Supprime le \n de fin */
		chaineFichiers[strlen(chaineFichiers) - 1] = '\0';

		/* Découpe la chaine de caractère en tableau (1 case = 1 nom de fichier) */
		tableauNomsFichiers = strtok(chaineFichiers, " ");

		/* Tant qu'il y a des fichiers qui n'ont pas été traiter */
		while(tableauNomsFichiers != NULL){

			/* Envoi le nom du fichier à télécharger */
			if(send(maSock, tableauNomsFichiers, strlen(tableauNomsFichiers), 0) == -1){
				perror("Erreur send() ");
				close(maSock);
				return EXIT_FAILURE;
			}
			else{
				
				/* 1er recv (tailleFichier ou -1) */
				if(recv(maSock, tailleFichier, sizeof(tailleFichier), 0) == -1){
					perror("Erreur recv() ");
					close(maSock);
					return EXIT_FAILURE;
				}

				strcpy(ack, "0");
				/* Envoi de l'accusé de récéption */
				if(send(maSock, ack, strlen(ack), 0) == -1){
					perror("Erreur send() ");
					close(maSock);
					return EXIT_FAILURE;
				}

				if(strcmp(tailleFichier, "-1") != 0){

					/* On extrait le nom du fichier (car peut etre un chemin) */
					char* temp = strdup(tableauNomsFichiers);
					char* nomFichier = basename(temp);

					/* On créer/ouvre le fichier */
					if((fichier = fopen(nomFichier, "wb+")) == NULL)
						perror("Erreur fopen() ");
				}

				nbCarRecuTotal = 0;

				/* Tant que le fichier n'est pas totalement reçus */
				do{
					/* Réinitialisation de la variable */
					memset(contenuFichier, 0, sizeof(contenuFichier));
					
					/* Récupération du contenu du fichier */
					if((nbCarRecu = recv(maSock, contenuFichier, sizeof(contenuFichier), 0)) == -1){
						perror("Erreur recv() ");
						close(maSock);
						return EXIT_FAILURE;
					}

					/* Si la taille = -1, afficher l'erreur */
					if(strcmp(tailleFichier, "-1") == 0){
						printf("Erreur sur le fichier %s : %s \n", tableauNomsFichiers, contenuFichier);
					}
					else{

						/* On se place à l'endroit où il faut écrire */
						fseek(fichier, nbCarRecuTotal, SEEK_SET);
						fwrite(contenuFichier, 1, nbCarRecu, fichier);
					}

					nbCarRecuTotal = nbCarRecuTotal + nbCarRecu;

					printf("%d/%d octets recus\n", nbCarRecuTotal, atoi(tailleFichier));


				}while(nbCarRecuTotal < atoi(tailleFichier));

				if(strcmp(tailleFichier, "-1") != 0){
					fclose(fichier);
					printf("Le fichier %s a bien ete telecharge. \n", tableauNomsFichiers);
				}
			}

			tableauNomsFichiers = strtok(NULL, " ");
		}
	}

	close(maSock);

	return EXIT_SUCCESS;
}