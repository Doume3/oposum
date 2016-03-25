#!/bin/bash

ERR_ARGS=-1

if [ $# -ne 5 ]
then
  echo "Usage: `basename $0` ip_vm nom_app type_app port_app path_app"
  exit $ERR_ARGS
fi

case $3 in
    client|serveur) 
	;;
    *)
	echo "Usage: client ou serveur"
	exit $ERR_ARGS;;
esac

if [ $4 -lt 10000 ] && [ $4 -gt 10100 ]; then
	echo "port_app : $4"
	echo "Usage: 10000 <= type_app <= 10100"
	exit $ERR_ARGS
fi

if [ -d "$5" ]; then
	echo "path_app : $5"
	echo "Usage : my/path/my/app/"
	exit $ERR_ARGS
fi

#On fetch l'adresse du controller
ADR=`rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`;

#On se connecte au controleur pour fetch l'IP de la VM
IP=`ssh root@$ADR 'source openstack-openrc.sh && nova list --name nvm_$2' | cut -d '|' -f 7 | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'`;

scp -p -r ~/xp5k-openstack/$5 debian@$1:
ssh debian@$1 "cd $1/; make;"

exit 0
