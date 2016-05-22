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

	system("clear");

	Json::Value config;
	Json::Value apps(Json::arrayValue);

	while(true){

		cout << "##### MENU #####" << endl;
		cout << "1. Voir la configuration actuelle" << endl;
		cout << "2. Charger un fichier de configuration" << endl;
		cout << "3. Ajouter une application" << endl;
		cout << "4. Modifier une application" << endl;
		cout << "5. Supprimer une application" << endl;
		cout << "6. Enregistrer le fichier de configuration" << endl;
		cout << "7. Envoyer le fichier de configuration sur Grid'5000" << endl;
		cout << "8. Quitter" << endl;

		cout << "> ";
		int choixMenu;
		cin >> choixMenu;
		cin.ignore();

		switch(choixMenu){
			case 1:{
				cout << apps << endl;

				cout << endl;
				break;
			}
			case 2:{
				Json::Reader reader;
				Json::Value configTemp;
				ifstream fichier("config.json", ifstream::binary);

				if(fichier){
					reader.parse(fichier, configTemp, false);
					if(apps.size() > 0){
						int confirm;
						cout << apps << endl;
						cout << "deviendra :" << endl;
						cout << configTemp["apps"] << endl;
						cout << "Confirmer (0/1) : ";
						cin >> confirm;
						if(confirm != 1){
							cout << "Configuration non chargé" << endl;
							cout << endl;
							break;
						}
					}
					config = configTemp;
					apps = configTemp["apps"];
					cout << apps << endl;
					cout << "Fichier de configuration chargé" << endl;
				}
				else{
					cout << "Il n'y a pas de fichier de configuration dans ce répertoire" << endl;
				}

				fichier.close();
				cout << endl;
				break;
			}
			case 3:{
				Json::Value app;
				setApp(app);

				cout << app << endl;
				apps.append(app);
				config["apps"] = apps;

				cout << endl;
				break;
			}
			case 4:{
				if(apps.size() > 0){
					int index;
					cout << apps << endl;
					do{
						cout << "Index de l'application à modifier (0 à " << apps.size() - 1 << ") : ";
						cin >> index;
						cin.ignore();
					}while(index < 0 || index > apps.size() - 1);

					cout << apps[index] << endl;
					Json::Value app;
					setApp(app);

					int confirm;
					cout << apps[index] << endl;
					cout << "deviendra :" << endl;
					cout << app << endl;
					cout << "Modifier cette application (0/1) : ";
					cin >> confirm;

					if(confirm == 1){
						apps[index] = app;
						config["apps"] = apps;
						cout << apps << endl;
						cout << "Application modifiée" << endl;
					}
					else{
						cout << "Application non modifiée" << endl;
					}
				}
				else{
					cout << "Aucune application à modifier" << endl;
				}

				cout << endl;
				break;
			}
			case 5:{
				if(apps.size() > 0){
					int index;
					cout << apps << endl;
					do{
						cout << "Index de l'application à supprimer (0 à " << apps.size() - 1 << ") : ";
						cin >> index;
						cin.ignore();
					}while(index < 0 || index > apps.size() - 1);

					int confirm;
					cout << apps[index] << endl;
					cout << "Supprimer cette application (0/1) : ";
					cin >> confirm;

					if(confirm == 1){
						Json::Value val;
						apps.removeIndex(index, &val);
						config["apps"] = apps;
						cout << apps << endl;
						cout << "Application supprimée" << endl;
					}
					else{
						cout << "Application non supprimée" << endl;
					}
				}
				else{
					cout << "Aucune application à supprimer" << endl;
				}

				cout << endl;
				break;
			}
			case 6:{
				ifstream fichier("config.json", ifstream::binary);
				if(fichier){
					Json::Reader reader;
					Json::Value configTemp;
					reader.parse(fichier, configTemp, false);

					int confirm;
					cout << configTemp["apps"] << endl;
					cout << "deviendra :" << endl;
					cout << apps << endl;
					cout << "Confirmer (0/1) : ";
					cin >> confirm;
					if(confirm != 1){
						cout << "Configuration non enregistré" << endl;
						cout << endl;
						break;
					}
				}
				fichier.close();

				ofstream fichierL("config.json");
				Json::StyledWriter styledWriter;
				fichierL << styledWriter.write(config);
				cout << "Fichier de configuration enregistré" << endl;
				
				fichierL.close();
				cout << endl;
				break;
			}
			case 7:{
				ifstream fichier("config.json", ifstream::binary);
				if(fichier){
					cout << "Nom d'utilisateur Grid'5000 : ";
					string user = "";
					getline(cin, user);

					cout << "Site Grid'5000 : ";
					string site = "";
					getline(cin, site);

					string cmd = "scp config.json " + user + "@access.grid5000.fr:" + site;
					system(cmd.c_str());

					cout << "Configuration envoyé sur Grid'5000" << endl;
				}
				else{
					cout << "Il n'y a pas de fichier de configuration dans ce répertoire" << endl;
				}

				fichier.close();
				cout << endl;
				break;
			}
			case 8:
				return EXIT_SUCCESS;
			default:
				break;
		}

	}

	return EXIT_SUCCESS;
}