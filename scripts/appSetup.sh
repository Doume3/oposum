#!/bin/bash

ERR_ARGS=-1

if [ $# -ne 5 ] || [ $# -ne 6 ]; then
  echo "Usage: `basename $0` nom_VM nom_APP type_APP port_APP path_APP [nom_VM_Serveur]"
  exit $ERR_ARGS
fi

echo "- Vérification du type de l'application";
case $3 in
    client|serveur|normal) 
	if [ "$3" = "serveur" ] || [ "$3" = "normal" ]; then
		if [ $# -ne 5 ]; then
			echo "Usage: `basename $0` nom_VM nom_APP $3 port_APP path_APP"
			exit $ERR_ARGS
		fi
	elif [ "$3" = "client" ]; then
		if [ $# -ne 6 ]; then
                        echo "Usage: `basename $0` nom_VM nom_APP $3 port_APP path_APP nom_VM_Serveur"
                        exit $ERR_ARGS
                fi
	fi;;
    *)
	echo "type_APP: client | serveur | normal"
	exit $ERR_ARGS;;
esac

echo "- Vérification du port de l'application";
if [ $4 -lt 10000 ] && [ $4 -gt 10100 ]; then
	echo "port_APP: 10000 à 10100"
	exit $ERR_ARGS
fi

# On récupère l'adresse du controller
ADR=`rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`;

# On se connecte au controleur pour récupérer l'IP de la VM
IP=`ssh root@$ADR "source openstack-openrc.sh && nova list --name $1" | cut -d '|' -f 7 | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'`;

# On se connecte au controleur pour récupérer l'IP de la VM serveur
IPServeur=`ssh root@$ADR "source openstack-openrc.sh && nova list --name $6" | cut -d '|' -f 7 | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'`;
if [ -z "$IPServeur" ]; then
	echo "L'IP de la VM serveur est introuvable"
	exit $ERR_ARGS
fi

case $3 in
	client)
		$CAST="$3 $IPServeur $4";;
	serveur)
		$CAST="$3 $4";;
	normal)
		$CAST="$3";;
esac

echo "- Copie de l'application du la VM"
scp -p -r $5 debian@$IP:

echo "- Démarrage de l'application"
ssh debian@$IP "cd $5; make $3; ./$CAST"

exit 0
