// COMPILATION : g++ -o configSetup createConfig.cpp createConfig/*.cpp (*.cpp correspond normalement à json_reader, json_value, json_writer)

#include <iostream>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <string>
#include "createConfig/json/json.h"

using namespace std;

void setApp(Json::Value &app){
	string nomApp = "";
	cout << "Nom de l'application (chat/FTP/echoTCP/echoUDP) : ";
	getline(cin, nomApp);
	
	string typeApp = "";
	cout << "### Créez les serveurs en priorité si vous avez des clients qui en dépendent !" << endl;
	cout << "Type de l'application (client/serveur/normal) : ";
	getline(cin, typeApp);

	string parametresApp = "";
	cout << "### Si vous avez besoin de l'IP d'une VM précédemment créé, utilisez {{IPVM:NomDeLaVM}} !" << endl;
	cout << "Paramètres de l'application (exemple: param1 {{IPVM:maVM}} param3) : ";
	getline(cin, parametresApp);

	int nbVMs;
	cout << "Nombre de machines virtuelles : ";
	cin >> nbVMs;
	cin.ignore();

	cout << "Nom des machines virtuelles : ";
	string nomVMs = "";
	getline(cin, nomVMs);

	cout << "Type des machines virtuelles (xs/small/medium/large/xlarge) : ";
	string typeVMs = "";
	getline(cin, typeVMs);

	app["nomApp"] = nomApp;
	app["typeApp"] = typeApp;
	app["parametresApp"] = parametresApp;
	app["nbVMs"] = nbVMs;
	app["nomVMs"] = nomVMs;
	app["typeVMs"] = typeVMs;
}

int main(){

	Json::Value config;
	Json::Value apps(Json::arrayValue);

	while(true){

		cout << endl << "##### MENU #####" << endl;
		cout << "1. Créer/modifier une configuration" << endl;
		cout << "2. Charger une configuration" << endl;
		cout << "3. Envoyer la configuration sur Grid'5000" << endl;
		cout << "4. Quitter" << endl;

		cout << "> ";
		int choixMenu;
		cin >> choixMenu;
		cin.ignore();

		switch(choixMenu){
			case 1:{
				bool exitCreateConfig = false;
				while(true){
					if(exitCreateConfig) break;
					cout << endl << "##### Création de la configuration #####" << endl;
					cout << "1. Ajouter une application" << endl;
					cout << "2. Modifier une application" << endl;
					cout << "3. Supprimer une application" << endl;
					cout << "4. Voir la configuration actuelle" << endl;
					cout << "5. Enregistrer le fichier de configuration" << endl;
					cout << "6. Retour au menu" << endl;

					cout << "> ";
					int choixCreateConfig;
					cin >> choixCreateConfig;
					cin.ignore();
					cout << endl;

					switch(choixCreateConfig){
						case 1:{
							Json::Value app;
							setApp(app);

							cout << app << endl;
							apps.append(app);
							config["apps"] = apps;

							break;
						}
						case 2:{
							int index;
							cout << apps << endl;
							cout << "Index de l'application à modifier (commence à 0) : ";
							cin >> index;
							cin.ignore();
							cout << endl;

							cout << apps[index] << endl;
							Json::Value app;
							setApp(app);

							int confirm;
							cout << apps[index] << endl;
							cout << "deviendra :" << endl;
							cout << app << endl;
							cout << "Modifier cette application (0/1) : ";
							cin >> confirm;
							cout << endl;

							if(confirm == 1){
								apps[index] = app;
								config["apps"] = apps;
								cout << apps << endl;
								cout << "Application modifiée" << endl;
							}
							else
								cout << "Application non modifiée" << endl;

							break;
						}
						case 3:{
							int index;
							cout << config["apps"] << endl;
							cout << "Index de l'application à supprimer (commence à 0) : ";
							cin >> index;
							cin.ignore();
							cout << endl;

							int confirm;
							cout << apps[index] << endl;
							cout << "Supprimer cette application (0/1) : ";
							cin >> confirm;
							cout << endl;

							if(confirm == 1){
								Json::Value val;
								apps.removeIndex(index, &val);
								config["apps"] = apps;
								cout << apps << endl;
								cout << "Application supprimée" << endl;
							}
							else
								cout << "Application non supprimée" << endl;

							break;
						}
						case 4:{
							cout << apps << endl;
							break;
						}
						case 5:{
							ofstream fichier;
    						fichier.open("config.json");

    						Json::StyledWriter styledWriter;
    						fichier << styledWriter.write(config);

    						fichier.close();
    						cout << "Fichier de configuration enregistré" << endl;
							break;
						}
						case 6:{
							exitCreateConfig = true;
							break;
						}
						default:
							break;
					}
				}
				break;
			}
			case 2:{
				Json::Reader reader;
				ifstream fichier("config.json", ifstream::binary);
				reader.parse(fichier, config, false);
				apps = config["apps"];
				cout << "Configuration chargé" << endl;
				cout << config << endl;
				break;
			}
			case 3:{
				cout << "Nom d'utilisateur Grid'5000 : ";
				string user = "";
				getline(cin, user);

				cout << "Site Grid'5000 : ";
				string site = "";
				getline(cin, site);

				string cmd = "scp config.json " + user + "@access.grid5000.fr:" + site;
				system(cmd.c_str());

				cout << "Configuration envoyé sur Grid'5000" << endl;
				break;
			}
			case 4:
				return EXIT_SUCCESS;
			default:
				break;
		}

	}

	return EXIT_SUCCESS;
}