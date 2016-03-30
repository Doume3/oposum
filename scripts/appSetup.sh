#!/bin/bash

ERR_ARGS=-1

if [ $# -ne 5 ] && [ $# -ne 6 ]; then
  echo "Usage: `basename $0` nom_VM nom_APP type_APP path_APP port_APP [type_APP=client=>serveur_APP]"
  exit $ERR_ARGS
fi

echo "- Vérification du type de l'application et des parametres";
case $3 in
    client)
	if [ $# -ne 6 ]; then
		echo "Usage: `basename $0` nom_VM nom_APP type_APP path_APP port_APP serveur_APP"
  		exit $ERR_ARGS
	fi
	;;
    normal)
	;;
    serveur)
	echo "- Vérification du port de l'application";
	if [ $5 -lt 10000 ] && [ $5 -gt 10100 ]; then
       		echo "port_APP: 10000 à 10100 : $5"
        	exit $ERR_ARGS
	fi	
	;;	
    *)
	echo "type_APP: client | serveur | normal : $3"
	exit $ERR_ARGS;;
esac

mkdir -p logs/$1/
LOG="logs/$1/appSetup.log"

# On récupère l'adresse du controller
ADR=`rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`;

# On se connecte au controleur pour récupérer l'IP de la VM
IP=`ssh root@$ADR "source openstack-openrc.sh && nova list --name $1" | cut -d '|' -f 7 | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'`;

if [ "$3" = "client" ]; then
	# On se connecte au controleur pour récupérer l'IP de la VM serveur
	IPServeur=`ssh root@$ADR "source openstack-openrc.sh && nova list --name $6" | cut -d '|' -f 7 | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'`;
	echo "IP VM serveur : $6:$IPServeur"
	if [ -z "$IPServeur" ]; then
	        echo "L'IP de la VM serveur est introuvable"
	        exit $ERR_ARGS
	fi
fi

echo "- Copie de l'application ($2) sur la VM"
scp -q -p -r $4 debian@$IP: >> $LOG

echo "- Démarrage de l'application"
if [ "$3" = "client" ]; then
	ssh -q debian@$IP "cd $2; make $3; ls -l; ./$3 $IPServeur $5" >> $LOG &
else
 	ssh -q debian@$IP "cd $2; make $3; ls -l; ./$3 $5" >> $LOG &
fi

exit 0
