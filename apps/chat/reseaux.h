#ifndef RESEAU_H
#define RESEAU_H

#define TAILLE_BUFFER_MESSAGE 2048
#define TAILLE_PSEUDO_CLIENT 32
#define MAX_CLIENTS 5

/* Définition des protocoles possibles */
typedef enum {UDP, TCP} Protocole;


/* Définition d'un client */
typedef struct Client Client;
struct Client{
	char pseudo[TAILLE_PSEUDO_CLIENT];
	int numSocket;
	int enchereMax;
};


/*
 * Description : obtient une IP à partir d'un nom de domaine
 * Entrées : nom
 * Sorties : l'IP correspondante, ou NULL en cas d'erreur (affiche par perror)
 * Exemple : getIPParNom("jhote.com");
 */
char* getIPParNom(const char nom[]);


/*
 * Description : ouvre et configure une socket pour un client
 * Entrées : protocole, nom du serveur (NDD/IP), numéro de port
 * Sorties : numéro de la socket, ou -1 en cas d'erreur (affiché par perror)
 * Exemple : socketClient(UDP, "120.23.21.58", 19999);
 */
int socketClient(Protocole protocole, const char nomServeur[], unsigned short int port);


/*
 * Description : ouvre et configure une socket pour un serveur
 * Entrées : protocole, numéro du port
 * Sorties : numéro de la socket, ou -1 en cas d'erreur (affiché par perror)
 *   En mode TCP, le serveur est prêt à accepter des connexions avec : msgSock = accept(num, NULL, NULL);
 *   En mode UDP, le socket est prêt pour lecture/écriture avec sendto/recvfrom.
 * Exemple : socketServeur(UDP, 19999);
 */
int socketServeur(Protocole protocole, unsigned short int port);


/* 
 * Description : affiche les informations d'une socket.
 * Entrées : le numéro de la socket
 * Sorties : sur stdout
 */
void infosSocket(int numSocket);


/*
 * Description : envoi un message à tous les clients
 * Entrées : la liste des clients, l'émetteur, le nombre de clients connectés, le message, 1 si c'est un message serveur
 * Sorties : sur stdout
 */
void envoyerMessageAuxClients(Client *clients, Client emetteur, int nbClients, const char *message, int messageServeur);


#endif

